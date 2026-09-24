import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';

const _paletteNames = <String, String>{
  'bg': '背景色',
  'bgSurface': '表面色',
  'bgSidebar': '侧边栏背景',
  'bgToolbar': '工具栏背景',
  'bgStatus': '状态栏背景',
  'bgHover': '悬停背景',
  'bgSelected': '选中背景',
  'bgSelectedMuted': '选中柔和背景',
  'bgInput': '输入框背景',
  'bgDivider': '分隔线色',
  'borderColor': '边框色',
  'accent': '强调色',
  'accentHover': '强调悬停色',
  'fg': '文字色',
  'fgMuted': '次要文字色',
  'fgSubtle': '弱文字色',
  'fgAccent': '强调文字色',
  'danger': '危险色',
  'success': '成功色',
  'warning': '警告色',
  'neutral': '中性色',
  'bgHoverStrong': '强悬停背景',
  'windowCloseHover': '关闭按钮悬停色',
  'windowClosePressed': '关闭按钮按下色',
  'shadowSubtle': '阴影色',
  'fileJs': 'JavaScript文件色',
  'fileHtml': 'HTML文件色',
  'fileCss': 'CSS文件色',
  'fileArchive': '压缩包文件色',
  'fileAudio': '音频文件色',
  'fileVideo': '视频文件色',
  'fileDefault': '默认文件色',
  'folderNameDark': '深色文件夹文字色',
  'folderNameLight': '浅色文件夹文字色',
};

@immutable
class AppThemePalette {
  final Color bg;
  final Color bgSurface;
  final Color bgSidebar;
  final Color bgToolbar;
  final Color bgStatus;
  final Color bgHover;
  final Color bgSelected;
  final Color bgSelectedMuted;
  final Color bgInput;
  final Color bgDivider;
  final Color borderColor;
  final Color accent;
  final Color accentHover;
  final Color fg;
  final Color fgMuted;
  final Color fgSubtle;
  final Color fgAccent;
  final Color danger;
  final Color success;
  final Color warning;
  final Color neutral;
  final Color bgHoverStrong;
  final Color windowCloseHover;
  final Color windowClosePressed;
  final Color shadowSubtle;
  final Color fileJs;
  final Color fileHtml;
  final Color fileCss;
  final Color fileArchive;
  final Color fileAudio;
  final Color fileVideo;
  final Color fileDefault;
  final Color folderNameDark;
  final Color folderNameLight;

  const AppThemePalette({
    required this.bg,
    required this.bgSurface,
    required this.bgSidebar,
    required this.bgToolbar,
    required this.bgStatus,
    required this.bgHover,
    required this.bgSelected,
    required this.bgSelectedMuted,
    required this.bgInput,
    required this.bgDivider,
    required this.borderColor,
    required this.accent,
    required this.accentHover,
    required this.fg,
    required this.fgMuted,
    required this.fgSubtle,
    required this.fgAccent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.neutral,
    required this.bgHoverStrong,
    required this.windowCloseHover,
    required this.windowClosePressed,
    required this.shadowSubtle,
    required this.fileJs,
    required this.fileHtml,
    required this.fileCss,
    required this.fileArchive,
    required this.fileAudio,
    required this.fileVideo,
    required this.fileDefault,
    this.folderNameDark = const Color(0xFFE9E9E9),
    this.folderNameLight = const Color(0xFF3C414B),
  });

