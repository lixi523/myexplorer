import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/fs/duplicate_finder.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/myexplorer_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_modal.dart';
import '../../utils/format.dart';
import 'operation_store.dart';

/// Scans a folder recursively for duplicate files (size → hash) and lets the
/// user trash or delete the duplicates while keeping one copy per group.
Future<void> showDuplicateFinderDialog({
  required BuildContext context,
  required String root,
  required OperationStore operationStore,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.bg.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _DuplicateFinderDialog(
          root: root,
          operationStore: operationStore,
        ),
      ),
    ),
  );
}

class _DuplicateFinderDialog extends StatefulWidget {
  final String root;
  final OperationStore operationStore;

  const _DuplicateFinderDialog({
    required this.root,
    required this.operationStore,
  });

  @override
  State<_DuplicateFinderDialog> createState() => _DuplicateFinderDialogState();
}

class _DuplicateFinderDialogState extends State<_DuplicateFinderDialog> {
  DuplicateScanHandle? _handle;
  final List<DuplicateGroup> _groups = [];
  final Set<String> _selected = {};
  bool _scanning = false;
  bool _done = false;
  int _filesScanned = 0;
  String _currentPath = '';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    setState(() {
      _scanning = true;
      _error = null;
    });
    _handle = DuplicateFinder.start(
      root: widget.root,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _filesScanned = progress.filesScanned;
          _currentPath = progress.currentPath;
        });
      },
      onGroups: (groups) {
        if (!mounted) return;
        setState(() {
          for (final group in groups) {
            _groups.add(group);
            // Keep the first copy, select the rest.
            for (final path in group.paths.skip(1)) {
              _selected.add(path);
            }
          }
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _done = true;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _error = error;
        });
      },
    );
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected({required bool toTrash}) async {
    if (_busy || _selected.isEmpty) return;
    final paths = _selected.toList();
    if (toTrash) {
      widget.operationStore.enqueueTrash(paths);
    } else {
      widget.operationStore.enqueueDelete(paths);
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _busy = false;
    });
  }

  int get _totalDupBytes {
    var bytes = 0;
    for (final group in _groups) {
      final kept = group.paths.length - 1;
      if (kept > 0) bytes += group.size * kept;
    }

    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final dupCount = _groups.fold<int>(0, (acc, g) => acc + g.paths.length - 1);

    return AppModal(
      icon: MyExplorerIconsRegular.copy,
      iconColor: AppColors.warning,
      title: t.duplicates.title,
      width: 620,
      height: 520,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.basename(widget.root),
            style: context.txt.bodyEmphasis,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (_scanning)
            Text(
              t.duplicates.scanning(
                files: _filesScanned,
                current: _currentPath,
              ),
              style: context.txt.muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (_done)
            Text(
              _groups.isEmpty
                  ? t.duplicates.none
                  : t.duplicates.summary(
                      groups: _groups.length,
                      files: dupCount,
                      bytes: formatBytes(_totalDupBytes),
                    ),
              style: context.txt.body.copyWith(
                color: _groups.isEmpty ? AppColors.success : AppColors.warning,
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: context.txt.captionSmall.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 10),
          if (_groups.isNotEmpty) ...[
            Expanded(
              child: ListView.separated(
                itemCount: _groups.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.bgDivider,
                ),
                itemBuilder: (_, gi) {
                  final group = _groups[gi];

                  return _GroupTile(
                    group: group,
                    selected: _selected,
                    onToggle: (path) {
                      setState(() {
                        if (_selected.contains(path)) {
                          _selected.remove(path);
                        } else {
                          _selected.add(path);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  t.duplicates.selectedCount(count: _selected.length),
                  style: context.txt.muted,
                ),
                const Spacer(),
                DialogButton(
                  label: t.duplicates.selectAllDups,
                  color: AppColors.fgMuted,
                  onTap: _busy
                      ? () {}
                      : () {
                          setState(() {
                            for (final group in _groups) {
                              _selected.addAll(group.paths.skip(1));
                            }
                          });
                        },
                ),
                const SizedBox(width: 8),
                DialogButton(
                  label: t.duplicates.trashSelected,
                  color: _busy ? AppColors.fgSubtle : AppColors.danger,
                  onTap: _busy ? () {} : () => _deleteSelected(toTrash: true),
                ),
              ],
            ),
          ] else if (!_scanning && _done) ...[
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DialogButton(
                  label: t.dialog.close,
                  color: AppColors.fgMuted,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final DuplicateGroup group;
  final Set<String> selected;
  final void Function(String path) onToggle;

  const _GroupTile({
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${group.paths.length} × ${formatBytes(group.size)}',
            style: context.txt.rowEmphasis.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: 4),
          for (final path in group.paths)
            InkWell(
              onTap: () => onToggle(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      selected.contains(path)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 14,
                      color: selected.contains(path)
                          ? AppColors.accent
                          : AppColors.fgSubtle,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        path,
                        style: context.txt.body.copyWith(
                          color: selected.contains(path)
                              ? AppColors.fg
                              : AppColors.fgMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
