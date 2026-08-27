import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';
import '../../core/platform/app_dirs.dart';
import '../../core/platform/gbk_codec.dart';
import '../../i18n/strings.g.dart';
import 'app_theme_definition.dart';

class AppThemeRegistry {
  AppThemeRegistry();

  static final AppThemeRegistry instance = AppThemeRegistry();
  static const defaultThemeId = 'dark';

  final _themes = <AppThemeDefinition>[...builtInThemes];
  final _warnedUnknownIds = <String>{};
  String? _cachedThemesDir;

  List<AppThemeDefinition> get themes => List.unmodifiable(_themes);

  AppThemeDefinition get defaultTheme => _themes.firstWhere(
    (theme) => theme.id == defaultThemeId,
    orElse: () => builtInThemes.first,
  );

  Future<void> load({String? customThemesPath}) async {
    final dir = customThemesPath ?? await AppDirs.themes();
    _cachedThemesDir = dir;
    await _seedBuiltInThemes(dir);
    _themes
      ..clear()
      ..addAll(await _loadThemesFromDir(dir));
  }

  void loadSync() {
    final dirPath = _cachedThemesDir;
    if (dirPath == null) return;
    _seedBuiltInThemesSync(dirPath);
    _themes
      ..clear()
      ..addAll(_loadThemesFromDirSync(dirPath));
  }

  AppThemeDefinition resolve(String id) {
    for (final theme in _themes) {
      if (theme.id == id) return theme;
    }
    if (id.isNotEmpty && id != defaultThemeId && _warnedUnknownIds.add(id)) {
      log.warn(
        'theme',
        t.preferences.appearance.unknownThemeUsingDefault(
          id: id,
          theme: t.preferences.appearance.themeDark,
        ),
      );
    }

    return defaultTheme;
  }

