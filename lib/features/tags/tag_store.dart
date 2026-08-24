import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/logging/app_logger.dart';
import '../../core/settings/settings_store.dart';
import '../../utils/ini_file.dart';

class TagDef {
  final int id;
  final String name;
  final Color color;
  final int orderIndex;

  const TagDef({
    required this.id,
    required this.name,
    required this.color,
    required this.orderIndex,
  });
}

const _defaultTags = <(String, int)>[
  ('红', 0xFFE5484D),
  ('绿', 0xFF46A758),
  ('蓝', 0xFF3E63DD),
];

class TagStore {
  static final TagStore instance = TagStore._();

  TagStore._();

  static const _tagsSection = '标签';
  static const _filesSection = '文件';

  final tags = signal<List<TagDef>>([]);

  late final byId = computed<Map<int, TagDef>>(
    () => {for (final tag in tags.value) tag.id: tag},
  );

  final fileTagsByName = signal<Map<String, Set<String>>>({});
  final fileTagsRevision = signal(0);

  @visibleForTesting
  String? directoryOverride;

  String get filePath {
    final dir = directoryOverride ?? p.dirname(Platform.resolvedExecutable);

    return p.join(dir, '标签.ini');
  }

  void notifyFileTagsChanged() => fileTagsRevision.value++;

  Map<String, Set<int>> get fileTagsById {
    final idByName = {for (final t in tags.value) t.name: t.id};

    return {
      for (final e in fileTagsByName.value.entries)
        e.key: {
          for (final name in e.value)
            if (idByName[name] != null) idByName[name]!,
        },
    };
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
    final defs = <TagDef>[];
    final tagEntries = ini.entries(_tagsSection) ?? const [];
    for (var i = 0; i < tagEntries.length; i++) {
      final color = int.tryParse(tagEntries[i].value) ?? 0xFF8B8D98;
      defs.add(
        TagDef(
          id: i + 1,
          name: tagEntries[i].key,
          color: Color(color),
          orderIndex: i,
        ),
      );
    }
    final fileMap = <String, Set<String>>{};
    final fileEntries = ini.entries(_filesSection) ?? const [];
    for (final e in fileEntries) {
      final names = e.value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (names.isNotEmpty) fileMap[e.key] = names;
    }
    tags.value = defs;
    fileTagsByName.value = fileMap;
  }

  Future<void> _migrateFromDb() async {
    try {
      final db = SettingsStore.instance.db;
      final rows = await db.getTags();
      final ini = IniFile();
      if (rows.isEmpty) {
        for (final d in _defaultTags) {
          ini.set(_tagsSection, d.$1, _colorString(d.$2));
        }
      } else {
        for (final row in rows) {
          ini.set(_tagsSection, row.name, _colorString(row.color));
        }
        for (final row in rows) {
          final paths = await db.getPathsForTag(row.id);
          for (final path in paths) {
            final current = ini.get(_filesSection, path);
            ini.set(
              _filesSection,
              path,
              current == null || current.isEmpty
                  ? row.name
                  : '$current,${row.name}',
            );
          }
        }
      }
      await ini.save(filePath);
      _applyIni(ini);
    } catch (e, st) {
      log.error('tags', 'failed to migrate tags', error: e, stack: st);
    }
  }

  String _colorString(int argb) =>
      '0x${argb.toRadixString(16).toUpperCase().padLeft(8, '0')}';

  Future<void> _save() async {
    final ini = IniFile();
    for (final tag in tags.value) {
      ini.set(_tagsSection, tag.name, _colorString(tag.color.toARGB32()));
    }
    for (final e in fileTagsByName.value.entries) {
      if (e.value.isEmpty) continue;
      ini.set(_filesSection, e.key, e.value.join(','));
    }
    await ini.save(filePath);
  }

  Future<void> createTag(String name, Color color) async {
    final maxId = tags.value.fold<int>(0, (m, t) => t.id > m ? t.id : m);
    tags.value = [
      ...tags.value,
      TagDef(
        id: maxId + 1,
        name: name,
        color: color,
        orderIndex: tags.value.length,
      ),
    ];
    await _save();
  }

  Future<void> updateTag(int id, {String? name, Color? color}) async {
    final current = byId.value[id];
    if (current == null) return;
    final newName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : current.name;
    tags.value = [
      for (final t in tags.value)
        if (t.id == id)
          TagDef(
            id: id,
            name: newName,
            color: color ?? current.color,
            orderIndex: t.orderIndex,
          )
        else
          t,
    ];
    if (newName != current.name) {
      final map = {
        for (final e in fileTagsByName.value.entries) e.key: {...e.value},
      };
      for (final entry in map.entries) {
        if (entry.value.contains(current.name)) {
          entry.value.remove(current.name);
          entry.value.add(newName);
        }
      }
      fileTagsByName.value = map;
    }
    await _save();
  }

  Future<void> deleteTag(int id) async {
    final def = byId.value[id];
    if (def == null) return;
    tags.value = tags.value.where((t) => t.id != id).toList();
    final map = {
      for (final e in fileTagsByName.value.entries) e.key: {...e.value},
    };
    for (final entry in map.entries) {
      entry.value.remove(def.name);
    }
    map.removeWhere((key, value) => value.isEmpty);
    fileTagsByName.value = map;
    notifyFileTagsChanged();
    await _save();
  }

  Future<void> reorder(List<int> idsInOrder) async {
    final byIdMap = {for (final t in tags.value) t.id: t};
    final next = <TagDef>[];
    for (final id in idsInOrder) {
      final t = byIdMap[id];
      if (t == null) continue;
      next.add(
        TagDef(id: t.id, name: t.name, color: t.color, orderIndex: next.length),
      );
    }
    tags.value = next;
    await _save();
  }

  Future<void> addFileTag(String path, int tagId) async {
    final name = byId.value[tagId]?.name;
    if (name == null) return;
    final map = {...fileTagsByName.value};
    final set = {...(map[path] ?? <String>{})};
    set.add(name);
    map[path] = set;
    fileTagsByName.value = map;
    await _save();
  }

  Future<void> removeFileTag(String path, int tagId) async {
    final name = byId.value[tagId]?.name;
    if (name == null) return;
    final map = {...fileTagsByName.value};
    final set = {...(map[path] ?? <String>{})};
    set.remove(name);
    if (set.isEmpty) {
      map.remove(path);
    } else {
      map[path] = set;
    }
    fileTagsByName.value = map;
    await _save();
  }

  Future<void> clearFileTags(String path) async {
    final map = {...fileTagsByName.value}..remove(path);
    fileTagsByName.value = map;
    await _save();
  }

  Future<void> moveFileTags(String oldPath, String newPath) async {
    final map = {...fileTagsByName.value};
    final names = map.remove(oldPath);
    if (names == null || names.isEmpty) return;
    map[newPath] = names;
    fileTagsByName.value = map;
    await _save();
  }
}
