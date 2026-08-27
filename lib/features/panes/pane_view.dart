import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/settings/settings_store.dart';
import '../../features/files/file_view.dart'
    show
        FileList,
        FileTree,
        OpenInNewTabCallback,
        BackgroundContextMenuCallback,
        FileContextMenuCallback,
        FileMenuActionCallback;
import '../../features/files/file_grid.dart' show FileGrid;
import '../../features/files/rubber_band_layer.dart'
    show RubberBandSelectCallback;
import '../git/git_status_bar.dart';
import '../navigation/navigation_store.dart';
import '../navigation/search_bar_widget.dart';
import '../navigation/toolbar.dart';
import '../plugins/plugin_bar.dart';
import '../plugins/plugin_store.dart';
import '../tabs/tab_strip.dart';
import '../../ui/icons/myexplorer_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';
import 'pane_store.dart';

class PaneView extends StatelessWidget {
  final PaneStore pane;
  final bool isActive;
  final VoidCallback onActivate;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final OpenInNewTabCallback? onOpenInNewTab;
  final void Function(String fullActionId)? onPluginToolbarAction;
  final PluginBarEffectsHandler? onPluginBarEffects;
  final bool isSingleMode;
  final VoidCallback? onReturnFocusToFiles;

  const PaneView({
    super.key,
    required this.pane,
    required this.isActive,
    required this.onActivate,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onOpenInNewTab,
    this.onPluginToolbarAction,
    this.onPluginBarEffects,
    required this.isSingleMode,
    this.onReturnFocusToFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActivate(),
      child: Stack(
        children: [
          Column(
            children: [
              TabStrip(tabsStore: pane.tabs, isActive: isActive),
              SignalBuilder(
                builder: (_) {
                  final tabStore = pane.tabs.activeTab.value.store;

                  return PaneLocationBar(
                    store: tabStore,
                    onPluginAction: onPluginToolbarAction,
                  );
                },
              ),
              SignalBuilder(
                builder: (_) =>
                    pane.tabs.activeTab.value.store.searchActive.value
                    ? AppSearchBar(store: pane.tabs.activeTab.value.store)
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: SignalBuilder(
                  builder: (_) {
                    final idx = pane.tabs.activeIndex.value;
                    final tabs = pane.tabs.tabs.value;

                    return IndexedStack(
                      index: idx,
                      children: [
                        for (final tab in tabs)
                          _TabContent(
                            store: tab.store,
                            onBackgroundContextMenu: onBackgroundContextMenu,
                            onContextMenu: onContextMenu,
                            onMenuAction: onMenuAction,
                            onOpenInNewTab: onOpenInNewTab,
                            onRectSelect: (paths, {additive = false}) => tab
                                .store
                                .onRectSelect(paths, additive: additive),
                          ),
                      ],
                    );
                  },
                ),
              ),
              SignalBuilder(
                builder: (_) {
                  final bars = PluginStore.instance.paneBarContributions();
                  final handler = onPluginBarEffects;
                  if (bars.isEmpty || handler == null) {
                    return const SizedBox.shrink();
                  }
                  final store = pane.tabs.activeTab.value.store;
                  final paths = store.selectedPaths.value.toList()..sort();
                  final ctx = {
                    'scope': 'pane',
                    'is_active': isActive,
                    'dir': store.currentPath.value,
                    'paths': paths,
                  };

                  return PluginBarHost(
                    hostId: 'pane:${pane.hashCode}',
                    bars: bars,
                    contextData: ctx,
                    contextKey:
                        '${store.currentPath.value}|${paths.join('\u0001')}|$isActive',
                    onEffects: handler,
                  );
                },
              ),
              SignalBuilder(
                builder: (_) {
                  final gitStore = pane.tabs.activeTab.value.store.gitStatus;
                  final status = gitStore.status.value;
                  if (status == null) return const SizedBox.shrink();

                  return GitStatusBar(status: status, store: gitStore);
                },
              ),
            ],
          ),
          if (!isActive)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.10)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final NavigationStore store;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final OpenInNewTabCallback? onOpenInNewTab;
  final RubberBandSelectCallback? onRectSelect;

  const _TabContent({
    required this.store,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onOpenInNewTab,
    this.onRectSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (store.isLoading.value) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.fgMuted,
              ),
            ),
          );
        }

        return SignalBuilder(
          builder: (context) {
            if (store.accessDenied.value) {
              return const _AccessDeniedPrompt();
            }
            final loadError = store.loadError.value;
            if (loadError != null) {
              return _LoadErrorNotice(
                message: loadError,
                onRetry: store.refresh,
              );
            }
            final files = store.visibleFiles.value;
            final selected = store.selectedPaths.value;
            final cursorIndex = store.cursorIndex.value;
            final cutPaths = store.clipboardMode.value == ClipboardMode.cut
                ? store.clipboardPaths.value
                : <String>{};
            final currentPath = store.currentPath.value;
            final rowDecorations = store.decorations.byPath.value;
            final recursive =
                store.searchActive.value && store.searchRecursive.value;
            final viewMode = SettingsStore.instance.fileViewMode.value;
            if (viewMode == 'grid') {
              return FileGrid(
                files: files,
                currentPath: currentPath,
                recursiveResults: recursive,
                onSelect: store.onSelect,
                onSecondarySelect: store.addToSelection,
                onOpen: store.onOpen,
                onMenuAction: onMenuAction,
                onBackgroundTap: store.onBackgroundTap,
                onBackgroundContextMenu: onBackgroundContextMenu,
                onContextMenu: onContextMenu,
                onDropFiles: store.dropFiles,
                selectedPaths: selected,
                secondarySelectedPaths: store.secondarySelectedPaths.value,
                cursorIndex: cursorIndex,
                cutPaths: cutPaths,
                renamingPath: store.renamingPath.value,
                renameAttempt: store.renameAttempt.value,
                onRenameSubmit: store.commitRename,
                onRenameCancel: store.cancelRename,
                onCloseSearch: store.closeSearch,
                onOpenInNewTab: onOpenInNewTab,
                onPageRows: store.setPageRows,
                onGridColumns: store.setGridColumns,
                onRectSelect: onRectSelect,
                rowDecorations: rowDecorations,
              );
            }

            if (viewMode == 'tree') {
              return FileTree(
                rows: store.treeRows.value,
                currentPath: currentPath,
                onSelect: store.onSelect,
                onSecondarySelect: store.addToSelection,
                onOpen: store.onOpen,
                onToggleFolder: store.toggleTreeFolder,
                onBackgroundTap: store.onBackgroundTap,
                onBackgroundContextMenu: onBackgroundContextMenu,
                onContextMenu: onContextMenu,
                onMenuAction: onMenuAction,
                onDropFiles: store.dropFiles,
                selectedPaths: selected,
                secondarySelectedPaths: store.secondarySelectedPaths.value,
                cursorIndex: cursorIndex,
                cutPaths: cutPaths,
                renamingPath: store.renamingPath.value,
                renameAttempt: store.renameAttempt.value,
                onRenameSubmit: store.commitRename,
                onRenameCancel: store.cancelRename,
                onCloseSearch: store.closeSearch,
                onOpenInNewTab: onOpenInNewTab,
                onRectSelect: onRectSelect,
                sortColumn: store.sortKey.value,
                sortAscending: store.sortAscending.value,
                onSortColumn: store.cycleSortColumn,
                onPageRows: store.setPageRows,
                folderSizes: store.folderSizes.displaySizes.value,
                rowDecorations: rowDecorations,
              );
            }

            return FileList(
              files: files,
              currentPath: currentPath,
              recursiveResults: recursive,
              onSelect: store.onSelect,
              onSecondarySelect: store.addToSelection,
              onOpen: store.onOpen,
              onBackgroundTap: store.onBackgroundTap,
              onBackgroundContextMenu: onBackgroundContextMenu,
              onContextMenu: onContextMenu,
              onMenuAction: onMenuAction,
              onDropFiles: store.dropFiles,
              selectedPaths: selected,
              secondarySelectedPaths: store.secondarySelectedPaths.value,
              cursorIndex: cursorIndex,
              cutPaths: cutPaths,
              renamingPath: store.renamingPath.value,
              renameAttempt: store.renameAttempt.value,
              onRenameSubmit: store.commitRename,
              onRenameCancel: store.cancelRename,
              onCloseSearch: store.closeSearch,
              onOpenInNewTab: onOpenInNewTab,
              onRectSelect: onRectSelect,
              sortColumn: store.sortKey.value,
              sortAscending: store.sortAscending.value,
              onSortColumn: store.cycleSortColumn,
              onPageRows: store.setPageRows,
              folderSizes: store.folderSizes.displaySizes.value,
              rowDecorations: rowDecorations,
            );
          },
        );
      },
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> actions;

  const _PermissionNotice({
    required this.title,
    required this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MyExplorerIconsRegular.warningCircle,
              size: 48,
              color: AppColors.fgSubtle,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.txt.dialogTitle.copyWith(color: AppColors.fgMuted),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.txt.body.copyWith(
                color: AppColors.fgMuted,
                height: 1.35,
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedPrompt extends StatelessWidget {
  const _AccessDeniedPrompt();

  @override
  Widget build(BuildContext context) {
    return _PermissionNotice(
      title: t.folderAccess.deniedTitle,
      body: t.folderAccess.deniedBody,
      actions: const [],
    );
  }
}

class _LoadErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadErrorNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _PermissionNotice(
      title: t.folderAccess.errorTitle,
      body: message,
      actions: [_PromptButton(label: t.folderAccess.retry, onTap: onRetry)],
    );
  }
}

class _PromptButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptButton({required this.label, required this.onTap});

  @override
  State<_PromptButton> createState() => _PromptButtonState();
}

class _PromptButtonState extends State<_PromptButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovered ? AppColors.accentHover : AppColors.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                MyExplorerIconsRegular.gearSix,
                size: 15,
                color: AppColors.bg,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: context.txt.bodyEmphasis.copyWith(color: AppColors.bg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
