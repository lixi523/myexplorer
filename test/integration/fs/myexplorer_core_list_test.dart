@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/models/file_entry.dart';
import 'package:myexplorer/core/fs/myexplorer_core_loader.dart';

void main() {
  test('native list returns sorted entries with size and mtime', () {
    expect(MyExplorerCoreLoader.load(), isNotNull);

    final root = Directory.systemTemp.createTempSync('myexplorer_list_test');
    try {
      Directory('${root.path}/zeta_dir').createSync();
      File('${root.path}/beta.txt').writeAsStringSync('hello');
      File('${root.path}/Alpha.bin').writeAsBytesSync([1, 2, 3, 4]);

      final blob = MyExplorerCoreLoader.listDir(root.path);
      expect(blob, isNotNull);
      final entries = FileEntryCodec.decode(blob!);

      expect(entries.map((e) => e.name).toList(), [
        'zeta_dir',
        'Alpha.bin',
        'beta.txt',
      ]);
      expect(entries[0].type, FileItemType.folder);
      final beta = entries.firstWhere((e) => e.name == 'beta.txt');
      expect(beta.size, 5);
      expect(beta.modifiedMs, greaterThan(0));
    } finally {
      root.deleteSync(recursive: true);
    }
  });

  test('native list returns null for a missing directory', () {
    expect(MyExplorerCoreLoader.load(), isNotNull);
    final missing =
        '${Directory.systemTemp.path}/myexplorer_does_not_exist_zzz_123';
    expect(MyExplorerCoreLoader.listDir(missing), isNull);
  });
}
