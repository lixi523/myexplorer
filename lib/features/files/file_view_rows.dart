part of 'file_view.dart';

class _ListRow extends StatefulWidget {
  final FileEntry entry;
  final int index;
  final bool selected;
  final Set<String> selectedPaths;
  final bool isCut;
  final bool isDraggingSelected;
  final bool isFolderDragOver;
  final bool isRenaming;
  final int renameAttempt;
  final RenameSubmitCallback? onRenameSubmit;
  final RenameCancelCallback? onRenameCancel;
  final FileSelectCallback onSelect;
  final FileSelectCallback? onSecondarySelect;
  final Set<String> secondarySelectedPaths;
  final FileOpenCallback onOpen;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final bool recursive;
  final double nameWidth;
  final double locationWidth;
  final List<FileColumn> columns;
  final Map<FileColumn, double> columnWidths;
  final double rowHeight;
  final double iconSize;
  final String dateFmt;
  final bool recentDatesRelative;
  final String? location;
  final OpenInNewTabCallback? onOpenInNewTab;
  final int? folderSize;
  final RowDecoration? rowDecoration;
  final bool treeMode;
  final int treeDepth;
  final bool treeExpanded;
  final bool treeLoading;
  final VoidCallback? onToggleTree;

  const _ListRow({
    required this.entry,
    required this.index,
    this.folderSize,
    this.rowDecoration,
    required this.selected,
    required this.selectedPaths,
    this.isCut = false,
    this.isDraggingSelected = false,
    this.isFolderDragOver = false,
    this.isRenaming = false,
    this.renameAttempt = 0,
    this.onRenameSubmit,
    this.onRenameCancel,
    required this.onSelect,
    this.onSecondarySelect,
    this.secondarySelectedPaths = const {},
    required this.onOpen,
    this.onContextMenu,
    this.onMenuAction,
    this.recursive = false,
    this.nameWidth = 0,
    this.locationWidth = _kLocationWidth,
    this.columns = const [],
    this.columnWidths = const {},
    this.rowHeight = _kRowHeightComfortable,
    this.iconSize = 16,
    this.dateFmt = 'locale',
    this.recentDatesRelative = true,
    this.location,
    this.onOpenInNewTab,
    this.treeMode = false,
    this.treeDepth = 0,
    this.treeExpanded = false,
    this.treeLoading = false,
    this.onToggleTree,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hovered = false;
  bool _treeDisclosureHovered = false;
  bool _dragging = false;
  DateTime? _lastTap;
  TextEditingController? _renameController;
  FocusNode? _renameFocusNode;
  bool _renameCommitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRenaming) _initRenameFields();
  }