  Future<List<AppThemeDefinition>> _loadThemesFromDir(String dirPath) async {
    final iniById = <String, AppThemeDefinition>{};
    final custom = <AppThemeDefinition>[];
    final dir = Directory(dirPath);
    try {
      await for (final entity in dir.list()) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.ini') {
          continue;
        }
        final theme = await _readThemeIni(entity);
        if (theme == null || iniById.containsKey(theme.id)) continue;
        iniById[theme.id] = theme;
        custom.add(theme);
      }
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.couldNotLoadCustomThemes,
        error: error,
        stack: stack,
      );
    }

    return _mergeThemes(iniById, custom);
  }

  List<AppThemeDefinition> _loadThemesFromDirSync(String dirPath) {
    final iniById = <String, AppThemeDefinition>{};
    final custom = <AppThemeDefinition>[];
    final dir = Directory(dirPath);
    try {
      for (final entity in dir.listSync()) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.ini') {
          continue;
        }
        final theme = _readThemeIniSync(entity);
        if (theme == null || iniById.containsKey(theme.id)) continue;
        iniById[theme.id] = theme;
        custom.add(theme);
      }
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.couldNotLoadCustomThemes,
        error: error,
        stack: stack,
      );
    }

    return _mergeThemes(iniById, custom);
  }

  List<AppThemeDefinition> _mergeThemes(
    Map<String, AppThemeDefinition> iniById,
    List<AppThemeDefinition> custom,
  ) {
    final builtInIds = builtInThemes.map((t) => t.id).toSet();
    final out = <AppThemeDefinition>[];
    for (final builtIn in builtInThemes) {
      out.add(iniById[builtIn.id] ?? builtIn);
    }
    for (final theme in custom) {
      if (!builtInIds.contains(theme.id)) out.add(theme);
    }

    return out;
  }

  Future<void> _seedBuiltInThemes(String dirPath) async {
    final dir = Directory(dirPath);
    try {
      await dir.create(recursive: true);
      final existingIds = await _themeIdsInDir(dir);
      for (final theme in builtInThemes) {
        if (existingIds.contains(theme.id)) continue;
        await File(
          p.join(dirPath, '${theme.id}.ini'),
        ).writeAsString(theme.toIni());
      }
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.couldNotLoadCustomThemes,
        error: error,
        stack: stack,
      );
    }
  }

  void _seedBuiltInThemesSync(String dirPath) {
    final dir = Directory(dirPath);
    try {
      dir.createSync(recursive: true);
      if (!dir.existsSync()) return;
      final existingIds = _themeIdsInDirSync(dir);
      for (final theme in builtInThemes) {
        if (existingIds.contains(theme.id)) continue;
        File(
          p.join(dirPath, '${theme.id}.ini'),
        ).writeAsStringSync(theme.toIni());
      }
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.couldNotLoadCustomThemes,
        error: error,
        stack: stack,
      );
    }
  }

  Future<Set<String>> _themeIdsInDir(Directory dir) async {
    final ids = <String>{};
    await for (final entity in dir.list()) {
      if (entity is! File || p.extension(entity.path).toLowerCase() != '.ini') {
        continue;
      }
      final theme = await _readThemeIni(entity);
      if (theme != null) ids.add(theme.id);
    }

    return ids;
  }

  Set<String> _themeIdsInDirSync(Directory dir) {
    final ids = <String>{};
    for (final entity in dir.listSync()) {
      if (entity is! File || p.extension(entity.path).toLowerCase() != '.ini') {
        continue;
      }
      final theme = _readThemeIniSync(entity);
      if (theme != null) ids.add(theme.id);
    }

    return ids;
  }

  Future<AppThemeDefinition?> _readThemeIni(File file) async {
    try {
      return AppThemeDefinition.fromIni(
        _decodeThemeBytes(await file.readAsBytes()),
      );
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.skippingThemeFile(path: file.path),
        error: error,
        stack: stack,
      );

      return null;
    }
  }

  AppThemeDefinition? _readThemeIniSync(File file) {
    try {
      return AppThemeDefinition.fromIni(
        _decodeThemeBytes(file.readAsBytesSync()),
      );
    } catch (e, st) {
      log.warn(
        'theme',
        'failed to load theme file ${file.path}',
        error: e,
        stack: st,
      );

      return null;
    }
  }

  /// Decodes theme ini bytes as UTF-8, falling back to GBK (ANSI on Chinese
  /// Windows) when the file was saved by an editor defaulting to the legacy
  /// codepage. Explicit BOMs are honoured first (UTF-8, UTF-16LE, UTF-16BE) so
  /// files saved by editors defaulting to UTF-16 still load. Unknown encodings
  /// fall back to UTF-8's lossy decode so a bad file still produces a parse
  /// error (and is skipped) instead of crashing.
  String _decodeThemeBytes(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes, 2, littleEndian: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes, 2, littleEndian: false);
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return decodeGbkBytes(bytes) ?? utf8.decode(bytes, allowMalformed: true);
    }
  }

  String _decodeUtf16(
    List<int> bytes,
    int offset, {
    required bool littleEndian,
  }) {
    final buffer = StringBuffer();
    for (var i = offset; i + 1 < bytes.length; i += 2) {
      final unit = littleEndian
          ? (bytes[i] | (bytes[i + 1] << 8))
          : ((bytes[i] << 8) | bytes[i + 1]);
      buffer.writeCharCode(unit);
    }

    return buffer.toString();
  }
}

