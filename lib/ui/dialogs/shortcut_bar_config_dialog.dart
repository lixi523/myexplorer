import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../../features/navigation/shortcut_bar_store.dart';
import '../../features/navigation/tc_bar_parser.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';

/// Manages the user-defined items on the shortcut bar below the title bar:
/// add, edit, remove or reorder shortcuts. When [editingId] is set, the form
/// is pre-filled with that item so the user can save changes onto it.
Future<void> showShortcutBarConfigDialog(
  BuildContext context, {
  int? editingId,
}) {
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
          child: _ShortcutBarConfigDialog(editingId: editingId),
        ),
      );
    },
  );
}

class _ShortcutBarConfigDialog extends StatefulWidget {
  final int? editingId;

  const _ShortcutBarConfigDialog({this.editingId});

  @override
  State<_ShortcutBarConfigDialog> createState() =>
      _ShortcutBarConfigDialogState();
}

class _ShortcutBarConfigDialogState extends State<_ShortcutBarConfigDialog> {
  final _store = ShortcutBarStore.instance;
  final _labelController = TextEditingController();
  final _targetController = TextEditingController();
  final _iconController = TextEditingController();
  bool _busy = false;
  bool _importing = false;
  String? _importMessage;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (!mounted) return;
      _applyEditingIdOnce();
    });
    _applyEditingIdOnce();
  }

  void _applyEditingIdOnce() {
    final editingId = widget.editingId;
    if (editingId == null || _editingId != null) return;
    final items = _store.items.value;
    for (final item in items) {
      if (item.id != editingId) continue;
      _editingId = editingId;
      _labelController.text = item.label;
      _targetController.text = item.target;
      _iconController.text = item.icon ?? '';
      break;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _targetController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _startEdit(int id) {
    final items = _store.items.value;
    for (final item in items) {
      if (item.id != id) continue;
      setState(() {
        _editingId = id;
        _importMessage = null;
        _labelController.text = item.label;
        _targetController.text = item.target;
        _iconController.text = item.icon ?? '';
      });

      return;
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _importMessage = null;
      _labelController.clear();
      _targetController.clear();
      _iconController.clear();
    });
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

  Future<void> _save() async {
    final label = _labelController.text.trim();
    final target = _targetController.text.trim();
    if (label.isEmpty || target.isEmpty || _busy) return;
    setState(() => _busy = true);
    final icon = _iconController.text.trim();
    final editingId = _editingId;
    if (editingId != null) {
      await _store.update(
        editingId,
        label: label,
        target: target,
        icon: icon.isEmpty ? null : icon,
      );
    } else {
      await _store.add(label, target, icon: icon.isEmpty ? null : icon);
    }
    _cancelEdit();
    if (mounted) setState(() => _busy = false);
  }

  /// Imports a Total Commander button bar (`.bar`) file, appending its
  /// buttons to the shortcut bar. GBK- and UTF-8-encoded files are both
  /// accepted; empty buttons become separators.
  Future<void> _importTcBar() async {
    if (_importing) return;
    setState(() {
      _importing = true;
      _importMessage = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: t.preferences.shortcutBar.importTcBar,
        lockParentWindow: true,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;

      final bytes = await File(path).readAsBytes();
      final entries = parseTcBar(decodeBarBytes(bytes));
      if (entries.isEmpty) {
        if (mounted) {
          setState(
            () => _importMessage = t.preferences.shortcutBar.importFailed,
          );
        }

        return;
      }
      final specs = <({String label, String target, String? icon})>[];
      for (final entry in entries) {
        if (entry.isEmpty) {
          specs.add((label: '', target: '', icon: null));
          continue;
        }
        specs.add((
          label: entry.menu.isNotEmpty
              ? entry.menu
              : _labelForCommand(entry.cmd),
          target: entry.commandLine,
          icon: entry.icon.isEmpty ? null : entry.icon,
        ));
      }
      await _store.addAll(specs);
      if (mounted) {
        setState(
          () => _importMessage = t.preferences.shortcutBar.imported(
            count: specs.length,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _importMessage = t.preferences.shortcutBar.importFailed);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Derives a label from a command when the bar file has no menu text.
  String _labelForCommand(String cmd) {
    final trimmed = cmd.trim();
    if (trimmed.isEmpty) return '';
    final cdMatch = RegExp(
      r'^cd\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (cdMatch != null) {
      return PlatformPaths.fileName(cdMatch.group(1)!.trim());
    }

    return PlatformPaths.fileName(trimmed);
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
          AppTextField(
            controller: _iconController,
            hintText: t.preferences.shortcutBar.iconHint,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                label: t.preferences.shortcutBar.importTcBar,
                busy: _importing,
                onTap: _importTcBar,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: t.preferences.shortcutBar.pickFile,
                onTap: _pickFile,
              ),
              const SizedBox(width: 8),
              if (_editingId != null) ...[
                _ActionButton(label: t.dialog.cancel, onTap: _cancelEdit),
                const SizedBox(width: 8),
              ],
              _ActionButton(
                label: _editingId != null
                    ? t.preferences.shortcutBar.save
                    : t.preferences.shortcutBar.add,
                busy: _busy,
                onTap: _save,
              ),
            ],
          ),
          if (_importMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _importMessage!,
              style: context.txt.captionSmall.copyWith(
                color: AppColors.fgMuted,
              ),
            ),
          ],
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
                        editing: item.id == _editingId,
                        onEdit: () => _startEdit(item.id),
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
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.label,
    required this.target,
    required this.editing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: editing ? AppColors.bgSelectedMuted : AppColors.bgSidebar,
        border: Border.all(
          color: editing ? AppColors.accent : AppColors.bgDivider,
        ),
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
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.edit,
                size: 14,
                color: editing ? AppColors.accent : AppColors.fgMuted,
              ),
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
  final bool busy;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSidebar,
          border: Border.all(color: AppColors.borderColor),
        ),
        child: busy
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: context.txt.row.copyWith(color: AppColors.fg)),
      ),
    );
  }
}
