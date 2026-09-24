import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;

import '../../i18n/strings.g.dart';
import '../logging/app_logger.dart';
import '../platform/win32_attributes.dart';
import 'app_entry.dart';
import 'mime_resolver.dart';

/// Thrown by [AppResolver.setDefault] when the platform cannot set a default
/// programmatically (e.g. Windows' protected UserChoice). UI surfaces this as
/// a disabled/explained control.
class SetDefaultUnsupported implements Exception {
  final String reason;
  const SetDefaultUnsupported(this.reason);
  @override
  String toString() => reason;
}

/// Platform abstraction for discovering and launching applications that can
/// open a given file type.
abstract class AppResolver {
  /// Applications associated with [mime]/[path], default first.
  Future<List<AppEntry>> appsFor(MimeType mime, String path);

  /// All launchable applications on the system, for the "choose another
  /// application" case. May be empty when enumeration is unsupported.
  Future<List<AppEntry>> allApps();

  Future<AppEntry?> defaultFor(MimeType mime, String path);

  /// Launches [app] with [paths]. Detached; never blocks the UI.
  Future<void> launch(AppEntry app, List<String> paths);

  /// Makes [app] the default handler for [mime]. Throws
  /// [SetDefaultUnsupported] when not possible on this platform.
  Future<void> setDefault(AppEntry app, MimeType mime);

  /// True when [setDefault] can work on this platform/environment.
  Future<bool> canSetDefault();

  factory AppResolver.platform() => WindowsAppResolver();
}

class WindowsAppResolver implements AppResolver {
  String _ext(String path) {
    final e = p.extension(path);

    return e.isEmpty ? '' : e;
  }

  @override
  Future<List<AppEntry>> appsFor(MimeType mime, String path) async {
    final ext = _ext(path);
    final apps = <String, AppEntry>{};
    final def = await defaultFor(mime, path);
    if (def != null) apps[def.id] = def;
    if (ext.isNotEmpty) {
      for (final prog in await _openWithProgids(ext)) {
        final entry = _entryForAssoc(prog, isDefault: false);
        if (entry != null) apps.putIfAbsent(entry.id, () => entry);
      }
    }
    final list = apps.values.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }

  List<AppEntry>? _allCache;

