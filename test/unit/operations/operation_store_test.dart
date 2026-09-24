import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/fs/sftp_session_manager.dart';
import 'package:myexplorer/core/models/file_operation.dart';
import 'package:myexplorer/features/operations/operation_store.dart';
import 'package:myexplorer/features/operations/sftp_task_executor.dart';

void main() {
  group('OperationStore plugin tasks', () {
    late OperationStore store;

    setUp(() {
      store = OperationStore();
    });

    tearDown(() {
      store.dispose();
    });

    test('beginPluginTask adds a running plugin task', () {
      final task = store.beginPluginTask(title: 'Plugin job', totalFiles: 10);

      expect(task.type, TaskType.plugin);
      expect(task.status, TaskStatus.running);
      expect(task.totalFiles, 10);
      expect(task.sources, ['Plugin job']);
      expect(store.tasks.value, hasLength(1));
    });

    test('updatePluginTask clamps progress and derives from bytes', () {
      final task = store.beginPluginTask(title: 'Copy', totalBytes: 1000);

      store.updatePluginTask(task.id, progress: 1.5);
      expect(task.progress, 1.0);

      store.updatePluginTask(task.id, progress: -0.2);
      expect(task.progress, 0.0);

      store.updatePluginTask(task.id, processedBytes: 250);
      expect(task.progress, closeTo(0.25, 0.001));
    });

    test('updatePluginTask derives progress from files', () {
      final task = store.beginPluginTask(title: 'Scan', totalFiles: 4);

      store.updatePluginTask(task.id, processedFiles: 2);

      expect(task.progress, closeTo(0.5, 0.001));
    });

    test('updatePluginTask records current file and speed', () {
      final task = store.beginPluginTask(title: 'Job');

      store.updatePluginTask(
        task.id,
        currentFile: 'data.bin',
        bytesPerSecond: 2048,
      );

      expect(task.currentFile, 'data.bin');
      expect(task.bytesPerSecond, 2048);
    });

    test('updatePluginTask no-ops for unknown id', () {
      final task = store.beginPluginTask(title: 'Job');

      store.updatePluginTask('nope', progress: 0.5);

      expect(task.progress, 0.0);
      expect(store.tasks.value, hasLength(1));
    });

    test('finishPluginTask completes and publishes completion', () {
      final task = store.beginPluginTask(title: 'Job');

      store.finishPluginTask(task.id, success: true, cancelled: false);

      expect(task.status, TaskStatus.completed);
      expect(task.progress, 1.0);
      expect(store.taskCompleted.value, task.id);
    });

    test('finishPluginTask keeps error message on failure', () {
      final task = store.beginPluginTask(title: 'Job');

      store.finishPluginTask(
        task.id,
        success: false,
        cancelled: false,
        error: 'boom',
      );

      expect(task.status, TaskStatus.failed);
      expect(task.errors.single.message, 'boom');
      expect(store.taskCompleted.value, task.id);
    });

    test('finishPluginTask marks cancelled', () {
      final task = store.beginPluginTask(title: 'Job');

      store.finishPluginTask(task.id, success: false, cancelled: true);

      expect(task.status, TaskStatus.cancelled);
    });
  });

  group('SftpTaskExecutor', () {
    test('involvesSftp detects sftp sources', () {
      expect(
        SftpTaskExecutor.involvesSftp(
          sources: ['sftp://user@host/home/user/file.txt'],
        ),
        isTrue,
      );
      expect(
        SftpTaskExecutor.involvesSftp(sources: ['C:/data/file.txt']),
        isFalse,
      );
    });

    test('involvesSftp detects sftp destination', () {
      expect(
        SftpTaskExecutor.involvesSftp(
          sources: ['C:/data/file.txt'],
          destination: 'sftp://user@host/home/user/',
        ),
        isTrue,
      );
    });

    test('involvesSftp ignores local destination', () {
      expect(
        SftpTaskExecutor.involvesSftp(
          sources: ['C:/data/file.txt'],
          destination: 'D:/backup/',
        ),
        isFalse,
      );
    });

    test('encodeSessions serializes seeded records', () {
      final records = [
        SftpSessionRecord(
          root: 'sftp://user@host',
          host: 'host',
          port: 22,
          user: 'user',
          sessionId: 3,
        ),
        SftpSessionRecord(
          root: 'sftp://admin@other:2222',
          host: 'other',
          port: 2222,
          user: 'admin',
          sessionId: 7,
        ),
      ];

      SftpSessionManager.seedRecords(records);
      final encoded = SftpTaskExecutor.encodeSessions();

      expect(encoded, contains('"host"'));
      expect(encoded, contains('"sessionId"'));
      expect(encoded, contains('"user"'));
      SftpSessionManager.debugReset();
    });
  });
}
