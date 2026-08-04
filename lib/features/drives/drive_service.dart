import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'drive_model.dart';
import '../../core/logging/app_logger.dart';
import '../../i18n/strings.g.dart';

abstract class DriveService {
  Future<List<Drive>> getDrives();
  Future<void> mount(Drive drive);
  Future<void> mountWithPassword(Drive drive, String password);
  Future<void> unmount(Drive drive);

  factory DriveService() {
    return _WindowsDriveService();
  }
}

typedef _WNetGetConnectionNative =
    Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Pointer<Uint32>);
typedef _WNetGetConnectionDart =
    int Function(Pointer<Utf16>, Pointer<Utf16>, Pointer<Uint32>);

class _WindowsDriveService implements DriveService {
  static final _wNetGetConnection = DynamicLibrary.open('mpr.dll')
      .lookupFunction<_WNetGetConnectionNative, _WNetGetConnectionDart>(
        'WNetGetConnectionW',
      );

  @override
  Future<List<Drive>> getDrives() async {
    final drives = <Drive>[];

    final bitMask = GetLogicalDrives();
    if (bitMask == 0) return drives;

    for (var i = 0; i < 26; i++) {
      if ((bitMask & (1 << i)) != 0) {
        final letter = String.fromCharCode(65 + i);
        final rootPath = '$letter:\\';
        final rootPathPtr = rootPath.toNativeUtf16();

        try {
          final driveType = GetDriveType(rootPathPtr);
          if (driveType == DRIVE_REMOTE) {
            final target = _networkDriveTarget(letter);
            drives.add(
              Drive(
                id: rootPath,
                label: t.sidebar.drives.windowsDriveLabel(
                  name: _shareName(target) ?? t.sidebar.drives.networkDrive,
                  letter: letter,
                ),
                mountPoint: rootPath,
                isRemovable: false,
                isNetwork: true,
                remoteTarget: target,
                fsType: null,
              ),
            );
          } else if (driveType == DRIVE_REMOVABLE || driveType == DRIVE_FIXED) {
            final volumeNameBuffer = wsalloc(MAX_PATH + 1);
            try {
              final result = GetVolumeInformation(
                rootPathPtr,
                volumeNameBuffer,
                MAX_PATH + 1,
                nullptr,
                nullptr,
                nullptr,
                nullptr,
                0,
              );

              String label = t.sidebar.drives.localDisk;
              if (result != 0) {
                label = volumeNameBuffer.toDartString();
              }
              if (label.isEmpty) {
                label = driveType == DRIVE_REMOVABLE
                    ? t.sidebar.drives.usbDrive
                    : t.sidebar.drives.localDisk;
              }

              drives.add(
                Drive(
                  id: rootPath,
                  label: t.sidebar.drives.windowsDriveLabel(
                    name: label,
                    letter: letter,
                  ),
                  mountPoint: rootPath,
                  isRemovable: driveType == DRIVE_REMOVABLE,
                  fsType: null,
                  space: _windowsSpace(rootPath),
                ),
              );
            } finally {
              free(volumeNameBuffer);
            }
          }
        } finally {
          free(rootPathPtr);
        }
      }
    }

    return drives;
  }

  @override
  Future<void> mount(Drive drive) async {}

  @override
  Future<void> mountWithPassword(Drive drive, String password) async {}

  @override
  Future<void> unmount(Drive drive) async {
    final letter = drive.id.replaceAll(r'\', '');
    if (drive.isNetwork) {
      await Process.run('net', ['use', letter, '/delete', '/y']);

      return;
    }
    if (!drive.isRemovable) return;
    final script =
        '\$driveEject = New-Object -comObject Shell.Application; \$driveEject.Namespace(17).ParseName("$letter").InvokeVerb("Eject")';
    await Process.run('powershell', ['-NoProfile', '-Command', script]);
  }

  /// Resolves the UNC path (e.g. `\\server\share`) backing a mapped network
  /// drive letter via WNetGetConnectionW. Returns null if it can't be read.
  String? _shareName(String? target) {
    if (target == null) return null;
    final parts = target
        .split(RegExp(r'[\\/]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;

    return parts.last;
  }

  String? _networkDriveTarget(String letter) {
    final local = '$letter:'.toNativeUtf16();
    final length = calloc<Uint32>()..value = MAX_PATH + 1;
    final remote = wsalloc(MAX_PATH + 1);
    try {
      final result = _wNetGetConnection(local, remote, length);
      if (result != 0) return null;
      final unc = remote.toDartString();

      return unc.isEmpty ? null : unc;
    } catch (e, st) {
      log.warn('drives', 'network drive lookup failed', error: e, stack: st);

      return null;
    } finally {
      free(local);
      free(remote);
      calloc.free(length);
    }
  }

  DriveSpace? _windowsSpace(String rootPath) {
    final path = rootPath.toNativeUtf16();
    final freeToCaller = calloc<Uint64>();
    final total = calloc<Uint64>();
    final free = calloc<Uint64>();
    try {
      final ok = GetDiskFreeSpaceEx(path, freeToCaller, total, free);
      if (ok == 0 || total.value <= 0) return null;

      return DriveSpace(totalBytes: total.value, freeBytes: free.value);
    } catch (e, st) {
      log.warn(
        'drives',
        'windows drive space lookup failed',
        error: e,
        stack: st,
      );

      return null;
    } finally {
      calloc.free(path);
      calloc.free(freeToCaller);
      calloc.free(total);
      calloc.free(free);
    }
  }
}
