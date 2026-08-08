import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';

/// Minimal 7-Zip support via the `7z`/`7za` command-line binary.
///
/// The binary is located in this order: next to the app executable, in
/// `$PATH`, or in the standard 7-Zip install directories. Listing uses
/// `7z l -slt -ba` (technical listing, bare); extraction streams a single
/// entry to stdout (`7z x -so`) or extracts everything into a folder.
///
/// Methods are synchronous so they can run inside the worker-pool isolates.
class SevenZipService {
  SevenZipService._();

  static final SevenZipService instance = SevenZipService._();

  static const _candidates = ['7z.exe', '7za.exe', '7zr.exe'];

  String? _binary;
  bool _probed = false;

  /// Returns the resolved 7-Zip binary path, or null when not found.
  String? get binary {
    if (_probed) return _binary;
    _probed = true;
    _binary = _locate();

    return _binary;
  }

  String? _locate() {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    for (final name in _candidates) {
      final nextToApp = p.join(exeDir, name);
      if (File(nextToApp).existsSync()) return nextToApp;
    }
    final pathDirs = Platform.environment['PATH']?.split(';') ?? const [];
    for (final dir in pathDirs) {
      if (dir.trim().isEmpty) continue;
      for (final name in _candidates) {
        final candidate = p.join(dir.trim(), name);
        if (File(candidate).existsSync()) return candidate;
      }
    }
    for (final base in [
      r'C:\Program Files\7-Zip',
      r'C:\Program Files (x86)\7-Zip',
    ]) {
      for (final name in _candidates) {
        final candidate = p.join(base, name);
        if (File(candidate).existsSync()) return candidate;
      }
    }
    // Scoop / Chocolatey managed installs.
    final home = Platform.environment['USERPROFILE'] ?? '';
    final scoopBases = [
      if (home.isNotEmpty) p.join(home, 'scoop', 'apps', '7zip', 'current'),
      r'C:\ProgramData\chocolatey\lib\7zip\tools',
    ];
    for (final base in scoopBases) {
      for (final name in _candidates) {
        final candidate = p.join(base, name);
        if (File(candidate).existsSync()) return candidate;
      }
    }

    return null;
  }

  bool get isAvailable => binary != null;

  /// Returns a raw list of entries (name, size, isDir) via `7z l -slt -ba`.
  /// Returns null when the binary is unavailable or the archive is invalid.
  List<({String path, int size, bool isDir})>? listEntries(String archivePath) {
    final bin = binary;
    if (bin == null) return null;
    try {
      final result = Process.runSync(bin, ['l', '-slt', '-ba', archivePath]);
      if (result.exitCode != 0) return null;
      final out = result.stdout as String;
      final entries = <({String path, int size, bool isDir})>[];
      final lines = const LineSplitter().convert(out);
      String? path;
      var size = 0;
      var attributes = '';
      void flush() {
        if (path == null) return;
        entries.add((
          path: path!.replaceAll(r'\', '/'),
          size: size,
          isDir: attributes.contains('D'),
        ));
        path = null;
        size = 0;
        attributes = '';
      }

      for (final line in lines) {
        if (line.trim().isEmpty) {
          flush();
          continue;
        }
        final eq = line.indexOf('=');
        if (eq <= 0) continue;
        final key = line.substring(0, eq).trim();
        final value = line.substring(eq + 1).trim();
        switch (key) {
          case 'Path':
            path = value;
          case 'Size':
            size = int.tryParse(value) ?? 0;
          case 'Attributes':
            attributes = value;
        }
      }
      flush();

      return entries;
    } catch (e, st) {
      log.warn('7z', 'list failed', error: e, stack: st);

      return null;
    }
  }

  /// Extracts a single entry to [destPath] by streaming it to stdout.
  /// Returns false on failure.
  bool extractEntry(String archivePath, String innerPath, String destPath) {
    final bin = binary;
    if (bin == null) return false;
    try {
      final result = Process.runSync(bin, [
        'x',
        '-so',
        archivePath,
        innerPath,
      ], stdoutEncoding: null);
      if (result.exitCode != 0) return false;
      final bytes = result.stdout;
      if (bytes is! List<int>) return false;
      final file = File(destPath);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);

      return true;
    } catch (e, st) {
      log.warn('7z', 'extract entry failed', error: e, stack: st);

      return false;
    }
  }

  /// Extracts the whole archive into [destDir]. Returns false on failure.
  bool extractAll(String archivePath, String destDir) {
    final bin = binary;
    if (bin == null) return false;
    try {
      Directory(destDir).createSync(recursive: true);
      final result = Process.runSync(bin, [
        'x',
        '-y',
        '-o$destDir',
        archivePath,
      ]);

      return result.exitCode == 0;
    } catch (e, st) {
      log.warn('7z', 'extract all failed', error: e, stack: st);

      return false;
    }
  }
}