  @override
  Future<List<AppEntry>> allApps() async {
    if (_allCache != null) return _allCache!;
    final apps = <String, AppEntry>{};
    final programData = Platform.environment['ProgramData'] ?? '';
    final appData = Platform.environment['APPDATA'] ?? '';
    final dirs = [
      if (programData.isNotEmpty)
        p.join(programData, r'Microsoft\Windows\Start Menu\Programs'),
      if (appData.isNotEmpty)
        p.join(appData, r'Microsoft\Windows\Start Menu\Programs'),
    ].where((d) => Directory(d).existsSync()).toList();
    if (dirs.isEmpty) return _allCache = const [];

    final dirList = dirs.map((d) => "'${d.replaceAll("'", "''")}'").join(',');
    final script =
        r'$sh=New-Object -ComObject WScript.Shell;'
        'Get-ChildItem -Path $dirList -Recurse -Filter *.lnk '
        r'-ErrorAction SilentlyContinue | ForEach-Object {'
        r'$t=$sh.CreateShortcut($_.FullName).TargetPath;'
        r'if($t -and $t.ToLower().EndsWith(".exe")){'
        r'"$($_.BaseName)|$t"}}';
    try {
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]).timeout(const Duration(seconds: 10));
      if (r.exitCode == 0) {
        for (final line in (r.stdout as String).split('\n')) {
          final parts = line.trim().split('|');
          if (parts.length != 2) continue;
          final name = parts.first.trim();
          final exe = parts[1].trim();
          if (name.isEmpty || exe.isEmpty || !File(exe).existsSync()) continue;
          apps.putIfAbsent(exe, () => AppEntry(id: exe, name: name, exec: exe));
        }
      }
    } catch (e, st) {
      log.warn('open', 'windows app enumeration failed', error: e, stack: st);
    }
    final list = apps.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return _allCache = list;
  }

  @override
  Future<AppEntry?> defaultFor(MimeType mime, String path) async {
    final ext = _ext(path);
    if (ext.isEmpty) return null;

    return _entryForAssoc(ext, isDefault: true);
  }

  /// Builds an [AppEntry] from a Windows association ([assoc] is either a file
  /// extension like `.png` or a ProgId). Resolves a real executable and a
  /// friendly name via the shell, so UWP/garbage ProgIds don't leak into the
  /// UI. Returns null when nothing usable is associated.
  AppEntry? _entryForAssoc(String assoc, {required bool isDefault}) {
    String? exe;
    String? friendly;
    String? command;
    try {
      exe = assocQueryStringOnWindows(assocStrExecutable, assoc);
      friendly = assocQueryStringOnWindows(assocStrFriendlyAppName, assoc);
      command = assocQueryStringOnWindows(assocStrCommand, assoc);
    } catch (e, st) {
      log.warn(
        'open',
        'windows association lookup failed',
        error: e,
        stack: st,
      );

      return null;
    }
    if ((exe == null || exe.isEmpty) && (command == null || command.isEmpty)) {
      return null;
    }
    final launchTarget = (exe != null && exe.isNotEmpty) ? exe : command!;
    final name = (friendly != null && friendly.isNotEmpty)
        ? friendly
        : (exe != null && exe.isNotEmpty)
        ? p.basenameWithoutExtension(exe)
        : assoc;

    return AppEntry(
      id: launchTarget,
      name: name,
      exec: launchTarget,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> launch(AppEntry app, List<String> paths) async {
    if (paths.isEmpty) return;
    final target = app.exec;
    if (File(target).existsSync()) {
      for (final path in paths) {
        if (shellOpenWithAppOnWindows(target, path)) continue;
        await _runCommandTemplate(target, [path]);
      }

      return;
    }
    await _runCommandTemplate(target, paths);
  }

  Future<void> _runCommandTemplate(String template, List<String> paths) async {
    final argv = _expandCommand(template, paths);
    if (argv.isEmpty) return;
    try {
      await Process.start(
        argv.first,
        argv.sublist(1),
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      log.warn(
        'open',
        'windows command template launch failed',
        error: e,
        stack: st,
      );
      shellOpenOnWindows(paths.first);
    }
  }

  /// Expands a Windows `shell\open\command` template: substitutes `%1`/`%L`/
  /// `%*`/`%V` with the file path(s), honouring double-quote tokenisation.
  static List<String> _expandCommand(String template, List<String> paths) {
    final tokens = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    var has = false;
    for (var i = 0; i < template.length; i++) {
      final c = template[i];
      if (c == '"') {
        inQuotes = !inQuotes;
        has = true;
        continue;
      }
      if (c == ' ' && !inQuotes) {
        if (has) {
          tokens.add(buf.toString());
          buf.clear();
          has = false;
        }
        continue;
      }
      buf.write(c);
      has = true;
    }
    if (has) tokens.add(buf.toString());

    final out = <String>[];
    var substituted = false;
    for (final tok in tokens) {
      if (RegExp(r'^%[1lLvV*]$').hasMatch(tok)) {
        out.addAll(paths);
        substituted = true;
      } else {
        out.add(tok);
      }
    }
    if (!substituted) out.addAll(paths);

    return out;
  }

  @visibleForTesting
  static List<String> debugExpandCommand(String template, List<String> paths) =>
      _expandCommand(template, paths);

  Future<List<String>> _openWithProgids(String ext) async {
    try {
      final r = await Process.run('reg', [
        'query',
        'HKCR\\$ext\\OpenWithProgids',
      ]).timeout(const Duration(seconds: 5));
      if (r.exitCode != 0) return const [];

      return (r.stdout as String)
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('HKEY'))
          .map((l) => l.split(RegExp(r'\s+')).first)
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e, st) {
      log.warn(
        'open',
        'windows OpenWithProgids lookup failed',
        error: e,
        stack: st,
      );

      return const [];
    }
  }

  @override
  Future<bool> canSetDefault() async => false;

  /// Windows protects per-user defaults with UserChoice hashes; the system
  /// dialog is the supported path.
  @override
  Future<void> setDefault(AppEntry app, MimeType mime) async {
    throw SetDefaultUnsupported(t.openWith.windowsDefaultDialogRequired);
  }
}
