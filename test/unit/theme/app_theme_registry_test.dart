import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/logging/app_logger.dart';
import 'package:myexplorer/core/platform/gbk_codec.dart';
import 'package:myexplorer/ui/theme/app_theme_registry.dart';

String _iniFor(String id, String name) => darkTheme
    .toIni()
    .replaceFirst('id=dark', 'id=$id')
    .replaceFirst('name=Dark', 'name=$name');

void main() {
  group('AppThemeRegistry', () {
    late Directory dir;

    final builtInIds = builtInThemes.map((theme) => theme.id).toList();

    setUp(() {
      dir = Directory.systemTemp.createTempSync('myexplorer_theme_registry_');
      log.clear();
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
      log.clear();
    });

    test('starts with built-in themes', () {
      final registry = AppThemeRegistry();

      expect(registry.themes.map((theme) => theme.id), builtInIds);
    });

    test('includes One Dark as a built-in theme', () {
      final registry = AppThemeRegistry();
      final theme = registry.resolve('one-dark');

      expect(theme.name, 'One Dark');
      expect(theme.builtIn, isTrue);
      expect(theme.palette.bg.toARGB32(), 0xFF282C34);
      expect(theme.palette.terminal.blue.toARGB32(), 0xFF61AFEF);
    });

    test('loads valid custom themes after built-ins', () async {
      File(
        '${dir.path}/midnight.ini',
      ).writeAsStringSync(_iniFor('midnight', 'Midnight'));

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.themes.map((theme) => theme.id), [
        ...builtInIds,
        'midnight',
      ]);
      expect(registry.resolve('midnight').name, 'Midnight');
    });

    test('skips invalid themes and logs diagnostics entries', () async {
      File('${dir.path}/broken.ini').writeAsStringSync(
        '[meta]\nid=broken\nname=Broken\nbrightness=dark\n\n[palette]\n',
      );

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.themes.map((theme) => theme.id), builtInIds);
      expect(log.entries.value, isNotEmpty);
      expect(log.entries.value.last.tag, 'theme');
    });

    test('ini themes override built-in themes with the same id', () async {
      File(
        '${dir.path}/dark.ini',
      ).writeAsStringSync(_iniFor('dark', 'Other Dark'));

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.resolve('dark').name, 'Other Dark');
      expect(registry.themes.length, builtInThemes.length);
    });

    test('loads GBK-encoded theme ini files', () async {
      final content = _iniFor('gbk-theme', '中文主题');
      final gbk = encodeGbkBytes(content);
      if (gbk == null) {
        markTestSkipped('GBK codec unavailable off Windows');
      }
      File('${dir.path}/gbk-theme.ini').writeAsBytesSync(gbk!);

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.resolve('gbk-theme').name, '中文主题');
    });

    test('unknown ids resolve to dark and log once', () {
      final registry = AppThemeRegistry();

      expect(registry.resolve('missing').id, 'dark');
      expect(registry.resolve('missing').id, 'dark');
      expect(
        log.entries.value.where((entry) => entry.tag == 'theme'),
        hasLength(1),
      );
    });
  });
}
