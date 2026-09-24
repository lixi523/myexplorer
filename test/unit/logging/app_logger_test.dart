import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/logging/app_logger.dart';
import 'package:myexplorer/core/logging/log_entry.dart';

void main() {
  final logger = AppLogger.instance;

  setUp(() {
    logger.clear();
  });

  group('AppLogger', () {
    test('records warn entries with tag and message', () {
      logger.warn('fs', 'disk full');
      final entry = logger.entries.value.single;
      expect(entry.level, LogLevel.warn);
      expect(entry.tag, 'fs');
      expect(entry.message, 'disk full');
      expect(entry.stackTrace, isNull);
    });

    test('records error entries and appends the error object', () {
      logger.error('db', 'open failed', error: StateError('locked'));
      final entry = logger.entries.value.single;
      expect(entry.level, LogLevel.error);
      expect(entry.message, 'open failed: Bad state: locked');
    });

    test('keeps the message unchanged when no error is given', () {
      logger.warn('tag', 'plain message');
      expect(logger.entries.value.single.message, 'plain message');
    });

    test('caps the in-memory ring at 500 entries, dropping the oldest', () {
      for (var i = 0; i < 600; i++) {
        logger.warn('tag', 'msg $i');
      }
      final entries = logger.entries.value;
      expect(entries, hasLength(500));
      expect(entries.first.message, 'msg 100');
      expect(entries.last.message, 'msg 599');
    });

    test('clear empties the ring', () {
      logger.warn('a', 'x');
      logger.warn('b', 'y');
      logger.clear();
      expect(logger.entries.value, isEmpty);
    });

    test('is safe to use before init (no file sink)', () {
      expect(logger.entries.value, isEmpty);
      logger.warn('tag', 'before init');
      expect(logger.entries.value, hasLength(1));
    });
  });

  group('LogEntry', () {
    test('serializes with the expected JSON shape', () {
      final entry = LogEntry(
        timestamp: DateTime.utc(2026, 8, 9),
        level: LogLevel.error,
        tag: 'net',
        message: 'timeout',
        stackTrace: 'line 1\nline 2',
      );
      final json = entry.toJson();
      expect(json['ts'], '2026-08-09T00:00:00.000Z');
      expect(json['level'], 'ERROR');
      expect(json['tag'], 'net');
      expect(json['msg'], 'timeout');
      expect(json['stack'], 'line 1\nline 2');
    });

    test('omits the stack key when absent', () {
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.warn,
        tag: 't',
        message: 'm',
      );
      expect(entry.toJson().containsKey('stack'), isFalse);
    });

    test('round-trips through jsonEncode', () {
      final entry = LogEntry(
        timestamp: DateTime.utc(2026, 8, 9, 12),
        level: LogLevel.warn,
        tag: 'fs',
        message: 'cleanup',
      );
      final decoded = jsonDecode(jsonEncode(entry.toJson()));
      expect(decoded['tag'], 'fs');
      expect(decoded['level'], 'WARN');
    });
  });

  group('LogLevelName', () {
    test('labels map to WARN and ERROR', () {
      expect(LogLevel.warn.label, 'WARN');
      expect(LogLevel.error.label, 'ERROR');
    });
  });
}
