part of 'sidebar.dart';

class _SidebarOperationsButton extends StatefulWidget {
  final OperationStore operationStore;
  final bool collapsed;

  const _SidebarOperationsButton({
    required this.operationStore,
    this.collapsed = false,
  });

  @override
  State<_SidebarOperationsButton> createState() =>
      _SidebarOperationsButtonState();
}

class _SidebarOperationsButtonState extends State<_SidebarOperationsButton> {
  bool _hovered = false;

  void _openPanel() {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset(box.size.width + 6, 0));
    showOperationsPanel(
      context: context,
      position: offset,
      operationStore: widget.operationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final tasks = widget.operationStore.tasks.value;
        final active = tasks.where(_isActiveTask).firstOrNull;
        if (active == null) return _buildIdle(context);

        final activeCount = widget.operationStore.activeCount.value;
        final progress = active.progress.clamp(0.0, 1.0).toDouble();
        final progressText = '${(progress * 100).round()}%';

        if (widget.collapsed) {
          return Tooltip(
            message: '${t.toolbar.operations} · $progressText',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onTap: _openPanel,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(
                      alpha: _hovered ? 0.22 : 0.14,
                    ),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          value: active.totalFiles > 0 ? progress : null,
                          strokeWidth: 2,
                          backgroundColor: AppColors.bgInput,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      Icon(
                        _operationIcon(active),
                        size: 12,
                        color: AppColors.fgAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Tooltip(
          message: t.toolbar.operations,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: _openPanel,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: _rowPadH,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: _hovered ? 0.18 : 0.11,
                  ),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.42),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _operationIcon(active),
                          size: _iconSize,
                          color: AppColors.fgAccent,
                        ),
                        const SizedBox(width: _iconGap),
                        Expanded(
                          child: Text(
                            TaskLabel.title(active),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.txt.rowEmphasis.copyWith(
                              color: AppColors.fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeCount > 1
                              ? '$progressText · $activeCount'
                              : progressText,
                          style: context.txt.caption.copyWith(
                            color: AppColors.fgAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: active.totalFiles > 0 ? progress : null,
                        minHeight: 3,
                        backgroundColor: AppColors.bgInput,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdle(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    if (widget.collapsed) {
      return Tooltip(
        message: t.toolbar.operations,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _openPanel,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.bgHover : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: Center(
                child: Icon(
                  MyExplorerIconsRegular.clockClockwise,
                  size: 14,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: t.toolbar.operations,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _openPanel,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Icon(
                  MyExplorerIconsRegular.clockClockwise,
                  size: _iconSize,
                  color: color,
                ),
                const SizedBox(width: _iconGap),
                Expanded(
                  child: Text(
                    t.toolbar.operations,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.rowEmphasis.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isActiveTask(FileTask task) {
    return task.status == TaskStatus.queued ||
        task.status == TaskStatus.preparing ||
        task.status == TaskStatus.waitingConflicts ||
        task.status == TaskStatus.running ||
        task.status == TaskStatus.cancelling;
  }

  static IconData _operationIcon(FileTask? task) {
    if (task == null) return MyExplorerIconsRegular.clockClockwise;
    if (task.status == TaskStatus.waitingConflicts) {
      return MyExplorerIconsRegular.warning;
    }

    return switch (task.type) {
      TaskType.copy => MyExplorerIconsRegular.copy,
      TaskType.move => MyExplorerIconsRegular.arrowRight,
      TaskType.delete => MyExplorerIconsRegular.trash,
      TaskType.trash => MyExplorerIconsRegular.trashSimple,
      TaskType.trashRestore => MyExplorerIconsRegular.arrowCounterClockwise,
      TaskType.trashDelete => MyExplorerIconsRegular.trash,
      TaskType.extract => MyExplorerIconsRegular.archive,
      TaskType.compress => MyExplorerIconsRegular.fileZip,
      TaskType.archiveEdit => MyExplorerIconsRegular.archive,
      TaskType.split => MyExplorerIconsRegular.scissors,
      TaskType.combine => MyExplorerIconsRegular.copy,
      TaskType.plugin => MyExplorerIconsRegular.gearSix,
    };
  }
}
