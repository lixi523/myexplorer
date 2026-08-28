part of 'file_view.dart';

class _ListHeader extends StatelessWidget {
  final bool recursive;
  final double leadingWidth;
  final double nameWidth;
  final double locationWidth;
  final List<FileColumn> columns;
  final Map<FileColumn, double> columnWidths;
  final bool resizable;
  final SortKey sortColumn;
  final bool sortAscending;
  final void Function(SortKey key)? onSortColumn;
  final void Function(String key, double delta)? onResizeColumn;
  final void Function(Offset globalPosition)? onConfigureColumns;
  const _ListHeader({
    this.recursive = false,
    this.leadingWidth = 22,
    this.nameWidth = 0,
    this.locationWidth = _kLocationWidth,
    this.columns = const [],
    this.columnWidths = const {},
    this.resizable = false,
    this.sortColumn = SortKey.name,
    this.sortAscending = true,
    this.onSortColumn,
    this.onResizeColumn,
    this.onConfigureColumns,
  });

  Widget _sortable(String label, SortKey key, TextStyle style) {
    final active = sortColumn == key;
    final ascending = sortAscending;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSortColumn == null ? null : () => onSortColumn!(key),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: active ? style.copyWith(color: AppColors.fg) : style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(
                ascending
                    ? MyExplorerIconsRegular.caretUp
                    : MyExplorerIconsRegular.caretDown,
                size: 10,
                color: AppColors.fgAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cell({
    required double width,
    required Widget child,
    required String resizeKey,
  }) {
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (resizable && onResizeColumn != null)
            Positioned(
              top: 0,
              right: -_kResizeHandleWidth / 2,
              bottom: 0,
              width: _kResizeHandleWidth,
              child: _ColumnResizeHandle(
                onDelta: (delta) => onResizeColumn!(resizeKey, delta),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = context.txt.fieldLabel;

    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 12, right: 16),
      decoration: BoxDecoration(color: AppColors.bg),
      child: Row(
        children: [
          SizedBox(
            width: leadingWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _ConfigureColumnsButton(onTap: onConfigureColumns),
            ),
          ),
          _cell(
            width: nameWidth,
            resizeKey: _kColumnWidthsNameKey,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sortable(
                t.fileView.columns.name,
                SortKey.name,
                headerStyle,
              ),
            ),
          ),
          if (recursive) ...[
            const SizedBox(width: _kColumnGap),
            _cell(
              width: locationWidth,
              resizeKey: _kColumnWidthsLocationKey,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.fileView.columns.location,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: headerStyle,
                ),
              ),
            ),
          ],
          for (final col in columns) ...[
            const SizedBox(width: _kColumnGap),
            _cell(
              width: columnWidths[col] ?? 0,
              resizeKey: columnWidthKey(col),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _sortable(
                  fileColumnLabel(col),
                  fileColumnSortKey(col),
                  headerStyle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigureColumnsButton extends StatefulWidget {
  final void Function(Offset globalPosition)? onTap;
  const _ConfigureColumnsButton({this.onTap});

  @override
  State<_ConfigureColumnsButton> createState() =>
      _ConfigureColumnsButtonState();
}

class _ConfigureColumnsButtonState extends State<_ConfigureColumnsButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (d) => widget.onTap!(d.globalPosition),
        child: Tooltip(
          message: t.fileView.columns.configure,
          child: Container(
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              MyExplorerIconsRegular.slidersHorizontal,
              size: 14,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDelta;

  const _ColumnResizeHandle({required this.onDelta});

  @override
  State<_ColumnResizeHandle> createState() => _ColumnResizeHandleState();
}

class _ColumnResizeHandleState extends State<_ColumnResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _dragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) => widget.onDelta(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: Center(
          child: Container(
            width: active ? 2 : 1,
            height: double.infinity,
            color: active ? AppColors.accent : AppColors.borderColor,
          ),
        ),
      ),
    );
  }
}

/// Popup that lets the user toggle optional file-list columns on/off and
/// reorder them by dragging, mirroring the sidebar edit-mode interaction.
class _ColumnConfigMenu extends StatelessWidget {
  const _ColumnConfigMenu();

  void _reorder(int oldIndex, int newIndex) {
    final cols = orderedColumns();
    if (oldIndex < 0 || oldIndex >= cols.length) return;
    var to = newIndex.clamp(0, cols.length - 1);
    if (to == oldIndex) return;
    final moved = cols.removeAt(oldIndex);
    cols.insert(to, moved);
    SettingsStore.instance.columnOrder.value = columnOrderToString(cols);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
color: AppColors.shadowSubtle,
blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SignalBuilder(
            builder: (context) {
              final cols = orderedColumns();

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: cols.length,
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final col = cols[index];

                  return _ColumnConfigRow(
                    key: ValueKey(col),
                    col: col,
                    index: index,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColumnConfigRow extends StatefulWidget {
  final FileColumn col;
  final int index;

  const _ColumnConfigRow({super.key, required this.col, required this.index});

  @override
  State<_ColumnConfigRow> createState() => _ColumnConfigRowState();
}

class _ColumnConfigRowState extends State<_ColumnConfigRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final signal = fileColumnSignal(widget.col);
    final visible = signal.value;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => signal.value = !signal.value,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(
                    MyExplorerIconsRegular.list,
                    size: 14,
                    color: AppColors.fgSubtle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileColumnLabel(widget.col),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.body.copyWith(
                    color: visible ? AppColors.fg : AppColors.fgMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ColumnCheckbox(value: visible),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnCheckbox extends StatelessWidget {
  final bool value;

  const _ColumnCheckbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: value ? AppColors.accent : AppColors.borderColor,
          width: 1,
        ),
      ),
      child: value
          ? Icon(MyExplorerIconsRegular.check, size: 10, color: AppColors.bg)
          : null,
    );
  }
}
