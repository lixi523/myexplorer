@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/models/file_entry.dart';
import 'package:myexplorer/core/fs/myexplorer_core_loader.dart';

void main() {
  test('native search finds matching names recursively', () {
    expect(
      MyExplorerCoreLoader.load(),
      isNotNull,
      reason:
          'myexplorer_core is a hard dependency; build it via '
          'scripts/build_myexplorer_core.sh',
    );

    final root = Directory.systemTemp.createTempSync('myexplorer_core_test');
    try {
      File('${root.path}/alpha.txt').writeAsStringSync('x');
      final sub = Directory('${root.path}/nested')..createSync();
      File('${sub.path}/alpha_deep.log').writeAsStringSync('y');
      File('${sub.path}/unrelated.bin').writeAsStringSync('z');

      final blob = MyExplorerCoreLoader.search(root.path, 'alpha', true);
      expect(blob, isNotNull);
      final entries = FileEntryCodec.decode(blob!);
      final names = entries.map((e) => e.name).toSet();
      expect(names.contains('alpha.txt'), isTrue);
      expect(names.contains('alpha_deep.log'), isTrue);
      expect(names.contains('unrelated.bin'), isFalse);
    } finally {
      root.deleteSync(recursive: true);
    }
  });

  test('native content search matches file bodies and skips binaries', () {
    expect(MyExplorerCoreLoader.load(), isNotNull);

    final root = Directory.systemTemp.createTempSync('myexplorer_core_grep');
    try {
      File('${root.path}/hit.txt').writeAsStringSync('hello NEEDLE world');
      File('${root.path}/miss.txt').writeAsStringSync('nothing here');
      File(
        '${root.path}/bin.dat',
      ).writeAsBytesSync([0x00, 0x4e, 0x45, 0x45, 0x44, 0x4c, 0x45]);

      final blob = MyExplorerCoreLoader.search(
        root.path,
        'needle',
        true,
        content: true,
      );
      expect(blob, isNotNull);
      final names = FileEntryCodec.decode(blob!).map((e) => e.name).toSet();
      expect(names, contains('hit.txt'));
      expect(names.contains('miss.txt'), isFalse);
      expect(names.contains('bin.dat'), isFalse);
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
