import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../i18n/strings.g.dart';
import 'seven_zip_service.dart';

class ArchiveReadException implements Exception {
  final String message;
  const ArchiveReadException(this.message);
  @override
  String toString() => message;
}

class ArchiveEntry {
  final String path;
  final int size;
  final bool isDir;
  final int mtimeSeconds;
  final DateTime? modified;

  const ArchiveEntry({
    required this.path,
    required this.size,
    required this.isDir,
    required this.mtimeSeconds,
    this.modified,
  });
}

class ArchiveReader {
  ArchiveReader._();

  static String _normalize(String path) {
    var p = path.replaceAll('\\', '/');
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    while (p.startsWith('./')) {
      p = p.substring(2);
    }

    return p;
  }

  static bool _isUnsafe(String path) {
    if (path.startsWith('/')) return true;
    for (final seg in path.split('/')) {
      if (seg == '..') return true;
    }

    return false;
  }

  static bool _isZipLike(String archivePath) {
    final lower = archivePath.toLowerCase();

    return lower.endsWith('.zip') ||
        lower.endsWith('.jar') ||
        lower.endsWith('.war') ||
        lower.endsWith('.apk') ||
        lower.endsWith('.xpi') ||
        lower.endsWith('.whl') ||
        lower.endsWith('.crx') ||
        lower.endsWith('.epub');
  }

  static DateTime? _zipModified(int value) {
    if (value <= 0) return null;
    final year = ((value >> 25) & 0x7f) + 1980;
    final month = (value >> 21) & 0x0f;
    final day = (value >> 16) & 0x1f;
    final hours = (value >> 11) & 0x1f;
    final minutes = (value >> 5) & 0x3f;
    final seconds = (value << 1) & 0x3e;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    return DateTime(year, month, day, hours, minutes, seconds);
  }

  static DateTime? _entryModified(String archivePath, ArchiveFile entry) {
    final value = entry.lastModTime;
    if (value <= 0) return null;
    if (_isZipLike(archivePath)) return _zipModified(value);

    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  static void _applyModified(File file, DateTime? modified) {
    if (modified == null) return;
    try {
      file.setLastModifiedSync(modified);
    } on FileSystemException catch (_) {
      return;
    }
  }

  static Archive _readArchive(String archivePath) {
    final lower = archivePath.toLowerCase();
    try {
      if (_isZipLike(archivePath)) {
        return ZipDecoder().decodeBytes(File(archivePath).readAsBytesSync());
      } else if (lower.endsWith('.tar')) {
        return TarDecoder().decodeBytes(File(archivePath).readAsBytesSync());
      }
      final bytes = File(archivePath).readAsBytesSync();
      if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
        final decoded = GZipDecoder().decodeBytes(bytes);

        return TarDecoder().decodeBytes(decoded);
      } else if (lower.endsWith('.tar.bz2') ||
          lower.endsWith('.tbz2') ||
          lower.endsWith('.tbz')) {
        final decoded = BZip2Decoder().decodeBytes(bytes);

        return TarDecoder().decodeBytes(decoded);
      } else if (lower.endsWith('.tar.xz') || lower.endsWith('.txz')) {
        final decoded = XZDecoder().decodeBytes(bytes);

        return TarDecoder().decodeBytes(decoded);
      }
      throw ArchiveReadException(t.errors.unsupportedArchiveFormat);
    } catch (e) {
      throw ArchiveReadException(t.errors.archiveReadFailed(error: e));
    }
  }

  static List<ArchiveEntry> listEntries(String archivePath) {
    final lower = archivePath.toLowerCase();
    if (lower.endsWith('.7z')) {
      final raw = SevenZipService.instance.listEntries(archivePath);
      if (raw == null) {
        throw ArchiveReadException(t.errors.archiveReadFailed(error: '7z'));
      }
      final modified = FileStat.statSync(archivePath).modified;
      final entries = <ArchiveEntry>[];
      for (final e in raw) {
        entries.add(
          ArchiveEntry(
            path: e.path,
            size: e.size,
            isDir: e.isDir,
            mtimeSeconds: modified.millisecondsSinceEpoch ~/ 1000,
            modified: modified,
          ),
        );
      }

      return entries;
    }
    final archive = _readArchive(archivePath);
    final entries = <ArchiveEntry>[];
    for (final entry in archive) {
      final raw = entry.name;
      final isDir = !entry.isFile || raw.endsWith('/');
      final modified = _entryModified(archivePath, entry);
      final name = _normalize(raw);
      if (name.isNotEmpty) {
        entries.add(
          ArchiveEntry(
            path: name,
            size: entry.size,
            isDir: isDir,
            mtimeSeconds: modified != null
                ? modified.millisecondsSinceEpoch ~/ 1000
                : entry.lastModTime,
            modified: modified,
          ),
        );
      }
    }

    return entries;
  }

