import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/fs/checksum_service.dart';

void main() {
  group('ChecksumService', () {
    test('normalizes expected checksums', () {
      expect(ChecksumService.normalizeExpected(' AB CD:12-34\n'), 'abcd1234');
    });

    test('validates algorithm-specific length', () {
      expect(
        ChecksumService.isExpectedFormatValid(
          ChecksumAlgorithm.md5,
          'd41d8cd98f00b204e9800998ecf8427e',
        ),
        isTrue,
      );
      expect(
        ChecksumService.isExpectedFormatValid(
          ChecksumAlgorithm.sha256,
          'd41d8cd98f00b204e9800998ecf8427e',
        ),
        isFalse,
      );
      expect(
        ChecksumService.isExpectedFormatValid(
          ChecksumAlgorithm.md5,
          'zz1d8cd98f00b204e9800998ecf8427e',
        ),
        isFalse,
      );
    });

    test('calculates md5 and sha256 for a file', () async {
      final dir = await Directory.systemTemp.createTemp(
        'myexplorer_checksum_test',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/sample.txt');
      await file.writeAsString('MyExplorer\n');

      final md5 = await ChecksumService.calculate(
        file.path,
        ChecksumAlgorithm.md5,
      );
      final sha256 = await ChecksumService.calculate(
        file.path,
        ChecksumAlgorithm.sha256,
      );

      expect(md5.digest, 'd51b10bf4277be517cfec21d060bba47');
      expect(
        sha256.digest,
        '3380d79b61b857bc5835b505fc7c0b288f5b91a5d917c638b537ac6f6b5bcc4f',
      );
      expect(md5.bytes, 11);
      expect(sha256.bytes, 11);
    });

    test('compares normalized expected value against actual digest', () {
      expect(
        ChecksumService.matches(
          algorithm: ChecksumAlgorithm.md5,
          expected: 'd5 1b 10 bf 42 77 be 51 7c fe c2 1d 06 0b ba 47',
          actual: 'd51b10bf4277be517cfec21d060bba47',
        ),
        isTrue,
      );
    });
  });
}
