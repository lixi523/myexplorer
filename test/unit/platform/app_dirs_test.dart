import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/platform/app_dirs.dart';

void main() {
  group('AppDirs', () {
    late Directory tempDir;

    setUp(() {
      AppDirs.debugReset();
      tempDir = Directory.systemTemp.createTempSync('myexplorer_appdirs_test');
      AppDirs.debugExeDirOverride = tempDir.path;
    });

    tearDown(() {
      AppDirs.debugExeDirOverride = null;
      AppDirs.debugReset();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('selectBase returns the writable exe dir', () {
      expect(AppDirs.selectBase(tempDir.path), tempDir.path);
    });

    test('selectBase falls back when the exe dir is not writable', () {
      final missing = '${tempDir.path}\\does-not-exist';
      final base = AppDirs.selectBase(missing);
      expect(base, isNot(missing));
      expect(base, isNotEmpty);
    });

    test('support resolves to the exe dir when writable', () async {
      final dir = await AppDirs.support();
      expect(dir, tempDir.path);
      expect(Directory(dir).existsSync(), isTrue);
    });

    test('child dirs live under the support dir', () async {
      final child = await AppDirs.logs();
      expect(child, startsWith(tempDir.path));
      expect(child, endsWith('logs'));
      expect(Directory(child).existsSync(), isTrue);

      final themes = await AppDirs.themes();
      expect(themes, startsWith(tempDir.path));
      expect(themes, endsWith('themes'));
      expect(Directory(themes).existsSync(), isTrue);

      final plugins = await AppDirs.plugins();
      expect(plugins, startsWith(tempDir.path));
      expect(plugins, endsWith('plugins'));
      expect(Directory(plugins).existsSync(), isTrue);

      final temp = await AppDirs.temp();
      expect(temp, startsWith(tempDir.path));
      expect(temp, endsWith('.tmp'));
    });

    test('tempSync matches the sync base decision', () {
      expect(AppDirs.tempSync(), startsWith(tempDir.path));
      expect(AppDirs.tempSync(), endsWith('.tmp'));
    });

    test('cached dirs are stable across calls', () async {
      final first = await AppDirs.support();
      final second = await AppDirs.support();
      expect(first, second);
    });

    test(
      'base is pinned until debugReset even if the exe dir changes',
      () async {
        final first = await AppDirs.support();
        expect(first, tempDir.path);

        final elsewhere = '${tempDir.path}\\elsewhere';
        Directory(elsewhere).createSync(recursive: true);
        AppDirs.debugExeDirOverride = elsewhere;

        final pinned = await AppDirs.support();
        expect(pinned, first);

        AppDirs.debugReset();
        final resolved = await AppDirs.support();
        expect(resolved, elsewhere);
      },
    );
  });

  group('AppDirs isWritableDir', () {
    test('true for an existing writable directory', () {
      final dir = Directory.systemTemp.createTempSync(
        'myexplorer_writable_test',
      );
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      });

      expect(AppDirs.isWritableDir(dir.path), isTrue);
    });

    test('false for a non-existent directory', () {
      expect(
        AppDirs.isWritableDir('Z:\\definitely-not-a-drive\\nope'),
        isFalse,
      );
    });
  });

  group('AppDirs cleanupStaleTemp', () {
    test(
      'removes stale 7z staging dirs but keeps fresh and unrelated ones',
      () {
        final dir = Directory.systemTemp.createTempSync(
          'myexplorer_stale_test',
        );
        addTearDown(() {
          try {
            dir.deleteSync(recursive: true);
          } catch (_) {}
        });
        AppDirs.debugReset();
        AppDirs.debugExeDirOverride = dir.path;

        final fresh = Directory('${dir.path}/.tmp/myexplorer-7z-fresh')
          ..createSync(recursive: true);
        final stale = Directory('${dir.path}/.tmp/myexplorer-7z-stale')
          ..createSync(recursive: true);
        final other = Directory('${dir.path}/.tmp/unrelated')
          ..createSync(recursive: true);

        Process.runSync('powershell', [
          '-NoProfile',
          '-Command',
          "(Get-Item '${stale.path}').LastWriteTime = (Get-Date).AddDays(-2)",
        ]);

        AppDirs.cleanupStaleTemp();

        expect(fresh.existsSync(), isTrue);
        expect(stale.existsSync(), isFalse);
        expect(other.existsSync(), isTrue);
      },
    );
  });
}
