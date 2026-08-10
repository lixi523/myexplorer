import 'dart:io';

import 'package:path/path.dart' as p;

/// Single source of truth for MyExplorer application directories.
///
/// All state lives under the executable's own directory (portable layout):
/// the app never writes outside the program folder. Each directory is
/// resolved and created at most once (cached future), so callers never
/// duplicate platform-path logic or `create(recursive:)` calls.
class AppDirs {
  AppDirs._();

  static Future<String>? _support;
  static Future<String>? _logs;
  static Future<String>? _themes;
  static Future<String>? _plugins;
  static Future<String>? _temp;
  static String? _tempSync;

  /// Base app-support dir: the executable's directory.
  static Future<String> support() {
    return _support ??= _resolveSupport();
  }

  static Future<String> _resolveSupport() async {
    final dir = p.dirname(Platform.resolvedExecutable);
    await Directory(dir).create(recursive: true);

    return dir;
  }

  /// Scratch space for transient operation files, still inside the program
  /// folder so the app never writes outside it.
  static Future<String> temp() {
    return _temp ??= _resolveChild('.tmp');
  }

  /// Synchronous variant for worker/isolate contexts that cannot await.
  static String tempSync() {
    return _tempSync ??= p.join(p.dirname(Platform.resolvedExecutable), '.tmp');
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
}
