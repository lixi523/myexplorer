import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myexplorer/ui/icons/myexplorer_icons.dart';

import '../../core/models/file_entry.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_toggle_chip.dart';
import 'operation_store.dart';

/// Preset part sizes for the split dialog (bytes).
const List<(String, int)> splitSizePresets = [
  ('1.44 MB (Floppy)', 1440 * 1024),
  ('100 MB', 100 * 1024 * 1024),
  ('650 MB', 650 * 1024 * 1024),
  ('700 MB (CD)', 700 * 1024 * 1024),
  ('4.7 GB (DVD)', 4700 * 1024 * 1024),
];

/// Returns true when [path] looks like a split part (`name.NNN`).
bool isSplitPartPath(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;

  return RegExp(r'^.+\.[0-9]{3}$').hasMatch(name);
}

/// Given the first part path (`name.001`), returns the ordered sibling parts
/// (`name.002`, `name.003`, …) that exist on disk.
List<String> siblingParts(String firstPartPath) {
  final sep = firstPartPath.contains('/') ? '/' : r'\';
  final dirPath = firstPartPath.substring(0, firstPartPath.lastIndexOf(sep));
  final name = firstPartPath.substring(firstPartPath.lastIndexOf(sep) + 1);
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return const [];
  final base = name.substring(0, dot);
  final parts = <String>[];
  for (var i = 1; i <= 999; i++) {
    final candidate = '$dirPath$sep$base.${i.toString().padLeft(3, '0')}';
    if (!File(candidate).existsSync()) break;
    parts.add(candidate);
  }

  return parts;
}

/// Shows the split-file dialog. On confirm, enqueues a split task for each
/// selected file (parts are written next to the source).
Future<void> showSplitDialog({
  required BuildContext context,
  required OperationStore operationStore,
  required List<FileEntry> entries,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.bg.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _SplitDialog(operationStore: operationStore, entries: entries),
      ),
    ),
  );
}

class _SplitDialog extends StatefulWidget {
  final OperationStore operationStore;
  final List<FileEntry> entries;

  const _SplitDialog({required this.operationStore, required this.entries});

  @override
  State<_SplitDialog> createState() => _SplitDialogState();
}

class _SplitDialogState extends State<_SplitDialog> {
  int _selectedPreset = 1; // 100 MB default
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int get _partSize {
    if (_selectedPreset == splitSizePresets.length) {
      return int.tryParse(_customCtrl.text.trim()) ?? 0;
    }

    return splitSizePresets[_selectedPreset].$2;
  }

  void _confirm() {
    final size = _partSize;
    if (size <= 0) return;
    widget.operationStore.enqueueSplit([
      for (final e in widget.entries)
        if (e.type == FileItemType.file) e.realPath,
    ], size);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: MyExplorerIconsRegular.scissors,
      iconColor: AppColors.accent,
      title: t.split.title,
      width: 480,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.split.filesCount(count: widget.entries.length),
            style: context.txt.body.copyWith(color: AppColors.fgMuted),
          ),
          const SizedBox(height: 14),
          Text(t.split.partSize, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < splitSizePresets.length; i++)
                SizedBox(
                  width: 190,
                  child: AppToggleChip(
                    label: splitSizePresets[i].$1,
                    selected: _selectedPreset == i,
                    onTap: () => setState(() => _selectedPreset = i),
                  ),
                ),
              SizedBox(
                width: 190,
                child: AppToggleChip(
                  label: t.split.custom,
                  selected: _selectedPreset == splitSizePresets.length,
                  onTap: () =>
                      setState(() => _selectedPreset = splitSizePresets.length),
                ),
              ),
            ],
          ),
          if (_selectedPreset == splitSizePresets.length) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: t.split.customHint,
                hintStyle: context.txt.muted,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
              style: context.txt.body,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: t.dialog.cancel,
                color: AppColors.fgMuted,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              DialogButton(
                label: t.split.split,
                color: AppColors.accent,
                onTap: _confirm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
