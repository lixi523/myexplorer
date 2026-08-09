import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/files/file_icons.dart';
import 'package:myexplorer/features/files/material_icons_map.dart';

void main() {
  group('materialFileExtensions', () {
    test('maps common file extensions to material icons', () {
      expect(materialFileExtensions['png'], isNotEmpty);
      expect(materialFileExtensions['exe'], isNotEmpty);
      expect(materialFileExtensions['zip'], isNotEmpty);
      expect(materialFileExtensions['pdf'], isNotEmpty);
      expect(materialFileExtensions['jpg'], isNotEmpty);
      expect(materialFileExtensions['mp4'], isNotEmpty);
      expect(materialFileExtensions['md'], isNotEmpty);
      expect(materialFileExtensions['txt'], isNotEmpty);
    });

    test('is empty for unknown extensions', () {
      expect(materialFileExtensions['zzzundefined'], isNull);
    });

    test('lookup is case-insensitive via lowercase keys', () {
      expect(materialFileExtensions.containsKey('.PNG'), isFalse);
      expect(materialFileExtensions['png'], isNotNull);
    });
  });

  group('materialFileNames', () {
    test('maps well-known file names', () {
      expect(materialFileNames['dockerfile'], 'docker');
      expect(materialFileNames['license'], 'certificate');
      expect(materialFileNames['.gitignore'], 'git');
    });
  });

  group('materialFolderNames', () {
    test('maps well-known folder names', () {
      expect(materialFolderNames['src'], 'folder-src');
      expect(materialFolderNames['lib'], 'folder-lib');
      expect(materialFolderNames['test'], 'folder-test');
    });
  });

  group('buildFileIcon', () {
    test('folder with a known name renders a custom svg icon', () {
      final icon = buildFileIcon(name: 'src', ext: '', isFolder: true);
      expect(icon, isA<SvgPicture>());
    });

    test('plain folder renders the default folder icon', () {
      final icon = buildFileIcon(name: 'misc', ext: '', isFolder: true);
      expect(icon, isA<Icon>());
    });

    test('file with a known extension renders an svg icon', () {
      final icon = buildFileIcon(name: 'shot.png', ext: 'png', isFolder: false);
      expect(icon, isA<SvgPicture>());
    });

    test('file with an unknown extension falls back to document', () {
      final icon = buildFileIcon(
        name: 'data.zzzundefined',
        ext: 'zzzundefined',
        isFolder: false,
      );
      expect(icon, isA<SvgPicture>());
    });
  });
}
