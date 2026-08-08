import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/navigation/shortcut_runner.dart';

void main() {
  const ctx = ShortcutRunContext(
    sourcePath: r'C:\src',
    targetPath: r'D:\dst',
    selectedNames: ['a.txt', 'b.txt'],
    selectedFullPaths: [r'C:\src\a.txt', r'C:\src\b.txt'],
    cursorName: 'a.txt',
    cursorFullPath: r'C:\src\a.txt',
  );

  group('expandShortcutMacros', () {
    test('uppercase macros are quoted', () {
      expect(expandShortcutMacros('%P', ctx), '"C:\\src"');
      expect(expandShortcutMacros('%N', ctx), '"a.txt"');
      expect(expandShortcutMacros('%T', ctx), '"D:\\dst"');
      expect(expandShortcutMacros('%L', ctx), '"C:\\src\\a.txt"');
    });

    test('lowercase macros are raw', () {
      expect(expandShortcutMacros('%p', ctx), r'C:\src');
      expect(expandShortcutMacros('%n', ctx), 'a.txt');
      expect(expandShortcutMacros('%t', ctx), r'D:\dst');
      expect(expandShortcutMacros('%l', ctx), r'C:\src\a.txt');
    });

    test('%M and %S join all selections', () {
      expect(expandShortcutMacros('%M', ctx), '"a.txt" "b.txt"');
      expect(expandShortcutMacros('%m', ctx), 'a.txt b.txt');
      expect(
        expandShortcutMacros('%S', ctx),
        '"C:\\src\\a.txt" "C:\\src\\b.txt"',
      );
      expect(expandShortcutMacros('%s', ctx), r'C:\src\a.txt C:\src\b.txt');
    });

    test('leaves unknown macros and plain text alone', () {
      expect(expandShortcutMacros('echo %X', ctx), 'echo %X');
      expect(expandShortcutMacros('100% done', ctx), '100% done');
    });

    test('mixed command line', () {
      expect(
        expandShortcutMacros('notepad.exe %L', ctx),
        'notepad.exe "C:\\src\\a.txt"',
      );
      expect(
        expandShortcutMacros('copy %S %T', ctx),
        'copy "C:\\src\\a.txt" "C:\\src\\b.txt" "D:\\dst"',
      );
    });

    test('empty values produce empty output', () {
      const empty = ShortcutRunContext.empty;
      expect(expandShortcutMacros('%P %N %M', empty), '  ');
    });
  });
}
