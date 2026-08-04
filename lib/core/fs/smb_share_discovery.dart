import 'dart:async';
import 'dart:io';

import '../../features/locations/location_resolver.dart';
import '../../i18n/strings.g.dart';

class SmbShare {
  final String name;
  final String? comment;

  const SmbShare({required this.name, this.comment});
}

sealed class SmbShareListResult {
  const SmbShareListResult();
}

class SmbShareListOk extends SmbShareListResult {
  final List<SmbShare> shares;
  const SmbShareListOk(this.shares);
}

class SmbShareListAuthRequired extends SmbShareListResult {
  const SmbShareListAuthRequired();
}

class SmbShareListError extends SmbShareListResult {
  final String message;
  const SmbShareListError(this.message);
}

class SmbShareListUnsupported extends SmbShareListResult {
  const SmbShareListUnsupported();
}

class _CacheEntry {
  final List<SmbShare> shares;
  final DateTime at;
  const _CacheEntry(this.shares, this.at);
}

class SmbShareDiscovery {
  SmbShareDiscovery._();

  static const Duration _cacheTtl = Duration(seconds: 60);
  static final Map<String, _CacheEntry> _cache = {};

  static Future<SmbShareListResult> list({
    required String host,
    int? port,
    SmbCredentials? credentials,
  }) async {
    final key = _cacheKey(host, port, credentials?.username);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return SmbShareListOk(cached.shares);
    }

    final result = await _windows(host);

    if (result is SmbShareListOk) {
      _cache[key] = _CacheEntry(result.shares, DateTime.now());
    }

    return result;
  }

  static void invalidate({required String host, int? port, String? username}) {
    _cache.remove(_cacheKey(host, port, username));
  }

  static void invalidateAll() => _cache.clear();

  static String _cacheKey(String host, int? port, String? user) =>
      '${user ?? ''}@${host.toLowerCase()}:${port ?? ''}';

  static bool _looksLikeAuthPrompt(String text) {
    final t = text.toLowerCase();

    return t.contains('nt_status_logon_failure') ||
        t.contains('nt_status_access_denied') ||
        t.contains('access denied') ||
        t.contains('logon failure') ||
        t.contains('authentication') ||
        t.contains('permission denied') ||
        t.contains('password');
  }

  static Future<SmbShareListResult> _windows(String host) async {
    ProcessResult result;
    try {
      result = await Process.run('net', [
        'view',
        '\\\\$host',
        '/all',
      ]).timeout(const Duration(seconds: 10));
    } on ProcessException catch (e) {
      return SmbShareListError(t.errors.netUnavailable(message: e.message));
    }
    final out = (result.stdout as String? ?? '');
    final err = (result.stderr as String? ?? '');
    if (result.exitCode != 0) {
      if (_looksLikeAuthPrompt('$out\n$err')) {
        return const SmbShareListAuthRequired();
      }
      final msg = err.trim().isNotEmpty ? err.trim() : out.trim();

      return SmbShareListError(
        msg.isEmpty ? t.errors.netViewFailed(code: result.exitCode) : msg,
      );
    }

    return SmbShareListOk(parseNetView(out));
  }

  /// Public for testing.
  static List<SmbShare> parseNetView(String text) {
    final out = <SmbShare>[];
    var inTable = false;
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('---')) {
        inTable = !inTable;
        continue;
      }
      if (!inTable) continue;
      final parts = line.split(RegExp(r'\s{2,}'));
      if (parts.length < 2) continue;
      final name = parts.first.trim();
      if (name.isEmpty || name.endsWith(r'$')) continue;
      final comment = parts.length >= 3 ? parts.last.trim() : '';
      out.add(SmbShare(name: name, comment: comment.isEmpty ? null : comment));
    }

    return out;
  }
}
