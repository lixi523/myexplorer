import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/fs/sftp_session_manager.dart';
import '../../core/logging/app_logger.dart';
import '../../i18n/strings.g.dart';
import 'location_uri.dart';

sealed class ResolveResult {
  const ResolveResult();
}

class ResolveSuccess extends ResolveResult {
  final String physicalPath;
  const ResolveSuccess(this.physicalPath);
}

class ResolveError extends ResolveResult {
  final String message;
  const ResolveError(this.message);
}

class ResolveAuthenticationRequired extends ResolveResult {
  const ResolveAuthenticationRequired();
}

class ResolveUnsupported extends ResolveResult {
  const ResolveUnsupported();
}

class SmbCredentials {
  final String username;
  final String password;

  const SmbCredentials({required this.username, required this.password});
}

enum SftpAuthMethod { auto, password, privateKey }

class SftpCredentials {
  final String username;
  final SftpAuthMethod method;
  final String? password;
  final String? privateKeyPath;
  final String? passphrase;

  const SftpCredentials({
    required this.username,
    required this.method,
    this.password,
    this.privateKeyPath,
    this.passphrase,
  });

  const SftpCredentials.password({
    required this.username,
    required String this.password,
  }) : method = SftpAuthMethod.password,
       privateKeyPath = null,
       passphrase = null;

  const SftpCredentials.key({
    required this.username,
    required String this.privateKeyPath,
    this.passphrase,
  }) : method = SftpAuthMethod.privateKey,
       password = null;
}

class LocationResolver {
  LocationResolver._();

  /// Maps `smb://host[:port]/share` 鈫?gvfs physical mount root, populated
  /// after a successful mount. Lets the UI keep working with logical URIs
  /// while FS operations use the physical mountpoint.
  static final Map<String, String> _logicalToPhysical = {};

  static Map<String, String> get debugMappings =>
      Map.unmodifiable(_logicalToPhysical);

  static void _pruneStaleMappings() {
    _logicalToPhysical.removeWhere((_, physical) {
      try {
        return !Directory(physical).existsSync();
      } catch (e, st) {
        log.warn(
          'locations',
          'failed to prune stale mount mapping',
          error: e,
          stack: st,
        );

        return true;
      }
    });
  }

  static List<String> mountedLocations() {
    _pruneStaleMappings();
    final locations = _logicalToPhysical.keys.toList();
    locations.addAll(SftpSessionManager.activeRoots());
    locations.sort();

    return locations;
  }

  static void debugSetMappingForTests(String logicalRoot, String physicalRoot) {
    assert(() {
      _logicalToPhysical[logicalRoot] = physicalRoot;

      return true;
    }());
  }

  static void debugClearMappingsForTests() {
    assert(() {
      _logicalToPhysical.clear();

      return true;
    }());
  }

  static String? physicalToLogical(String physical) {
    _pruneStaleMappings();
    for (final entry in _logicalToPhysical.entries) {
      final physicalRoot = entry.value;
      if (physical == physicalRoot) return entry.key;
      final prefix =
          (physicalRoot.endsWith('/') ||
              physicalRoot.endsWith(Platform.pathSeparator))
          ? physicalRoot
          : '$physicalRoot${Platform.pathSeparator}';
      if (physical.startsWith(prefix)) {
        final sub = physical.substring(prefix.length);

        return '${entry.key}/${sub.replaceAll(Platform.pathSeparator, '/')}';
      }
    }

    return null;
  }

  static String? logicalToPhysical(String logical) {
    if (!logical.startsWith('smb://')) return null;
    _pruneStaleMappings();
    for (final entry in _logicalToPhysical.entries) {
      final logicalRoot = entry.key;
      if (logical == logicalRoot) return entry.value;
      final prefix = '$logicalRoot/';
      if (logical.startsWith(prefix)) {
        final sub = logical.substring(prefix.length);

        return p.join(entry.value, sub.replaceAll('/', p.separator));
      }
    }

    return null;
  }

