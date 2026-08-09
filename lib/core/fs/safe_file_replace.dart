import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../../i18n/strings.g.dart';
import '../logging/app_logger.dart';
import 'native_copy.dart';

class SafeFileReplace {
  SafeFileReplace._();

  /// Copies [source] to [destinationPath] via a temp sibling, then atomically
  /// swaps it in. Returns false (leaving no target) if [isCancelled] fired
  /// mid-copy; the partial temp file is always cleaned up.
  static Future<bool> copyFile(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? isCancelled,
    bool useAsyncIo = false,
  }) async {
    final tempPath = temporarySiblingPath(destinationPath);
    Object? copyError;
    StackTrace? copyStack;
    var tempReady = false;
    var cancelled = false;

    try {
      cancelled = !await _copyToPath(
        source,
        tempPath,
        onProgress: onProgress,
        isCancelled: isCancelled,
        useAsyncIo: useAsyncIo,
      );
      if (cancelled) return false;
      _copyBasicMetadata(source, File(tempPath));
      tempReady = true;
      replaceWithFile(tempPath, destinationPath);
    } catch (e, st) {
      copyError = e;
      copyStack = st;
    } finally {
      if (!tempReady ||
          FileSystemEntity.typeSync(tempPath, followLinks: false) !=
              FileSystemEntityType.notFound) {
        try {
          File(tempPath).deleteSync();
        } catch (e, st) {
          log.warn(
            'fs.replace',
            'failed to remove temp file',
            error: e,
            stack: st,
          );
        }
      }
    }

    if (copyError != null) {
      Error.throwWithStackTrace(copyError, copyStack!);
    }

    return true;
  }

  static void replaceWithFile(String replacementPath, String destinationPath) {
    _replaceWindows(replacementPath, destinationPath);
  }

  static String temporarySiblingPath(String path) {
    final separator = Platform.pathSeparator;
    final split = path.lastIndexOf(separator);
    final dir = split >= 0 ? path.substring(0, split) : '.';
    final name = split >= 0 ? path.substring(split + 1) : path;
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    for (var counter = 0; counter < 10000; counter++) {
      final tempPath =
          '$dir$separator.$name.myexplorer_tmp_${timestamp}_$counter';
      if (FileSystemEntity.typeSync(tempPath, followLinks: false) ==
          FileSystemEntityType.notFound) {
        return tempPath;
      }
    }

    return '$dir$separator.$name.myexplorer_tmp_${DateTime.now().microsecondsSinceEpoch}';
  }

  static void cleanupLeftovers(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! File) continue;
        final name = _fileName(entity.path);
        if (!name.contains('.myexplorer_tmp_')) continue;
        try {
          if (entity.statSync().modified.isBefore(cutoff)) {
            entity.deleteSync();
          }
        } catch (e, st) {
          log.warn(
            'fs.replace',
            'failed to remove stale temp file',
            error: e,
            stack: st,
          );
        }
      }
    } catch (e, st) {
      log.warn(
        'fs.replace',
        'failed to scan stale temp files',
        error: e,
        stack: st,
      );
    }
  }

  /// Returns false if the copy was cancelled mid-stream, true on completion.
  static Future<bool> _copyToPath(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? isCancelled,
    bool useAsyncIo = false,
  }) async {
    final fast = Platform.isWindows && useAsyncIo
        ? FastCopyResult.unsupported
        : await NativeCopy.tryFastCopy(
            source.path,
            destinationPath,
            onProgress: onProgress,
            shouldCancel: isCancelled,
          );
    if (fast == FastCopyResult.done) return true;
    if (fast == FastCopyResult.cancelled) return false;

    if (useAsyncIo) {
      return _copyToPathAsync(
        source,
        destinationPath,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
    }

    const chunkSize = 8 * 1024 * 1024;
    const yieldEvery = 16 * 1024 * 1024;
    final input = source.openSync(mode: FileMode.read);
    final output = File(destinationPath).openSync(mode: FileMode.write);
    final buffer = Uint8List(chunkSize);
    Object? error;
    StackTrace? stack;
    var completed = true;
    var sinceYield = 0;

    try {
      while (true) {
        if (isCancelled != null && isCancelled()) {
          completed = false;
          break;
        }
        final n = input.readIntoSync(buffer);
        if (n <= 0) break;
        output.writeFromSync(buffer, 0, n);
        onProgress?.call(n);
        sinceYield += n;
        if (sinceYield >= yieldEvery) {
          sinceYield = 0;
          await Future<void>.delayed(Duration.zero);
        }
      }
    } catch (e, st) {
      error = e;
      stack = st;
    } finally {
      input.closeSync();
      output.closeSync();
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stack!);
    }

    return completed;
  }

  static Future<bool> _copyToPathAsync(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) return false;
    await source.copy(destinationPath);
    if (isCancelled?.call() ?? false) return false;
    onProgress?.call(await source.length());

    return true;
  }

  static void _copyBasicMetadata(File source, File destination) {
    try {
      final stat = source.statSync();
      destination.setLastModifiedSync(stat.modified);
    } catch (e, st) {
      log.warn(
        'fs.replace',
        'failed to copy file metadata',
        error: e,
        stack: st,
      );
    }
  }

  static void _replaceWindows(String replacementPath, String destinationPath) {
    final replacement = replacementPath.toNativeUtf16();
    final destination = destinationPath.toNativeUtf16();
    try {
      final result = MoveFileEx(
        replacement,
        destination,
        MOVEFILE_REPLACE_EXISTING,
      );
      if (result == 0) {
        throw FileSystemException(
          t.errors.moveFileExFailed(error: GetLastError()),
          destinationPath,
        );
      }
    } finally {
      calloc.free(replacement);
      calloc.free(destination);
    }
  }

  static String _fileName(String path) {
    final separator = Platform.pathSeparator;
    final split = path.lastIndexOf(separator);

    return split >= 0 ? path.substring(split + 1) : path;
  }
}