  factory AppThemePalette.fromIni(Map<String, String> ini) {
    Color read(String key) {
      final value = ini[key] ?? ini[_paletteNames[key] ?? ''];
      if (value == null) {
        throw FormatException(t.preferences.appearance.missingColor(key: key));
      }

      return parseThemeColor(value, key);
    }

    Color readOpt(String key, Color fallback) {
      final value = ini[key] ?? ini[_paletteNames[key] ?? ''];
      if (value == null) return fallback;
      try {
        return parseThemeColor(value, key);
      } catch (e) {
        return fallback;
      }
    }

    return AppThemePalette(
      bg: read('bg'),
      bgSurface: read('bgSurface'),
      bgSidebar: read('bgSidebar'),
      bgToolbar: read('bgToolbar'),
      bgStatus: read('bgStatus'),
      bgHover: read('bgHover'),
      bgSelected: read('bgSelected'),
      bgSelectedMuted: read('bgSelectedMuted'),
      bgInput: read('bgInput'),
      bgDivider: read('bgDivider'),
      borderColor: read('borderColor'),
      accent: read('accent'),
      accentHover: read('accentHover'),
      fg: read('fg'),
      fgMuted: read('fgMuted'),
      fgSubtle: read('fgSubtle'),
      fgAccent: read('fgAccent'),
      danger: read('danger'),
      success: read('success'),
      warning: read('warning'),
      neutral: read('neutral'),
      bgHoverStrong: read('bgHoverStrong'),
      windowCloseHover: read('windowCloseHover'),
      windowClosePressed: read('windowClosePressed'),
      shadowSubtle: read('shadowSubtle'),
      fileJs: read('fileJs'),
      fileHtml: read('fileHtml'),
      fileCss: read('fileCss'),
      fileArchive: read('fileArchive'),
      fileAudio: read('fileAudio'),
      fileVideo: read('fileVideo'),
      fileDefault: read('fileDefault'),
      folderNameDark: readOpt('folderNameDark', const Color(0xFFE9E9E9)),
      folderNameLight: readOpt('folderNameLight', const Color(0xFF3C414B)),
    );
  }

  String toIni() {
    final b = StringBuffer();
    b.writeln('[palette]');
    b.writeln('${_paletteNames['bg']}=${_iniColor(bg)}');
    b.writeln('${_paletteNames['bgSurface']}=${_iniColor(bgSurface)}');
    b.writeln('${_paletteNames['bgSidebar']}=${_iniColor(bgSidebar)}');
    b.writeln('${_paletteNames['bgToolbar']}=${_iniColor(bgToolbar)}');
    b.writeln('${_paletteNames['bgStatus']}=${_iniColor(bgStatus)}');
    b.writeln('${_paletteNames['bgHover']}=${_iniColor(bgHover)}');
    b.writeln('${_paletteNames['bgSelected']}=${_iniColor(bgSelected)}');
    b.writeln(
      '${_paletteNames['bgSelectedMuted']}=${_iniColor(bgSelectedMuted)}',
    );
    b.writeln('${_paletteNames['bgInput']}=${_iniColor(bgInput)}');
    b.writeln('${_paletteNames['bgDivider']}=${_iniColor(bgDivider)}');
    b.writeln('${_paletteNames['borderColor']}=${_iniColor(borderColor)}');
    b.writeln('${_paletteNames['accent']}=${_iniColor(accent)}');
    b.writeln('${_paletteNames['accentHover']}=${_iniColor(accentHover)}');
    b.writeln('${_paletteNames['fg']}=${_iniColor(fg)}');
    b.writeln('${_paletteNames['fgMuted']}=${_iniColor(fgMuted)}');
    b.writeln('${_paletteNames['fgSubtle']}=${_iniColor(fgSubtle)}');
    b.writeln('${_paletteNames['fgAccent']}=${_iniColor(fgAccent)}');
    b.writeln('${_paletteNames['danger']}=${_iniColor(danger)}');
    b.writeln('${_paletteNames['success']}=${_iniColor(success)}');
    b.writeln('${_paletteNames['warning']}=${_iniColor(warning)}');
    b.writeln('${_paletteNames['neutral']}=${_iniColor(neutral)}');
    b.writeln('${_paletteNames['bgHoverStrong']}=${_iniColor(bgHoverStrong)}');
    b.writeln(
      '${_paletteNames['windowCloseHover']}=${_iniColor(windowCloseHover)}',
    );
    b.writeln(
      '${_paletteNames['windowClosePressed']}=${_iniColor(windowClosePressed)}',
    );
    b.writeln('${_paletteNames['shadowSubtle']}=${_iniColor(shadowSubtle)}');
    b.writeln('${_paletteNames['fileJs']}=${_iniColor(fileJs)}');
    b.writeln('${_paletteNames['fileHtml']}=${_iniColor(fileHtml)}');
    b.writeln('${_paletteNames['fileCss']}=${_iniColor(fileCss)}');
    b.writeln('${_paletteNames['fileArchive']}=${_iniColor(fileArchive)}');
    b.writeln('${_paletteNames['fileAudio']}=${_iniColor(fileAudio)}');
    b.writeln('${_paletteNames['fileVideo']}=${_iniColor(fileVideo)}');
    b.writeln('${_paletteNames['fileDefault']}=${_iniColor(fileDefault)}');
    b.writeln(
      '${_paletteNames['folderNameDark']}=${_iniColor(folderNameDark)}',
    );
    b.writeln(
      '${_paletteNames['folderNameLight']}=${_iniColor(folderNameLight)}',
    );

    return b.toString();
  }
}

