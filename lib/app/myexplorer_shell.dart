import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:myexplorer/ui/icons/myexplorer_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../core/archive/archive_path.dart';
import '../core/archive/archive_writer.dart';
import '../core/fs/file_system_service.dart';
import '../core/fs/recursive_search.dart';
import '../core/logging/app_logger.dart';
import '../features/files/sort_menu.dart';
import '../features/locations/location_resolver.dart';
import '../core/open/open_service.dart';
import '../core/keyboard/keyboard_shortcuts.dart';
import '../core/platform/platform_paths.dart';
import '../core/models/app_notification.dart';
import '../core/models/file_entry.dart';
import '../core/models/file_operation.dart';
import '../core/settings/settings_store.dart';
import '../features/containers/wsl_path.dart';
import '../features/checksum/checksum_dialog.dart';
import '../features/checksum/checksum_manifest_dialog.dart';
import '../features/command_palette/app_command.dart';
import '../features/command_palette/command_palette_launcher.dart';
import '../features/command_palette/command_palette_view.dart';
import '../features/command_palette/command_usage_store.dart';
import '../features/compare/compare_mode_bar.dart';
import '../features/drives/drive_store.dart';
import '../features/help/help_dialog.dart';
import '../features/navigation/bookmark_store.dart';
import '../features/hidden/hidden_list_store.dart';
import '../features/navigation/navigation_store.dart';
import '../features/navigation/shortcut_bar_store.dart';
import '../features/navigation/shortcut_runner.dart';
import '../features/navigation/sidebar.dart';
import '../features/navigation/status_bar.dart';
import '../features/operations/operation_store.dart';
import '../features/operations/split_dialog.dart';
import '../features/operations/duplicate_dialog.dart';
import '../features/panes/pane_view.dart';
import '../features/panes/pane_divider.dart';
import '../features/panes/center_shortcut_bar.dart';
import '../features/panes/shell_store.dart';
import '../features/plugins/plugin_bar.dart';
import '../features/plugins/plugin_form_dialog.dart';
import '../features/plugins/plugin_icons.dart';
import '../features/plugins/plugin_models.dart';
import '../features/plugins/plugin_settings_store.dart';
import '../features/plugins/plugin_store.dart';
import '../features/settings/keybinding_labels.dart';
import '../features/settings/preferences_view.dart';
import '../i18n/strings.g.dart';
import '../ui/chrome/title_bar.dart';
import '../ui/dialogs/compress_dialog.dart';
import '../ui/dialogs/dialog.dart';
import '../ui/dialogs/hidden_list_dialog.dart';
import '../ui/dialogs/color_rules_dialog.dart';
import '../ui/dialogs/multi_rename_dialog.dart';
import '../ui/dialogs/open_with_dialog.dart';
import '../ui/overlays/context_menu.dart';
import '../ui/overlays/notification_overlay.dart';
import '../ui/widgets/app_text_field.dart';
import '../features/navigation/select_pattern_dialog.dart';
import '../features/quick_look/quick_look.dart';
import '../features/quick_look/quick_view_panel.dart';
import '../ui/overlays/notification_store.dart';
import '../ui/overlays/toast.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/app_text_styles.dart';
import '../ui/window/window.dart';

part 'myexplorer_shell/base.dart';
part 'myexplorer_shell/actions.dart';
part 'myexplorer_shell/menus.dart';
part 'myexplorer_shell/menus_plugin.dart';
part 'myexplorer_shell/command_palette.dart';
part 'myexplorer_shell/keyboard.dart';

class MyExplorerShell extends StatefulWidget {
  const MyExplorerShell({super.key});

  @override
  State<MyExplorerShell> createState() => _MyExplorerShellState();
}

