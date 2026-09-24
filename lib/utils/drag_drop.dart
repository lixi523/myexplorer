import 'dart:async';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

const formatLocalFile = CustomValueFormat<String>(
  applicationId: 'dev.myexplorer.local-file',
);

/// Maximum time to wait for a single drag-and-drop data read operation.
const _kDragDropReadTimeout = Duration(seconds: 5);

Future<List<String>> pathsFromSession(DropSession session) async {
  final paths = <String>[];
  for (final item in session.items) {
    final local = item.localData;
    if (local is Map && local['paths'] is List) {
      paths.addAll((local['paths'] as List).whereType<String>());
      continue;
    }
    if (item.canProvide(formatLocalFile)) {
      final reader = item.dataReader;
      if (reader != null) {
        final completer = Completer<String?>();
        reader.getValue(formatLocalFile, (value) {
          completer.complete(value);
        }, onError: (_) => completer.complete(null));
        final data = await completer.future.timeout(
          _kDragDropReadTimeout,
          onTimeout: () => null,
        );
        if (data != null && data.isNotEmpty) {
          final lines = data.split('\n');
          for (final line in lines) {
            if (line.isNotEmpty) paths.add(line);
          }
          continue;
        }
      }
    }
    if (item.canProvide(Formats.fileUri)) {
      final reader = item.dataReader;
      if (reader != null) {
        final completer = Completer<String?>();
        reader.getValue(Formats.fileUri, (value) {
          completer.complete(value?.toFilePath());
        }, onError: (_) => completer.complete(null));
        final path = await completer.future.timeout(
          _kDragDropReadTimeout,
          onTimeout: () => null,
        );
        if (path != null && path.isNotEmpty) paths.add(path);
      }
    }
  }

  return paths;
}
