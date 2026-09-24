import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/fs/duplicate_finder.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('myexplorer_dup_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('finds duplicate files by content across subdirectories', () async {
    final sub = Directory('${tempDir.path}${Platform.pathSeparator}sub')
      ..createSync();
    File(
      '${tempDir.path}${Platform.pathSeparator}a.txt',
    ).writeAsStringSync('hello world');
    File(
      '${tempDir.path}${Platform.pathSeparator}b.txt',
    ).writeAsStringSync('hello world');
    File(
      '${sub.path}${Platform.pathSeparator}c.txt',
    ).writeAsStringSync('different content');
    File(
      '${sub.path}${Platform.pathSeparator}d.txt',
    ).writeAsStringSync('hello world');

    final groups = <DuplicateGroup>[];
    final done = Completer<void>();
    final handle = DuplicateFinder.start(
      root: tempDir.path,
      onGroups: (g) => groups.addAll(g),
      onDone: done.complete,
    );

    await done.future.timeout(const Duration(seconds: 15));
    handle.dispose();

    expect(groups, hasLength(1));
    expect(groups.single.paths, hasLength(3));
    expect(groups.single.size, 'hello world'.length);
  });

  test('does not report unique files', () async {
    File(
      '${tempDir.path}${Platform.pathSeparator}a.txt',
    ).writeAsStringSync('one');
    File(
      '${tempDir.path}${Platform.pathSeparator}b.txt',
    ).writeAsStringSync('two');
    File(
      '${tempDir.path}${Platform.pathSeparator}c.txt',
    ).writeAsStringSync('three');

    final groups = <DuplicateGroup>[];
    final done = Completer<void>();
    final handle = DuplicateFinder.start(
      root: tempDir.path,
      onGroups: (g) => groups.addAll(g),
      onDone: done.complete,
    );

    await done.future.timeout(const Duration(seconds: 15));
    handle.dispose();

    expect(groups, isEmpty);
  });
}
