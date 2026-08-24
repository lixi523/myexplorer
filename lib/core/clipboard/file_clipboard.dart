import 'dart:io';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

class FileClipboard {
  static Future<void> writeFiles(
    List<String> paths, {
    required bool isCut,
  }) async {
    try {
      await _writeWindows(paths);
    } catch (e, st) {
      log.warn(
        'clipboard',
        'native file clipboard write failed',
        error: e,
        stack: st,
      );
    }

    try {
      final uris = paths.map((p) => Uri.file(p).toString()).join('\n');
      final action = isCut ? 'cut' : 'copy';
      await Clipboard.setData(ClipboardData(text: 'x-special/$action\n$uris'));
    } catch (e, st) {
      log.warn(
        'clipboard',
        'text clipboard fallback write failed',
        error: e,
        stack: st,
      );
    }
  }

  static Future<List<String>> readFilePaths() async {
    try {
      return await _readWindows();
    } catch (e, st) {
      log.warn('clipboard', 'file clipboard read failed', error: e, stack: st);

      return [];
    }
  }

  static Future<bool> isCutOperation() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text?.startsWith('x-special/cut') ?? false) return true;

      return false;
    } catch (e, st) {
      log.warn(
        'clipboard',
        'clipboard cut-state read failed',
        error: e,
        stack: st,
      );

      return false;
    }
  }

  static Future<void> _writeWindows(List<String> paths) async {
    final escaped = paths.map((p) => "'${p.replaceAll("'", "''")}'").join(',');
    final process = await Process.start('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      '-',
    ]);
    try {
      process.stdin.writeln('Set-Clipboard -LiteralPath @($escaped)');
    } finally {
      await process.stdin.close();
    }
    await process.exitCode;
  }

  static Future<List<String>> _readWindows() async {
    final output = await _runRead('powershell', [
      '-NoProfile',
      '-Command',
      '(Get-Clipboard -Format FileDropList).FullName',
    ]);
    if (output == null || output.trim().isEmpty) return [];

    return output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static Future<String?> _runRead(
    String cmd,
    List<String> args, {
    Duration? timeout,
  }) async {
    final process = await Process.start(cmd, args);
    final stdoutFuture = process.stdout
        .transform(const SystemEncoding().decoder)
        .join();

    int exitCode;
    if (timeout != null) {
      exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();

          return -1;
        },
      );
    } else {
      exitCode = await process.exitCode;
    }

    if (exitCode != 0) {
      await process.stderr.drain();

      return null;
    }

    return await stdoutFuture;
  }
}
