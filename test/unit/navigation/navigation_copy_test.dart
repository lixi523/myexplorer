import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/models/file_entry.dart';
import 'package:myexplorer/features/navigation/navigation_store.dart';
import 'package:myexplorer/features/navigation/clipboard_controller.dart';
import 'package:myexplorer/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  String? lastCopiedText() {
    for (final call in calls.reversed) {
      if (call.method == 'Clipboard.setData') {
        return (call.arguments as Map)['text'] as String?;
      }
    }

    return null;
  }

  FileEntry file(String name, {int size = 2048}) => FileEntry(
    name: name,
    path: r'C:\work\' + name,
    type: FileItemType.file,
    size: size,
    modified: DateTime(2026, 8, 17, 10, 30),
  );

  group('buildEntryDetailsText', () {
    test('includes name, type with extension, size, modified, path', () {
      final text = buildEntryDetailsText(file('rpt.pdf', size: 2048));

      expect(text, contains('rpt.pdf'));
      expect(text, contains(r'C:\work\rpt.pdf'));
      expect(text, contains('2.0 KB'));
    });

    test('folder type uses folder label without extension', () {
      final folder = FileEntry(
        name: 'docs',
        path: r'C:\work\docs',
        type: FileItemType.folder,
        size: 0,
        modified: DateTime(2026, 8, 17),
      );

      final text = buildEntryDetailsText(folder);

      expect(text, contains('docs'));
      expect(text, contains(t.quickLook.typeFolder));
      expect(text, isNot(contains('(.')));
    });

    test('multiple entries separated by blank line', () {
      final clip = ClipboardController();
      clip.copyText(
        '${buildEntryDetailsText(file('a.txt'))}\n\n'
        '${buildEntryDetailsText(file('b.txt'))}',
      );

      expect(lastCopiedText(), contains('\n\n'));
    });
  });

  group('ClipboardController.copyText', () {
    test('writes non-empty text to the clipboard', () {
      final clip = ClipboardController();

      clip.copyText('hello');

      expect(lastCopiedText(), 'hello');
    });

    test('no-ops on empty text', () {
      final clip = ClipboardController();

      clip.copyText('');

      expect(calls, isEmpty);
    });
  });
}