const darkTheme = AppThemeDefinition(
  id: 'dark',
  name: 'Dark',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF464B55),
    bgSurface: Color(0xFF464B55),
    bgSidebar: Color(0xFF464B55),
    bgToolbar: Color(0xFF464B55),
    bgStatus: Color(0xFF464B55),
    bgHover: Color(0xFF525966),
    bgSelected: Color(0xFF525966),
    bgSelectedMuted: Color(0xFF525966),
    bgInput: Color(0xFF525966),
    bgDivider: Color(0xFF5A6070),
    borderColor: Color(0xFF5A6070),
    accent: Color(0xFF5CA8FF),
    accentHover: Color(0xFF7CBCFF),
    fg: Color(0xFFDFE9E9),
    fgMuted: Color(0xFF9CA3AF),
    fgSubtle: Color(0xFF7A808C),
    fgAccent: Color(0xFF7CBCFF),
    danger: Color(0xFFCF6679),
    success: Color(0xFFA6E3A1),
    warning: Color(0xFFF9E2AF),
    neutral: Color(0xFF7B8794),
    bgHoverStrong: Color(0xFF5B6270),
    windowCloseHover: Color(0xFFE81123),
    windowClosePressed: Color(0xFFBF0F1F),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFF7DF1E),
    fileHtml: Color(0xFFE34F26),
    fileCss: Color(0xFF1572B6),
    fileArchive: Color(0xFFFAB387),
    fileAudio: Color(0xFFCBA6F7),
    fileVideo: Color(0xFFF5C2E7),
    fileDefault: Color(0xFF6B6B6B),
  ),
);

const lightTheme = AppThemeDefinition(
  id: 'light',
  name: 'Light',
  brightness: Brightness.light,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFFF4F5F7),
    bgSurface: Color(0xFFFFFFFF),
    bgSidebar: Color(0xFFEDEEF0),
    bgToolbar: Color(0xFFEDEEF0),
    bgStatus: Color(0xFFEDEEF0),
    bgHover: Color(0xFFE4E7EB),
    bgSelected: Color(0xFFD6E4FB),
    bgSelectedMuted: Color(0xFFE4E7EB),
    bgInput: Color(0xFFFFFFFF),
    bgDivider: Color(0xFFD7DAE0),
    borderColor: Color(0xFFD7DAE0),
    accent: Color(0xFF2F7FE5),
    accentHover: Color(0xFF1D63C9),
    fg: Color(0xFF3C414B),
    fgMuted: Color(0xFF4A515C),
    fgSubtle: Color(0xFF878D98),
    fgAccent: Color(0xFF1D63C9),
    danger: Color(0xFFC8323C),
    success: Color(0xFF1F7A33),
    warning: Color(0xFF9A6B00),
    neutral: Color(0xFF566270),
    bgHoverStrong: Color(0xFFD7DAE0),
    windowCloseHover: Color(0xFFE81123),
    windowClosePressed: Color(0xFFBF0F1F),
    shadowSubtle: Color(0x1A000000),
    fileJs: Color(0xFFC9A800),
    fileHtml: Color(0xFFE34F26),
    fileCss: Color(0xFF1572B6),
    fileArchive: Color(0xFFC9762B),
    fileAudio: Color(0xFF8A5CF0),
    fileVideo: Color(0xFFC2418A),
    fileDefault: Color(0xFF9AA0A6),
  ),
);

const nordTheme = AppThemeDefinition(
  id: 'nord',
  name: 'Nord',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF2E3440),
    bgSurface: Color(0xFF3B4252),
    bgSidebar: Color(0xFF242933),
    bgToolbar: Color(0xFF242933),
    bgStatus: Color(0xFF242933),
    bgHover: Color(0xFF434C5E),
    bgSelected: Color(0xFF4C566A),
    bgSelectedMuted: Color(0xFF434C5E),
    bgInput: Color(0xFF3B4252),
    bgDivider: Color(0xFF4C566A),
    borderColor: Color(0xFF4C566A),
    accent: Color(0xFF88C0D0),
    accentHover: Color(0xFF8FBCBB),
    fg: Color(0xFFECEFF4),
    fgMuted: Color(0xFFD8DEE9),
    fgSubtle: Color(0xFF81A1C1),
    fgAccent: Color(0xFF8FBCBB),
    danger: Color(0xFFBF616A),
    success: Color(0xFFA3BE8C),
    warning: Color(0xFFEBCB8B),
    neutral: Color(0xFF81A1C1),
    bgHoverStrong: Color(0xFF4C566A),
    windowCloseHover: Color(0xFFBF616A),
    windowClosePressed: Color(0xFFA84F58),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFEBCB8B),
    fileHtml: Color(0xFFD08770),
    fileCss: Color(0xFF5E81AC),
    fileArchive: Color(0xFFD08770),
    fileAudio: Color(0xFFB48EAD),
    fileVideo: Color(0xFFB48EAD),
    fileDefault: Color(0xFF81A1C1),
  ),
);

