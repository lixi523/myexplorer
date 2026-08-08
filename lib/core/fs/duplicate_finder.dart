import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../../core/logging/app_logger.dart';

/// A set of files that share the same content (same size and digest).
class DuplicateGroup {
  final List<String> paths;
  final int size;

  const DuplicateGroup({required this.paths, required this.size});
}

class DuplicateScanProgress {
  final int filesScanned;
  final String currentPath;

  const DuplicateScanProgress(this.filesScanned, this.currentPath);
}

/// Finds duplicate files under a root directory by comparing sizes first,
/// then hashing only the same-size candidates. Runs in a background isolate
/// and reports progress batches.
class DuplicateFinder {
  /// Starts a duplicate scan. Returns a handle with a results stream and a
  /// cancel method. Duplicate groups are emitted progressively as they are
  /// found (a group is emitted once a digest group has more than one file).
  static DuplicateScanHandle start({
    required String root,
    bool includeHidden = false,
    void Function(DuplicateScanProgress progress)? onProgress,
    void Function(List<DuplicateGroup> groups)? onGroups,
    void Function()? onDone,
    void Function(String error)? onError,
  }) {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final token = <dynamic>[root, includeHidden, receivePort.sendPort];
    Isolate.spawn<List<dynamic>>(
      _duplicateEntryPoint,
      token,
      errorsAreFatal: true,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    final subscriptions = <StreamSubscription<dynamic>>[
      receivePort.listen((msg) {
        if (msg is DuplicateGroup) {
          onGroups?.call([msg]);
        } else if (msg is DuplicateScanProgress) {
          onProgress?.call(msg);
        } else if (msg == 'done') {
          onDone?.call();
        }
      }),
      errorPort.listen((e) {
        log.warn('duplicates', 'scan isolate error', error: e);
        onError?.call('$e');
      }),
    ];

    return DuplicateScanHandle(
      sendPort: receivePort.sendPort,
      subscriptions: subscriptions,
      exitPort: exitPort,
      receivePort: receivePort,
    );
  }
}

class DuplicateScanHandle {
  final SendPort _sendPort;
  final List<StreamSubscription<dynamic>> _subscriptions;
  final ReceivePort _exitPort;
  final ReceivePort _receivePort;

  DuplicateScanHandle({
    required SendPort sendPort,
    required List<StreamSubscription<dynamic>> subscriptions,
    required ReceivePort exitPort,
    required ReceivePort receivePort,
  }) : _sendPort = sendPort,
       _subscriptions = subscriptions,
       _exitPort = exitPort,
       _receivePort = receivePort;

  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _sendPort.send('cancel');
  }

  void dispose() {
    cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _exitPort.close();
    _receivePort.close();
  }
}

class _ScanState {
  final SendPort port;
  final bool includeHidden;
  bool cancelled = false;
  int filesScanned = 0;
  final Map<int, List<String>> bySize = {};
  int lastProgressAt = 0;

  _ScanState(this.port, this.includeHidden);
}

Future<void> _duplicateEntryPoint(List<dynamic> args) async {
  final root = args[0] as String;
  final includeHidden = args[1] as bool;
  final mainPort = args[2] as SendPort;
  final control = ReceivePort();
  mainPort.send(control.sendPort);

  final state = _ScanState(mainPort, includeHidden);

  control.listen((msg) {
    if (msg == 'cancel') state.cancelled = true;
  });

  final watch = Stopwatch()..start();
  try {
    await _walk(state, root);
    if (state.cancelled) {
      mainPort.send('done');

      return;
    }
    // Hash same-size candidates and emit duplicate groups.
    var candidates = 0;
    final sizeGroups = state.bySize.values
        .where((paths) => paths.length > 1)
        .toList();
    for (final paths in sizeGroups) {
      if (state.cancelled) break;
      final digestToPaths = <String, List<String>>{};
      for (final path in paths) {
        if (state.cancelled) break;
        candidates++;
        final digest = await _md5OfFile(path);
        if (digest == null) continue;
        digestToPaths.putIfAbsent(digest, () => []).add(path);
        if (watch.elapsedMilliseconds - state.lastProgressAt >= 200) {
          state.lastProgressAt = watch.elapsedMilliseconds;
          mainPort.send(
            DuplicateScanProgress(state.filesScanned + candidates, path),
          );
        }
      }
      for (final dupPaths in digestToPaths.values) {
        if (dupPaths.length > 1) {
          final size = File(dupPaths.first).lengthSync();
          mainPort.send(DuplicateGroup(paths: dupPaths, size: size));
        }
      }
    }
    mainPort.send('done');
  } catch (e) {
    mainPort.send('error:$e');
  }
}

Future<void> _walk(_ScanState state, String dir) async {
  if (state.cancelled) return;
  final watch = Stopwatch()..start();
  final children = Directory(dir).listSync(followLinks: false);
  for (final entity in children) {
    if (state.cancelled) return;
    final name = entity.path.split(Platform.pathSeparator).last;
    if (!state.includeHidden && name.startsWith('.')) continue;
    try {
      if (entity is File) {
        final size = entity.lengthSync();
        state.bySize.putIfAbsent(size, () => []).add(entity.path);
        state.filesScanned++;
        if (watch.elapsedMilliseconds >= 150) {
          state.lastProgressAt = watch.elapsedMilliseconds;
          state.port.send(
            DuplicateScanProgress(state.filesScanned, entity.path),
          );
          watch.reset();
        }
      } else if (entity is Directory) {
        await _walk(state, entity.path);
      }
    } catch (_) {
      // Unreadable entries are skipped.
    }
  }
}

Future<String?> _md5OfFile(String path) async {
  try {
    final output = _Md5Sink();
    final input = md5.startChunkedConversion(output);
    await for (final chunk in File(path).openRead()) {
      input.add(chunk);
    }
    input.close();

    return output.value?.toString();
  } catch (_) {
    return null;
  }
}

class _Md5Sink implements Sink<Digest> {
  Digest? _value;

  Digest? get value => _value;

  @override
  void add(Digest data) {
    _value = data;
  }

  @override
  void close() {}
}
