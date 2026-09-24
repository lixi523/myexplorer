/// Parsing and serialization for the `隐藏文件.ini` hidden-list file.
///
/// Format:
/// ```ini
/// [Hidden]
/// desktop.ini
/// D:\path\to\file.txt
/// D:\path\to\folder
/// ; comment lines start with a semicolon
/// ```
///
/// Each entry has one of two matching modes, inferred from the entry itself:
///
/// * **Name entries** contain no path separator (`\` or `/`), e.g. `desktop.ini`.
///   They hide any file or folder with that name anywhere (case-insensitive).
/// * **Path entries** contain a separator, e.g. `D:\path\to\file.txt`. They
///   hide exactly that full path (case-insensitive, separator-normalized).
///
/// Windows file names cannot contain `\` or `/`, so the two modes never
/// overlap. Matching compares against [normalizeHiddenPath].
library;

import 'dart:convert';

/// Whether [entry] is a full-path entry (contains a path separator) rather
/// than a bare file/folder name entry.
bool isPathEntry(String entry) {
  return entry.contains('\\') || entry.contains('/');
}

/// Normalizes a path for comparison: trims whitespace, converts `/` to `\`,
/// strips a trailing separator (except a bare drive root like `C:\`) and
/// lowercases it.
///
/// The trailing-separator rule mirrors Windows path semantics: `C:\foo\` and
/// `C:\foo` are the same directory.
String normalizeHiddenPath(String path) {
  var p = path.trim();
  if (p.isEmpty) return p;
  p = p.replaceAll('/', r'\');
  while (p.length > 3 && p.endsWith(r'\')) {
    p = p.substring(0, p.length - 1);
  }

  return p.toLowerCase();
}

/// Parses the content of a `隐藏文件.ini` file into the list of hidden paths
/// (raw, un-normalized). Lines outside the `[Hidden]` section, blank lines and
/// `;`-prefixed comments are ignored. A UTF-8 BOM, if present, is stripped.
List<String> parseHiddenIni(String content) {
  var text = content;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final paths = <String>[];
  var inHiddenSection = false;
  for (final rawLine in const LineSplitter().convert(text)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith(';') || line.startsWith('#')) continue;
    if (line.startsWith('[') && line.endsWith(']')) {
      inHiddenSection = line.toLowerCase() == '[hidden]';
      continue;
    }
    if (inHiddenSection) paths.add(line);
  }

  return paths;
}

/// Serializes a list of hidden paths into INI content (without BOM; callers
/// may prepend one when writing to disk). Paths are deduplicated by
/// [normalizeHiddenPath] and sorted for stable diffs.
String serializeHiddenIni(Iterable<String> paths) {
  final seen = <String>{};
  final unique = <String>[];
  for (final p in paths) {
    final norm = normalizeHiddenPath(p);
    if (p.isEmpty || norm.isEmpty || seen.contains(norm)) continue;
    seen.add(norm);
    unique.add(p.trim());
  }
  unique.sort(
    (a, b) => normalizeHiddenPath(a).compareTo(normalizeHiddenPath(b)),
  );
  final buffer = StringBuffer('[Hidden]\n');
  for (final p in unique) {
    buffer.writeln(p);
  }

  return buffer.toString();
}
