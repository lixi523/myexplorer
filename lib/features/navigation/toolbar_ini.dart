/// Parsing and serialization for the `快捷栏.ini` toolbar configuration file.
///
/// Format:
/// ```ini
/// [Toolbar]
/// label | target | icon
/// ; comment
/// |
/// ```
///
/// Each non-comment, non-blank line under `[Toolbar]` is a button:
/// - `label | target | icon` — a button with optional icon path
/// - `|` — a separator (both label and target empty)
/// Lines starting with `;` or `#` are comments.
library;

import 'dart:convert';

/// Parses the content of a `快捷栏.ini` file into toolbar items.
/// Each item is a tuple of (label, target, icon?).
List<({String label, String target, String? icon})> parseToolbarIni(
  String content,
) {
  var text = content;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final items = <({String label, String target, String? icon})>[];
  var inSection = false;
  for (final rawLine in const LineSplitter().convert(text)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith(';') || line.startsWith('#')) continue;
    if (line.startsWith('[') && line.endsWith(']')) {
      inSection = line.toLowerCase() == '[toolbar]';
      continue;
    }
    if (!inSection) continue;
    final parts = _splitLine(line);
    final label = parts[0].trim();
    final target = parts.length > 1 ? parts[1].trim() : '';
    final icon = parts.length > 2 ? parts[2].trim() : null;
    items.add((
      label: label,
      target: target,
      icon: (icon != null && icon.isNotEmpty) ? icon : null,
    ));
  }
  return items;
}

/// Splits a line on `|` delimiters, respecting `\`-escaped pipes.
List<String> _splitLine(String line) {
  final result = <String>[];
  var current = StringBuffer();
  var inEscape = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (inEscape) {
      current.write(ch);
      inEscape = false;
      continue;
    }
    if (ch == '\\') {
      inEscape = true;
      continue;
    }
    if (ch == '|') {
      result.add(current.toString());
      current = StringBuffer();
      continue;
    }
    current.write(ch);
  }
  result.add(current.toString());
  return result;
}

/// Serializes toolbar items into INI content (without BOM).
String serializeToolbarIni(
  Iterable<({String label, String target, String? icon})> items,
) {
  final buffer = StringBuffer('[Toolbar]\n');
  for (final item in items) {
    final parts = [item.label, item.target];
    if (item.icon != null && item.icon!.isNotEmpty) {
      parts.add(item.icon!);
    }
    buffer.writeln(parts.join(' | '));
  }
  return buffer.toString();
}
