import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import 'toolbar_ini.dart';

/// User-defined items shown on the shortcut bar below the title bar.
///
/// Items are persisted in `<exe dir>\快捷栏.ini` — a hand-editable INI file
/// that serves as the single source of truth. The file is read on startup and
/// written on every mutation (add, remove, reorder).
class ShortcutBarStore {
  static final ShortcutBarStore instance = ShortcutBarStore._();

  ShortcutBarStore._();

  final items = signal<List<ShortcutBarItem>>([]);

  /// The INI file location: `<exe dir>\快捷栏.ini`.
  String get filePath =>
      p.join(p.dirname(Platform.resolvedExecutable), '快捷栏.ini');

  /// Loads items from the INI file. Starts with an empty list when missing.
  Future<void> load() async {
    final file = File(filePath);
    try {
      if (!file.existsSync()) {
        items.value = const [];
        return;
      }
      final bytes = await file.readAsBytes();
      var content = utf8.decode(bytes, allowMalformed: true);
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }
      final parsed = parseToolbarIni(content);
      items.value = [
        for (var i = 0; i < parsed.length; i++)
          ShortcutBarItem(
            id: i,
            orderIndex: i,
            label: parsed[i].label,
            target: parsed[i].target,
            icon: parsed[i].icon,
          ),
      ];
    } catch (_) {
      items.value = const [];
    }
  }

  /// Adds a new item and persists the INI file.
  Future<void> add(String label, String target, {String? icon}) async {
    final current = [...items.value];
    final id = current.isEmpty ? 0 : current.map((e) => e.id).reduce(max) + 1;
    current.add(
      ShortcutBarItem(
        id: id,
        orderIndex: id,
        label: label,
        target: target,
        icon: icon,
      ),
    );
    items.value = current;
    await _save();
  }

  /// Inserts [specs] in order and persists once. Empty label/target entries
  /// are kept as separators.
  Future<void> addAll(
    List<({String label, String target, String? icon})> specs,
  ) async {
    if (specs.isEmpty) return;
    final current = [...items.value];
    var nextId = current.isEmpty ? 0 : current.map((e) => e.id).reduce(max) + 1;
    for (final spec in specs) {
      current.add(
        ShortcutBarItem(
          id: nextId,
          orderIndex: nextId,
          label: spec.label,
          target: spec.target,
          icon: spec.icon,
        ),
      );
      nextId++;
    }
    items.value = current;
    await _save();
  }

  /// Removes the item with [id] and persists.
  Future<void> remove(int id) async {
    final current = [...items.value];
    current.removeWhere((e) => e.id == id);
    items.value = current;
    await _save();
  }

  /// Reorders items to match [idsInOrder] and persists.
  Future<void> reorder(List<int> idsInOrder) async {
    final current = [...items.value];
    final reordered = <ShortcutBarItem>[];
    final remaining = <ShortcutBarItem>[...current];
    for (final id in idsInOrder) {
      final idx = remaining.indexWhere((e) => e.id == id);
      if (idx >= 0) {
        reordered.add(remaining.removeAt(idx));
      }
    }
    reordered.addAll(remaining);
    for (var i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].copyWith(orderIndex: i);
    }
    items.value = reordered;
    await _save();
  }

  Future<void> _pendingSave = Future.value();

  /// Serializes writes so rapid mutations cannot race on the shared `.tmp`
  /// file. Each call snapshots the current items; the chain applies them in
  /// order, so the final file always reflects the last mutation.
  Future<void> _save() {
    final specs = items.value
        .map((e) => (label: e.label, target: e.target, icon: e.icon))
        .toList();
    _pendingSave = _pendingSave.then((_) => _writeFile(specs));

    return _pendingSave;
  }

  Future<void> _writeFile(
    List<({String label, String target, String? icon})> specs,
  ) async {
    final file = File(filePath);
    try {
      final content = serializeToolbarIni(specs);
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(content)];
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      if (file.existsSync()) await file.delete();
      await tmp.rename(file.path);
    } catch (_) {
      // write failures are non-fatal
    }
  }
}