class _MyExplorerShellState extends State<MyExplorerShell>
    with
        _MyExplorerStateBase,
        _MyExplorerActionsMixin,
        _MyExplorerPluginMixin,
        _MyExplorerMenuMixin,
        _MyExplorerCommandPaletteMixin,
        _MyExplorerKeyboardMixin {
  @override
  void initState() {
    super.initState();
    _operationStore.confirmTransfer = _confirmTransfer;
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        final completedId = _operationStore.taskCompleted.value;
        if (completedId != null) {
          _operationStore.taskCompleted.value = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final tasks = _operationStore.tasks.value;
            FileTask? task;
            for (final t in tasks) {
              if (t.id == completedId) {
                task = t;
                break;
              }
            }
            if (task == null) return;
            final destLogical = LocationResolver.physicalToLogical(
              task.destination ?? '',
            );
            for (final store in _shell.allStores) {
              final cp = store.currentPath.value;
              final destMatches = task.destination == cp || destLogical == cp;
              final isTrashTask =
                  task.type == TaskType.trashRestore ||
                  task.type == TaskType.trashDelete;
              final isRemoval =
                  task.type == TaskType.move ||
                  task.type == TaskType.delete ||
                  task.type == TaskType.trash;
              final treeRefreshTargets = <String>{};
              final destination = task.destination;
              if (destination != null && destination.isNotEmpty) {
                treeRefreshTargets.add(destination);
                if (destLogical != null) treeRefreshTargets.add(destLogical);
              }
              final removalMatches =
                  isRemoval &&
                  task.sources.any((s) {
                    final d = p.dirname(s);
                    final logical = LocationResolver.physicalToLogical(d);
                    treeRefreshTargets.add(d);
                    if (logical != null) treeRefreshTargets.add(logical);

                    return d == cp || logical == cp;
                  });
              if (destMatches ||
                  (isTrashTask && store.isTrashView) ||
                  removalMatches) {
                store.refresh();
              }
              for (final target in treeRefreshTargets) {
                if (target != cp) unawaited(store.refreshTreePath(target));
              }
            }
            if (task.errors.isNotEmpty &&
                (task.status == TaskStatus.completed ||
                    task.status == TaskStatus.failed)) {
              final label = TaskLabel.title(task);
              showToast(
                context: context,
                message: t.toast.taskErrors(
                  label: label,
                  count: task.errors.length,
                ),
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
      }),
    );
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        if (!isWindowChromeSupported) return;
        final pane = _shell.activePane.value;
        if (pane == null) {
          appWindow.title = t.app.title;

          return;
        }
        final title = pane.tabs.activeTab.value.title.value;
        appWindow.title = '$title - ${t.app.title}';
      }),
    );
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        final active = _active.searchActive.value;
        if (!active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_isEditableFocused()) return;
            _focusNode.requestFocus();
          });
        }
      }),
    );
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        _shell.panes.value;
        _installRenameErrorEffects();
      }),
    );
    _installPluginEventEffects();
    CommandPaletteLauncher.instance.open = _openCommandPalette;
  }

  @override
  void dispose() {
    if (CommandPaletteLauncher.instance.open == _openCommandPalette) {
      CommandPaletteLauncher.instance.open = null;
    }
    for (final d in _effectDisposers) {
      d();
    }
    _effectDisposers.clear();
    for (final d in _renameErrorDisposers.values) {
      d();
    }
    _renameErrorDisposers.clear();
    for (final d in _renameFocusDisposers.values) {
      d();
    }
    _renameFocusDisposers.clear();
    _navEventTimer?.cancel();
    _selectionEventTimer?.cancel();
    _focusNode.dispose();
    _notificationStore.dispose();
    _shell.dispose();
    _operationStore.dispose();
    super.dispose();
  }

  Widget _buildPane(
    int slot, {
    required bool isActive,
    required VoidCallback onActivate,
    required bool isSingleMode,
  }) {
    return PaneView(
      pane: _shell.panes.value[slot],
      isSingleMode: isSingleMode,
      isActive: isActive,
      onActivate: onActivate,
      onBackgroundContextMenu: _handleBackgroundContextMenu,
      onContextMenu: _handleContextMenu,
      onMenuAction: _handleMenuAction,
      onOpenInNewTab: _openInNewTab,
      onPluginToolbarAction: (id) => _runPluginAction(id, background: true),
      onPluginBarEffects: (effects, target) =>
          _applyPluginEffects(effects, target, background: true),
    );
  }

  /// Wraps a pane with its optional quick view panel (Ctrl+Q). The panel
  /// previews the *other* pane's cursor entry and sits at the bottom of this
  /// pane; the file view keeps the top portion.
  Widget _buildPaneWithQuickView(
    int slot, {
    required bool isActive,
    required VoidCallback onActivate,
  }) {
    final showQuickView = _shell.quickViewVisible.value[slot];
    if (!showQuickView) {
      return _buildPane(
        slot,
        isActive: isActive,
        onActivate: onActivate,
        isSingleMode: false,
      );
    }
    final otherSlot = slot ^ 1;
    final panes = _shell.panes.value;
    if (otherSlot >= panes.length) {
      return _buildPane(
        slot,
        isActive: isActive,
        onActivate: onActivate,
        isSingleMode: false,
      );
    }
    final source = panes[otherSlot].tabs.activeTab.value.store;

    return Column(
      children: [
        Expanded(
          child: _buildPane(
            slot,
            isActive: isActive,
            onActivate: onActivate,
            isSingleMode: false,
          ),
        ),
        SizedBox(
          height: 240,
          child: QuickViewPanel(
            source: source,
            onClose: () => _shell.toggleQuickView(slot),
          ),
        ),
      ],
    );
  }

  Widget _buildPaneArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SignalBuilder(
          builder: (_) {
            // Establish reactive dependency on view mode so the center
            // shortcut bar's tree/list/grid active indicators update.
            SettingsStore.instance.fileViewMode.value;
            final activeIdx = _shell.activePaneIndex.value;
            final ratio = _shell.splitRatio.value;
            final leftWidth = constraints.maxWidth * ratio;
            final barWidth = CenterShortcutBar.barWidth;
            final leftPaneWidth = leftWidth - barWidth / 2;

            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: leftPaneWidth,
                  child: _buildPaneWithQuickView(
                    0,
                    isActive: activeIdx == 0,
                    onActivate: _activatePane(0),
                  ),
                ),
                Positioned(
                  left: leftWidth + barWidth / 2,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildPaneWithQuickView(
                    1,
                    isActive: activeIdx == 1,
                    onActivate: _activatePane(1),
                  ),
                ),
                Positioned(
                  left: leftWidth - barWidth / 2,
                  top: 0,
                  bottom: 0,
                  width: barWidth,
                  child: CenterShortcutBar(
                    buttons: _buildCenterShortcutButtons(),
                  ),
                ),
                Positioned(
                  left: leftWidth + barWidth / 2 - PaneDivider.hitWidth / 2,
                  top: 0,
                  bottom: 0,
                  child: PaneDivider(
                    shell: _shell,
                    totalWidth: constraints.maxWidth,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<CenterShortcutButton> _buildCenterShortcutButtons() {
    final store = _active;
    final viewMode = SettingsStore.instance.fileViewMode;

    return [
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.fileTxt,
        tooltip: t.quickLook.title,
        onTap: _openQuickLook,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.file,
        tooltip: t.toolbar.newFile,
        onTap: () => store.startCreate(type: FileItemType.file),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.folderPlus,
        tooltip: t.toolbar.newFolder,
        onTap: store.startCreate,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.copy,
        tooltip: t.menu.copyToOtherPane,
        onTap: () => _dualPaneTransfer(store, move: false),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.arrowRight,
        tooltip: t.menu.moveToOtherPane,
        onTap: () => _dualPaneTransfer(store, move: true),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.trash,
        tooltip: t.menu.delete,
        onTap: _confirmAndDelete,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.clipboard,
        tooltip: t.toolbar.copyNames,
        onTap: store.copySelectedNames,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.folder,
        tooltip: t.toolbar.copyParentPath,
        onTap: store.copySelectedParentPaths,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.arrowSquareOut,
        tooltip: t.toolbar.copyFullPath,
        onTap: store.copySelectedPaths,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.textAa,
        tooltip: t.toolbar.copyDetails,
        onTap: store.copySelectedDetails,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.treeStructure,
        tooltip: t.toolbar.treeView,
        isActive: () => viewMode.value == 'tree',
        onTap: _setTreeView,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.list,
        tooltip: t.toolbar.listView,
        isActive: () => viewMode.value == 'list',
        onTap: _setListView,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.squaresFour,
        tooltip: t.toolbar.gridView,
        isActive: () => viewMode.value == 'grid',
        onTap: _setGridView,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.selectionAll,
        tooltip: t.menu.selectGroup,
        onTap: () => _openSelectPattern(),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.prohibit,
        tooltip: t.menu.deselectGroup,
        onTap: () => _openSelectPattern(deselect: true),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.arrowsLeftRight,
        tooltip: t.menu.invertSelection,
        onTap: store.invertSelection,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.magnifyingGlass,
        tooltip: t.toolbar.search,
        isActive: () => store.searchActive.value,
        onTap: () =>
            store.searchActive.value ? store.closeSearch() : store.openSearch(),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.arrowsClockwise,
        tooltip: t.toolbar.sync,
        isActive: () => _shell.compare.active.value,
        onTap: () => _shell.compare.toggle(),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.pencilSimple,
        tooltip: t.menu.multiRename,
        onTap: () => _multiRename(store),
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.eye,
        tooltip: t.menu.showHidden,
        isActive: () => SettingsStore.instance.showHiddenDefault.value,
        onTap: _toggleShowHiddenGlobal,
      ),
      CenterShortcutButton(
        icon: MyExplorerIconsRegular.info,
        tooltip: t.menu.properties,
        onTap: () => _openPropertiesFromMenu(store),
      ),
    ];
  }

  void _setTreeView() {
    SettingsStore.instance.fileViewMode.value = 'tree';
  }

  void _setListView() {
    SettingsStore.instance.fileViewMode.value = 'list';
  }

  void _setGridView() {
    SettingsStore.instance.fileViewMode.value = 'grid';
  }

  Map<String, dynamic> _pluginBarContext(
    NavigationStore store, {
    required String scope,
    int? pane,
    bool isActive = true,
  }) {
    final paths = store.selectedPaths.value.toList()..sort();

    return {
      'scope': scope,
      'pane': pane,
      'is_active': isActive,
      'dir': store.currentPath.value,
      'paths': paths,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            SignalBuilder(
              builder: (_) {
                if (_shell.ready.value) {
                  _active.selectedCount.value;
                  _active.visibleFiles.value.length;
                }

                return TitleBar(
                  menuTrailing: _buildViewMenu(),
                  pluginContributions: PluginStore.instance
                      .menubarContributions(),
                  onPluginAction: _runPluginAction,
                  onShortcutAction: _handleShortcutAction,
                  child: SignalBuilder(
                    builder: (context) {
                      if (!_shell.ready.value) {
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

                      return Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _SidebarHost(
                                  active: _active,
                                  operationStore: _operationStore,
                                  onOpenInNewTab: _openInNewTab,
                                ),
                                Expanded(child: _buildPaneArea()),
                              ],
                            ),
                          ),
                          SignalBuilder(
                            builder: (context) {
                              final bars = PluginStore.instance
                                  .globalBarContributions();

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (bars.isNotEmpty)
                                    Builder(
                                      builder: (context) {
                                        final ctx = _pluginBarContext(
                                          _active,
                                          scope: 'global',
                                        );

                                        return PluginBarHost(
                                          hostId: 'global',
                                          bars: bars,
                                          contextData: ctx,
                                          contextKey: jsonEncode(ctx),
                                          onEffects: (effects, target) =>
                                              _applyPluginEffects(
                                                effects,
                                                target,
                                                background: true,
                                              ),
                                        );
                                      },
                                    ),
                                  CompareModeBar(controller: _shell.compare),
                                ],
                              );
                            },
                          ),
                          SignalBuilder(
                            builder: (context) => StatusBar(
                              store: _active,
                              operationStore: _operationStore,
                              notificationStore: _notificationStore,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            NotificationOverlay(store: _notificationStore),
          ],
        ),
      ),
    );
  }
}

class _SidebarHost extends StatefulWidget {
  final NavigationStore active;
  final OperationStore operationStore;
  final void Function(String path) onOpenInNewTab;

  const _SidebarHost({
    required this.active,
    required this.operationStore,
    required this.onOpenInNewTab,
  });

  @override
  State<_SidebarHost> createState() => _SidebarHostState();
}

class _SidebarHostState extends State<_SidebarHost> {
  static const _railWidth = 52.0;
  static const _minExpanded = 160.0;
  static const _maxExpanded = 400.0;

  /// Drag the expanded sidebar narrower than this and it snaps to the icon rail.
  static const _collapseThreshold = 120.0;
  static const _animDuration = Duration(milliseconds: 140);

  double? _dragWidth;
  bool _dragging = false;

  void _toggleUserCollapsed() {
    final s = SettingsStore.instance.sidebarCollapsed;
    s.value = !s.value;
  }

  void _onDragStart(DragStartDetails _) {
    final settings = SettingsStore.instance;
    _dragWidth = settings.sidebarCollapsed.value
        ? _railWidth
        : settings.sidebarWidth.value.clamp(_minExpanded, _maxExpanded);
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final settings = SettingsStore.instance;
    final next = ((_dragWidth ?? _railWidth) + details.delta.dx).clamp(
      _railWidth,
      _maxExpanded,
    );

    final shouldCollapse = next < _collapseThreshold;
    if (settings.sidebarCollapsed.value != shouldCollapse) {
      settings.sidebarCollapsed.value = shouldCollapse;
    }
    if (!shouldCollapse) {
      settings.sidebarWidth.value = next.clamp(_minExpanded, _maxExpanded);
    }
    setState(() => _dragWidth = next);
  }

  void _onDragEnd() {
    setState(() {
      _dragging = false;
      _dragWidth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final settings = SettingsStore.instance;
        final collapsed = settings.sidebarCollapsed.value;
        final width =
            _dragWidth ??
            (collapsed
                ? _railWidth
                : settings.sidebarWidth.value.clamp(
                    _minExpanded,
                    _maxExpanded,
                  ));

        return AnimatedContainer(
          duration: _dragging ? Duration.zero : _animDuration,
          curve: Curves.easeOut,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: Sidebar(
                    store: widget.active,
                    operationStore: widget.operationStore,
                    onOpenInNewTab: widget.onOpenInNewTab,
                    collapsed: collapsed,
                    onToggleCollapsed: _toggleUserCollapsed,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: _SidebarResizeHandle(
                  onDragStart: _onDragStart,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: _onDragEnd,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarResizeHandle extends StatefulWidget {
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  const _SidebarResizeHandle({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: widget.onDragStart,
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: (_) => widget.onDragEnd(),
        onHorizontalDragCancel: widget.onDragEnd,
        child: SizedBox(
          width: 8,
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _hovered ? 2 : 1,
              color: _hovered ? AppColors.accent : AppColors.bgDivider,
            ),
          ),
        ),
      ),
    );
  }
}