  static void forget(String logical) {
    final uri = LocationUri.parse(logical);
    if (uri.scheme != LocationScheme.smb) return;
    _logicalToPhysical.remove(_logicalRoot(uri));
  }

  static bool isMapped(String logical) => logicalToPhysical(logical) != null;

  static Future<void> unmount(String logical) async {
    final uri = LocationUri.parse(logical);
    if (uri.scheme == LocationScheme.sftp) {
      SftpSessionManager.closeRoot(SftpSessionManager.rootOf(uri));
    }
  }

  static String _logicalRoot(LocationUri uri) {
    final buf = StringBuffer('smb://');
    final username = uri.username;
    if (username != null && username.isNotEmpty) {
      buf.write(Uri.encodeComponent(username));
      buf.write('@');
    }
    buf.write(uri.host);
    if (uri.port != null) {
      buf.write(':');
      buf.write(uri.port);
    }
    buf.write('/');
    buf.write(uri.share);

    return buf.toString();
  }

  static Future<ResolveResult> resolve(String input) async {
    final uri = LocationUri.parse(input);
    switch (uri.scheme) {
      case LocationScheme.local:
      case LocationScheme.trash:
      case LocationScheme.windowsUnc:
        return ResolveSuccess(input);
      case LocationScheme.smb:
        if (uri.port != null) {
          return ResolveError(t.errors.smbPortsNotSupportedOnWindows);
        }
        final unc = uri.toWindowsUnc();
        if (unc == null) {
          return ResolveError(t.errors.invalidSmbUri);
        }

        return ResolveSuccess(unc);
      case LocationScheme.sftp:
        return _resolveSftp(uri);
      case LocationScheme.other:
        return const ResolveUnsupported();
    }
  }

  static Future<ResolveResult> resolveWithCredentials(
    String input,
    SmbCredentials credentials,
  ) async {
    return resolve(input);
  }

  static Future<ResolveResult> resolveSftpWithCredentials(
    String input,
    SftpCredentials credentials,
  ) async {
    final uri = LocationUri.parse(input);
    if (uri.scheme != LocationScheme.sftp) return resolve(input);

    return _resolveSftp(uri, credentials: credentials);
  }

  static Future<ResolveResult> _resolveSftp(
    LocationUri uri, {
    SftpCredentials? credentials,
  }) async {
    final host = uri.host;
    if (host == null || host.isEmpty) {
      return ResolveError(t.errors.missingSftpHost);
    }
    try {
      final port = uri.port ?? 22;
      final username = credentials?.username.isNotEmpty == true
          ? credentials!.username
          : (uri.username ?? Platform.environment['USER'] ?? '');
      final outcome = await SftpSessionManager.openSession(
        host: host,
        port: port,
        username: username,
        credentials: credentials,
      );
      switch (outcome.status) {
        case SftpOpenStatus.authRequired:
          return const ResolveAuthenticationRequired();
        case SftpOpenStatus.error:
          return ResolveError(outcome.message ?? t.errors.sftpConnectFailed);
        case SftpOpenStatus.ok:
          final sessionId = outcome.sessionId;
          final hasExplicitPath = _sftpHasExplicitPath(uri.raw);
          final remote = !hasExplicitPath
              ? (sessionId == null
                    ? '/'
                    : SftpSessionManager.defaultRemotePath(sessionId, username))
              : (uri.path == null || uri.path!.isEmpty)
              ? '/'
              : uri.path!.startsWith('/')
              ? uri.path!
              : '/${uri.path}';

          return ResolveSuccess(
            SftpSessionManager.logicalPathForSession(
              host: host,
              port: port,
              user: username,
              remotePath: remote,
            ),
          );
      }
    } catch (e) {
      return ResolveError(t.errors.sftpError(error: e));
    }
  }

  static bool _sftpHasExplicitPath(String raw) {
    final lower = raw.toLowerCase();
    if (!lower.startsWith('sftp://')) return false;

    return raw.substring('sftp://'.length).contains('/');
  }
}
