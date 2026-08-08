/// Parsing and serialization for checksum manifest files
/// (`.md5` / `.sha256`), GNU coreutils compatible.
///
/// Format (one entry per line):
/// ```text
/// <hex-digest><two spaces><relative-path>
/// ```
/// Lines starting with `#` are comments. A UTF-8 BOM is stripped. Relative
/// paths use `/` as separator in the manifest and are resolved against the
/// directory that contains the manifest file.
library;

import 'dart:convert';

class ManifestEntry {
  final String relativePath;
  final String expectedDigest;

  const ManifestEntry({required this.relativePath, required this.expectedDigest});
}

/// Serializes manifest entries into GNU coreutils format, sorted by path for
/// stable diffs. [digestFor] maps a relative path to its lowercase hex digest.
String serializeChecksumManifest(
  List<String> relativePaths,
  String Function(String relativePath) digestFor,
) {
  final sorted = [...relativePaths]..sort();
  final buffer = StringBuffer();
  for (final path in sorted) {
    buffer.writeln('${digestFor(path)}  ${_toManifestPath(path)}');
  }

  return buffer.toString();
}

/// Parses manifest content into entries. Malformed lines are skipped.
/// Returns null when the content has no valid entries.
List<ManifestEntry>? parseChecksumManifest(String content) {
  var text = content;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final entries = <ManifestEntry>[];
  for (final rawLine in const LineSplitter().convert(text)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) continue;
    // Digest is 32 (md5) or 64 (sha256) hex chars followed by two spaces.
    final match = RegExp(
      r'^([0-9a-fA-F]{32}|[0-9a-fA-F]{64})\s{1,2}(.+)$',
    ).firstMatch(line);
    if (match == null) continue;
    entries.add(
      ManifestEntry(
        relativePath: _fromManifestPath(match.group(2)!.trim()),
        expectedDigest: match.group(1)!.toLowerCase(),
      ),
    );
  }
  if (entries.isEmpty) return null;

  return entries;
}

/// Converts a path to the manifest representation: `/` separators.
String _toManifestPath(String path) => path.replaceAll(r'\', '/');

/// Converts a manifest path back to platform separators.
String _fromManifestPath(String path) => path.replaceAll('/', r'\');
