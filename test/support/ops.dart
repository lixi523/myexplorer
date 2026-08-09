import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:myexplorer/core/models/file_operation.dart';
import 'package:myexplorer/features/operations/operation_store.dart';

/// Creates a zip archive of [srcPath] at [zipPath], mirroring `zip -qr`
/// semantics so integration fixtures do not depend on an external zip binary.
/// [only] restricts the archive to specific relative paths.
void createZipFixture(String zipPath, String srcPath, {List<String>? only}) {
  final archive = Archive();
  final src = Directory(srcPath);
  final files = only != null
      ? only.map((rel) => File(p.join(srcPath, rel)))
      : src.listSync(recursive: true).whereType<File>();
  for (final file in files) {
    final rel = p.relative(file.path, from: srcPath).replaceAll('\\', '/');
    final entry = ArchiveFile(rel, file.lengthSync(), file.readAsBytesSync())
      ..lastModTime = file.statSync().modified.millisecondsSinceEpoch ~/ 1000;
    archive.addFile(entry);
  }
  final bytes = ZipEncoder().encode(archive);
  File(zipPath).writeAsBytesSync(bytes!);
}

Future<FileTask> waitForTask(
  OperationStore store,
  bool Function(FileTask task) predicate, {
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    for (final task in store.tasks.value) {
      if (predicate(task)) return task;
    }
    await Future<void>.delayed(pollInterval);
  }
  final states = store.tasks.value
      .map(
        (task) =>
            '${task.id}:${task.type.name}:${task.status.name}:conflicts=${task.conflicts.length}:errors=${task.errors.length}',
      )
      .join(', ');
  fail('Timed out waiting for task state. Tasks: $states');
}

bool isTerminalTask(FileTask task) =>
    task.status == TaskStatus.completed ||
    task.status == TaskStatus.failed ||
    task.status == TaskStatus.cancelled;
