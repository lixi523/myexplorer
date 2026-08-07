import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/logging/app_logger.dart';
import 'hidden_ini.dart';

/// Loads, holds and persists the user's hidden file/folder list.
///
/// The list is stored as `隐藏文件.ini` (INI format, UTF-8 with BOM) in the
/// directory that contains the application executable (the "software folder
/// root"). The file is the single source of truth: editing it by hand (e.g.
/// removing a line) is the only supported way to un-hide an item.
class HiddenListStore {
  HiddenListStore._();

  static final HiddenListStore instance = HiddenListStore._();

  /// Overridable for tests; when null the file lives next to the executable.
  @visibleForTesting
  String? directoryOverride;

  final paths = signal<List<String>>(const []);
  final loaded = signal(false);

  /// The INI file location: `<exe dir>\隐藏文件.ini`.
  String get filePath {
    final dir = directoryOverride ?? p.dirname(Platform.resolvedExecutable);

    return p.join(dir, '隐藏文件.ini');
  }

  bool get isLoaded => loaded.value;

  /// Returns true when [path] matches an entry exactly (after normalization).
  bool isHidden(String path) {
    final norm = normalizeHiddenPath(path);
    if (norm.isEmpty) return false;

    return paths.value.any((e) => normalizeHiddenPath(e) == norm);
  }

  /// Loads the INI file (or starts with an empty list when missing).
  Future<void> load() async {
    final file = File(filePath);
    try {
      if (!file.existsSync()) {
        paths.value = const [];
        loaded.value = true;

        return;
      }
      final bytes = await file.readAsBytes();
      var content = utf8.decode(bytes, allowMalformed: true);
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }
      paths.value = parseHiddenIni(content);
      loaded.value = true;
    } catch (e, st) {
      log.error('hidden', 'failed to read $filePath', error: e, stack: st);
      _backupCorruptFile(file);
      paths.value = const [];
      loaded.value = true;
    }
  }

  /// Adds one or more paths (deduplicated) and persists the file.
  Future<void> addPaths(Iterable<String> newPaths) async {
    var changed = false;
    final next = [...paths.value];
    for (final raw in newPaths) {
      final norm = normalizeHiddenPath(raw);
      if (norm.isEmpty) continue;
      if (next.any((e) => normalizeHiddenPath(e) == norm)) continue;
      next.add(raw.trim());
      changed = true;
    }
    if (!changed) return;
    paths.value = next;
    await _save();
  }

  /// Removes a single entry by exact path match and persists the file.
  Future<void> removePath(String path) async {
    final norm = normalizeHiddenPath(path);
    final next = paths.value
        .where((e) => normalizeHiddenPath(e) != norm)
        .toList();
    if (next.length == paths.value.length) return;
    paths.value = next;
    await _save();
  }

  Future<void> _save() async {
    final file = File(filePath);
    try {
      final content = serializeHiddenIni(paths.value);
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(content)];
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      if (file.existsSync()) await file.delete();
      await tmp.rename(file.path);
    } catch (e, st) {
      log.error('hidden', 'failed to write $filePath', error: e, stack: st);
    }
  }

  void _backupCorruptFile(File file) {
    try {
      if (!file.existsSync()) return;
      file.copySync('${file.path}.bak');
    } catch (e) {
      log.error('hidden', 'failed to back up corrupt $filePath', error: e);
    }
  }
}