const tokyoNightTheme = AppThemeDefinition(
  id: 'tokyo-night',
  name: 'Tokyo Night',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF1A1B26),
    bgSurface: Color(0xFF1F2335),
    bgSidebar: Color(0xFF16161E),
    bgToolbar: Color(0xFF16161E),
    bgStatus: Color(0xFF16161E),
    bgHover: Color(0xFF292E42),
    bgSelected: Color(0xFF283457),
    bgSelectedMuted: Color(0xFF292E42),
    bgInput: Color(0xFF1F2335),
    bgDivider: Color(0xFF3B4261),
    borderColor: Color(0xFF3B4261),
    accent: Color(0xFF7AA2F7),
    accentHover: Color(0xFF89DDFF),
    fg: Color(0xFFC0CAF5),
    fgMuted: Color(0xFFA9B1D6),
    fgSubtle: Color(0xFF565F89),
    fgAccent: Color(0xFF89DDFF),
    danger: Color(0xFFF7768E),
    success: Color(0xFF9ECE6A),
    warning: Color(0xFFE0AF68),
    neutral: Color(0xFF737AA2),
    bgHoverStrong: Color(0xFF343A55),
    windowCloseHover: Color(0xFFF7768E),
    windowClosePressed: Color(0xFFDB4B4B),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFE0AF68),
    fileHtml: Color(0xFFFF9E64),
    fileCss: Color(0xFF7AA2F7),
    fileArchive: Color(0xFFFF9E64),
    fileAudio: Color(0xFFBB9AF7),
    fileVideo: Color(0xFF9D7CD8),
    fileDefault: Color(0xFF737AA2),
  ),
);

const oneDarkTheme = AppThemeDefinition(
  id: 'one-dark',
  name: 'One Dark',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF282C34),
    bgSurface: Color(0xFF202329),
    bgSidebar: Color(0xFF202329),
    bgToolbar: Color(0xFF202329),
    bgStatus: Color(0xFF202329),
    bgHover: Color(0xFF2C313A),
    bgSelected: Color(0xFF323844),
    bgSelectedMuted: Color(0xFF2C313A),
    bgInput: Color(0xFF282C34),
    bgDivider: Color(0xFF333841),
    borderColor: Color(0xFF333841),
    accent: Color(0xFF568AF2),
    accentHover: Color(0xFF6494ED),
    fg: Color(0xFFABB2BF),
    fgMuted: Color(0xFF7E8491),
    fgSubtle: Color(0xFF5C6370),
    fgAccent: Color(0xFF568AF2),
    danger: Color(0xFFE06C75),
    success: Color(0xFF89CA78),
    warning: Color(0xFFD9A343),
    neutral: Color(0xFF5C6370),
    bgHoverStrong: Color(0xFF3D424B),
    windowCloseHover: Color(0xFFE81123),
    windowClosePressed: Color(0xFFBF0F1F),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFE5C07B),
    fileHtml: Color(0xFFE06C75),
    fileCss: Color(0xFF61AFEF),
    fileArchive: Color(0xFFC678DD),
    fileAudio: Color(0xFF56B6C2),
    fileVideo: Color(0xFFE06C75),
    fileDefault: Color(0xFFABB2BF),
  ),
);

