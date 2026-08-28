import 'dart:convert';
import 'dart:io';

import '../core/logging/app_logger.dart';

class IniEntry {
  final String key;
  final String value;

  const IniEntry(this.key, this.value);
}

class IniFile {
  final Map<String, List<IniEntry>> _sections = {};
  final List<String> _sectionOrder = [];

  static Future<IniFile?> load(String path) async {
    final file = File(path);
    try {
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      var content = utf8.decode(bytes, allowMalformed: true);
      if (content.startsWith('\uFEFF')) content = content.substring(1);
      final ini = IniFile();
      ini._parse(content);

      return ini;
    } catch (e, st) {
      log.error('ini', 'failed to read $path', error: e, stack: st);

      return null;
    }
  }

  void _parse(String content) {
    var section = '';
    for (final raw in const LineSplitter().convert(content)) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) {
        continue;
      }
      if (line.startsWith('[') && line.endsWith(']')) {
        section = line.substring(1, line.length - 1).trim();
        if (!_sections.containsKey(section)) {
          _sections[section] = [];
          _sectionOrder.add(section);
        }
        continue;
      }
      final eq = line.indexOf('=');
      if (eq < 0) continue;
      final key = line.substring(0, eq).trim();
      if (key.isEmpty) continue;
      final value = line.substring(eq + 1).trim();
      _ensure(section).add(IniEntry(key, value));
    }
  }

  List<IniEntry> _ensure(String section) {
    final existing = _sections[section];
    if (existing != null) return existing;
    final list = <IniEntry>[];
    _sections[section] = list;
    _sectionOrder.add(section);

    return list;
  }

  List<IniEntry>? entries(String section) => _sections[section];

  String? get(String section, String key) {
    final list = _sections[section];
    if (list == null) return null;
    for (final e in list) {
      if (e.key == key) return e.value;
    }

    return null;
  }

  void set(String section, String key, String value) {
    final list = _ensure(section);
    for (var i = 0; i < list.length; i++) {
      if (list[i].key == key) {
        list[i] = IniEntry(key, value);

        return;
      }
    }
    list.add(IniEntry(key, value));
  }

  void remove(String section, String key) {
    final list = _sections[section];
    if (list == null) return;
    list.removeWhere((e) => e.key == key);
    if (list.isEmpty) {
      _sections.remove(section);
      _sectionOrder.remove(section);
    }
  }

  void setList(String section, String key, Iterable<String> values) =>
      set(section, key, values.join(','));

  List<String>? getList(String section, String key) {
    final raw = get(section, key);
    if (raw == null) return null;

    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  String serialize() {
    final sb = StringBuffer();
    for (final name in _sectionOrder) {
      final list = _sections[name];
      if (list == null || list.isEmpty) continue;
      if (name.isNotEmpty) sb.writeln('[$name]');
      for (final e in list) {
        sb.writeln('${e.key}=${e.value}');
      }
      sb.writeln();
    }

    return sb.toString();
  }

  Future<void> save(String path) async {
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(serialize())];
    final file = File(path);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    if (file.existsSync()) await file.delete();
    await tmp.rename(file.path);
  }
}
