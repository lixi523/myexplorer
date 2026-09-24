import 'dart:io';

import '../logging/app_logger.dart';

/// Distribution format the running binary was installed as.
enum InstallFormat { windowsInstaller, windowsPortable, unknown }

class InstallFormatDetector {
  /// Best-effort detection based on the actual binary path, not the OS.
  /// Falls back to the portable variant when no system installer owns the
  /// running executable - this covers users who extracted a zip instead of
  /// running the .exe installer.
  static Future<InstallFormat> detect() async {
    final exe = _resolveExe(Platform.resolvedExecutable);
    final lower = exe.toLowerCase();
    if (lower.contains(r'\program files') ||
        lower.contains(r'\programfiles') ||
        lower.contains(r'\appdata\local\programs\')) {
      return InstallFormat.windowsInstaller;
    }

    return InstallFormat.windowsPortable;
  }

  static String _resolveExe(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (e, st) {
      log.warn(
        'update',
        'executable path resolution failed',
        error: e,
        stack: st,
      );

      return path;
    }
  }
}
