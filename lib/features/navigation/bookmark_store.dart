import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../utils/ini_file.dart';
import '../locations/location_resolver.dart';
import '../locations/location_uri.dart';

class BookmarkStore {
  static final BookmarkStore instance = BookmarkStore._();

  BookmarkStore._();

  static const _section = '书签';

  final bookmarks = signal<List<Bookmark>>([]);

  @visibleForTesting
  String? directoryOverride;

  String get filePath {
    final dir = directoryOverride ?? p.dirname(Platform.resolvedExecutable);

    return p.join(dir, '书签.ini');
  }

  Future<void> load() async {
    final ini = await IniFile.load(filePath);
    if (ini == null) {
      await _migrateFromDb();

      return;
    }
    _applyIni(ini);
  }

  void _applyIni(IniFile ini) {
    final entries = ini.entries(_section) ?? const [];
    bookmarks.value = [
      for (var i = 0; i < entries.length; i++)
        Bookmark(
          id: i + 1,
          orderIndex: i,
          label: entries[i].value,
          path: entries[i].key,
        ),
    ];
  }

  Future<void> _migrateFromDb() async {
    try {
      final db = SettingsStore.instance.db;
      final rows = await db.getBookmarks();
      if (rows.isEmpty) return;
      final ini = IniFile();
      for (final row in rows) {
        ini.set(_section, row.path, row.label);
      }
      await ini.save(filePath);
      _applyIni(ini);
    } catch (e, st) {
      log.error(
        'bookmarks',
        'failed to migrate bookmarks',
        error: e,
        stack: st,
      );
    }
  }

  Future<void> _save() async {
    final ini = IniFile();
    for (final b in bookmarks.value) {
      ini.set(_section, b.path, b.label);
    }
    await ini.save(filePath);
  }

  Future<void> addPath(String path) async {
    final storedPath = _storedPathFor(path);
    if (storedPath == null) return;
    final uri = LocationUri.parse(storedPath);
    final label = uri.isLocal
        ? PlatformPaths.fileName(storedPath)
        : uri.displayLabel;
    await _addUnique(label, storedPath);
  }

  bool containsPath(String path) {
    final storedPath = _storedPathFor(path);
    if (storedPath == null) return false;

    return bookmarks.value.any((b) => b.path == storedPath);
  }

  Future<void> togglePath(String path) async {
    final storedPath = _storedPathFor(path);
    if (storedPath == null) return;
    final existing = bookmarks.value
        .where((b) => b.path == storedPath)
        .firstOrNull;
    if (existing != null) {
      await remove(existing);

      return;
    }
    final uri = LocationUri.parse(storedPath);
    final label = uri.isLocal
        ? PlatformPaths.fileName(storedPath)
        : uri.displayLabel;
    await _addUnique(label, storedPath);
  }

  String? _storedPathFor(String path) {
    final uri = LocationUri.parse(path);
    if (uri.isLocal) {
      final normalized = PlatformPaths.normalize(path);
      final logical = LocationResolver.physicalToLogical(normalized);
      if (logical != null) return logical;
      if (!Directory(normalized).existsSync()) return null;

      return normalized;
    }

    return uri.raw;
  }

  Future<void> addLocation(String location, {String? label}) async {
    final uri = LocationUri.parse(location);
    final stored = uri.isLocal ? PlatformPaths.normalize(uri.raw) : uri.raw;
    final lbl = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : (uri.isLocal ? PlatformPaths.fileName(stored) : uri.displayLabel);
    await _addUnique(lbl, stored);
  }

  Future<void> _addUnique(String label, String storedPath) async {
    final list = bookmarks.value;
    if (list.any((b) => b.path == storedPath)) return;
    bookmarks.value = [
      ...list,
      Bookmark(
        id: list.length + 1,
        orderIndex: list.length,
        label: label,
        path: storedPath,
      ),
    ];
    await _save();
  }

  Future<void> rename(Bookmark bookmark, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == bookmark.label) return;
    bookmarks.value = [
      for (final b in bookmarks.value)
        if (b.id == bookmark.id)
          Bookmark(
            id: b.id,
            orderIndex: b.orderIndex,
            label: trimmed,
            path: b.path,
          )
        else
          b,
    ];
    await _save();
  }

  Future<void> remove(Bookmark bookmark) async {
    bookmarks.value = bookmarks.value
        .where((b) => b.id != bookmark.id)
        .toList();
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...bookmarks.value];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    var to = newIndex;
    if (to < 0) to = 0;
    if (to > list.length - 1) to = list.length - 1;
    if (to == oldIndex) return;
    final item = list.removeAt(oldIndex);
    list.insert(to, item);
    bookmarks.value = [
      for (var i = 0; i < list.length; i++)
        Bookmark(
          id: i + 1,
          orderIndex: i,
          label: list[i].label,
          path: list[i].path,
        ),
    ];
    await _save();
  }
}
