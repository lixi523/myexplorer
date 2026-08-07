import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../features/hidden/hidden_list_store.dart';
import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';

/// Manages the `隐藏文件.ini` hidden list: shows the INI file location, the
/// current entries (each removable) and lets the user add new paths (multi
/// line paste supported). Removing an entry is the only way to un-hide an
/// item; the file itself is the single source of truth.
Future<void> showHiddenListDialog(BuildContext context) {
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
          child: const _HiddenListDialog(),
        ),
      );
    },
  );
}

class _HiddenListDialog extends StatefulWidget {
  const _HiddenListDialog();

  @override
  State<_HiddenListDialog> createState() => _HiddenListDialogState();
}

class _HiddenListDialogState extends State<_HiddenListDialog> {
  final _store = HiddenListStore.instance;
  final _pathsController = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (!_store.isLoaded) _store.load();
  }

  @override
  void dispose() {
    _pathsController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    final raw = _pathsController.text.trim();
    if (raw.isEmpty) return;
    setState(() => _busy = true);
    final paths = raw
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await _store.addPaths(paths);
    _pathsController.clear();
    if (mounted) {
      setState(() {
        _busy = false;
        _message = t.hiddenList.added(count: paths.length);
      });
    }
  }

  Future<void> _remove(String path) async {
    await _store.removePath(path);
    if (mounted) setState(() => _message = null);
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.visibility_off,
      iconColor: AppColors.fgAccent,
      title: t.hiddenList.title,
      width: 520,
      padding: const EdgeInsets.all(16),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _store.filePath,
            style: context.txt.captionSmall.copyWith(color: AppColors.fgMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _pathsController,
            hintText: t.hiddenList.pathHint,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                label: t.hiddenList.add,
                busy: _busy,
                onTap: _add,
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
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
                final items = _store.paths.value;
                if (items.isEmpty) {
                  return Text(
                    t.hiddenList.empty,
                    style: context.txt.captionSmall.copyWith(
                      color: AppColors.fgMuted,
                    ),
                  );
                }

                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final path in items)
                      _PathRow(path: path, onDelete: () => _remove(path)),
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

class _PathRow extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const _PathRow({required this.path, required this.onDelete});

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
          Icon(
            Icons.visibility_off_outlined,
            size: 14,
            color: AppColors.fgMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              path,
              style: context.txt.row,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
