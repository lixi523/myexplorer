import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/database/app_database.dart';
import 'package:myexplorer/core/platform/platform_paths.dart';
import 'package:myexplorer/features/navigation/shortcut_runner.dart';

ShortcutBarItem _item(String target, {String? label, String? icon}) {
  return ShortcutBarItem(
    id: 1,
    orderIndex: 0,
    label: label ?? target,
    target: target,
    icon: icon,
  );
}

void main() {
  late Directory tempDir;
  late String folderPath;
  late String filePath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('myexplorer_shortcut_test');
    folderPath = tempDir.path;
    filePath = '${tempDir.path}${Platform.pathSeparator}note.txt';
    File(filePath).writeAsStringSync('hello');
    PlatformPaths.environmentOverrideForTesting = {
      'USERPROFILE': r'C:\Users\test',
      'SystemRoot': r'C:\Windows',
    };
    PlatformPaths.homePathOverrideForTesting = r'C:\Users\test';
  });

  tearDown(() {
    PlatformPaths.environmentOverrideForTesting = null;
    PlatformPaths.homePathOverrideForTesting = null;
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('classifyShortcutTarget', () {
    test('empty target is none', () {
      final t = classifyShortcutTarget('  ');
      expect(t.kind, ShortcutTargetKind.none);
    });

    test('existing directory is folder', () {
      final t = classifyShortcutTarget(folderPath);
      expect(t.kind, ShortcutTargetKind.folder);
      expect(t.value, folderPath);
    });

    test('existing file is file', () {
      final t = classifyShortcutTarget(filePath);
      expect(t.kind, ShortcutTargetKind.file);
      expect(t.value, filePath);
    });

    test('CD command becomes cd with the folder path', () {
      final t = classifyShortcutTarget('CD $folderPath');
      expect(t.kind, ShortcutTargetKind.cd);
      expect(t.value, folderPath);
    });

    test('CD is case-insensitive and trims quotes', () {
      final t = classifyShortcutTarget('cd "$folderPath"');
      expect(t.kind, ShortcutTargetKind.cd);
      expect(t.value, folderPath);
    });

    test('cm_ commands become internal', () {
      expect(
        classifyShortcutTarget('cm_OpenDesktop').kind,
        ShortcutTargetKind.internal,
      );
      expect(
        classifyShortcutTarget('CM_OPENRECYCLED').value,
        'CM_OPENRECYCLED',
      );
    });

    test('expands environment variables before probing', () {
      final t = classifyShortcutTarget(r'%USERPROFILE%\Desktop');
      expect(t.value, r'C:\Users\test\Desktop');
      expect(t.kind, ShortcutTargetKind.command); // does not exist on disk
    });

    test('unknown target is a command', () {
      final t = classifyShortcutTarget('calc.exe');
      expect(t.kind, ShortcutTargetKind.command);
      expect(t.value, 'calc.exe');
    });

    test('strips surrounding quotes from bare commands', () {
      final t = classifyShortcutTarget('"C:\\Program Files\\App\\app.exe" -v');
      expect(t.kind, ShortcutTargetKind.command);
      expect(t.value, '"C:\\Program Files\\App\\app.exe" -v');
    });
  });

  group('runShortcutItem', () {
    test('folder navigates', () async {
      final navigated = <String>[];
      await runShortcutItem(
        _item(folderPath),
        navigateTo: (p) async => navigated.add(p),
        openFile: (p) async {},
        launchCommand: (c) async {},
      );
      expect(navigated, [folderPath]);
    });

    test('file opens', () async {
      final opened = <String>[];
      await runShortcutItem(
        _item(filePath),
        navigateTo: (p) async {},
        openFile: (p) async => opened.add(p),
        launchCommand: (c) async {},
      );
      expect(opened, [filePath]);
    });

    test('CD navigates to the folder', () async {
      final navigated = <String>[];
      await runShortcutItem(
        _item('CD $folderPath'),
        navigateTo: (p) async => navigated.add(p),
        openFile: (p) async {},
        launchCommand: (c) async {},
      );
      expect(navigated, [folderPath]);
    });

    test('CD to a missing folder does nothing', () async {
      final navigated = <String>[];
      await runShortcutItem(
        _item('CD ${tempDir.path}\\missing'),
        navigateTo: (p) async => navigated.add(p),
        openFile: (p) async {},
        launchCommand: (c) async {},
      );
      expect(navigated, isEmpty);
    });

    test('command launches through launchCommand', () async {
      final launched = <String>[];
      await runShortcutItem(
        _item('someapp.exe /flag'),
        navigateTo: (p) async {},
        openFile: (p) async {},
        launchCommand: (c) async => launched.add(c),
      );
      expect(launched, ['someapp.exe /flag']);
    });

    test('cm_OpenDesktop navigates to the desktop', () async {
      final navigated = <String>[];
      await runShortcutItem(
        _item('cm_OpenDesktop'),
        navigateTo: (p) async => navigated.add(p),
        openFile: (p) async {},
        launchCommand: (c) async {},
      );
      expect(navigated, [r'C:\Users\test\Desktop']);
    });

    test('separator item does nothing', () async {
      var launched = false;
      await runShortcutItem(
        _item('  '),
        navigateTo: (p) async {},
        openFile: (p) async {},
        launchCommand: (c) async => launched = true,
      );
      expect(launched, isFalse);
    });
  });
}
