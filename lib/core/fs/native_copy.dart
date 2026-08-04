import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../logging/app_logger.dart';

enum FastCopyResult { done, unsupported, cancelled }

/// Best-effort native fast-copy. Uses CopyFileEx on Windows (kernel-side
/// buffered copy). Returns unsupported on any failure so the caller falls
/// back to a portable copy.
class NativeCopy {
  NativeCopy._();

  static Future<FastCopyResult> tryFastCopy(
    String sourcePath,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return _windowsCopyFileEx(sourcePath, destinationPath, onProgress)
        ? FastCopyResult.done
        : FastCopyResult.unsupported;
  }

  static bool _windowsCopyFileEx(
    String src,
    String dst,
    void Function(int bytes)? onProgress,
  ) {
    final s = src.toNativeUtf16();
    final d = dst.toNativeUtf16();
    try {
      final ok =
          CopyFileEx(
            s,
            d,
            nullptr,
            nullptr,
            nullptr,
            COPY_FILE_FAIL_IF_EXISTS,
          ) !=
          0;
      if (ok && onProgress != null) {
        try {
          onProgress(File(src).lengthSync());
        } catch (e, st) {
          log.warn(
            'fs.copy',
            'fast copy progress stat failed',
            error: e,
            stack: st,
          );
        }
      }

      return ok;
    } catch (e, st) {
      log.warn('fs.copy', 'windows CopyFileEx failed', error: e, stack: st);

      return false;
    } finally {
      calloc.free(s);
      calloc.free(d);
    }
  }
}
