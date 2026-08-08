import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

/// One color rule: files whose extension matches [extension] (without dot,
/// case-insensitive) are tinted with [color].
class ColorRule {
  final String extension;
  final Color color;

  const ColorRule({required this.extension, required this.color});

  bool matches(String ext) => extension.toLowerCase() == ext.toLowerCase();
}

/// Holds the user's file-coloring rules (extension → tint).
///
/// NOTE: rules are runtime-only for now (not persisted) because build_runner
/// cannot regenerate the drift code in the local toolchain. Persist once
/// codegen is available.
class ColorRuleStore {
  ColorRuleStore._();

  static final ColorRuleStore instance = ColorRuleStore._();

  final rules = signal<List<ColorRule>>(_defaultRules());

  static List<ColorRule> _defaultRules() {
    return const [
      ColorRule(extension: 'exe', color: Color(0xFFE5484D)),
      ColorRule(extension: 'bat', color: Color(0xFFE5484D)),
      ColorRule(extension: 'cmd', color: Color(0xFFE5484D)),
      ColorRule(extension: 'msi', color: Color(0xFFE5484D)),
      ColorRule(extension: 'png', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'jpg', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'jpeg', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'gif', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'webp', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'bmp', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'svg', color: Color(0xFF8E4EC6)),
      ColorRule(extension: 'zip', color: Color(0xFFB4691E)),
      ColorRule(extension: 'rar', color: Color(0xFFB4691E)),
      ColorRule(extension: '7z', color: Color(0xFFB4691E)),
      ColorRule(extension: 'tar', color: Color(0xFFB4691E)),
      ColorRule(extension: 'gz', color: Color(0xFFB4691E)),
      ColorRule(extension: 'pdf', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'doc', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'docx', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'xls', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'xlsx', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'ppt', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'pptx', color: Color(0xFF3E63DD)),
      ColorRule(extension: 'mp3', color: Color(0xFF46A758)),
      ColorRule(extension: 'wav', color: Color(0xFF46A758)),
      ColorRule(extension: 'flac', color: Color(0xFF46A758)),
      ColorRule(extension: 'mp4', color: Color(0xFF46A758)),
      ColorRule(extension: 'mkv', color: Color(0xFF46A758)),
      ColorRule(extension: 'avi', color: Color(0xFF46A758)),
      ColorRule(extension: 'md', color: Color(0xFF11A8CD)),
      ColorRule(extension: 'txt', color: Color(0xFF11A8CD)),
    ];
  }

  Color? colorFor(String extension) {
    if (extension.isEmpty) return null;
    for (final rule in rules.value) {
      if (rule.matches(extension)) return rule.color;
    }

    return null;
  }

  void addRule(String extension, Color color) {
    final ext = extension.trim().replaceAll('.', '');
    if (ext.isEmpty) return;
    final next = rules.value.where((r) => !r.matches(ext)).toList();
    next.add(ColorRule(extension: ext, color: color));
    rules.value = next;
  }

  void removeRule(String extension) {
    rules.value = rules.value.where((r) => !r.matches(extension)).toList();
  }

  void resetDefaults() {
    rules.value = _defaultRules();
  }
}
