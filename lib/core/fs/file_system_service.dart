import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../platform/app_dirs.dart';
import '../archive/archive_path.dart';
import '../archive/archive_reader.dart';
import '../archive/archive_writer.dart';
import '../logging/app_logger.dart';
import '../models/file_entry.dart';
import '../models/file_operation.dart';
import '../open/open_service.dart';
import '../platform/platform_paths.dart';
import '../platform/trash_location.dart';
import '../settings/settings_store.dart';
import '../terminal/terminal.dart';
import '../../i18n/strings.g.dart';
import 'fs_worker_pool.dart';
import 'sftp_fs.dart';
import 'safe_file_replace.dart';
import 'myexplorer_core_loader.dart';
import 'trash_service.dart';

part 'file_system_workers.dart';

sealed class RenameResult {
  const RenameResult();
}

class RenameSuccess extends RenameResult {
  final String newPath;
  const RenameSuccess(this.newPath);
}

class RenameInvalidName extends RenameResult {
  const RenameInvalidName();
}

class RenameAlreadyExists extends RenameResult {
  const RenameAlreadyExists();
}

class RenameNoChange extends RenameResult {
  const RenameNoChange();
}

class RenameError extends RenameResult {
  final String message;
  const RenameError(this.message);
}

class FileSystemService {
  static const int _progressReportIntervalMs = 1000;

  /// Files at/above this size are copied on their own (exclusive disk
  /// access) — they are bandwidth-bound, so concurrency adds nothing and
  /// would only thrash spinning disks.
  static const int _largeCopyBytes = 16 * 1024 * 1024;

  /// Max concurrent small-file copies. Enough to fill an NVMe/network
  /// queue and hide latency without over-subscribing the device.
  static final int _copyConcurrency = () {
    final n = Platform.numberOfProcessors ~/ 2;

    return n.clamp(2, 4);
  }();

  static final int _deleteConcurrency = Platform.numberOfProcessors.clamp(2, 4);

  static RenameResult rename(String oldPath, String newName) {
    if (!PlatformPaths.isValidFileName(newName)) {
      return const RenameInvalidName();
    }

    final newPath = p.join(p.dirname(oldPath), newName);

    if (oldPath == newPath) return const RenameNoChange();

    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) {
      return const RenameAlreadyExists();
    }

    try {
      final type = FileSystemEntity.typeSync(oldPath, followLinks: false);
      if (type == FileSystemEntityType.link) {
        Link(oldPath).renameSync(newPath);
      } else if (type == FileSystemEntityType.directory) {
        Directory(oldPath).renameSync(newPath);
      } else {
        File(oldPath).renameSync(newPath);
      }

      return RenameSuccess(newPath);
    } on FileSystemException catch (e) {
      return RenameError(_friendlyError(e));
    }
  }

  static Future<List<FileEntry>> listDirectory(String path) {
    final loc = ArchivePath.resolve(path);
    if (loc != null) {
      return FsWorkerPool.instance.listArchive(loc.archivePath, loc.innerPath);
    }

    return FsWorkerPool.instance.listDirectory(path);
  }

  static Future<bool> directoryExists(String path) =>
      FsWorkerPool.instance.directoryExists(path);

  static Future<bool> isNavigable(String path) async {
    if (ArchivePath.resolve(path) != null) return true;

    return FsWorkerPool.instance.directoryExists(path);
  }

  static bool isInsideArchive(String path) {
    final loc = ArchivePath.resolve(path);

    return loc != null && !loc.isRoot;
  }

  static Future<List<String>> materializeArchiveSources(
    List<String> sources,
  ) async {
    if (!sources.any(isInsideArchive)) return sources;
    final staging = Directory(
      p.join(
        AppDirs.tempSync(),
        'myexplorer-archive-stage',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    )..createSync(recursive: true);
    final out = <String>[];
    for (final s in sources) {
      final loc = ArchivePath.resolve(s);
      if (loc == null || loc.isRoot) {
        out.add(s);
        continue;
      }
      out.add(
        await FsWorkerPool.instance.extractArchiveTree(
          loc.archivePath,
          loc.innerPath,
          staging.path,
        ),
      );
    }

    return out;
  }

  static String archiveBaseName(String archivePath) {
    var name = p.basename(archivePath);
    final lower = name.toLowerCase();
    for (final ext in const [
      '.tar.gz',
      '.tar.bz2',
      '.tar.xz',
      '.tar.zst',
      '.tar.lz',
      '.tar.lzma',
      '.tar.z',
    ]) {
      if (lower.endsWith(ext)) {
        return name.substring(0, name.length - ext.length);
      }
    }
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);

    return name;
  }

  static String uniquePath(String desired) {
    bool taken(String p) =>
        FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound;
    if (!taken(desired)) return desired;
    for (var i = 1; i < 10000; i++) {
      final candidate = '$desired ($i)';
      if (!taken(candidate)) return candidate;
    }

    return '$desired ${DateTime.now().microsecondsSinceEpoch}';
  }

  static Future<void> openArchiveEntry(ArchiveLocation loc) async {
    final tempRoot = Directory(
      p.join(AppDirs.tempSync(), 'myexplorer-archive'),
    );
    final dest = p.join(
      tempRoot.path,
      p.basename(loc.archivePath),
      loc.innerPath,
    );
    await FsWorkerPool.instance.extractArchiveEntry(
      loc.archivePath,
      loc.innerPath,
      dest,
    );
    await OpenService.openDefault(dest);
  }

  static Future<void> createDirectory(String path) =>
      FsWorkerPool.instance.createDirectory(path);

  /// Creates an empty file. SFTP paths write an empty payload remotely;
  /// local / SMB paths use [File.create].
  static Future<void> createFile(String path) async {
    if (PlatformPaths.isSftpUri(path)) {
      return const SftpFs().writeBytes(path, Uint8List(0));
    }
    await File(path).create();
  }

  static Future<void> openInTerminal(String directory) =>
      TerminalService.openInDirectory(
        directory,
        preferredId: SettingsStore.instance.terminal.value,
        customCommand: SettingsStore.instance.terminalCustomCommand.value,
      );

  static Future<void> openWithDefaultApp(String path) =>
      OpenService.openDefault(path);
}
