part of 'sidebar.dart';

class _EditSection extends StatelessWidget {
  final _SidebarSection section;
  final int sectionIndex;
  final void Function(int oldIndex, int newIndex) onReorderItem;

  const _EditSection({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.onReorderItem,
  });

  @override
  Widget build(BuildContext context) {
    final store = SidebarStore.instance;
    final sectionHidden = store.isSectionHidden(section.id);
    final allowItemHide = section.id != sidebarSectionBookmarks;
    final entries = section.entries;

    return Padding(
      padding: const EdgeInsets.only(bottom: _sectionGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: sectionIndex,
                  child: const _DragHandle(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    section.title.toUpperCase(),
                    style: context.txt.sectionLabel.copyWith(
                      color: sectionHidden ? AppColors.fgSubtle : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _VisibilityToggle(
                  hidden: sectionHidden,
                  onTap: () =>
                      store.setSectionHidden(section.id, !sectionHidden),
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: entries.length,
              onReorder: onReorderItem,
              itemBuilder: (context, index) {
                final entry = entries[index];

                return _EditRow(
                  key: ValueKey('item:${section.id}:${entry.key}'),
                  entry: entry,
                  index: index,
                  scope: section.id,
                  allowHide: allowItemHide,
                  dimmed: sectionHidden,
                  orderedKeys: entries.map((e) => e.key).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final _SidebarEntry entry;
  final int index;
  final String scope;
  final bool allowHide;
  final bool dimmed;
  final List<String> orderedKeys;

  const _EditRow({
    super.key,
    required this.entry,
    required this.index,
    required this.scope,
    required this.allowHide,
    required this.dimmed,
    required this.orderedKeys,
  });

  @override
  Widget build(BuildContext context) {
    final store = SidebarStore.instance;
    final itemHidden = allowHide && store.isItemHidden(scope, entry.key);
    final faded = dimmed || itemHidden;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Opacity(
        opacity: faded ? 0.45 : 1,
        child: Container(
          height: _rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.bgHover.withValues(alpha: 0.4),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const _DragHandle(),
              ),
              const SizedBox(width: 8),
              Icon(entry.item.icon, size: 15, color: AppColors.fgMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.item.label,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.body,
                ),
              ),
              if (allowHide)
                _VisibilityToggle(
                  hidden: itemHidden,
                  onTap: () => store.setItemHidden(
                    scope,
                    entry.key,
                    !itemHidden,
                    orderedKeys,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Icon(
        MyExplorerIconsRegular.list,
        size: 14,
        color: AppColors.fgSubtle,
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool hidden;
  final VoidCallback onTap;

  const _VisibilityToggle({required this.hidden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hidden ? t.sidebar.show : t.sidebar.hide,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              hidden
                  ? MyExplorerIconsRegular.prohibit
                  : MyExplorerIconsRegular.eye,
              size: 14,
              color: hidden ? AppColors.fgSubtle : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
