@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/models/file_entry.dart';
import 'package:myexplorer/core/fs/myexplorer_core_loader.dart';

void main() {
  test('native enumerate returns full tree, deepest-first', () {
    expect(MyExplorerCoreLoader.load(), isNotNull);

    final root = Directory.systemTemp.createTempSync('myexplorer_enum_test');
    try {
      Directory('${root.path}/a/b/c').createSync(recursive: true);
      File('${root.path}/a/top.txt').writeAsStringSync('1');
      File('${root.path}/a/b/c/.hidden_deep').writeAsStringSync('2');

      final blob = MyExplorerCoreLoader.enumerate(root.path, postorder: true);
      expect(blob, isNotNull);
      final entries = FileEntryCodec.decode(blob!);
      final sep = Platform.pathSeparator;
      final paths = entries.map((e) => e.path).toList();

      expect(paths.contains('${root.path}${sep}a'), isTrue);
      expect(paths.contains('${root.path}${sep}a${sep}b${sep}c'), isTrue);
      expect(
        paths.contains('${root.path}${sep}a${sep}b${sep}c${sep}.hidden_deep'),
        isTrue,
      );
      expect(paths.contains('${root.path}${sep}a${sep}top.txt'), isTrue);
      // root itself is excluded.
      expect(paths.contains(root.path), isFalse);

      // Deepest-first: every child precedes its parent directory.
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          if (paths[j].startsWith('${paths[i]}/')) {
            fail('parent ${paths[i]} appeared before child ${paths[j]}');
          }
        }
      }
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
