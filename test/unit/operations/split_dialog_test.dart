import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/operations/split_dialog.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('waydir_split_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('isSplitPartPath', () {
    test('matches .NNN suffix', () {
      expect(isSplitPartPath(r'C:\data\movie.001'), isTrue);
      expect(isSplitPartPath(r'C:\data\movie.999'), isTrue);
    });

    test('rejects non-part names', () {
      expect(isSplitPartPath(r'C:\data\movie.001.zip'), isFalse);
      expect(isSplitPartPath(r'C:\data\movie.txt'), isFalse);
      expect(isSplitPartPath(r'C:\data\movie'), isFalse);
    });
  });

  group('siblingParts', () {
    test('returns ordered existing parts from the first part', () {
      final dir = tempDir.path;
      File('$dir\\movie.001').writeAsStringSync('a');
      File('$dir\\movie.002').writeAsStringSync('b');
      File('$dir\\movie.003').writeAsStringSync('c');
      File(
        '$dir\\movie.010',
      ).writeAsStringSync('x'); // gap: stops at missing 004

      final parts = siblingParts('$dir\\movie.001');
      expect(parts, hasLength(3));
      expect(parts[0], endsWith('movie.001'));
      expect(parts[1], endsWith('movie.002'));
      expect(parts[2], endsWith('movie.003'));
    });

    test('returns just the first part when it is alone', () {
      final dir = tempDir.path;
      File('$dir\\solo.001').writeAsStringSync('a');
      final parts = siblingParts('$dir\\solo.001');
      expect(parts, hasLength(1));
      expect(parts.single, endsWith('solo.001'));
    });
  });
}
