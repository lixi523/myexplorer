import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/navigation/toolbar_ini.dart';

void main() {
  group('parseToolbarIni', () {
    test('parses label, target and icon', () {
      const content =
          '[Toolbar]\n'
          'Home | C:\\Programs\\App | C:\\Programs\\App\\icon.ico\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(1));
      expect(items.single.label, 'Home');
      expect(items.single.target, r'C:\Programs\App');
      expect(items.single.icon, r'C:\Programs\App\icon.ico');
    });

    test('parses entries without an icon', () {
      const content =
          '[Toolbar]\n'
          'Docs | D:\\Docs\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(1));
      expect(items.single.label, 'Docs');
      expect(items.single.target, r'D:\Docs');
      expect(items.single.icon, isNull);
    });

    test('treats an empty icon as absent', () {
      const content =
          '[Toolbar]\n'
          'Docs | D:\\Docs | \n';
      final items = parseToolbarIni(content);
      expect(items.single.icon, isNull);
    });

    test('parses a separator line', () {
      const content =
          '[Toolbar]\n'
          'A | C:\\A\n'
          '|\n'
          'B | C:\\B\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(3));
      expect(items[1].label, isEmpty);
      expect(items[1].target, isEmpty);
      expect(items[1].icon, isNull);
    });

    test('keeps Windows backslashes in paths', () {
      const content = r'''[Toolbar]
Home | C:\Users\me | C:\Users\me\icon.ico
''';
      final items = parseToolbarIni(content);
      expect(items.single.target, r'C:\Users\me');
      expect(items.single.icon, r'C:\Users\me\icon.ico');
    });

    test('parses escaped backslashes', () {
      const content =
          '[Toolbar]\n'
          r'Share | \\server\share'
          '\n';
      final items = parseToolbarIni(content);
      expect(items.single.target, r'\server\share');
    });

    test('unwraps escaped pipes', () {
      const content =
          '[Toolbar]\n'
          r'Notes | C:\Dir with\|pipe'
          '\n';
      final items = parseToolbarIni(content);
      expect(items.single.target, r'C:\Dir with|pipe');
    });

    test('skips comments and blank lines', () {
      const content =
          '[Toolbar]\n'
          '; a comment\n'
          '\n'
          '# another comment\n'
          'A | C:\\A\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(1));
      expect(items.single.label, 'A');
    });

    test('strips a UTF-8 BOM', () {
      const content =
          '\uFEFF[Toolbar]\n'
          'A | C:\\A\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(1));
      expect(items.single.label, 'A');
    });

    test('ignores content outside the [Toolbar] section', () {
      const content =
          '[Other]\n'
          'X | C:\\X\n'
          '[Toolbar]\n'
          'A | C:\\A\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(1));
      expect(items.single.label, 'A');
    });

    test('matches the section name case-insensitively', () {
      const content =
          '[toolbar]\n'
          'A | C:\\A\n';
      final items = parseToolbarIni(content);
      expect(items, hasLength(1));
      expect(items.single.label, 'A');
    });

    test('trims surrounding whitespace from fields', () {
      const content =
          '[Toolbar]\n'
          '  A  |  C:\\A  \n';
      final items = parseToolbarIni(content);
      expect(items.single.label, 'A');
      expect(items.single.target, r'C:\A');
    });

    test('tolerates a single field', () {
      const content =
          '[Toolbar]\n'
          'A\n';
      final items = parseToolbarIni(content);
      expect(items.single.label, 'A');
      expect(items.single.target, isEmpty);
    });
  });

  group('serializeToolbarIni', () {
    test('writes the section header for an empty list', () {
      expect(serializeToolbarIni(const []), '[Toolbar]\n');
    });

    test('writes three fields', () {
      final content = serializeToolbarIni(const [
        (label: 'Home', target: r'C:\App', icon: r'C:\App\icon.ico'),
      ]);
      expect(
        content,
        '[Toolbar]\n'
        r'Home | C:\\App | C:\\App\\icon.ico'
        '\n',
      );
    });

    test('omits the icon when absent', () {
      final content = serializeToolbarIni(const [
        (label: 'Docs', target: r'D:\Docs', icon: null),
      ]);
      expect(
        content,
        '[Toolbar]\n'
        r'Docs | D:\\Docs'
        '\n',
      );
    });

    test('writes separators', () {
      final content = serializeToolbarIni(const [
        (label: 'A', target: r'C:\A', icon: null),
        (label: '', target: '', icon: null),
      ]);
      expect(
        content,
        '[Toolbar]\n'
        r'A | C:\\A'
        '\n'
        ' | \n',
      );
    });

    test('escapes pipes and backslashes in fields', () {
      final content = serializeToolbarIni(const [
        (label: 'Notes', target: r'C:\Dir\with|pipe', icon: null),
      ]);
      expect(
        content,
        '[Toolbar]\n'
        r'Notes | C:\\Dir\\with\|pipe'
        '\n',
      );
    });
  });

  group('round-trip', () {
    test('serialize then parse yields identical items', () {
      const items = [
        (label: 'Home', target: r'C:\Users\me', icon: r'C:\Users\me\i.ico'),
        (label: 'Docs', target: r'D:\Docs', icon: null),
        (label: '', target: '', icon: null),
        (label: 'Pipe', target: r'C:\Dir with\|pipe', icon: null),
      ];
      final content = serializeToolbarIni(items);
      final parsed = parseToolbarIni(content);
      expect(parsed, hasLength(items.length));
      for (var i = 0; i < items.length; i++) {
        expect(parsed[i].label, items[i].label);
        expect(parsed[i].target, items[i].target);
        expect(parsed[i].icon, items[i].icon);
      }
    });

    test('round-trips UNC paths', () {
      const items = [
        (label: 'Share', target: r'\\server\share\folder', icon: null),
      ];
      final parsed = parseToolbarIni(serializeToolbarIni(items));
      expect(parsed.single.target, r'\\server\share\folder');
    });

    test('parse then serialize round-trips through the parser', () {
      const content =
          '[Toolbar]\n'
          r'A | C:\A | C:\A\i.ico'
          '\n'
          r'B | D:\B'
          '\n';
      final items = parseToolbarIni(content);
      final serialized = serializeToolbarIni(items);
      final reparsed = parseToolbarIni(serialized);
      expect(reparsed, hasLength(items.length));
      for (var i = 0; i < items.length; i++) {
        expect(reparsed[i].label, items[i].label);
        expect(reparsed[i].target, items[i].target);
        expect(reparsed[i].icon, items[i].icon);
      }
    });
  });
}
