import 'package:flutter/widgets.dart';

import '../../ui/icons/myexplorer_icons.dart';

/// Glyph shown for a plugin entry that declares no icon, or an unknown name.
const IconData defaultPluginGlyph = MyExplorerIconsRegular.gearSix;

/// Named builtin icons a plugin may set via `icon = "<name>"` instead of
/// shipping an image file. Keep names stable - they are part of the plugin API.
const Map<String, IconData> _pluginGlyphs = {
  'archive': MyExplorerIconsRegular.archive,
  'arrow-clockwise': MyExplorerIconsRegular.arrowClockwise,
  'bell': MyExplorerIconsRegular.bell,
  'bookmark': MyExplorerIconsRegular.bookmarkSimple,
  'bug': MyExplorerIconsRegular.bug,
  'calendar': MyExplorerIconsRegular.calendar,
  'check': MyExplorerIconsRegular.check,
  'clipboard': MyExplorerIconsRegular.clipboard,
  'clock': MyExplorerIconsRegular.clock,
  'code': MyExplorerIconsRegular.code,
  'copy': MyExplorerIconsRegular.copy,
  'desktop': MyExplorerIconsRegular.desktop,
  'download': MyExplorerIconsRegular.downloadSimple,
  'eye': MyExplorerIconsRegular.eye,
  'file': MyExplorerIconsRegular.file,
  'file-audio': MyExplorerIconsRegular.fileAudio,
  'file-code': MyExplorerIconsRegular.fileCode,
  'file-image': MyExplorerIconsRegular.fileImage,
  'file-pdf': MyExplorerIconsRegular.filePdf,
  'file-text': MyExplorerIconsRegular.fileTxt,
  'file-zip': MyExplorerIconsRegular.fileZip,
  'folder': MyExplorerIconsRegular.folder,
  'folder-open': MyExplorerIconsRegular.folderOpen,
  'folder-plus': MyExplorerIconsRegular.folderPlus,
  'gear': MyExplorerIconsRegular.gearSix,
  'git-branch': MyExplorerIconsRegular.gitBranch,
  'hard-drive': MyExplorerIconsRegular.hardDrive,
  'image': MyExplorerIconsRegular.image,
  'info': MyExplorerIconsRegular.info,
  'keyboard': MyExplorerIconsRegular.keyboard,
  'list': MyExplorerIconsRegular.list,
  'magic-wand': MyExplorerIconsRegular.magicWand,
  'music': MyExplorerIconsRegular.musicNote,
  'note': MyExplorerIconsRegular.notebook,
  'palette': MyExplorerIconsRegular.palette,
  'pencil': MyExplorerIconsRegular.pencilSimple,
  'plus': MyExplorerIconsRegular.plus,
  'refresh': MyExplorerIconsRegular.arrowClockwise,
  'ruler': MyExplorerIconsRegular.ruler,
  'scissors': MyExplorerIconsRegular.scissors,
  'search': MyExplorerIconsRegular.magnifyingGlass,
  'sliders': MyExplorerIconsRegular.slidersHorizontal,
  'terminal': MyExplorerIconsRegular.terminal,
  'trash': MyExplorerIconsRegular.trash,
  'tree': MyExplorerIconsRegular.treeStructure,
  'usb': MyExplorerIconsRegular.usb,
  'video': MyExplorerIconsRegular.videoCamera,
  'warning': MyExplorerIconsRegular.warning,
};

/// Resolves a plugin's `icon` name to a builtin glyph. Image paths (`.svg`/
/// `.png`) are handled separately via `PluginContribution.iconPath`; this
/// returns the fallback for those and for unknown names.
IconData pluginGlyph(String? name) {
  if (name == null) return defaultPluginGlyph;

  return _pluginGlyphs[name] ?? defaultPluginGlyph;
}