const gruvboxDarkTheme = AppThemeDefinition(
  id: 'gruvbox-dark',
  name: 'Gruvbox Dark',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF282828),
    bgSurface: Color(0xFF32302F),
    bgSidebar: Color(0xFF1D2021),
    bgToolbar: Color(0xFF1D2021),
    bgStatus: Color(0xFF1D2021),
    bgHover: Color(0xFF3C3836),
    bgSelected: Color(0xFF504945),
    bgSelectedMuted: Color(0xFF3C3836),
    bgInput: Color(0xFF32302F),
    bgDivider: Color(0xFF504945),
    borderColor: Color(0xFF504945),
    accent: Color(0xFF83A598),
    accentHover: Color(0xFF8EC07C),
    fg: Color(0xFFEBDBB2),
    fgMuted: Color(0xFFA89984),
    fgSubtle: Color(0xFF665C54),
    fgAccent: Color(0xFF8EC07C),
    danger: Color(0xFFFB4934),
    success: Color(0xFFB8BB26),
    warning: Color(0xFFFABD2F),
    neutral: Color(0xFF928374),
    bgHoverStrong: Color(0xFF504945),
    windowCloseHover: Color(0xFFFB4934),
    windowClosePressed: Color(0xFFCC241D),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFFABD2F),
    fileHtml: Color(0xFFFE8019),
    fileCss: Color(0xFF83A598),
    fileArchive: Color(0xFFFE8019),
    fileAudio: Color(0xFFD3869B),
    fileVideo: Color(0xFFB16286),
    fileDefault: Color(0xFF928374),
  ),
);

const gruvboxLightTheme = AppThemeDefinition(
  id: 'gruvbox-light',
  name: 'Gruvbox Light',
  brightness: Brightness.light,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFFFBF1C7),
    bgSurface: Color(0xFFF9F5D7),
    bgSidebar: Color(0xFFF2E5BC),
    bgToolbar: Color(0xFFF2E5BC),
    bgStatus: Color(0xFFF2E5BC),
    bgHover: Color(0xFFEBDBB2),
    bgSelected: Color(0xFFD5C4A1),
    bgSelectedMuted: Color(0xFFEBDBB2),
    bgInput: Color(0xFFF9F5D7),
    bgDivider: Color(0xFFD5C4A1),
    borderColor: Color(0xFFD5C4A1),
    accent: Color(0xFF076678),
    accentHover: Color(0xFF427B58),
    fg: Color(0xFF3C3836),
    fgMuted: Color(0xFF665C54),
    fgSubtle: Color(0xFFA89984),
    fgAccent: Color(0xFF427B58),
    danger: Color(0xFF9D0006),
    success: Color(0xFF79740E),
    warning: Color(0xFFB57614),
    neutral: Color(0xFF7C6F64),
    bgHoverStrong: Color(0xFFD5C4A1),
    windowCloseHover: Color(0xFFCC241D),
    windowClosePressed: Color(0xFF9D0006),
    shadowSubtle: Color(0x1A000000),
    fileJs: Color(0xFFB57614),
    fileHtml: Color(0xFFAF3A03),
    fileCss: Color(0xFF076678),
    fileArchive: Color(0xFFAF3A03),
    fileAudio: Color(0xFF8F3F71),
    fileVideo: Color(0xFFB16286),
    fileDefault: Color(0xFF928374),
  ),
);

const draculaTheme = AppThemeDefinition(
  id: 'dracula',
  name: 'Dracula',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF282A36),
    bgSurface: Color(0xFF2D2F3D),
    bgSidebar: Color(0xFF21222C),
    bgToolbar: Color(0xFF21222C),
    bgStatus: Color(0xFF21222C),
    bgHover: Color(0xFF343746),
    bgSelected: Color(0xFF44475A),
    bgSelectedMuted: Color(0xFF343746),
    bgInput: Color(0xFF21222C),
    bgDivider: Color(0xFF44475A),
    borderColor: Color(0xFF44475A),
    accent: Color(0xFFBD93F9),
    accentHover: Color(0xFFD6ACFF),
    fg: Color(0xFFF8F8F2),
    fgMuted: Color(0xFFAEB3CC),
    fgSubtle: Color(0xFF6272A4),
    fgAccent: Color(0xFF8BE9FD),
    danger: Color(0xFFFF5555),
    success: Color(0xFF50FA7B),
    warning: Color(0xFFF1FA8C),
    neutral: Color(0xFF6272A4),
    bgHoverStrong: Color(0xFF44475A),
    windowCloseHover: Color(0xFFFF5555),
    windowClosePressed: Color(0xFFD64545),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFF1FA8C),
    fileHtml: Color(0xFFFFB86C),
    fileCss: Color(0xFF8BE9FD),
    fileArchive: Color(0xFFFFB86C),
    fileAudio: Color(0xFFBD93F9),
    fileVideo: Color(0xFFFF79C6),
    fileDefault: Color(0xFF6272A4),
  ),
);

