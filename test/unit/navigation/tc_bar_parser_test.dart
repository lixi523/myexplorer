import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/platform/gbk_codec.dart';
import 'package:myexplorer/features/navigation/tc_bar_parser.dart';

void main() {
  group('parseTcBar', () {
    test('parses buttons with cmd, param, icon and menu', () {
      const content = '''
[Buttonbar]
Buttoncount=3
button1=D:\\Tools\\App.exe
cmd1=D:\\Tools\\App.exe
param1=/x /y
iconic1=0
menu1=My App
button2=shell32.dll,34
cmd2=cm_OpenDesktop
iconic2=0
menu2=桌面
button3=shell32.dll,19
cmd3=CD D:\\Projects\\
''';

      final entries = parseTcBar(content);

      expect(entries, hasLength(3));
      expect(entries[0].index, 1);
      expect(entries[0].icon, r'D:\Tools\App.exe');
      expect(entries[0].cmd, r'D:\Tools\App.exe');
      expect(entries[0].param, '/x /y');
      expect(entries[0].menu, 'My App');
      expect(entries[0].commandLine, r'D:\Tools\App.exe /x /y');
      expect(entries[0].isEmpty, isFalse);

      expect(entries[1].icon, 'shell32.dll,34');
      expect(entries[1].cmd, 'cm_OpenDesktop');
      expect(entries[1].commandLine, 'cm_OpenDesktop');

      expect(entries[2].cmd, r'CD D:\Projects\');
      expect(entries[2].menu, '');
      expect(entries[2].commandLine, r'CD D:\Projects\');
    });

    test('empty buttons are separators', () {
      const content = '''
[Buttonbar]
Buttoncount=3
button1=C:\\Tools\\A.exe
cmd1=C:\\Tools\\A.exe
menu1=A
button2=
iconic2=0
button3=C:\\Tools\\B.exe
cmd3=C:\\Tools\\B.exe
menu3=B
''';

      final entries = parseTcBar(content);

      expect(entries, hasLength(3));
      expect(entries[0].isEmpty, isFalse);
      expect(entries[1].isEmpty, isTrue);
      expect(entries[2].isEmpty, isFalse);
    });

    test('falls back to highest buttonN when Buttoncount is missing', () {
      const content = '''
[Buttonbar]
button1=C:\\A.exe
cmd1=C:\\A.exe
button5=C:\\E.exe
cmd5=C:\\E.exe
''';

      final entries = parseTcBar(content);

      expect(entries, hasLength(5));
      expect(entries[4].cmd, r'C:\E.exe');
      expect(entries[1].isEmpty, isTrue);
    });

    test('ignores sections other than Buttonbar', () {
      const content = '''
[Buttonbar]
Buttoncount=1
button1=C:\\A.exe
cmd1=C:\\A.exe
menu1=A
[SomeOtherSection]
button2=C:\\Ignored.exe
''';

      final entries = parseTcBar(content);

      expect(entries, hasLength(1));
      expect(entries.single.cmd, r'C:\A.exe');
    });
  });

  group('decodeBarBytes', () {
    test('decodes UTF-8 content', () {
      final bytes = utf8.encode(
        '[Buttonbar]\nButtoncount=1\nbutton1=C:\\A.exe\ncmd1=C:\\A.exe\nmenu1=Hello 世界\n',
      );

      final text = decodeBarBytes(bytes);

      expect(text, contains('Hello 世界'));
    });

    test('decodes GBK content when UTF-8 is invalid', () {
      final gbk = encodeGbkBytes('[Buttonbar]\nButtoncount=1\nmenu1=视频压缩\n');
      if (gbk == null || gbk.every((b) => b == 0)) {
        markTestSkipped('GBK encoding unavailable (non-Windows host)');

        return;
      }

      final text = decodeBarBytes(gbk);
      if (text.isEmpty || text.codeUnits.every((c) => c == 0)) {
        markTestSkipped('GBK decoding unavailable (non-Windows host)');

        return;
      }

      expect(text, contains('视频压缩'));
    }, skip: !Platform.isWindows);
  });
}
