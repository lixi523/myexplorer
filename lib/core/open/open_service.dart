import 'dart:io';

import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';
import '../platform/win32_attributes.dart';
import '../settings/settings_store.dart';
import 'app_entry.dart';
import 'app_resolver.dart';
import 'mime_resolver.dart';

export 'app_entry.dart' show AppEntry;
export 'mime_resolver.dart' show MimeType;

/// Facade for file-type detection and opening.
///
/// MyExplorer owns its own "file type → application" default mapping (stored in
/// the app database), independent of the OS associations. Every open path —
/// double-click, Enter, the "Open With [app]" menu entry — funnels through
/// [openDefault], so behaviour is identical by construction. The OS default is
/// only the fallback when MyExplorer has no mapping for the type yet.
class OpenService {
  OpenService._();

  static final MimeResolver _mime = MimeResolver.platform();
  static final AppResolver _apps = AppResolver.platform();

  /// The key MyExplorer stores its default under: the file extension (with dot,
  /// lowercased).
  static Future<String> typeKeyFor(String path) async {
    return p.extension(path).toLowerCase();
  }

  static Future<MimeType> mimeOf(String path) => _mime.resolve(path);

  /// Opens [path] with MyExplorer's chosen default for its type; if none is set,
  /// falls back to the OS default handler.
  static Future<void> openDefault(String path) async {
    await _osOpenDefault(path);
  }

  static Future<void> _osOpenDefault(String path) async {
    shellOpenOnWindows(path);
  }

  /// MyExplorer's stored default for [path]'s type. On first encounter with a type
  /// the OS default handler is resolved and **persisted** as MyExplorer's default,
  /// so from then on it is a concrete, editable mapping (shown in "Open With
  /// [app]", preselected in the chooser, etc.) rather than an ephemeral
  /// fallback. Returns null only when the OS has no resolvable handler either.
  static Future<AppEntry?> getMyExplorerDefault(String path) async {
    try {
      final key = await typeKeyFor(path);
      final db = SettingsStore.instance.db;
      final row = await db.getDefaultApp(key);
      if (row != null) {
        return AppEntry(
          id: row.appId,
          name: row.appName,
          exec: row.appExec,
          iconPath: row.iconPath,
          isDefault: true,
        );
      }
      final mime = await _mime.resolve(path);
      final osDefault = await _apps.defaultFor(mime, path);
      if (osDefault == null) return null;
      await db.setDefaultApp(
        typeKey: key,
        appId: osDefault.id,
        appName: osDefault.name,
        appExec: osDefault.exec,
        iconPath: osDefault.iconPath,
      );

      return osDefault.copyWith(isDefault: true);
    } catch (e, st) {
      log.warn(
        'open',
        'failed to resolve stored default app',
        error: e,
        stack: st,
      );

      return null;
    }
  }

  static Future<void> setMyExplorerDefault(String path, AppEntry app) async {
    final key = await typeKeyFor(path);
    await SettingsStore.instance.db.setDefaultApp(
      typeKey: key,
      appId: app.id,
      appName: app.name,
      appExec: app.exec,
      iconPath: app.iconPath,
    );
  }

  static Future<void> clearMyExplorerDefault(String path) async {
    final key = await typeKeyFor(path);
    await SettingsStore.instance.db.clearDefaultApp(key);
  }

  /// Apps for the "Open With" UI. The default is MyExplorer's stored choice when
  /// set, otherwise the OS-resolved handler as a seed.
  static Future<OpenWithOptions> optionsFor(String path) async {
    final mime = await _mime.resolve(path);
    final associated = await _apps.appsFor(mime, path);
    final recent = await _recentFor(mime);
    final defaultApp = await getMyExplorerDefault(path);

    return OpenWithOptions(
      mime: mime,
      recent: recent,
      associated: associated,
      defaultApp: defaultApp,
      isMyExplorerManaged: defaultApp != null,
    );
  }

  static Future<List<AppEntry>> allApps() => _apps.allApps();

  static Future<void> openWith(AppEntry app, List<String> paths) async {
    if (app.isSystemDefault) {
      for (final path in paths) {
        await _osOpenDefault(path);
      }

      return;
    }
    await _apps.launch(app, paths);
    if (paths.isNotEmpty) {
      final mime = await _mime.resolve(paths.first);
      await _recordRecent(mime, app);
    }
  }

  /// Opens the native "Open with…" chooser.
  static Future<void> systemOpenWithDialog(String path) async {
    try {
      await Process.start('rundll32.exe', [
        'shell32.dll,OpenAs_RunDLL',
        path,
      ], mode: ProcessStartMode.detached);
    } catch (e, st) {
      log.warn(
        'open',
        'failed to open "Open with" dialog',
        error: e,
        stack: st,
      );
    }
  }

  static Future<List<AppEntry>> _recentFor(MimeType mime) async {
    try {
      final rows = await SettingsStore.instance.db.getRecentApps(mime.value);

      return rows
          .map(
            (r) => AppEntry(
              id: r.appId,
              name: r.appName,
              exec: r.appExec,
              iconPath: r.iconPath,
            ),
          )
          .toList();
    } catch (e, st) {
      log.warn('open', 'failed to load recent apps', error: e, stack: st);

      return const [];
    }
  }

  static Future<void> _recordRecent(MimeType mime, AppEntry app) async {
    try {
      await SettingsStore.instance.db.recordRecentApp(
        mime: mime.value,
        appId: app.id,
        appName: app.name,
        appExec: app.exec,
        iconPath: app.iconPath,
      );
    } catch (e, st) {
      log.warn('open', 'failed to record recent app', error: e, stack: st);
    }
  }
}

class OpenWithOptions {
  final MimeType mime;
  final List<AppEntry> recent;
  final List<AppEntry> associated;

  /// MyExplorer's stored default, or the OS-resolved handler as a seed.
  final AppEntry? defaultApp;

  /// True when [defaultApp] comes from MyExplorer's own mapping (vs OS seed).
  final bool isMyExplorerManaged;

  const OpenWithOptions({
    required this.mime,
    required this.recent,
    required this.associated,
    required this.defaultApp,
    required this.isMyExplorerManaged,
  });

  bool get isEmpty => recent.isEmpty && associated.isEmpty;
}
