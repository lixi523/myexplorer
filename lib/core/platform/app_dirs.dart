import 'dart:io';

import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';

/// Single source of truth for MyExplorer application directories.
///
/// Preferred layout is portable: all state lives under the executable's own
/// directory, so the app never writes outside the program folder. When the
/// program folder is not writable (e.g. installed under `Program Files`),
/// data falls back to the per-user `%LOCALAPPDATA%\MyExplorer` folder so the
/// app still works instead of failing silently. Each directory is resolved
/// and created at most once (cached future), so callers never duplicate
/// platform-path logic or `create(recursive:)` calls.
class AppDirs {
  AppDirs._();

  static Future<String>? _support;
  static Future<String>? _logs;
  static Future<String>? _themes;
  static Future<String>? _plugins;
  static Future<String>? _temp;
  static String? _tempSync;

  /// Test seam: overrides where the executable directory is reported to be.
  static String? debugExeDirOverride;

  static String? _probeDir;
  static bool? _probeResult;

  static String _exeDir() =>
      debugExeDirOverride ?? p.dirname(Platform.resolvedExecutable);

  static String _fallbackBase() {
    final local = Platform.environment['LOCALAPPDATA'];
    if (local != null && local.isNotEmpty) return p.join(local, 'MyExplorer');
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      return p.join(userProfile, 'MyExplorer');
    }

    return _exeDir();
  }

  /// Whether [dir] accepts writes right now. Used to detect read-only
  /// installs (`Program Files`, `C:\Windows`, ...) so the store can fall back.
  /// The probe result is cached per directory since the writability of the
  /// executable folder does not change at runtime.
  static bool isWritableDir(String dir) {
    if (_probeDir == dir && _probeResult != null) return _probeResult!;
    var result = false;
    try {
      final probe = File(p.join(dir, '.myexplorer-write-probe'));
      probe.writeAsBytesSync(const []);
      probe.deleteSync();
      result = true;
    } catch (_) {
      result = false;
    }
    _probeDir = dir;
    _probeResult = result;

    return result;
  }

  /// Resolves the base support directory: the executable's folder when it is
  /// writable, otherwise the per-user fallback. Synchronous so worker/isolate
  /// contexts and [tempSync] can share the same decision.
  static String selectBase(String exeDir) {
    if (isWritableDir(exeDir)) return exeDir;

    return _fallbackBase();
  }

  /// Base app-support dir: the executable's directory (or the per-user
  /// fallback when the program folder is read-only).
  static Future<String> support() {
    return _support ??= _resolveSupport();
  }

  static Future<String> _resolveSupport() async {
    final base = selectBase(_exeDir());
    await Directory(base).create(recursive: true);

    return base;
  }

  /// Scratch space for transient operation files, still inside the data
  /// folder chosen by [support] so the app never writes outside it.
  static Future<String> temp() {
    return _temp ??= _resolveChild('.tmp');
  }

  /// Synchronous variant for worker/isolate contexts that cannot await.
  static String tempSync() {
    return _tempSync ??= p.join(selectBase(_exeDir()), '.tmp');
  }

  static Future<String> logs() {
    return _logs ??= _resolveChild('logs');
  }

  static Future<String> themes() {
    return _themes ??= _resolveChild('themes');
  }

  static Future<String> plugins() {
    return _plugins ??= _resolveChild('plugins');
  }

  static Future<String> _resolveChild(String name) async {
    final base = await support();
    final dir = p.join(base, name);
    await Directory(dir).create(recursive: true);

    return dir;
  }

  /// Test seam: clear cached dirs so the next call re-resolves.
  static void debugReset() {
    _support = null;
    _logs = null;
    _themes = null;
    _plugins = null;
    _temp = null;
    _tempSync = null;
    _probeDir = null;
    _probeResult = null;
  }

  /// Removes stale scratch directories left in [tempSync] by a previous run
  /// that crashed before its `finally` cleanup (e.g. 7z staging folders).
  static void cleanupStaleTemp({Duration olderThan = const Duration(days: 1)}) {
    final dir = Directory(tempSync());
    if (!dir.existsSync()) return;
    final cutoff = DateTime.now().subtract(olderThan);
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! Directory) continue;
        if (!p.basename(entity.path).startsWith('myexplorer-7z-')) continue;
        try {
          if (entity.statSync().modified.isBefore(cutoff)) {
            entity.deleteSync(recursive: true);
          }
        } catch (e, st) {
          log.warn(
            'app-dirs',
            'failed to remove stale temp dir',
            error: e,
            stack: st,
          );
        }
      }
    } catch (e, st) {
      log.warn(
        'app-dirs',
        'failed to scan stale temp dirs',
        error: e,
        stack: st,
      );
    }
  }
}
