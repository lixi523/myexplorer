import 'dart:convert';

import '../../core/platform/gbk_codec.dart';

/// One button from a Total Commander button bar (`.bar` file).
///
/// Mirrors the `[Buttonbar]` section keys: `buttonN` is the icon source (an
/// `.exe`/`.dll`/`.ico` path, possibly with a `,index` suffix such as
/// `shell32.dll,34`), `cmdN` the command, `paramN` its arguments and `menuN`
/// the tooltip text. Empty buttons act as separators.
class TcBarEntry {
  const TcBarEntry({
    required this.index,
    required this.icon,
    required this.cmd,
    required this.param,
    required this.menu,
  });

  /// 1-based button number.
  final int index;

  /// Raw `buttonN` value; icon source, may be empty.
  final String icon;

  /// Raw `cmdN` value; command or folder path (`CD …`) or internal command
  /// (`cm_…`). May be empty for separator buttons.
  final String cmd;

  /// Raw `paramN` value; command arguments.
  final String param;

  /// Raw `menuN` value; tooltip text.
  final String menu;

  /// Separator button: no command and no icon source.
  bool get isEmpty => cmd.trim().isEmpty && icon.trim().isEmpty;

  /// Full command line as Total Commander would run it: command + arguments.
  String get commandLine =>
      param.trim().isEmpty ? cmd.trim() : '${cmd.trim()} ${param.trim()}';
}

/// Parses the `[Buttonbar]` section of a Total Commander bar file.
///
/// The parser is tolerant: keys are case-insensitive, `Buttoncount` may be
/// missing (the highest `buttonN` is then used), and unknown keys are ignored.
List<TcBarEntry> parseTcBar(String content) {
  final values = <String, String>{};
  var inButtonbar = false;
  var highestIndex = 0;

  for (final rawLine in content.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('[')) {
      inButtonbar = line.toLowerCase() == '[buttonbar]';
      continue;
    }
    if (!inButtonbar) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim().toLowerCase();
    final value = line.substring(eq + 1).trim();
    values[key] = value;
    final indexMatch = RegExp(r'^button(\d+)$').firstMatch(key);
    if (indexMatch != null) {
      final n = int.tryParse(indexMatch.group(1)!) ?? 0;
      if (n > highestIndex) highestIndex = n;
    }
  }

  var count = int.tryParse(values['buttoncount'] ?? '') ?? 0;
  if (count <= 0) count = highestIndex;

  final entries = <TcBarEntry>[];
  for (var i = 1; i <= count; i++) {
    entries.add(
      TcBarEntry(
        index: i,
        icon: values['button$i'] ?? '',
        cmd: values['cmd$i'] ?? '',
        param: values['param$i'] ?? '',
        menu: values['menu$i'] ?? '',
      ),
    );
  }

  return entries;
}

/// Decodes raw bar file bytes. Total Commander writes ANSI (GBK on Chinese
/// Windows); UTF-8 files are also accepted. Falls back to GBK only when the
/// bytes are not valid UTF-8.
String decodeBarBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return decodeGbkBytes(bytes) ?? '';
  }
}
