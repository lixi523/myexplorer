import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/drives/drive_model.dart';

void main() {
  group('DriveSpace', () {
    test('computes used bytes', () {
      const space = DriveSpace(totalBytes: 1000, freeBytes: 300);
      expect(space.usedBytes, 700);
    });

    test('computes used fraction within bounds', () {
      const space = DriveSpace(totalBytes: 1000, freeBytes: 250);
      expect(space.usedFraction, 0.75);
    });

    test('returns zero fraction for unknown total size', () {
      const space = DriveSpace(totalBytes: 0, freeBytes: 0);
      expect(space.usedFraction, 0);
    });

    test('clamps used fraction to the [0, 1] range', () {
      const negative = DriveSpace(totalBytes: 10, freeBytes: 100);
      expect(negative.usedFraction, 0);
      const overfull = DriveSpace(totalBytes: 10, freeBytes: -5);
      expect(overfull.usedFraction, 1);
    });

    test('equality and hashCode match on both fields', () {
      const a = DriveSpace(totalBytes: 100, freeBytes: 40);
      const b = DriveSpace(totalBytes: 100, freeBytes: 40);
      const c = DriveSpace(totalBytes: 100, freeBytes: 41);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('Drive', () {
    test('reports mounted state from the mount point', () {
      const mounted = Drive(
        id: 'C:',
        label: 'Local Disk',
        mountPoint: 'C:\\',
        isRemovable: false,
      );
      const unmounted = Drive(id: 'Z:', label: 'Share', isRemovable: false);
      expect(mounted.isMounted, isTrue);
      expect(unmounted.isMounted, isFalse);
    });

    test('defaults isNetwork to false', () {
      const drive = Drive(id: 'C:', label: 'Local Disk', isRemovable: false);
      expect(drive.isNetwork, isFalse);
      expect(drive.remoteTarget, isNull);
      expect(drive.fsType, isNull);
    });

    test('equality and hashCode cover all fields', () {
      final a = Drive(
        id: 'Z:',
        label: 'Share',
        mountPoint: 'Z:\\',
        isRemovable: false,
        isNetwork: true,
        remoteTarget: r'\\server\share',
        fsType: 'NTFS',
      );
      final b = Drive(
        id: 'Z:',
        label: 'Share',
        mountPoint: 'Z:\\',
        isRemovable: false,
        isNetwork: true,
        remoteTarget: r'\\server\share',
        fsType: 'NTFS',
      );
      final different = Drive(
        id: 'Z:',
        label: 'Share',
        isRemovable: false,
        isNetwork: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == different, isFalse);
    });
  });
}
