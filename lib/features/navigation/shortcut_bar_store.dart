import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import '../../core/settings/settings_store.dart';

/// User-defined items shown on the shortcut bar below the title bar.
/// Each item opens a folder/file path or runs a command line, following
/// Total Commander button bar conventions (`CD …`, `cm_…`, `path,index`
/// icons, empty items as separators).
class ShortcutBarStore {
  static final ShortcutBarStore instance = ShortcutBarStore._();

  ShortcutBarStore._();

  final items = signal<List<ShortcutBarItem>>([]);

  AppDatabase get _db => SettingsStore.instance.db;

  Future<void> load() async {
    items.value = await _db.getShortcutBarItems();
  }

  Future<void> add(String label, String target, {String? icon}) async {
    await _db.addShortcutBarItem(label, target, icon: icon);
    await load();
  }

  /// Inserts [specs] in order and reloads once. Empty label/target specs are
  /// kept as separators.
  Future<void> addAll(
    List<({String label, String target, String? icon})> specs,
  ) async {
    if (specs.isEmpty) return;
    await _db.addShortcutBarItems(specs);
    await load();
  }

  Future<void> remove(int id) async {
    await _db.deleteShortcutBarItem(id);
    await load();
  }

  Future<void> reorder(List<int> idsInOrder) async {
    await _db.reorderShortcutBarItems(idsInOrder);
    await load();
  }
}
