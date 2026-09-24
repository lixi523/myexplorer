import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../logging/app_logger.dart';
import 'myexplorer_core_loader.dart';

enum FastCopyResult { done, unsupported, cancelled }

typedef _CopyStartNative = Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _CopyStartDart = Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>);

typedef _CopyPollNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Uint64>,
      Pointer<Int32>,
      Pointer<Int32>,
    );
typedef _CopyPollDart =
    int Function(
      Pointer<Void>,
      Pointer<Uint64>,
      Pointer<Int32>,
      Pointer<Int32>,
    );

typedef _CopyCancelNative = Void Function(Pointer<Void>);
typedef _CopyCancelDart = void Function(Pointer<Void>);

typedef _CopyFreeNative = Void Function(Pointer<Void>);
typedef _CopyFreeDart = void Function(Pointer<Void>);

/// Windows kernel CopyFileEx copy, driven from a Rust worker thread.
///
/// A synchronous FFI call would freeze this isolate's event loop, so the
/// native side runs CopyFileEx on its own thread, updates an atomic progress
/// counter and checks an atomic cancel flag from CopyFileEx's progress
/// routine. Dart polls asynchronously here, which keeps the caller's event
/// loop alive for live progress and immediate cancellation.
class NativeCopy {
  NativeCopy._();

  static const Duration _pollInterval = Duration(milliseconds: 50);
  static const int _progressChunk = 1 << 20;

  static Future<FastCopyResult> tryFastCopy(
    String sourcePath,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final lib = MyExplorerCoreLoader.load();
    if (lib == null) return FastCopyResult.unsupported;
    final start = lib.lookupFunction<_CopyStartNative, _CopyStartDart>(
      'myexplorer_copy_start',
    );
    final poll = lib.lookupFunction<_CopyPollNative, _CopyPollDart>(
      'myexplorer_copy_poll',
    );
    final cancel = lib.lookupFunction<_CopyCancelNative, _CopyCancelDart>(
      'myexplorer_copy_cancel',
    );
    final free = lib.lookupFunction<_CopyFreeNative, _CopyFreeDart>(
      'myexplorer_copy_free',
    );

    final srcPtr = sourcePath.toNativeUtf8();
    final dstPtr = destinationPath.toNativeUtf8();
    final outBytes = calloc<Uint64>();
    final outDone = calloc<Int32>();
    final outResult = calloc<Int32>();
    Pointer<Void> handle = nullptr;
    try {
      handle = start(srcPtr, dstPtr);
      if (handle == nullptr) return FastCopyResult.unsupported;
      var reported = 0;
      while (true) {
        if (shouldCancel?.call() ?? false) {
          cancel(handle);
        }
        poll(handle, outBytes, outDone, outResult);
        final done = outDone.value != 0;
        final bytes = outBytes.value;
        if (onProgress != null && bytes - reported >= _progressChunk) {
          onProgress(bytes - reported);
          reported = bytes;
        }
        if (done) {
          final result = outResult.value;
          if (onProgress != null && bytes > reported) {
            onProgress(bytes - reported);
          }

          return switch (result) {
            0 => FastCopyResult.done,
            1 => FastCopyResult.cancelled,
            _ => FastCopyResult.unsupported,
          };
        }
        await Future<void>.delayed(_pollInterval);
      }
    } catch (e, st) {
      log.warn('fs.copy', 'native copy failed', error: e, stack: st);

      return FastCopyResult.unsupported;
    } finally {
      if (handle != nullptr) free(handle);
      calloc.free(srcPtr);
      calloc.free(dstPtr);
      calloc.free(outBytes);
      calloc.free(outDone);
      calloc.free(outResult);
    }
  }
}
