import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/clipboard/file_clipboard.dart';

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

  group('FileClipboard', () {
    test('isCutOperation returns true for a cut payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{
                'text': 'x-special/cut\nfile:///C:/tmp/a.txt',
              };
            }
            return null;
          });
      final cut = await FileClipboard.isCutOperation();
      expect(cut, isTrue);
    });

    test('isCutOperation returns false for a copy payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{
                'text': 'x-special/copy\nfile:///C:/tmp/a.txt',
              };
            }
            return null;
          });
      final cut = await FileClipboard.isCutOperation();
      expect(cut, isFalse);
    });

    test('isCutOperation returns false for unrelated text', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': 'ordinary text'};
            }
            return null;
          });
      final cut = await FileClipboard.isCutOperation();
      expect(cut, isFalse);
    });

    test('isCutOperation returns false when the platform call fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            throw PlatformException(code: 'access_denied');
          });
      final cut = await FileClipboard.isCutOperation();
      expect(cut, isFalse);
    });

    test('isCutOperation returns false when clipboard is empty', () async {
      final cut = await FileClipboard.isCutOperation();
      expect(cut, isFalse);
    });
  });
}
