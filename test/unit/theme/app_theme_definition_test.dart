import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/ui/theme/app_theme_definition.dart';
import 'package:myexplorer/ui/theme/app_theme_registry.dart';

void main() {
  group('AppThemeDefinition', () {
    test('round-trips through ini', () {
      final theme = AppThemeDefinition(
        id: 'custom',
        name: 'Custom',
        brightness: Brightness.dark,
        palette: darkTheme.palette,
      );

      final parsed = AppThemeDefinition.fromIni(theme.toIni());

      expect(parsed.id, 'custom');
      expect(parsed.name, 'Custom');
      expect(parsed.brightness, Brightness.dark);
      expect(parsed.palette.bg, darkTheme.palette.bg);
      expect(parsed.palette.accent, darkTheme.palette.accent);
    });

    test('parses rgb and argb hex colors', () {
      expect(parseThemeColor('#181818', 'bg'), const Color(0xFF181818));
      expect(parseThemeColor('#33181818', 'bg'), const Color(0x33181818));
      expect(parseThemeColor('0xFF181818', 'bg'), const Color(0xFF181818));
      expect(parseThemeColor('FF181818', 'bg'), const Color(0xFF181818));
    });

    test('rejects missing required color fields', () {
      final ini = AppThemeDefinition(
        id: 'broken',
        name: 'Broken',
        brightness: Brightness.dark,
        palette: darkTheme.palette,
      ).toIni();
      final broken = ini
          .split('\n')
          .where((line) => !line.startsWith('背景色='))
          .join('\n');

      expect(
        () => AppThemeDefinition.fromIni(broken),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid colors', () {
      expect(
        () => parseThemeColor('#XYZ', 'accent'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