const solarizedDarkTheme = AppThemeDefinition(
  id: 'solarized-dark',
  name: 'Solarized Dark',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF002B36),
    bgSurface: Color(0xFF073642),
    bgSidebar: Color(0xFF00212B),
    bgToolbar: Color(0xFF00212B),
    bgStatus: Color(0xFF00212B),
    bgHover: Color(0xFF073642),
    bgSelected: Color(0xFF0A4A57),
    bgSelectedMuted: Color(0xFF073642),
    bgInput: Color(0xFF073642),
    bgDivider: Color(0xFF0D3C47),
    borderColor: Color(0xFF0D3C47),
    accent: Color(0xFF268BD2),
    accentHover: Color(0xFF2AA198),
    fg: Color(0xFF839496),
    fgMuted: Color(0xFF657B83),
    fgSubtle: Color(0xFF586E75),
    fgAccent: Color(0xFF2AA198),
    danger: Color(0xFFDC322F),
    success: Color(0xFF859900),
    warning: Color(0xFFB58900),
    neutral: Color(0xFF586E75),
    bgHoverStrong: Color(0xFF0A4A57),
    windowCloseHover: Color(0xFFDC322F),
    windowClosePressed: Color(0xFFB52926),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFB58900),
    fileHtml: Color(0xFFCB4B16),
    fileCss: Color(0xFF268BD2),
    fileArchive: Color(0xFFCB4B16),
    fileAudio: Color(0xFF6C71C4),
    fileVideo: Color(0xFFD33682),
    fileDefault: Color(0xFF586E75),
  ),
);

const solarizedLightTheme = AppThemeDefinition(
  id: 'solarized-light',
  name: 'Solarized Light',
  brightness: Brightness.light,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFFFDF6E3),
    bgSurface: Color(0xFFFFFCF2),
    bgSidebar: Color(0xFFEEE8D5),
    bgToolbar: Color(0xFFEEE8D5),
    bgStatus: Color(0xFFEEE8D5),
    bgHover: Color(0xFFE9E2CC),
    bgSelected: Color(0xFFDDD6BF),
    bgSelectedMuted: Color(0xFFE9E2CC),
    bgInput: Color(0xFFFFFCF2),
    bgDivider: Color(0xFFDDD6BF),
    borderColor: Color(0xFFDDD6BF),
    accent: Color(0xFF268BD2),
    accentHover: Color(0xFF2AA198),
    fg: Color(0xFF586E75),
    fgMuted: Color(0xFF657B83),
    fgSubtle: Color(0xFF93A1A1),
    fgAccent: Color(0xFF2AA198),
    danger: Color(0xFFDC322F),
    success: Color(0xFF859900),
    warning: Color(0xFFB58900),
    neutral: Color(0xFF93A1A1),
    bgHoverStrong: Color(0xFFDDD6BF),
    windowCloseHover: Color(0xFFDC322F),
    windowClosePressed: Color(0xFFB52926),
    shadowSubtle: Color(0x1A000000),
    fileJs: Color(0xFFB58900),
    fileHtml: Color(0xFFCB4B16),
    fileCss: Color(0xFF268BD2),
    fileArchive: Color(0xFFCB4B16),
    fileAudio: Color(0xFF6C71C4),
    fileVideo: Color(0xFFD33682),
    fileDefault: Color(0xFF93A1A1),
  ),
);

