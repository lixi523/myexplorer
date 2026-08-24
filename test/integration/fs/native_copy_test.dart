@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/fs/native_copy.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('native_copy_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('native copy copies a file fully with progress', () async {
    final src = File('${tempDir.path}/src.bin');
    src.writeAsBytesSync(List<int>.generate(4 * 1024 * 1024, (i) => i % 251));
    final dst = '${tempDir.path}/dst.bin';
    var reported = 0;
    final result = await NativeCopy.tryFastCopy(
      src.path,
      dst,
      onProgress: (d) => reported += d,
    );
    expect(result, FastCopyResult.done);
    expect(File(dst).existsSync(), isTrue);
    expect(File(dst).lengthSync(), src.lengthSync());
    expect(reported, src.lengthSync());
  });

  test('native copy can be cancelled mid-flight', () async {
    final src = File('${tempDir.path}/big.bin');
    final sink = src.openSync(mode: FileMode.write);
    sink.truncateSync(512 * 1024 * 1024);
    sink.closeSync();
    final dst = '${tempDir.path}/dst.bin';
    var polls = 0;
    final result = await NativeCopy.tryFastCopy(
      src.path,
      dst,
      shouldCancel: () => ++polls > 3,
    );
    expect(result, FastCopyResult.cancelled);
  });

  test('native copy reports unsupported when the target exists', () async {
    final src = File('${tempDir.path}/src.bin');
    src.writeAsBytesSync(List<int>.generate(1024, (i) => i % 251));
    final dst = File('${tempDir.path}/dst.bin');
    dst.writeAsBytesSync(const [1, 2, 3]);
    final result = await NativeCopy.tryFastCopy(src.path, dst.path);
    expect(result, FastCopyResult.unsupported);
    expect(dst.lengthSync(), 3);
  });
}
