import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/hidden/hidden_ini.dart';
import 'package:myexplorer/features/hidden/hidden_list_store.dart';

void main() {
  group('normalizeHiddenPath', () {
    test('lowercases and converts forward slashes', () {
      expect(normalizeHiddenPath(r'D:\Docs\File.TXT'), r'd:\docs\file.txt');
      expect(normalizeHiddenPath('D:/Docs/File.txt'), r'd:\docs\file.txt');
    });

    test('strips trailing separators but keeps drive roots', () {
      expect(normalizeHiddenPath(r'D:\Docs\'), r'd:\docs');
      expect(normalizeHiddenPath(r'D:\Docs\\'), r'd:\docs');
      expect(normalizeHiddenPath(r'C:\'), r'c:\');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeHiddenPath('  D:\\a\\b  '), r'd:\a\b');
    });
  });

  group('isPathEntry', () {
    test('detects full-path entries', () {
      expect(isPathEntry(r'D:\a\b.txt'), isTrue);
      expect(isPathEntry('D:/a/b.txt'), isTrue);
      expect(isPathEntry('desktop.ini'), isFalse);
      expect(isPathEntry('node_modules'), isFalse);
      expect(isPathEntry(''), isFalse);
    });
  });

  group('parseHiddenIni', () {
    test('parses paths under [Hidden] section', () {
      final paths = parseHiddenIni('[Hidden]\r\nD:\\a.txt\r\nD:\\b\\c\r\n');
      expect(paths, [r'D:\a.txt', r'D:\b\c']);
    });

    test('ignores comments, blanks and other sections', () {
      final paths = parseHiddenIni(
        '; header comment\n[Other]\nD:\\x\n\n[Hidden]\n; inner comment\nD:\\a\n\nD:\\b\n# hash comment\n',
      );
      expect(paths, [r'D:\a', r'D:\b']);
    });

    test('strips UTF-8 BOM', () {
      final paths = parseHiddenIni('\uFEFF[Hidden]\nD:\\a\n');
      expect(paths, [r'D:\a']);
    });

    test('returns empty list when no [Hidden] section', () {
      expect(parseHiddenIni('[Foo]\nD:\\a\n'), isEmpty);
    });
  });

  group('serializeHiddenIni', () {
    test('writes section header and deduplicates case-insensitively', () {
      final content = serializeHiddenIni([r'D:\B', r'D:\a', r'D:\b']);
      expect(content, '[Hidden]\nD:\\a\nD:\\B\n');
    });
  });

  group('HiddenListStore', () {
    late Directory tempDir;
    late HiddenListStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('myexplorer_hidden_test');
      store = HiddenListStore.instance;
      store.directoryOverride = tempDir.path;
    });

    tearDown(() {
      store.directoryOverride = null;
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('load returns empty list when file missing', () async {
      await store.load();
      expect(store.paths.value, isEmpty);
      expect(store.isHidden(r'D:\anything'), isFalse);
    });

    test('addPaths persists and reloads', () async {
      await store.load();
      await store.addPaths([r'D:\a.txt', r'D:\b\folder']);
      expect(store.isHidden(r'D:\a.txt'), isTrue);
      expect(store.isHidden(r'd:\A.TXT'), isTrue); // case-insensitive
      expect(store.isHidden(r'D:\other'), isFalse);

      // file exists with BOM
      final bytes = File(store.filePath).readAsBytesSync();
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);

      // fresh load reads back from disk
      await store.load();
      expect(store.isHidden(r'D:\a.txt'), isTrue);
      expect(store.isHidden(r'D:\b\folder'), isTrue);
    });

    test('addPaths deduplicates', () async {
      await store.load();
      await store.addPaths([r'D:\a.txt', r'd:\A.txt']);
      expect(store.paths.value.length, 1);
    });

    test('removePath un-hides', () async {
      await store.load();
      await store.addPaths([r'D:\a.txt', r'D:\b.txt']);
      await store.removePath(r'D:\a.txt');
      expect(store.isHidden(r'D:\a.txt'), isFalse);
      expect(store.isHidden(r'D:\b.txt'), isTrue);
    });

    test('unreadable file at INI path is tolerated', () async {
      // A directory at the INI path makes reads fail; load must not crash
      // and falls back to an empty list.
      Directory(store.filePath).createSync();
      await store.load();
      expect(store.paths.value, isEmpty);
      expect(store.isLoaded, isTrue);
    });
  });

  group('HiddenListStore name vs path entries', () {
    late Directory tempDir;
    late HiddenListStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'myexplorer_hidden_mode_test',
      );
      store = HiddenListStore.instance;
      store.directoryOverride = tempDir.path;
    });

    tearDown(() {
      store.directoryOverride = null;
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('name entry hides the same file name anywhere', () async {
      await store.load();
      await store.addPaths(['desktop.ini']);

      expect(store.isHidden(r'D:\a\desktop.ini'), isTrue);
      expect(store.isHidden(r'C:\other\sub\Desktop.INI'), isTrue);
      expect(store.isHidden(r'D:\a\desktop.txt'), isFalse);
      expect(store.isHidden(r'D:\a\desktop.ini.bak'), isFalse);
    });

    test('name entry hides the same folder name anywhere', () async {
      await store.load();
      await store.addPaths(['node_modules']);

      expect(store.isHidden(r'D:\proj\node_modules'), isTrue);
      expect(store.isHidden(r'D:\proj\src\node_modules'), isTrue);
      expect(store.isHidden('D:/proj/node_modules'), isTrue);
      expect(store.isHidden(r'D:\proj\modules'), isFalse);
    });

    test('path entry still matches exactly, not by name', () async {
      await store.load();
      await store.addPaths([r'D:\only\this.txt']);

      expect(store.isHidden(r'D:\only\this.txt'), isTrue);
      expect(store.isHidden(r'E:\only\this.txt'), isFalse);
      expect(store.isHidden('D:/only/this.txt'), isTrue);
    });

    test('name and path entries coexist in one list', () async {
      await store.load();
      await store.addPaths(['Thumbs.db', r'D:\keep\secret.txt']);

      expect(store.isHidden(r'X:\pics\Thumbs.db'), isTrue);
      expect(store.isHidden(r'D:\keep\secret.txt'), isTrue);
      expect(store.isHidden(r'E:\other\secret.txt'), isFalse);

      // round-trips through the ini file
      await store.load();
      expect(store.isHidden(r'X:\pics\Thumbs.db'), isTrue);
      expect(store.isHidden(r'D:\keep\secret.txt'), isTrue);
    });

    test('updatePath replaces an entry in a single save', () async {
      await store.load();
      await store.addPaths([r'D:\old.txt', r'D:\keep.txt']);

      await store.updatePath(r'D:\old.txt', r'D:\new.txt');
      expect(store.isHidden(r'D:\old.txt'), isFalse);
      expect(store.isHidden(r'D:\new.txt'), isTrue);
      expect(store.isHidden(r'D:\keep.txt'), isTrue);

      await store.load();
      expect(store.isHidden(r'D:\new.txt'), isTrue);
      expect(store.isHidden(r'D:\old.txt'), isFalse);
    });

    test('updatePath normalizes case and keeps names', () async {
      await store.load();
      await store.addPaths(['desktop.ini']);

      await store.updatePath('desktop.ini', 'Thumbs.db');
      expect(store.isHidden(r'Z:\a\desktop.ini'), isFalse);
      expect(store.isHidden(r'Z:\a\Thumbs.db'), isTrue);
    });

    test('updatePath with empty value just removes the entry', () async {
      await store.load();
      await store.addPaths([r'D:\gone.txt']);

      await store.updatePath(r'D:\gone.txt', '   ');
      expect(store.isHidden(r'D:\gone.txt'), isFalse);
    });
  });
}