  @override
  void didUpdateWidget(covariant _ListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRenaming && !oldWidget.isRenaming) {
      _initRenameFields();
    } else if (!widget.isRenaming && oldWidget.isRenaming) {
      _disposeRenameFields();
    } else if (widget.isRenaming &&
        widget.renameAttempt != oldWidget.renameAttempt) {
      _renameCommitted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _renameFocusNode == null || _renameController == null) {
          return;
        }
        _renameFocusNode!.requestFocus();
        _renameController!.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _renameController!.text.length,
        );
      });
    }
  }

  void _initRenameFields() {
    _renameCommitted = false;
    final name = widget.entry.name;
    String initialText;
    int selectionEnd;
    if (widget.entry.type == FileItemType.file) {
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex > 0) {
        initialText = name;
        selectionEnd = dotIndex;
      } else {
        initialText = name;
        selectionEnd = name.length;
      }
    } else {
      initialText = name;
      selectionEnd = name.length;
    }
    _renameController = TextEditingController(text: initialText);
    _renameController!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: selectionEnd,
    );
    _renameFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _renameFocusNode != null) {
        _renameFocusNode!.requestFocus();
      }
    });
  }

  void _disposeRenameFields() {
    _renameController?.dispose();
    _renameController = null;
    _renameFocusNode?.dispose();
    _renameFocusNode = null;
  }

  @override
  void dispose() {
    _disposeRenameFields();
    super.dispose();
  }

  void _commitRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    final newName = _renameController?.text ?? '';
    widget.onRenameSubmit?.call(newName);
  }

  void _cancelRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    widget.onRenameCancel?.call();
  }

  Color get _bg {
    if (widget.isFolderDragOver) {
      return AppColors.accent.withValues(alpha: 0.12);
    }
    if (_dragging) return AppColors.accent.withValues(alpha: 0.08);
    if (widget.selected) return AppColors.bgSelectedMuted;
    if (_hovered) return AppColors.bgHover;
    final tint = widget.rowDecoration?.tint;
    if (tint != null) return tint.withValues(alpha: 0.18);

    return Colors.transparent;
  }

  BoxBorder? get _border {
    if (widget.isFolderDragOver) {
      return Border.all(color: AppColors.accent.withValues(alpha: 0.4));
    }
    if (widget.selected) {
      return Border(left: BorderSide(color: AppColors.accent, width: 2));
    }

    return null;
  }

  Widget _buildTagDots() {
    final colors = widget.rowDecoration?.badgeColors ?? const [];
    if (colors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final color in colors)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconWithBadge(BuildContext context, FileEntry e, bool isFolder) {
    final icon = buildFileIcon(
      name: e.name,
      ext: e.extension,
      isFolder: isFolder,
      size: widget.iconSize,
    );
    final badge = widget.rowDecoration?.badge;
    if (badge == null) return icon;

    return SizedBox(
      width: widget.iconSize,
      height: widget.iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Center(child: icon)),
          Positioned(
            right: -2,
            top: -4,
            child: Text(
              badge,
              style: context.txt.badge.copyWith(
                color: widget.rowDecoration!.tint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreePrefix(bool isFolder) {
    if (!widget.treeMode) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: widget.treeDepth * _kTreeIndentWidth),
        SizedBox(
          width: _kTreeDisclosureWidth,
          height: widget.rowHeight,
          child: isFolder
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _treeDisclosureHovered = true),
                  onExit: (_) => setState(() => _treeDisclosureHovered = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onToggleTree,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _treeDisclosureHovered
                              ? AppColors.bgHoverStrong
                              : Colors.transparent,
                          border: Border.all(
                            color: _treeDisclosureHovered
                                ? AppColors.borderColor
                                : Colors.transparent,
                          ),
                        ),
                        child: widget.treeLoading
                            ? SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.fgSubtle,
                                ),
                              )
                            : Icon(
                                widget.treeExpanded
                                    ? MyExplorerIconsRegular.caretDown
                                    : MyExplorerIconsRegular.caretRight,
                                size: 12,
                                color: _treeDisclosureHovered
                                    ? AppColors.fg
                                    : AppColors.fgSubtle,
                              ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  List<Widget> _buildColumnCells(BuildContext context, FileEntry e) {
    final muted = context.txt.muted;

    return [
      for (final col in widget.columns) ...[
        const SizedBox(width: _kColumnGap),
        SizedBox(
          width: widget.columnWidths[col] ?? 0,
          child: Text(
            fileColumnText(
              col,
              e,
              dateFmt: widget.dateFmt,
              recentDatesRelative: widget.recentDatesRelative,
              folderSize: widget.folderSize,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: muted,
          ),
        ),
      ],
    ];
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!).inMilliseconds < _kDoubleTapMs) {
      _lastTap = null;
      widget.onOpen(widget.entry);

      return;
    }
    _lastTap = now;
    widget.onSelect(
      FileSelectionEvent(entry: widget.entry, index: widget.index),
    );
  }

  Widget _buildDragImage(BuildContext context, Widget child) {
    final dragCount = widget.selected ? widget.selectedPaths.length : 1;

    final e = widget.entry;
    final isFolder = e.type == FileItemType.folder;

    final visualRow = Container(
      width: 260,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.bgDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          buildFileIcon(
            name: e.name,
            ext: e.extension,
            isFolder: isFolder,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dragCount > 1 ? t.fileView.movingItems(count: dragCount) : e.name,
              overflow: TextOverflow.ellipsis,
              style: context.txt.dialogTitle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return visualRow;
  }

  Future<DragItem?> _provideDragItem(DragItemRequest request) async {
    if (!widget.selected) {
      widget.onSelect(
        FileSelectionEvent(entry: widget.entry, index: widget.index),
      );
    }

    final pathsToDrag = _pathsToDrag();
    final item = _dragItemForPaths(pathsToDrag);

    final initialMode = initialDragMode();

    void updateDragging() {
      final isDragging = request.session.dragging.value;
      if (mounted) {
        setState(() => _dragging = isDragging);
      }
      if (isDragging) {
        DragHintController.instance.mode.value = initialMode;
      }
    }

    request.session.dragging.addListener(updateDragging);
    updateDragging();

    return item;
  }

  List<String> _pathsToDrag() {
    final selectedPaths = widget.selectedPaths.toList();
    if (widget.selected && selectedPaths.isNotEmpty) return selectedPaths;

    return [widget.entry.path];
  }

  DragItem _dragItemForPaths(List<String> paths) {
    final item = DragItem(
      localData: {'paths': paths},
      suggestedName: paths.length == 1 ? p.basename(paths.first) : null,
    );
    item.add(formatLocalFile(paths.join('\n')));

    for (final path in paths) {
      item.add(Formats.fileUri(Uri.file(path)));
    }

    return item;
  }

  Future<DragConfiguration> _expandDragConfiguration(
    DragConfiguration configuration,
    DragSession session,
  ) async {
    final paths = _pathsToDrag();
    if (paths.length <= 1 || configuration.items.isEmpty) {
      return configuration;
    }

    final preview = configuration.items.first;
    final extraImages = <TargetedWidgetSnapshot>[];
    for (var i = 1; i < paths.length; i++) {
      extraImages.add(await _transparentDragSnapshot(preview.image));
    }

    return DragConfiguration(
      items: [
        for (final (index, path) in paths.indexed)
          DragConfigurationItem(
            item: _dragItemForPaths([path]),
            image: index == 0 ? preview.image : extraImages[index - 1],
          ),
      ],
      allowedOperations: configuration.allowedOperations,
      options: configuration.options,
    );
  }

  Future<TargetedWidgetSnapshot> _transparentDragSnapshot(
    TargetedWidgetSnapshot preview,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(Colors.transparent, ui.BlendMode.clear);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    picture.dispose();

    return TargetedWidgetSnapshot(
      WidgetSnapshot.image(image),
      Rect.fromLTWH(preview.rect.left, preview.rect.top, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isFolder = e.type == FileItemType.folder;
    final opacity = widget.isCut ? 0.4 : (_dragging ? 0.4 : 1.0);

    if (widget.isRenaming) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: widget.rowHeight,
          padding: const EdgeInsets.only(
            left: _kRowPaddingLeft,
            right: _kRowPaddingRight,
          ),
          decoration: BoxDecoration(color: _bg, border: _border),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                _buildTreePrefix(isFolder),
                _buildIconWithBadge(context, e, isFolder),
                const SizedBox(width: 6),
                SizedBox(
                  width: widget.nameWidth,
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape):
                          _cancelRename,
                    },
                    child: TextField(
                      controller: _renameController,
                      focusNode: _renameFocusNode,
                      autofocus: true,
                      style: context.txt.bodyEmphasis,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.bgDivider,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _commitRename(),
                      onTapOutside: (_) => _commitRename(),
                    ),
                  ),
                ),
                if (widget.recursive) ...[
                  const SizedBox(width: _kColumnGap),
                  SizedBox(
                    width: widget.locationWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                ],
                ..._buildColumnCells(context, e),
              ],
            ),
          ),
        ),
      );
    }

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        onTertiaryTapUp: (_) {
          if (widget.entry.type == FileItemType.folder) {
            widget.onOpenInNewTab?.call(widget.entry.path);
          }
        },
        child: Container(
          height: widget.rowHeight,
          padding: EdgeInsets.only(
            left: widget.selected ? _kRowPaddingLeft - 2 : _kRowPaddingLeft,
            right: _kRowPaddingRight,
          ),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: widget.isFolderDragOver ? BorderRadius.zero : null,
            border: _border,
          ),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                _buildTreePrefix(isFolder),
                _buildIconWithBadge(context, e, isFolder),
                const SizedBox(width: 6),
                SizedBox(
                  width: widget.nameWidth,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.name,
                          overflow: TextOverflow.ellipsis,
                          style: context.txt.body.copyWith(
                            color: widget.selected
                                ? AppColors.fg
                                : widget.rowDecoration?.nameColor ??
                                      AppColors.fg.withValues(alpha: 0.9),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      _buildTagDots(),
                    ],
                  ),
                ),
                if (widget.recursive) ...[
                  const SizedBox(width: _kColumnGap),
                  SizedBox(
                    width: widget.locationWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                ],
                ..._buildColumnCells(context, e),
              ],
            ),
          ),
        ),
      ),
    );

    return DragItemWidget(
      dragItemProvider: _provideDragItem,
      allowedOperations: () => [DropOperation.copy, DropOperation.move],
      canAddItemToExistingSession: true,
      dragBuilder: _buildDragImage,
      child: DraggableWidget(
        onDragConfiguration: _expandDragConfiguration,
        child: row,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback? onCloseSearch;

  const _EmptyState({this.isSearching = false, this.onCloseSearch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MyExplorerIconsRegular.folderOpen,
              size: 48,
              color: AppColors.fgSubtle,
            ),
            const SizedBox(height: 12),
            if (isSearching) ...[
              Text(
                t.search.noMatches,
                style: context.txt.dialogTitle.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
              const SizedBox(height: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onCloseSearch,
                  child: Text(
                    t.search.clear,
                    style: context.txt.body.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ] else
              Text(
                t.fileView.empty,
                style: context.txt.dialogTitle.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDateBy(
  DateTime d,
  String mode, {
  required bool recentDatesRelative,
}) => formatEntryDate(d, mode, recentDatesRelative: recentDatesRelative);

class _PinnedVerticalScrollbar extends StatelessWidget {
  final ScrollController controller;
  const _PinnedVerticalScrollbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (!controller.hasClients) return const SizedBox.shrink();
            final position = controller.position;
            if (!position.hasContentDimensions ||
                !position.hasViewportDimension ||
                !position.hasPixels) {
              return const SizedBox.shrink();
            }
            final maxScroll = position.maxScrollExtent;
            final viewport = position.viewportDimension;
            if (maxScroll <= 0 || viewport <= 0) {
              return const SizedBox.shrink();
            }
            final thumbHeight = math.max(
              24.0,
              trackHeight * viewport / (viewport + maxScroll),
            );
            final maxTravel = trackHeight - thumbHeight;
            final t = (position.pixels / maxScroll).clamp(0.0, 1.0);
            final top = maxTravel * t;

            return Stack(
              children: [
                Positioned(
                  top: top,
                  right: 0,
                  width: _kScrollbarThumbWidth,
                  height: thumbHeight,
                  child: GestureDetector(
                    onVerticalDragUpdate: (d) {
                      if (maxTravel <= 0) return;
                      final delta = d.delta.dy / maxTravel * maxScroll;
                      controller.jumpTo(
                        (position.pixels + delta).clamp(
                          position.minScrollExtent,
                          position.maxScrollExtent,
                        ),
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.fgSubtle),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
