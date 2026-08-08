import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/archive/archive_path.dart';
import 'package:waydir/core/archive/archive_reader.dart';
import 'package:waydir/core/archive/archive_writer.dart';

void main() {
  late Directory tempDir;
  late String zipPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('waydir_edit_test');
    zipPath = '${tempDir.path}${Platform.pathSeparator}test.zip';
    // Build a zip with a single entry.
    final source = File('${tempDir.path}${Platform.pathSeparator}a.txt')
      ..writeAsStringSync('hello');
    ArchiveWriter.create(
      [source.path],
      zipPath,
      ArchiveFormat.zip,
      CompressionLevel.normal,
    );
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('readEntryBytes reads an entry without extracting to disk', () {
    final bytes = ArchiveReader.readEntryBytes(zipPath, 'a.txt');
    expect(utf8.decode(bytes), 'hello');
  });

  test('ArchivePath resolves inner file paths', () {
    final loc = ArchivePath.resolve('$zipPath${Platform.pathSeparator}a.txt');
    expect(loc, isNotNull);
    expect(loc!.archivePath, zipPath);
    expect(loc.innerPath, 'a.txt');
  });

  test('mutate replaces an entry with new content', () {
    // Add the modified file back into the archive.
    final updated = File('${tempDir.path}${Platform.pathSeparator}updated.txt')
      ..writeAsStringSync('changed content');
    ArchiveWriter.mutate(
      zipPath,
      replaceSource: updated.path,
      replaceInner: 'a.txt',
    );

    final bytes = ArchiveReader.readEntryBytes(zipPath, 'a.txt');
    expect(utf8.decode(bytes), 'changed content');
  });

  test('readEntryBytes returns Uint8List', () {
    final bytes = ArchiveReader.readEntryBytes(zipPath, 'a.txt');
    expect(bytes, isA<Uint8List>());
  });
}
