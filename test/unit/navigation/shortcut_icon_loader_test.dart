import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/navigation/shortcut_icon_loader.dart';

void main() {
  group('parseIconSpec', () {
    test('splits path,index specs', () {
      expect(parseIconSpec(r'C:\x\shell32.dll,34'), (r'C:\x\shell32.dll', 34));
      expect(parseIconSpec(r'C:\x\app.exe'), (r'C:\x\app.exe', 0));
    });

    test('strips surrounding quotes', () {
      expect(parseIconSpec(r'"C:\x\app.exe,2"'), (r'C:\x\app.exe', 2));
    });

    test('handles null and empty specs', () {
      expect(parseIconSpec(null), ('', 0));
      expect(parseIconSpec(''), ('', 0));
    });
  });

  group('isSvgIconSpec', () {
    test('detects svg specs only', () {
      expect(isSvgIconSpec(r'C:\x\icon.svg'), isTrue);
      expect(isSvgIconSpec(r'C:\x\app.exe'), isFalse);
      expect(isSvgIconSpec(null), isFalse);
      expect(isSvgIconSpec(''), isFalse);
    });
  });

  group('resolveShortcutIcon', () {
    test('returns null for a missing file', () async {
      final provider = await resolveShortcutIcon(
        r'C:\Windows\System32\does_not_exist_zzz.exe',
      );
      expect(provider, isNull);
    });

    test('extracts an embedded icon from an exe', () async {
      final target = r'C:\Windows\System32\notepad.exe';
      if (!File(target).existsSync()) {
        markTestSkipped('notepad.exe not found on this host');
        return;
      }
      final provider = await resolveShortcutIcon(target);
      expect(provider, isNotNull, reason: 'exe icon extraction failed');
    });
  });
}
