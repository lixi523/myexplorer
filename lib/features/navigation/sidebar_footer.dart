part of 'sidebar.dart';

class _SidebarFooter extends StatelessWidget {
  final OperationStore operationStore;
  final bool collapsed;
  final VoidCallback onConnect;

  const _SidebarFooter({
    required this.operationStore,
    required this.collapsed,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border(top: BorderSide(color: AppColors.bgDivider));

    if (collapsed) {
      return DecoratedBox(
        decoration: BoxDecoration(border: border),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ConnectToServerButton(collapsed: true, onTap: onConnect),
              const SizedBox(height: 2),
              _SidebarOperationsButton(
                operationStore: operationStore,
                collapsed: true,
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(border: border),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_gutter, 6, _expandedRightGutter, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConnectToServerButton(collapsed: false, onTap: onConnect),
            const SizedBox(height: 2),
            _SidebarOperationsButton(operationStore: operationStore),
          ],
        ),
      ),
    );
  }
}

class _ConnectToServerButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;

  const _ConnectToServerButton({required this.collapsed, required this.onTap});

  @override
  State<_ConnectToServerButton> createState() => _ConnectToServerButtonState();
}

class _ConnectToServerButtonState extends State<_ConnectToServerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    if (!widget.collapsed) {
      return Tooltip(
        message: t.sidebar.connectToServer,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
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
                    MyExplorerIconsRegular.treeStructure,
                    size: _iconSize,
                    color: color,
                  ),
                  const SizedBox(width: _iconGap),
                  Expanded(
                    child: Text(
                      t.sidebar.connectToServer,
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

    return Tooltip(
      message: t.sidebar.connectToServer,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Icon(
              MyExplorerIconsRegular.treeStructure,
              size: 15,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDropTarget extends StatefulWidget {
  final Widget child;
  final Future<void> Function(String path) onDropBookmark;

  const _SidebarDropTarget({required this.child, required this.onDropBookmark});

  @override
  State<_SidebarDropTarget> createState() => _SidebarDropTargetState();
}

class _SidebarDropTargetState extends State<_SidebarDropTarget> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: [Formats.fileUri, formatLocalFile],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (!_dragOver) setState(() => _dragOver = true);

        return DropOperation.copy;
      },
      onDropLeave: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onDropEnded: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onPerformDrop: (event) async {
        final paths = await pathsFromSession(event.session);
        for (final path in paths) {
          if (Directory(path).existsSync()) {
            await widget.onDropBookmark(path);
          }
        }
        if (_dragOver) setState(() => _dragOver = false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _dragOver
              ? AppColors.accent.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: widget.child,
      ),
    );
  }
}