  static void extractEntry(
    String archivePath,
    String innerPath,
    String destPath,
  ) {
    if (archivePath.toLowerCase().endsWith('.7z')) {
      if (!SevenZipService.instance.extractEntry(
        archivePath,
        innerPath,
        destPath,
      )) {
        throw ArchiveReadException(
          t.errors.archiveEntryNotFound(path: innerPath),
        );
      }

      return;
    }
    final archive = _readArchive(archivePath);
    final target = _normalize(innerPath);
    var found = false;

    for (final entry in archive) {
      final raw = entry.name;
      if (_normalize(raw) == target) {
        found = true;
        if (entry.isFile) {
          final file = File(destPath);
          file.parent.createSync(recursive: true);
          final data = entry.content as List<int>;
          file.writeAsBytesSync(data);
          _applyModified(file, _entryModified(archivePath, entry));
        }
        break;
      }
    }
    if (!found) {
      throw ArchiveReadException(
        t.errors.archiveEntryNotFound(path: innerPath),
      );
    }
  }

  /// Returns the raw bytes of a single archive entry without touching the
  /// file system (used for in-archive preview and edit).
  static Uint8List readEntryBytes(String archivePath, String innerPath) {
    if (archivePath.toLowerCase().endsWith('.7z')) {
      final tmp = File(
        p.join(
          Directory.systemTemp.path,
          'myexplorer-7z-entry-${DateTime.now().microsecondsSinceEpoch}.bin',
        ),
      );
      try {
        if (!SevenZipService.instance.extractEntry(
          archivePath,
          innerPath,
          tmp.path,
        )) {
          throw ArchiveReadException(
            t.errors.archiveEntryNotFound(path: innerPath),
          );
        }

        return tmp.readAsBytesSync();
      } finally {
        try {
          if (tmp.existsSync()) tmp.deleteSync();
        } catch (_) {}
      }
    }
    final archive = _readArchive(archivePath);
    final target = _normalize(innerPath);
    for (final entry in archive) {
      final raw = entry.name;
      if (!entry.isFile) continue;
      if (_normalize(raw) != target) continue;
      final data = entry.content as List<int>;
      if (data is Uint8List) return data;

      return Uint8List.fromList(data);
    }
    throw ArchiveReadException(t.errors.archiveEntryNotFound(path: innerPath));
  }

