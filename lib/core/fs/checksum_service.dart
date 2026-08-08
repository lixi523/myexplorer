import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../features/checksum/checksum_manifest.dart';
import '../logging/app_logger.dart';

enum ChecksumAlgorithm {
  md5,
  sha256;

  String get label {
    return switch (this) {
      ChecksumAlgorithm.md5 => 'MD5',
      ChecksumAlgorithm.sha256 => 'SHA-256',
    };
  }

  int get hexLength {
    return switch (this) {
      ChecksumAlgorithm.md5 => 32,
      ChecksumAlgorithm.sha256 => 64,
    };
  }
}

class ChecksumResult {
  final ChecksumAlgorithm algorithm;
  final String digest;
  final int bytes;

  const ChecksumResult({
    required this.algorithm,
    required this.digest,
    required this.bytes,
  });
}

/// Outcome of verifying one file against a manifest entry.
enum ManifestCheckStatus { ok, mismatch, missing, error }

class ManifestCheck {
  final String relativePath;
  final ManifestCheckStatus status;
  final String expectedDigest;
  final String? actualDigest;

  const ManifestCheck({
    required this.relativePath,
    required this.status,
    required this.expectedDigest,
    this.actualDigest,
  });
}

class ChecksumService {
  static String normalizeExpected(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s:-]'), '');
  }

  static bool isExpectedFormatValid(ChecksumAlgorithm algorithm, String value) {
    final normalized = normalizeExpected(value);
    if (normalized.length != algorithm.hexLength) return false;

    return RegExp(r'^[0-9a-f]+$').hasMatch(normalized);
  }

  static bool matches({
    required ChecksumAlgorithm algorithm,
    required String expected,
    required String actual,
  }) {
    if (!isExpectedFormatValid(algorithm, expected)) return false;

    return normalizeExpected(expected) == actual.toLowerCase();
  }

  static Future<ChecksumResult> calculate(
    String path,
    ChecksumAlgorithm algorithm,
  ) {
    return Isolate.run(() => _calculateInIsolate(path, algorithm));
  }

  /// Verifies a list of manifest entries against files on disk, resolving
  /// each relative path against [baseDir]. Runs concurrently with bounded
  /// parallelism; results are returned in the same order as [entries].
  static Future<List<ManifestCheck>> verifyManifest({
    required List<ManifestEntry> entries,
    required String baseDir,
    required ChecksumAlgorithm algorithm,
  }) async {
    final results = List<ManifestCheck?>.filled(entries.length, null);
    var next = 0;
    final workers = <Future<void>>[];
    const concurrency = 4;
    for (var w = 0; w < concurrency; w++) {
      workers.add(() async {
        while (true) {
          final i = next++;
          if (i >= entries.length) return;
          final entry = entries[i];
          final fullPath = p.join(baseDir, entry.relativePath);
          final file = File(fullPath);
          if (!file.existsSync()) {
            results[i] = ManifestCheck(
              relativePath: entry.relativePath,
              status: ManifestCheckStatus.missing,
              expectedDigest: entry.expectedDigest,
            );
            continue;
          }
          try {
            final result = await calculate(fullPath, algorithm);
            final ok = matches(
              algorithm: algorithm,
              expected: entry.expectedDigest,
              actual: result.digest,
            );
            results[i] = ManifestCheck(
              relativePath: entry.relativePath,
              status: ok
                  ? ManifestCheckStatus.ok
                  : ManifestCheckStatus.mismatch,
              expectedDigest: entry.expectedDigest,
              actualDigest: result.digest,
            );
          } catch (e, st) {
            log.warn(
              'checksum',
              'manifest check failed for $fullPath',
              error: e,
              stack: st,
            );
            results[i] = ManifestCheck(
              relativePath: entry.relativePath,
              status: ManifestCheckStatus.error,
              expectedDigest: entry.expectedDigest,
            );
          }
        }
      }());
    }
    await Future.wait(workers);

    return results.cast<ManifestCheck>();
  }
}

Future<ChecksumResult> _calculateInIsolate(
  String path,
  ChecksumAlgorithm algorithm,
) async {
  final file = File(path);
  final output = _DigestResultSink();
  final input = switch (algorithm) {
    ChecksumAlgorithm.md5 => md5.startChunkedConversion(output),
    ChecksumAlgorithm.sha256 => sha256.startChunkedConversion(output),
  };
  var bytes = 0;
  await for (final chunk in file.openRead()) {
    bytes += chunk.length;
    input.add(chunk);
  }
  input.close();

  return ChecksumResult(
    algorithm: algorithm,
    digest: output.value.toString(),
    bytes: bytes,
  );
}

class _DigestResultSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) {
    _value = data;
  }

  @override
  void close() {}
}
