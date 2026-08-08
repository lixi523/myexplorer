import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/archive/archive_reader.dart';
import 'package:waydir/core/archive/seven_zip_service.dart';

void main() {
  late Directory tempDir;
  late String archivePath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('waydir_7z_test');
    archivePath = '${tempDir.path}${Platform.pathSeparator}test.7z';
    final bin = SevenZipService.instance.binary;
    if (bin == null) {
      return; // skip setup when 7z is unavailable
    }
    File(
      '${tempDir.path}${Platform.pathSeparator}a.txt',
    ).writeAsStringSync('hello 7z');
    Directory('${tempDir.path}${Platform.pathSeparator}sub').createSync();
    File(
      '${tempDir.path}${Platform.pathSeparator}sub${Platform.pathSeparator}b.txt',
    ).writeAsStringSync('nested');
    final result = Process.runSync(bin, [
      'a',
      archivePath,
      '${tempDir.path}${Platform.pathSeparator}a.txt',
      '${tempDir.path}${Platform.pathSeparator}sub',
    ]);
    expect(result.exitCode, 0, reason: '7z create failed: ${result.stderr}');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('SevenZipService', () {
    test('binary is available', () {
      expect(SevenZipService.instance.binary, isNotNull);
    }, skip: SevenZipService.instance.binary == null);

    test(
      'listEntries parses files and folders',
      () {
        final entries = SevenZipService.instance.listEntries(archivePath);
        expect(entries, isNotNull);
        final names = entries!.map((e) => e.path).toList();
        expect(names, contains('a.txt'));
        expect(names, contains('sub'));
        expect(names, contains('sub/b.txt'));
        final a = entries.firstWhere((e) => e.path == 'a.txt');
        expect(a.isDir, isFalse);
        final sub = entries.firstWhere((e) => e.path == 'sub');
        expect(sub.isDir, isTrue);
      },
      skip: SevenZipService.instance.binary == null,
    );

    test(
      'extractEntry streams a single file',
      () {
        final dest = '${tempDir.path}${Platform.pathSeparator}out.txt';
        final ok = SevenZipService.instance.extractEntry(
          archivePath,
          'a.txt',
          dest,
        );
        expect(ok, isTrue);
        expect(File(dest).readAsStringSync(), 'hello 7z');
      },
      skip: SevenZipService.instance.binary == null,
    );

    test(
      'extractAll unpacks the whole archive',
      () {
        final destDir = '${tempDir.path}${Platform.pathSeparator}out';
        final ok = SevenZipService.instance.extractAll(archivePath, destDir);
        expect(ok, isTrue);
        expect(
          File('$destDir${Platform.pathSeparator}a.txt').readAsStringSync(),
          'hello 7z',
        );
        expect(
          File(
            '$destDir${Platform.pathSeparator}sub${Platform.pathSeparator}b.txt',
          ).readAsStringSync(),
          'nested',
        );
      },
      skip: SevenZipService.instance.binary == null,
    );
  });

  group('ArchiveReader 7z integration', () {
    test(
      'listEntries exposes 7z contents',
      () {
        final entries = ArchiveReader.listEntries(archivePath);
        final names = entries.map((e) => e.path).toList();
        expect(names, contains('a.txt'));
        expect(names, contains('sub/b.txt'));
      },
      skip: SevenZipService.instance.binary == null,
    );

    test(
      'readEntryBytes reads a 7z entry',
      () {
        final bytes = ArchiveReader.readEntryBytes(archivePath, 'a.txt');
        expect(utf8.decode(bytes), 'hello 7z');
      },
      skip: SevenZipService.instance.binary == null,
    );

    test(
      'extractEntry writes a 7z entry to disk',
      () {
        final dest = '${tempDir.path}${Platform.pathSeparator}out.txt';
        ArchiveReader.extractEntry(archivePath, 'a.txt', dest);
        expect(File(dest).readAsStringSync(), 'hello 7z');
      },
      skip: SevenZipService.instance.binary == null,
    );
  });
}
