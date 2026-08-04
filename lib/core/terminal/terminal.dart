import 'dart:io';

import '../logging/app_logger.dart';

class _TerminalSpec {
  final String id;
  final String displayName;
  final String executable;
  final List<String> Function(String directory) argsBuilder;

  const _TerminalSpec({
    required this.id,
    required this.displayName,
    required this.executable,
    required this.argsBuilder,
  });
}

class _TerminalRegistry {
  static final List<_TerminalSpec> windows = [
    _TerminalSpec(
      id: 'wt',
      displayName: 'Windows Terminal',
      executable: 'wt',
      argsBuilder: (d) => ['-d', d],
    ),
    _TerminalSpec(
      id: 'powershell',
      displayName: 'PowerShell',
      executable: 'powershell',
      argsBuilder: (d) => [
        '-NoExit',
        '-Command',
        'Set-Location -LiteralPath "$d"',
      ],
    ),
    _TerminalSpec(
      id: 'cmd',
      displayName: 'Command Prompt',
      executable: 'cmd',
      argsBuilder: (d) => ['/k', 'cd', '/d', d],
    ),
  ];

  static List<_TerminalSpec> all() => windows;

  static _TerminalSpec? byId(String id) {
    for (final t in all()) {
      if (t.id == id) return t;
    }

    return null;
  }
}

class ExternalTerminal {
  final String id;
  final String displayName;

  const ExternalTerminal({required this.id, required this.displayName});
}

class TerminalService {
  static final _detectionCache = <String, bool>{};

  static Future<List<ExternalTerminal>> availableTerminals() async {
    final specs = _TerminalRegistry.all().toList();
    final available = await Future.wait([
      for (final spec in specs) _isAvailable(spec.executable),
    ]);

    return [
      for (var i = 0; i < specs.length; i++)
        if (available[i])
          ExternalTerminal(id: specs[i].id, displayName: specs[i].displayName),
    ];
  }

  static Future<bool> _isAvailable(String executable) async {
    final cached = _detectionCache[executable];
    if (cached != null) return cached;
    final result = await _which(executable);
    _detectionCache[executable] = result;

    return result;
  }

  static Future<bool> _which(String executable) async {
    try {
      final result = await Process.run('where', [executable], runInShell: true);

      return result.exitCode == 0;
    } catch (e, st) {
      log.warn(
        'terminal',
        'terminal availability check failed',
        error: e,
        stack: st,
      );

      return false;
    }
  }

  static Future<bool> _launch(_TerminalSpec spec, String directory) async {
    try {
      await Process.start(
        spec.executable,
        spec.argsBuilder(directory),
        workingDirectory: directory,
        mode: ProcessStartMode.detached,
        runInShell: true,
      );

      return true;
    } catch (e, st) {
      log.warn('terminal', 'terminal launch failed', error: e, stack: st);

      return false;
    }
  }

  static Future<void> openInDirectory(
    String directory, {
    String? preferredId,
    String? customCommand,
  }) async {
    if (preferredId == 'custom' &&
        customCommand != null &&
        customCommand.trim().isNotEmpty) {
      if (await _launchCustom(customCommand, directory)) return;
    }
    if (preferredId != null &&
        preferredId != 'auto' &&
        preferredId != 'custom') {
      final spec = _TerminalRegistry.byId(preferredId);
      if (spec != null && await _launch(spec, directory)) return;
    }
    for (final spec in _TerminalRegistry.all()) {
      if (!await _isAvailable(spec.executable)) continue;
      if (await _launch(spec, directory)) return;
    }
  }

  static Future<bool> _launchCustom(String command, String directory) async {
    try {
      final expanded = command.replaceAll(r'{dir}', directory);
      final parts = _tokenize(expanded);
      if (parts.isEmpty) return false;
      await Process.start(
        parts.first,
        parts.sublist(1),
        workingDirectory: directory,
        mode: ProcessStartMode.detached,
        runInShell: true,
      );

      return true;
    } catch (e, st) {
      log.warn(
        'terminal',
        'custom terminal launch failed',
        error: e,
        stack: st,
      );

      return false;
    }
  }

  static Future<bool> runScript(String scriptPath) async {
    return false;
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buf = StringBuffer();
    String? quote;
    for (int i = 0; i < input.length; i++) {
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
}
