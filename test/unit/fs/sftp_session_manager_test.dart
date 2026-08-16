import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/fs/sftp_session_manager.dart';
import 'package:myexplorer/features/locations/location_uri.dart';

void main() {
  group('SftpSessionManager', () {
    setUp(() {
      SftpSessionManager.debugReset();
    });

    tearDown(() {
      SftpSessionManager.debugReset();
    });

    test('rootOf builds root without default port', () {
      final uri = LocationUri.parse('sftp://user@host/path/to/dir');
      expect(SftpSessionManager.rootOf(uri), 'sftp://user@host');
    });

    test('rootOf keeps non-default port and encodes user', () {
      final uri = LocationUri.parse('sftp://us er@host:2222/dir');
      expect(SftpSessionManager.rootOf(uri), 'sftp://us%20er@host:2222');
    });

    test('rootOf omits empty username', () {
      final uri = LocationUri.parse('sftp://host:2222/dir');
      expect(SftpSessionManager.rootOf(uri), 'sftp://host:2222');
    });

    test('buildLogicalPath builds uri with default port omitted', () {
      expect(
        SftpSessionManager.buildLogicalPath(
          host: 'host',
          port: 22,
          user: 'user',
        ),
        'sftp://user@host',
      );
      expect(
        SftpSessionManager.buildLogicalPath(
          host: 'host',
          port: 22,
          user: 'user',
          remotePath: '/home/user/a b',
        ),
        'sftp://user@host/home/user/a b',
      );
    });

    test('buildLogicalPath keeps explicit non-default port', () {
      expect(
        SftpSessionManager.buildLogicalPath(
          host: 'host',
          port: 2222,
          user: 'user',
        ),
        'sftp://user@host:2222',
      );
    });

    test('remotePath maps uri to server path', () {
      expect(
        SftpSessionManager.remotePath('sftp://user@host/home/user/file'),
        '/home/user/file',
      );
      expect(SftpSessionManager.remotePath('sftp://user@host'), '/');
      expect(SftpSessionManager.remotePath('C:/local/path'), 'C:/local/path');
    });

    test('record json round-trips', () {
      final record = SftpSessionRecord(
        root: 'sftp://user@host:2222',
        host: 'host',
        port: 2222,
        user: 'user',
        sessionId: 42,
      );

      final decoded = SftpSessionRecord.fromJson(record.toJson());

      expect(decoded.root, record.root);
      expect(decoded.host, record.host);
      expect(decoded.port, record.port);
      expect(decoded.user, record.user);
      expect(decoded.sessionId, record.sessionId);
    });

    test('logicalPathForSession matches buildLogicalPath', () {
      expect(
        SftpSessionManager.logicalPathForSession(
          host: 'host',
          port: 2222,
          user: 'admin',
          remotePath: '/srv/data',
        ),
        SftpSessionManager.buildLogicalPath(
          host: 'host',
          port: 2222,
          user: 'admin',
          remotePath: '/srv/data',
        ),
      );
    });

    test('recordFor resolves after seeding', () {
      final record = SftpSessionRecord(
        root: 'sftp://user@host',
        host: 'host',
        port: 22,
        user: 'user',
        sessionId: 5,
      );

      SftpSessionManager.seedRecords([record]);

      expect(
        SftpSessionManager.recordFor(
          'sftp://user@host/home/user/x.txt',
        )?.sessionId,
        5,
      );
      expect(SftpSessionManager.recordFor('C:/local'), isNull);
      expect(SftpSessionManager.activeRoots(), contains('sftp://user@host'));
    });
  });
}
