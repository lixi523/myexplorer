import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';

class PlatformPaths {
  PlatformPaths._();

  static String? trashPathOverride;
  static bool? isWindowsOverrideForTesting;
  static String? homePathOverrideForTesting;
  static Map<String, String>? environmentOverrideForTesting;
  static final p.Context _windowsPath = p.Context(style: p.Style.windows);

  static String get separator => Platform.pathSeparator;

  static String get homePath {
    final override = homePathOverrideForTesting;
    if (override != null) return override;
    return Platform.environment['USERPROFILE'] ??
        '${Platform.environment['HOMEDRIVE'] ?? 'C:'}${Platform.environment['HOMEPATH'] ?? r'\Users\Default'}';
  }

  static String get rootPath => _windowsDriveRoot(homePath);

  static bool get isWindows =>
      isWindowsOverrideForTesting ?? Platform.isWindows;

  static bool isSmbUri(String path) => path.startsWith('smb://');

  static bool isSftpUri(String path) => path.startsWith('sftp://');

  static bool isRemoteUri(String path) => isSmbUri(path) || isSftpUri(path);

  /// Whether [path] lives on a network/remote filesystem (logical remote URIs,
  /// Windows UNC or mapped network drives). Used to keep the local-FS
  /// machinery (directory watcher, synchronous git probing) off slow network
  /// paths so the UI doesn't stall during transfers.
  static bool isNetworkPath(String path) {
    if (path.isEmpty) return false;
    if (isRemoteUri(path)) return true;

    return _windowsIsNetworkPath(path);
  }

  static int Function(Pointer<Utf16>)? _getDriveType;
  static bool _getDriveTypeResolved = false;

  static bool _windowsIsNetworkPath(String path) {
    final cleaned = _normalizeWindowsPath(path);
    if (_isWindowsUncPath(cleaned)) return true;
    if (!RegExp(r'^[A-Za-z]:').hasMatch(cleaned)) return false;
    final fn = _resolveGetDriveType();
    if (fn == null) return false;
    final ptr = _windowsDriveRoot(cleaned).toNativeUtf16();
    try {
      return fn(ptr) == 4; // DRIVE_REMOTE
    } catch (e, st) {
      log.warn('platform', 'GetDriveType failed', error: e, stack: st);

      return false;
    } finally {
      malloc.free(ptr);
    }
  }

  static int Function(Pointer<Utf16>)? _resolveGetDriveType() {
    if (_getDriveTypeResolved) return _getDriveType;
    _getDriveTypeResolved = true;
    try {
      _getDriveType = DynamicLibrary.open('kernel32.dll')
          .lookupFunction<
            Uint32 Function(Pointer<Utf16>),
            int Function(Pointer<Utf16>)
          >('GetDriveTypeW');
    } catch (e, st) {
      log.warn('platform', 'GetDriveType lookup failed', error: e, stack: st);
      _getDriveType = null;
    }

    return _getDriveType;
  }

  static bool isRoot(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final slashes = '/'.allMatches(rest).length;

      return slashes <= 1;
    }
    final cleaned = _normalizeWindowsPath(path);
    if (_isWindowsUncPath(cleaned)) {
      final parts = _stripTrailingWindowsSeparator(
        cleaned,
      ).substring(2).split(r'\').where((s) => s.isNotEmpty).toList();

      return parts.length <= 1;
    }

    return RegExp(r'^[A-Za-z]:\\?$').hasMatch(cleaned);
  }

