import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/logging/app_logger.dart';
import '../../core/settings/settings_store.dart';
import '../../utils/ini_file.dart';

const sidebarSectionFavorites = 'favorites';
const sidebarSectionDevices = 'devices';
const sidebarSectionContainers = 'containers';
const sidebarSectionNetwork = 'network';
const sidebarSectionBookmarks = 'bookmarks';
const sidebarSectionTags = 'tags';

const _defaultSectionOrder = [
  sidebarSectionFavorites,
  sidebarSectionDevices,
  sidebarSectionContainers,
  sidebarSectionNetwork,
  sidebarSectionTags,
  sidebarSectionBookmarks,
];

const _scopeSectionName = <String, String>{
  sidebarSectionFavorites: '收藏',
  sidebarSectionDevices: '设备',
  sidebarSectionContainers: '容器',
  sidebarSectionNetwork: '网络',
};

class SidebarStore {
  static final SidebarStore instance = SidebarStore._();

  SidebarStore._();

  static const _areaSection = '区域';
  static const _orderKey = '顺序';
  static const _hiddenKey = '隐藏';
  static const _collapsedKey = '折叠';

  final editing = signal<bool>(false);
  final sectionOrder = signal<List<String>>(_defaultSectionOrder);
  final hiddenSections = signal<Set<String>>(const {});
  final collapsedSections = signal<Set<String>>(const {});
  final itemOrder = signal<Map<String, List<String>>>(const {});
  final hiddenItems = signal<Map<String, Set<String>>>(const {});

  @visibleForTesting
  String? directoryOverride;

  String get filePath {
    final dir = directoryOverride ?? p.dirname(Platform.resolvedExecutable);

    return p.join(dir, '侧栏.ini');
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
    final storedSections = ini.getList(_areaSection, _orderKey) ?? const [];
    sectionOrder.value = [
      ...storedSections.where(_defaultSectionOrder.contains),
      ..._defaultSectionOrder.where((s) => !storedSections.contains(s)),
    ];
    hiddenSections.value = {
      ...(ini.getList(_areaSection, _hiddenKey) ?? const []),
    };
    collapsedSections.value = {
      ...(ini.getList(_areaSection, _collapsedKey) ?? const []),
    };

    final order = <String, List<String>>{};
    final hidden = <String, Set<String>>{};
    for (final scope in _defaultSectionOrder) {
      if (scope == sidebarSectionBookmarks) continue;
      final sectionName = _scopeSectionName[scope]!;
      order[scope] = ini.getList(sectionName, _orderKey) ?? const [];
      hidden[scope] = {...(ini.getList(sectionName, _hiddenKey) ?? const [])};
    }
    itemOrder.value = order;
    hiddenItems.value = hidden;
  }

  Future<void> _migrateFromDb() async {
    try {
      final db = SettingsStore.instance.db;
      final rows = await db.getSidebarPrefs();
      if (rows.isEmpty) return;
      final ini = IniFile();
      final sectionRows = rows.where((r) => r.scope == 'section').toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      ini.setList(_areaSection, _orderKey, sectionRows.map((r) => r.itemKey));
      ini.setList(
        _areaSection,
        _hiddenKey,
        sectionRows.where((r) => r.hidden).map((r) => r.itemKey),
      );
      ini.setList(
        _areaSection,
        _collapsedKey,
        rows
            .where((r) => r.scope == 'collapsed' && r.hidden)
            .map((r) => r.itemKey),
      );
      for (final scope in _defaultSectionOrder) {
        if (scope == sidebarSectionBookmarks) continue;
        final scopeRows = rows.where((r) => r.scope == scope).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        final sectionName = _scopeSectionName[scope]!;
        ini.setList(sectionName, _orderKey, scopeRows.map((r) => r.itemKey));
        ini.setList(
          sectionName,
          _hiddenKey,
          scopeRows.where((r) => r.hidden).map((r) => r.itemKey),
        );
      }
      await ini.save(filePath);
      _applyIni(ini);
    } catch (e, st) {
      log.error(
        'sidebar',
        'failed to migrate sidebar prefs',
        error: e,
        stack: st,
      );
    }
  }

  Future<void> _save() async {
    final ini = IniFile();
    ini.setList(_areaSection, _orderKey, sectionOrder.value);
    ini.setList(_areaSection, _hiddenKey, hiddenSections.value);
    ini.setList(_areaSection, _collapsedKey, collapsedSections.value);
    for (final scope in _defaultSectionOrder) {
      if (scope == sidebarSectionBookmarks) continue;
      final sectionName = _scopeSectionName[scope]!;
      ini.setList(sectionName, _orderKey, itemOrder.value[scope] ?? const []);
      ini.setList(
        sectionName,
        _hiddenKey,
        hiddenItems.value[scope] ?? const {},
      );
    }
    await ini.save(filePath);
  }

  void toggleEditing() => editing.value = !editing.value;

  bool isSectionHidden(String id) => hiddenSections.value.contains(id);

  bool isSectionCollapsed(String id) => collapsedSections.value.contains(id);

  Future<void> setSectionCollapsed(String id, bool collapsed) async {
    final next = {...collapsedSections.value};
    if (collapsed) {
      next.add(id);
    } else {
      next.remove(id);
    }
    collapsedSections.value = next;
    await _save();
  }

  bool isItemHidden(String scope, String key) =>
      hiddenItems.value[scope]?.contains(key) ?? false;

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    final next = _moved(sectionOrder.value, oldIndex, newIndex);
    if (next == null) return;
    sectionOrder.value = next;
    await _save();
  }

  Future<void> setSectionHidden(String id, bool hidden) async {
    final next = {...hiddenSections.value};
    if (hidden) {
      next.add(id);
    } else {
      next.remove(id);
    }
    hiddenSections.value = next;
    await _save();
  }

  List<T> orderItems<T>(String scope, List<T> items, String Function(T) keyOf) {
    final order = itemOrder.value[scope];
    if (order == null || order.isEmpty) return items;
    final pos = {for (var i = 0; i < order.length; i++) order[i]: i};
    final known = <T>[];
    final unknown = <T>[];
    for (final item in items) {
      (pos.containsKey(keyOf(item)) ? known : unknown).add(item);
    }
    known.sort((a, b) => pos[keyOf(a)]!.compareTo(pos[keyOf(b)]!));

    return [...known, ...unknown];
  }

  Future<void> reorderItems(
    String scope,
    int oldIndex,
    int newIndex,
    List<String> currentKeys,
  ) async {
    final next = _moved(currentKeys, oldIndex, newIndex);
    if (next == null) return;
    final map = {...itemOrder.value};
    map[scope] = next;
    itemOrder.value = map;
    await _save();
  }

  Future<void> setItemHidden(
    String scope,
    String key,
    bool hidden,
    List<String> currentKeys,
  ) async {
    final map = {
      for (final e in hiddenItems.value.entries) e.key: {...e.value},
    };
    final bucket = map.putIfAbsent(scope, () => <String>{});
    if (hidden) {
      bucket.add(key);
    } else {
      bucket.remove(key);
    }
    hiddenItems.value = map;
    final order = {...itemOrder.value};
    order[scope] = currentKeys;
    itemOrder.value = order;
    await _save();
  }

  List<String>? _moved(List<String> source, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= source.length) return null;
    var to = newIndex;
    if (to < 0) to = 0;
    if (to > source.length - 1) to = source.length - 1;
    if (to == oldIndex) return null;
    final list = [...source];
    final item = list.removeAt(oldIndex);
    list.insert(to, item);

    return list;
  }
}
