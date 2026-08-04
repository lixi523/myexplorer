class SystemFonts {
  SystemFonts._();

  static const _fallback = [
    'monospace',
    'Cascadia Code',
    'Consolas',
    'Courier New',
    'Source Code Pro',
    'JetBrains Mono',
    'Fira Code',
    'Hack',
    'DejaVu Sans Mono',
    'Liberation Mono',
    'Noto Sans Mono',
  ];

  static Future<List<String>> monospaceFamilies() async => _fallback;
}