  static String parentOf(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final slash = rest.lastIndexOf('/');
      if (slash < 0) return path;

      return '$scheme${rest.substring(0, slash)}';
    }
    final cleaned = _normalizeWindowsPath(path);
    if (_isWindowsUncPath(cleaned)) {
      final trimmed = _stripTrailingWindowsSeparator(cleaned);
      final parts = trimmed
          .substring(2)
          .split(r'\')
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length <= 1) return _ensureTrailingWindowsSeparator(trimmed);

      return '\\\\${parts.sublist(0, parts.length - 1).join('\\')}';
    }
    final root = _windowsRoot(cleaned);
    final cleanedTrimmed = _stripTrailingWindowsSeparator(cleaned);
    final rootTrimmed = _stripTrailingWindowsSeparator(root);
    if (cleanedTrimmed == rootTrimmed) {
      return root;
    }
    final parent = _windowsPath.dirname(cleanedTrimmed);
    if (parent.isEmpty || parent == '.' || parent.length < rootTrimmed.length) {
      return root;
    }

    return parent;
  }

  static String join(String part1, [String? part2, String? part3]) {
    if (isSmbUri(part1) || isSftpUri(part1)) {
      final parts = [part1, ?part2, ?part3];

      return parts.where((part) => part.isNotEmpty).fold<String>('', (
        acc,
        part,
      ) {
        if (acc.isEmpty) return part.replaceAll(RegExp(r'/+$'), '');

        return '${acc.replaceAll(RegExp(r'/+$'), '')}/${part.replaceAll(RegExp(r'^/+'), '')}';
      });
    }

    return _windowsPath.join(part1, part2, part3);
  }

  static List<String> segments(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final parts = rest.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return [scheme];
      final root = '$scheme${parts.first}';

      return [root, ...parts.sublist(1)];
    }
    final cleaned = _normalizeWindowsPath(path);
    if (_isWindowsUncPath(cleaned)) {
      final parts = _stripTrailingWindowsSeparator(
        cleaned,
      ).substring(2).split(r'\').where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return [_stripTrailingWindowsSeparator(cleaned)];

      return ['\\\\${parts.first}', ...parts.sublist(1)];
    }
    final root = _windowsDriveRoot(cleaned);
    final rest = cleaned.length > root.length
        ? cleaned.substring(root.length)
        : '';
    final parts = rest.split(r'\').where((s) => s.isNotEmpty).toList();
    final rootLabel = root.replaceAll(r'\', '').replaceAll('/', '');

    return [rootLabel, ...parts];
  }

  static String buildPartialPath(List<String> segments, int upToIndex) {
    if (segments.isNotEmpty &&
        (segments.first.startsWith('smb://') ||
            segments.first.startsWith('sftp://'))) {
      if (upToIndex == 0) return segments.first;

      return '${segments.first}/${segments.sublist(1, upToIndex + 1).join('/')}';
    }
    final root = segments.first;
    if (upToIndex == 0) return _ensureTrailingWindowsSeparator(root);
    final rest = segments.sublist(1, upToIndex + 1).join(r'\');

    return '${_ensureTrailingWindowsSeparator(root)}$rest';
  }

  static String get desktopPath => join(homePath, 'Desktop');
  static String get documentsPath => join(homePath, 'Documents');
  static String get downloadsPath => join(homePath, 'Downloads');
  static String get picturesPath => join(homePath, 'Pictures');
  static String get musicPath => join(homePath, 'Music');
  static String get videosPath => join(homePath, 'Videos');

  static String? get trashPath {
    final override = trashPathOverride;
    if (override != null) return override;

    return null;
  }

  static bool get canOpenTrash => true;

  static bool isValidFileName(String name) {
    if (name.isEmpty || name == '.' || name == '..') return false;
    if (name.contains(RegExp(r'[/\\:*?"<>|]'))) return false;
    final upper = name.toUpperCase();
    const reserved = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    ];
    final base = upper.contains('.')
        ? upper.substring(0, upper.indexOf('.'))
        : upper;
    if (reserved.contains(base)) return false;
    if (name.endsWith('.') || name.endsWith(' ')) return false;

    return true;
  }

  static String fileName(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final slash = rest.lastIndexOf('/');
      if (slash < 0) return rest;

      return rest.substring(slash + 1);
    }

    return _windowsPath.basename(path);
  }

  static String expandTilde(String path) {
    if (!path.startsWith('~')) return path;
    if (path == '~') return homePath;
    final second = path[1];
    if (second == '/' || second == r'\') {
      return join(homePath, path.substring(2));
    }

    return path;
  }

  static String expandEnvVars(String path) {
    if (path.isEmpty || isRemoteUri(path)) return path;
    final env = environmentOverrideForTesting ?? Platform.environment;

    return path.replaceAllMapped(RegExp(r'%([^%]+)%'), (m) {
      final name = m[1]!.toLowerCase();
      for (final e in env.entries) {
        if (e.key.toLowerCase() == name) return e.value;
      }

      return m[0]!;
    });
  }

  static String normalize(String path) {
    if (isSmbUri(path) || isSftpUri(path)) return path;

    return _normalizeWindowsPath(path);
  }

  static List<String> listDrives() {
    final drives = <String>[];
    for (var i = 65; i <= 90; i++) {
      final letter = String.fromCharCode(i);
      final root = '$letter:\\';
      try {
        if (Directory(root).existsSync()) {
          drives.add(root);
        }
      } catch (e, st) {
        log.warn('platform', 'windows drive probe failed', error: e, stack: st);
      }
    }

    return drives;
  }

  /// Normalises a path for native directory listing. On Windows a bare UNC
  /// share root (e.g. `\\server\share`) must carry a trailing separator or
  /// `read_dir` rejects it, so the share root lists empty.
  static String listablePath(String path) {
    if (isRemoteUri(path)) return path;
    final cleaned = _normalizeWindowsPath(path);
    final uncRoot = _windowsUncRoot(cleaned);
    if (uncRoot != null &&
        _stripTrailingWindowsSeparator(cleaned) ==
            _stripTrailingWindowsSeparator(uncRoot)) {
      return _ensureTrailingWindowsSeparator(cleaned);
    }

    return path;
  }

  /// Returns the host of a Windows UNC server root (`\\host` with no share),
  /// or null otherwise. Native directory listing cannot enumerate the shares
  /// of a bare server, so callers list them via share discovery the way
  /// Explorer does.
  static String? windowsUncServerRoot(String path) {
    if (path.isEmpty) return null;
    final cleaned = _normalizeWindowsPath(path);
    if (!_isWindowsUncPath(cleaned)) return null;
    final parts = _stripTrailingWindowsSeparator(
      cleaned,
    ).substring(2).split(r'\').where((s) => s.isNotEmpty).toList();
    if (parts.length != 1) return null;

    return parts.first;
  }

  static String _windowsDriveRoot(String path) {
    if (path.length >= 2 && path[1] == ':') {
      return '${path[0].toUpperCase()}:\\';
    }

    return 'C:\\';
  }

  static String _windowsRoot(String path) {
    return _windowsUncRoot(path) ?? _windowsDriveRoot(path);
  }

  static bool _isWindowsUncPath(String path) {
    return path.startsWith(r'\\') &&
        !path.startsWith(r'\\?\') &&
        !path.startsWith(r'\\.\');
  }

  static String? _windowsUncRoot(String path) {
    if (!_isWindowsUncPath(path)) return null;
    final parts = path
        .substring(2)
        .split(r'\')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      return _ensureTrailingWindowsSeparator(path);
    }

    return '\\\\${parts.first}\\${parts[1]}\\';
  }

  static String _normalizeWindowsPath(String path) {
    var p = path.replaceAll('/', r'\');
    if (p.length >= 2 && p[1] == ':' && (p.length == 2 || p[2] != r'\')) {
      p = '${p.substring(0, 2)}\\${p.substring(2)}';
    }

    return p;
  }

  static String _ensureTrailingWindowsSeparator(String path) {
    return path.endsWith(r'\') ? path : '$path\\';
  }

  static String _stripTrailingWindowsSeparator(String path) {
    var out = path;
    while (out.length > 1 && out.endsWith(r'\')) {
      if (RegExp(r'^[A-Za-z]:\\$').hasMatch(out)) break;
      out = out.substring(0, out.length - 1);
    }

    return out;
  }
}
