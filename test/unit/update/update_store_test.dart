import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myexplorer/core/update/github_releases.dart';
import 'package:myexplorer/core/update/install_format.dart';
import 'package:myexplorer/core/update/update_store.dart';

void main() {
  group('GithubAsset', () {
    test('parses release asset digest', () {
      final asset = GithubAsset.fromJson({
        'name': 'myexplorer.zip',
        'browser_download_url': 'https://example.invalid/myexplorer.zip',
        'size': 7,
        'digest':
            'sha256:3380d79b61b857bc5835b505fc7c0b288f5b91a5d917c638b537ac6f6b5bcc4f',
      });

      expect(
        asset.digest,
        'sha256:3380d79b61b857bc5835b505fc7c0b288f5b91a5d917c638b537ac6f6b5bcc4f',
      );
    });
  });

  group('UpdateStore download integrity', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('myexplorer_update_test');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('accepts a download with matching SHA-256 digest', () async {
      final store = _store(
        dir,
        responseBody: 'MyExplorer\n',
        digest:
            'sha256:3380d79b61b857bc5835b505fc7c0b288f5b91a5d917c638b537ac6f6b5bcc4f',
      );
      addTearDown(store.dispose);

      await store.download();

      expect(store.status.value, UpdateStatus.ready);
      expect(store.errorMessage.value, isNull);
      expect(store.downloadedFile.value, isNotNull);
      expect(await store.downloadedFile.value!.readAsString(), 'MyExplorer\n');
    });

    test('rejects a download without a valid digest', () async {
      final store = _store(dir, responseBody: 'MyExplorer\n', digest: '');
      addTearDown(store.dispose);

      await store.download();

      expect(store.status.value, UpdateStatus.error);
      expect(store.downloadedFile.value, isNull);
      expect(store.errorMessage.value, contains('valid SHA-256 checksum'));
    });

    test('rejects launch when the downloaded file is modified', () async {
      final store = _store(
        dir,
        responseBody: 'MyExplorer\n',
        digest:
            'sha256:3380d79b61b857bc5835b505fc7c0b288f5b91a5d917c638b537ac6f6b5bcc4f',
      );
      addTearDown(store.dispose);

      await store.download();
      await store.downloadedFile.value!.writeAsString('tampered');
      store.installFormat.value = InstallFormat.unknown;

      final launched = await store.launchInstaller();

      expect(launched, isFalse);
      expect(store.status.value, UpdateStatus.error);
      expect(store.errorMessage.value, contains('SHA-256 verification'));
    });
  });
}

UpdateStore _store(
  Directory dir, {
  required String responseBody,
  required String digest,
}) {
  final store = UpdateStore(
    currentVersion: '0.0.0',
    temporaryDirectory: () async => dir,
    downloadClientFactory: () =>
        MockClient((request) async => http.Response(responseBody, 200)),
  );
  store.selectedAsset.value = GithubAsset(
    name: 'myexplorer.zip',
    downloadUrl: 'https://example.invalid/myexplorer.zip',
    sizeBytes: responseBody.length,
    digest: digest,
  );
  store.installFormat.value = InstallFormat.windowsPortable;
  return store;
}
