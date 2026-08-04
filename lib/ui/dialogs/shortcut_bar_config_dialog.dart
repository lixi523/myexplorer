import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../../features/navigation/shortcut_bar_store.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';

/// Manages the user-defined items on the shortcut bar below the title bar:
/// add a folder/file/command shortcut, remove or reorder existing ones.
Future<void> showShortcutBarConfigDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: const _ShortcutBarConfigDialog(),
        ),
      );
    },
  );
}

class _ShortcutBarConfigDialog extends StatefulWidget {
  const _ShortcutBarConfigDialog();

  @override
  State<_ShortcutBarConfigDialog> createState() =>
      _ShortcutBarConfigDialogState();
}

class _ShortcutBarConfigDialogState extends State<_ShortcutBarConfigDialog> {
  final _store = ShortcutBarStore.instance;
  final _labelController = TextEditingController();
  final _targetController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: t.preferences.shortcutBar.pickFile,
      lockParentWindow: true,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    if (_labelController.text.trim().isEmpty) {
      _labelController.text = PlatformPaths.fileName(path);
    }
    _targetController.text = path;
  }

  Future<void> _add() async {
    final label = _labelController.text.trim();
    final target = _targetController.text.trim();
    if (label.isEmpty || target.isEmpty || _busy) return;
    setState(() => _busy = true);
    await _store.add(label, target);
    _labelController.clear();
    _targetController.clear();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove(int id) async {
    await _store.remove(id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.bolt,
      iconColor: AppColors.fgAccent,
      title: t.preferences.shortcutBar.title,
      width: 480,
      padding: const EdgeInsets.all(16),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _labelController,
                  hintText: t.preferences.shortcutBar.labelHint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: _targetController,
                  hintText: t.preferences.shortcutBar.targetHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                label: t.preferences.shortcutBar.pickFile,
                onTap: _pickFile,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: t.preferences.shortcutBar.add,
                primary: true,
                busy: _busy,
                onTap: _add,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.bgDivider),
          const SizedBox(height: 12),
          Flexible(
            child: SignalBuilder(
              builder: (context) {
                final items = _store.items.value;

                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in items)
                      _ItemRow(
                        label: item.label,
                        target: item.target,
                        onDelete: () => _remove(item.id),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String label;
  final String target;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.label,
    required this.target,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border.all(color: AppColors.bgDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 16, color: AppColors.fgMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.txt.row),
                Text(
                  target,
                  style: context.txt.captionSmall.copyWith(
                    color: AppColors.fgMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: AppColors.fgMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool busy;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.fgAccent : AppColors.fg;
    final bg = primary ? AppColors.accent : AppColors.bgSidebar;

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: AppColors.borderColor),
        ),
        child: busy
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: context.txt.row.copyWith(color: fg)),
      ),
    );
  }
}
