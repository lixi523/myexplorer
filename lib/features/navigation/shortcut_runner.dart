import 'dart:io';

import '../../core/database/app_database.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';

/// Classification of a shortcut bar target, following the Total Commander
/// button bar conventions.
enum ShortcutTargetKind {
  /// Existing directory → open in the active pane.
  folder,

  /// Existing file → open with the default handler.
  file,

  /// `CD <path>` command → navigate to the given folder.
  cd,

  /// Built-in command (`cm_OpenDesktop`, `cm_OpenRecycled`, …).
  internal,

  /// Anything else → launch as a command line.
  command,

  /// Empty target (separator button); nothing to run.
  none,
}

class ShortcutTarget {
  const ShortcutTarget(this.kind, this.value);

  final ShortcutTargetKind kind;

  /// Path, command line or internal command name, depending on [kind].
  final String value;
}

typedef ShortcutNavigate = Future<void> Function(String path);
typedef ShortcutOpenFile = Future<void> Function(String path);
typedef ShortcutLaunchCommand = Future<void> Function(String commandLine);

/// Classifies a raw shortcut target. Pure and testable: environment variables
/// are expanded first, then Total Commander conventions (`cm_…`, `CD …`) are
/// checked before filesystem lookups.
ShortcutTarget classifyShortcutTarget(String rawTarget) {
  final trimmed = rawTarget.trim();
  if (trimmed.isEmpty) {
    return const ShortcutTarget(ShortcutTargetKind.none, '');
  }
  var t = trimmed;
  if (t.length >= 2 &&
      ((t.startsWith('"') && t.endsWith('"')) ||
          (t.startsWith("'") && t.endsWith("'")))) {
    t = t.substring(1, t.length - 1).trim();
  }
  if (t.isEmpty) return const ShortcutTarget(ShortcutTargetKind.none, '');

  final expanded = PlatformPaths.expandEnvVars(t);
  if (expanded.toLowerCase().startsWith('cm_')) {
    return ShortcutTarget(ShortcutTargetKind.internal, expanded);
  }
  final cdMatch = RegExp(
    r'^cd\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(expanded);
  if (cdMatch != null) {
    var dir = cdMatch.group(1)!.trim();
    if (dir.length >= 2 &&
        ((dir.startsWith('"') && dir.endsWith('"')) ||
            (dir.startsWith("'") && dir.endsWith("'")))) {
      dir = dir.substring(1, dir.length - 1);
    }

    return ShortcutTarget(ShortcutTargetKind.cd, dir);
  }
  try {
    final type = FileSystemEntity.typeSync(expanded, followLinks: true);
    if (type == FileSystemEntityType.directory) {
      return ShortcutTarget(ShortcutTargetKind.folder, expanded);
    }
    if (type == FileSystemEntityType.file) {
      return ShortcutTarget(ShortcutTargetKind.file, expanded);
    }
  } catch (e, st) {
    log.warn('shortcut', 'target probe failed', error: e, stack: st);
  }

  return ShortcutTarget(ShortcutTargetKind.command, expanded);
}

/// Runs a shortcut bar item with Total Commander semantics:
///
/// 1. `cm_OpenDesktop` / `cm_OpenRecycled` / `cm_OpenDrives` → built-ins.
/// 2. `CD <path>` → navigate to the folder.
/// 3. Existing directory → navigate.
/// 4. Existing file → open with the default handler.
/// 5. Anything else → launch as a command line.
Future<void> runShortcutItem(
  ShortcutBarItem item, {
  required ShortcutNavigate navigateTo,
  required ShortcutOpenFile openFile,
  ShortcutLaunchCommand? launchCommand,
}) async {
  final target = classifyShortcutTarget(item.target);
  switch (target.kind) {
    case ShortcutTargetKind.folder:
      await navigateTo(target.value);
    case ShortcutTargetKind.file:
      await openFile(target.value);
    case ShortcutTargetKind.cd:
      try {
        if (Directory(target.value).existsSync()) {
          await navigateTo(target.value);
        }
      } catch (e, st) {
        log.warn('shortcut', 'CD target unavailable', error: e, stack: st);
      }
    case ShortcutTargetKind.internal:
      await _runInternal(
        target.value,
        navigateTo: navigateTo,
        launchCommand: launchCommand,
      );
    case ShortcutTargetKind.command:
      await (launchCommand ?? _launchCommandLine)(target.value);
    case ShortcutTargetKind.none:
      break;
  }
}

Future<void> _runInternal(
  String cmd, {
  required ShortcutNavigate navigateTo,
  ShortcutLaunchCommand? launchCommand,
}) async {
  switch (cmd.toLowerCase()) {
    case 'cm_opendesktop':
      await navigateTo(PlatformPaths.desktopPath);
    case 'cm_openrecycled':
      // Waydir cannot list the virtual recycle-bin folder, so open it with
      // Explorer, mirroring Total Commander's behaviour.
      await (launchCommand ?? _launchCommandLine)(
        'explorer.exe shell:RecycleBinFolder',
      );
    case 'cm_opendrives':
      await navigateTo(PlatformPaths.rootPath);
    default:
      log.warn('shortcut', 'unknown internal command: $cmd');
  }
}

Future<void> _launchCommandLine(String commandLine) async {
  final parts = _tokenizeCommand(commandLine);
  if (parts.isEmpty) return;
  try {
    await Process.start(
      parts.first,
      parts.sublist(1),
      mode: ProcessStartMode.detached,
      runInShell: true,
    );
  } catch (e, st) {
    log.warn('shortcut', 'failed to launch command', error: e, stack: st);
  }
}

/// Splits a command line into an executable and its arguments, honoring
/// double and single quotes.
List<String> _tokenizeCommand(String input) {
  final tokens = <String>[];
  final buf = StringBuffer();
  String? quote;
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (quote != null) {
      if (c == quote) {
        quote = null;
      } else {
        buf.write(c);
      }
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == ' ' || c == '\t') {
      if (buf.isNotEmpty) {
        tokens.add(buf.toString());
        buf.clear();
      }
    } else {
      buf.write(c);
    }
  }
  if (buf.isNotEmpty) tokens.add(buf.toString());

  return tokens;
}