  static String extractTree(
    String archivePath,
    String innerPath,
    String stagingDir,
  ) {
    if (archivePath.toLowerCase().endsWith('.7z')) {
      // Extract the whole archive to a sub-staging dir, then move the
      // requested subtree out.
      final work = Directory(
        p.join(stagingDir, 'work-${DateTime.now().microsecondsSinceEpoch}'),
      )..createSync(recursive: true);
      try {
        if (!SevenZipService.instance.extractAll(archivePath, work.path)) {
          throw ArchiveReadException(t.errors.archiveReadFailed(error: '7z'));
        }
        final target = _normalize(innerPath);
        final baseName = target.contains('/')
            ? target.substring(target.lastIndexOf('/') + 1)
            : target;
        final stagedRoot = '$stagingDir/$baseName';
        final src = p.joinAll([work.path, ...target.split('/')]);
        final type = FileSystemEntity.typeSync(src);
        if (type == FileSystemEntityType.directory) {
          Directory(src).renameSync(stagedRoot);
        } else if (type == FileSystemEntityType.file) {
          final f = File(src);
          f.parent.createSync(recursive: true);
          f.copySync(stagedRoot);
        } else {
          throw ArchiveReadException(
            t.errors.archiveEntryNotFound(path: innerPath),
          );
        }

        return stagedRoot;
      } finally {
        try {
          work.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    final archive = _readArchive(archivePath);
    final target = _normalize(innerPath);
    final baseName = target.contains('/')
        ? target.substring(target.lastIndexOf('/') + 1)
        : target;
    final stagedRoot = '$stagingDir/$baseName';
    var found = false;

    for (final entry in archive) {
      final raw = entry.name;
      final epath = _normalize(raw);
      String dest;

      if (epath == target) {
        dest = stagedRoot;
      } else if (epath.startsWith('$target/')) {
        dest = '$stagedRoot/${epath.substring(target.length + 1)}';
      } else {
        continue;
      }

      found = true;
      final isDir = !entry.isFile || raw.endsWith('/');
      final modified = _entryModified(archivePath, entry);
      if (isDir) {
        Directory(dest).createSync(recursive: true);
        continue;
      }

      final file = File(dest);
      file.parent.createSync(recursive: true);
      final data = entry.content as List<int>;
      file.writeAsBytesSync(data);
      _applyModified(file, modified);
    }

    if (!found) {
      throw ArchiveReadException(
        t.errors.archiveEntryNotFound(path: innerPath),
      );
    }

    return stagedRoot;
  }

  static void extractAll(
    String archivePath,
    String destDir, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    extractAllResolved(
      archivePath,
      (epath, isDir) => '$destDir/$epath',
      onEntry: onEntry,
      isCancelled: isCancelled,
    );
  }

  static void extractAllResolved(
    String archivePath,
    String? Function(String epath, bool isDir) resolveDest, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    if (archivePath.toLowerCase().endsWith('.7z')) {
      _extractSevenZipResolved(
        archivePath,
        resolveDest,
        onEntry: onEntry,
        isCancelled: isCancelled,
      );

      return;
    }
    final archive = _readArchive(archivePath);

    for (final entry in archive) {
      if (isCancelled != null && isCancelled()) break;

      final raw = entry.name;
      final epath = _normalize(raw);
      if (epath.isEmpty || _isUnsafe(epath)) continue;

      final isDir = !entry.isFile || raw.endsWith('/');
      onEntry?.call(epath);

      final dest = resolveDest(epath, isDir);
      if (dest == null) continue;

      final modified = _entryModified(archivePath, entry);
      if (isDir) {
        Directory(dest).createSync(recursive: true);
        continue;
      }

      final file = File(dest);
      file.parent.createSync(recursive: true);
      final data = entry.content as List<int>;
      file.writeAsBytesSync(data);
      _applyModified(file, modified);
    }
  }

  /// Extracts a 7z archive into a temp staging dir, then walks the staged
  /// tree and routes each entry through [resolveDest] (mirroring the native
  /// branch). Directories are created via resolveDest too.
  static void _extractSevenZipResolved(
    String archivePath,
    String? Function(String epath, bool isDir) resolveDest, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final staging = Directory(
      p.join(
        Directory.systemTemp.path,
        'myexplorer-7z-${DateTime.now().microsecondsSinceEpoch}',
      ),
    )..createSync(recursive: true);
    try {
      if (!SevenZipService.instance.extractAll(archivePath, staging.path)) {
        throw ArchiveReadException(t.errors.archiveReadFailed(error: '7z'));
      }
      _walkStaged(staging, '', resolveDest, onEntry, isCancelled);
    } finally {
      try {
        staging.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  static void _walkStaged(
    Directory dir,
    String prefix,
    String? Function(String epath, bool isDir) resolveDest,
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  ) {
    for (final entity in dir.listSync(followLinks: false)) {
      if (isCancelled != null && isCancelled()) return;
      final name = entity.path.split(Platform.pathSeparator).last;
      final rel = prefix.isEmpty ? name : '$prefix/$name';
      if (entity is Directory) {
        onEntry?.call(rel);
        final dest = resolveDest(rel, true);
        if (dest != null) Directory(dest).createSync(recursive: true);
        _walkStaged(entity, rel, resolveDest, onEntry, isCancelled);
      } else if (entity is File) {
        onEntry?.call(rel);
        final dest = resolveDest(rel, false);
        if (dest == null) continue;
        final file = File(dest);
        file.parent.createSync(recursive: true);
        entity.copySync(dest);
      }
    }
  }
}