const catppuccinMochaTheme = AppThemeDefinition(
  id: 'catppuccin-mocha',
  name: 'Catppuccin Mocha',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF1E1E2E),
    bgSurface: Color(0xFF313244),
    bgSidebar: Color(0xFF181825),
    bgToolbar: Color(0xFF181825),
    bgStatus: Color(0xFF181825),
    bgHover: Color(0xFF313244),
    bgSelected: Color(0xFF45475A),
    bgSelectedMuted: Color(0xFF313244),
    bgInput: Color(0xFF313244),
    bgDivider: Color(0xFF45475A),
    borderColor: Color(0xFF45475A),
    accent: Color(0xFF89B4FA),
    accentHover: Color(0xFF74C7EC),
    fg: Color(0xFFCDD6F4),
    fgMuted: Color(0xFFA6ADC8),
    fgSubtle: Color(0xFF6C7086),
    fgAccent: Color(0xFF89DCEB),
    danger: Color(0xFFF38BA8),
    success: Color(0xFFA6E3A1),
    warning: Color(0xFFF9E2AF),
    neutral: Color(0xFF7F849C),
    bgHoverStrong: Color(0xFF45475A),
    windowCloseHover: Color(0xFFF38BA8),
    windowClosePressed: Color(0xFFD05A78),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFF9E2AF),
    fileHtml: Color(0xFFFAB387),
    fileCss: Color(0xFF89B4FA),
    fileArchive: Color(0xFFFAB387),
    fileAudio: Color(0xFFCBA6F7),
    fileVideo: Color(0xFFF5C2E7),
    fileDefault: Color(0xFF6C7086),
  ),
);

const catppuccinLatteTheme = AppThemeDefinition(
  id: 'catppuccin-latte',
  name: 'Catppuccin Latte',
  brightness: Brightness.light,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFFEFF1F5),
    bgSurface: Color(0xFFFFFFFF),
    bgSidebar: Color(0xFFE6E9EF),
    bgToolbar: Color(0xFFE6E9EF),
    bgStatus: Color(0xFFE6E9EF),
    bgHover: Color(0xFFCCD0DA),
    bgSelected: Color(0xFFBCC0CC),
    bgSelectedMuted: Color(0xFFCCD0DA),
    bgInput: Color(0xFFFFFFFF),
    bgDivider: Color(0xFFCCD0DA),
    borderColor: Color(0xFFCCD0DA),
    accent: Color(0xFF1E66F5),
    accentHover: Color(0xFF209FB5),
    fg: Color(0xFF4C4F69),
    fgMuted: Color(0xFF6C6F85),
    fgSubtle: Color(0xFF9CA0B0),
    fgAccent: Color(0xFF209FB5),
    danger: Color(0xFFD20F39),
    success: Color(0xFF40A02B),
    warning: Color(0xFFDF8E1D),
    neutral: Color(0xFF8C8FA1),
    bgHoverStrong: Color(0xFFBCC0CC),
    windowCloseHover: Color(0xFFD20F39),
    windowClosePressed: Color(0xFFA80C2E),
    shadowSubtle: Color(0x1A000000),
    fileJs: Color(0xFFDF8E1D),
    fileHtml: Color(0xFFFE640B),
    fileCss: Color(0xFF1E66F5),
    fileArchive: Color(0xFFFE640B),
    fileAudio: Color(0xFF8839EF),
    fileVideo: Color(0xFFEA76CB),
    fileDefault: Color(0xFF9CA0B0),
  ),
);

const builtInThemes = [
  darkTheme,
  lightTheme,
  nordTheme,
  tokyoNightTheme,
  oneDarkTheme,
  gruvboxDarkTheme,
  gruvboxLightTheme,
  draculaTheme,
  solarizedDarkTheme,
  solarizedLightTheme,
  catppuccinMochaTheme,
  catppuccinLatteTheme,
];