@immutable
class AppThemeDefinition {
  final String id;
  final String name;
  final Brightness brightness;
  final AppThemePalette palette;
  final bool builtIn;

  const AppThemeDefinition({
    required this.id,
    required this.name,
    required this.brightness,
    required this.palette,
    this.builtIn = false,
  });

  factory AppThemeDefinition.fromIni(String content) {
    final sections = _parseIni(content);
    final meta = sections['meta'] ?? const <String, String>{};
    final id = meta['id'];
    final name = meta['name'];
    final brightness = meta['brightness'];
    final palette = sections['palette'];
    if (id == null || id.trim().isEmpty) {
      throw FormatException(t.preferences.appearance.missingThemeId);
    }
    if (name == null || name.trim().isEmpty) {
      throw FormatException(t.preferences.appearance.missingThemeName);
    }
    if (brightness == null) {
      throw FormatException(t.preferences.appearance.missingThemeBrightness);
    }
    if (palette == null || palette.isEmpty) {
      throw FormatException(t.preferences.appearance.missingThemePalette);
    }

    return AppThemeDefinition(
      id: id.trim(),
      name: name.trim(),
      brightness: _parseBrightness(brightness),
      palette: AppThemePalette.fromIni(palette),
    );
  }

  String toIni() {
    final b = StringBuffer();
    b.writeln('; 半透明颜色（如 阴影色）请保留 8 位 #AARRGGBB 以保留透明度');

    b.writeln('[meta]');
    b.writeln('id=$id');
    b.writeln('name=$name');
    b.writeln('brightness=${brightness == Brightness.dark ? 'dark' : 'light'}');
    b.writeln();
    b.write(palette.toIni());

    return b.toString();
  }
}

Map<String, Map<String, String>> _parseIni(String content) {
  final sections = <String, Map<String, String>>{};
  String? current;
  for (var line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(';') || trimmed.startsWith('#')) {
      continue;
    }
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      current = trimmed.substring(1, trimmed.length - 1).trim();
      sections[current] = <String, String>{};
      continue;
    }
    if (current == null) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    final key = trimmed.substring(0, eq).trim();
    final value = trimmed.substring(eq + 1).trim();
    sections[current]![key] = value;
  }

  return sections;
}

String _iniColor(Color color) {
  String h(int v) => v.toRadixString(16).padLeft(2, '0');
  final a = (color.a * 255).round();
  final r = h((color.r * 255).round());
  final g = h((color.g * 255).round());
  final b = h((color.b * 255).round());
  if (a == 255) return (r + g + b).toUpperCase();

  return (h(a) + r + g + b).toUpperCase();
}

Color parseThemeColor(String value, String key) {
  var hex = value.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  } else if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.substring(2);
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8 || !RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) {
    throw FormatException(t.preferences.appearance.invalidColor(key: key));
  }

  return Color(int.parse(hex, radix: 16));
}

Brightness _parseBrightness(String value) {
  return switch (value.trim().toLowerCase()) {
    'dark' => Brightness.dark,
    'light' => Brightness.light,
    _ => throw FormatException(t.preferences.appearance.invalidThemeBrightness),
  };
}
