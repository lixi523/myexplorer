import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/checksum/checksum_manifest.dart';

// Backslash as a literal character, avoiding raw-string escape pitfalls.
const _bs = r'\';

void main() {
  group('serializeChecksumManifest', () {
    test('writes digest + two spaces + path, converts separators, sorted', () {
      final content = serializeChecksumManifest([
        'a.txt',
        'B${_bs}b.txt',
      ], (rel) => rel.startsWith('a') ? 'aaaa' : 'bbbb');
      // Plain string sort: 'B/b.txt' (uppercase B) sorts before 'a.txt'.
      expect(content, 'bbbb  B/b.txt\naaaa  a.txt\n');
    });
  });

  group('parseChecksumManifest', () {
    test('parses md5 and sha256 entries', () {
      final entries = parseChecksumManifest(
        '0123456789abcdef0123456789abcdef  file.txt\n'
        'AA${'A' * 62}  sub/folder.bin\n',
      );
      expect(entries, hasLength(2));
      expect(entries![0].relativePath, 'file.txt');
      expect(entries[0].expectedDigest, '0123456789abcdef0123456789abcdef');
      expect(entries[1].relativePath, 'sub${_bs}folder.bin');
      expect(entries[1].expectedDigest.toLowerCase(), 'a' * 64);
    });

    test('strips BOM and ignores comments/blank lines', () {
      final entries = parseChecksumManifest(
        '\uFEFF# comment\n\n'
        '0123456789abcdef0123456789abcdef  a.txt\n'
        '# another\n'
        'fedcba9876543210fedcba9876543210  b.txt\n',
      );
      expect(entries, hasLength(2));
    });

    test('skips malformed lines', () {
      final entries = parseChecksumManifest(
        'not-a-digest  x.txt\n'
        '0123456789abcdef0123456789abcdef  ok.txt\n'
        'short  y.txt\n',
      );
      expect(entries, hasLength(1));
      expect(entries!.single.relativePath, 'ok.txt');
    });

    test('returns null when no valid entries', () {
      expect(parseChecksumManifest('garbage\n# comment\n'), isNull);
    });
  });
}
