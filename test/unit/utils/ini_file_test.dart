import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/utils/ini_file.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('ini_file_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  String path(String name) => '${tmp.path}${Platform.pathSeparator}$name';

  group('IniFile parse', () {
    test('loads sections, keys and skips comments', () async {
      final file = File(path('a.ini'));
      await file.writeAsBytes([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(
          '; comment\n[书签]\nC:\\a=Label A\nD:\\b=Label B\n\n[标签]\n红=0xFFE5484D\n',
        ),
      ]);

      final ini = await IniFile.load(file.path);

      expect(ini, isNotNull);
      expect(ini!.entries('书签')?.length, 2);
      expect(ini.get('书签', r'C:\a'), 'Label A');
      expect(ini.get('标签', '红'), '0xFFE5484D');
      expect(ini.get('标签', 'missing'), isNull);
    });

    test('returns null when the file does not exist', () async {
      expect(await IniFile.load(path('missing.ini')), isNull);
    });
  });

  group('IniFile write', () {
    test('round-trips values through save and load', () async {
      final ini = IniFile();
      ini.setList('区域', '顺序', ['a', 'b', 'c']);
      ini.set('区域', '隐藏', 'b');
      ini.set('收藏', '顺序', 'x,y');

      await ini.save(path('out.ini'));

      final loaded = await IniFile.load(path('out.ini'));

      expect(loaded, isNotNull);
      expect(loaded!.getList('区域', '顺序'), ['a', 'b', 'c']);
      expect(loaded.get('区域', '隐藏'), 'b');
      expect(loaded.getList('收藏', '顺序'), ['x', 'y']);
    });

    test('set updates an existing key in place', () async {
      final ini = IniFile();
      ini.set('s', 'k', 'v1');
      ini.set('s', 'k', 'v2');

      expect(ini.entries('s')?.length, 1);
      expect(ini.get('s', 'k'), 'v2');
    });

    test('serialize drops empty sections', () {
      final ini = IniFile();
      ini.set('s', 'k', 'v');
      ini.remove('s', 'k');

      expect(ini.serialize(), isEmpty);
    });
  });
}
