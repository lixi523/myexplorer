part of 'sidebar.dart';

class _SectionHeader extends StatefulWidget {
  final String title;
  final bool collapsed;
  final VoidCallback onToggle;

  const _SectionHeader({
    required this.title,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    return Tooltip(
      message: widget.collapsed
          ? t.sidebar.expandSection
          : t.sidebar.collapseSection,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, _rowPadH, 6),
            child: Row(
              children: [
                Icon(
                  widget.collapsed
                      ? MyExplorerIconsRegular.caretRight
                      : MyExplorerIconsRegular.caretDown,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: context.txt.sectionLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final _SidebarItem item;
  final bool isSelected;
  final bool isMounted;
  final DriveSpace? space;
  final bool collapsed;
  final ValueChanged<String> onTap;
  final VoidCallback? onMiddleTap;
  final void Function(List<String> paths, {bool move}) onDropFiles;
  final bool isTagTarget;
  final VoidCallback? onUnmount;
  final void Function(Offset position)? onContextMenu;
  final String? tooltip;

  const _ItemRow({
    required this.item,
    required this.isSelected,
    this.isMounted = true,
    this.space,
    this.collapsed = false,
    required this.onTap,
    this.onMiddleTap,
    required this.onDropFiles,
    this.isTagTarget = false,
    this.onUnmount,
    this.onContextMenu,
    this.tooltip,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: [Formats.fileUri, formatLocalFile],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (!_dragOver) setState(() => _dragOver = true);
        if (widget.isTagTarget) return DropOperation.link;

        return DragHintController.instance.mode.value == DragMode.move
            ? DropOperation.move
            : DropOperation.copy;
      },
      onDropLeave: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onDropEnded: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onPerformDrop: (event) async {
        final paths = await pathsFromSession(event.session);
        final move = DragHintController.instance.mode.value == DragMode.move;
        if (paths.isNotEmpty) widget.onDropFiles(paths, move: move);
        if (_dragOver) setState(() => _dragOver = false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.item.path),
          onTertiaryTapUp: (_) {
            if (widget.isMounted) {
              widget.onMiddleTap?.call();
            }
          },
          onSecondaryTapUp: widget.onContextMenu != null
              ? (details) => widget.onContextMenu!(details.globalPosition)
              : null,
          child: Builder(
            builder: (context) {
              final row = widget.collapsed ? _railRow() : _expandedRow(context);
              final tooltipMessage = _tooltipMessage();
              if (tooltipMessage == null) return row;

              return Tooltip(
                message: tooltipMessage,
                waitDuration: const Duration(milliseconds: 400),
                child: row,
              );
            },
          ),
        ),
      ),
    );
  }

  Color get _bg {
    if (_dragOver) return AppColors.accent.withValues(alpha: 0.12);
    if (widget.isSelected) return AppColors.bgSelectedMuted;
    if (_hovered) return AppColors.bgHover;

    return Colors.transparent;
  }

  Color get _iconColor {
    final brand = widget.item.iconColor;
    if (brand != null) {
      return widget.isMounted ? brand : brand.withValues(alpha: 0.55);
    }
    if (widget.isSelected) return AppColors.fgAccent;

    return widget.isMounted
        ? AppColors.fg.withValues(alpha: 0.85)
        : AppColors.fgMuted;
  }

  Border? get _dragBorder => _dragOver
      ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
      : null;

  Widget _railRow() {
    return Container(
      height: _railRowHeight,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(color: _bg, border: _dragBorder),
      child: Stack(
        children: [
          if (widget.isSelected)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _SelectionAccent(),
            ),
          Center(
            child:
                widget.item.leading ??
                Icon(widget.item.icon, size: _iconSize, color: _iconColor),
          ),
        ],
      ),
    );
  }

  Widget _expandedRow(BuildContext context) {
    final content = Row(
      children: [
        widget.item.leading ??
            Icon(widget.item.icon, size: _iconSize, color: _iconColor),
        const SizedBox(width: _iconGap),
        Expanded(
          child: Text(
            widget.item.label,
            overflow: TextOverflow.ellipsis,
            style: context.txt.body.copyWith(
              color: widget.isSelected
                  ? AppColors.fg
                  : (widget.isMounted
                        ? AppColors.fg.withValues(alpha: 0.85)
                        : AppColors.fgMuted),
              fontWeight: widget.isSelected
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ),
        if (widget.onUnmount != null)
          _RowIconButton(
            icon: MyExplorerIconsRegular.eject,
            tooltip: t.menu.eject,
            onTap: widget.onUnmount!,
          ),
      ],
    );

    final body = widget.space == null
        ? content
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              content,
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: _iconSize + _iconGap),
                child: _DriveSpaceBar(space: widget.space!),
              ),
            ],
          );

    return Container(
      height: widget.space == null ? _rowHeight : _rowHeightWithSpace,
      decoration: BoxDecoration(color: _bg, border: _dragBorder),
      child: Stack(
        children: [
          if (widget.isSelected)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _SelectionAccent(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
            child: Center(child: body),
          ),
        ],
      ),
    );
  }

  String? _tooltipMessage() {
    final space = widget.space;
    if (space == null) {
      if (widget.collapsed) return widget.item.label;

      return widget.tooltip;
    }

    final usedPercent = (space.usedFraction * 100).toStringAsFixed(1);

    return [
      widget.item.label,
      '${t.sidebar.driveSpace.used}: ${formatBytes(space.usedBytes)} ($usedPercent%)',
      '${t.sidebar.driveSpace.free}: ${formatBytes(space.freeBytes)}',
      '${t.sidebar.driveSpace.total}: ${formatBytes(space.totalBytes)}',
    ].join('\n');
  }
}

class _SelectionAccent extends StatelessWidget {
  const _SelectionAccent();

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, color: AppColors.accent);
  }
}

class _RowIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RowIconButton> createState() => _RowIconButtonState();
}

class _RowIconButtonState extends State<_RowIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DriveSpaceBar extends StatelessWidget {
  final DriveSpace space;

  const _DriveSpaceBar({required this.space});

  @override
  Widget build(BuildContext context) {
    final used = space.usedFraction;
    final color = used >= 0.9
        ? AppColors.danger
        : used >= 0.75
        ? AppColors.warning
        : AppColors.success;

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: used,
          minHeight: 2,
          backgroundColor: AppColors.bgDivider,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
