part of '../myexplorer_shell.dart';

/// Context-menu and top-bar menu construction plus action dispatch. Plugin
/// execution lives in `_MyExplorerPluginMixin` (menus_plugin.dart); this mixin
/// only builds menu items and delegates actions to the plugin domain.
mixin _MyExplorerMenuMixin
    on
        State<MyExplorerShell>,
        _MyExplorerStateBase,
        _MyExplorerActionsMixin,
        _MyExplorerTerminalMixin,
        _MyExplorerPluginMixin {
  Future<void> _handleBackgroundContextMenu(Offset position) async {
    final store = _active;
    if (store.isTrashView) {
      showContextMenu(
        context: context,
        position: position,
        items: [
          ContextMenuItem(
            icon: MyExplorerIconsRegular.arrowClockwise,
            label: t.toolbar.refresh,
            action: 'refresh',
          ),
          ContextMenuItem(
            icon: MyExplorerIconsRegular.selectionAll,
            label: t.menu.selectAll,
            action: 'select_all',
          ),
        ],
        onSelect: _handleBackgroundMenuAction,
      );

      return;
    }
    final canPaste = await store.hasPasteableFiles();
    if (!mounted) return;
    final items = <ContextMenuItem>[
      if (canPaste) ...[
        ContextMenuItem(
          icon: MyExplorerIconsRegular.clipboard,
          label: t.menu.paste,
          action: 'paste',
        ),
        ContextMenuItem.divider,
      ],
      ContextMenuItem(
        icon: MyExplorerIconsRegular.terminal,
        label: t.menu.openInTerminal,
        action: 'open_in_terminal',
      ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.folderPlus,
        label: t.toolbar.newFolder,
        action: 'new_folder',
      ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.arrowClockwise,
        label: t.toolbar.refresh,
        action: 'refresh',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: MyExplorerIconsRegular.selectionAll,
        label: t.menu.selectAll,
        action: 'select_all',
      ),
      ContextMenuItem.divider,
      sortMenuParent(store),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: MyExplorerIconsRegular.info,
        label: t.menu.properties,
        action: 'properties',
      ),
    ];

    final pluginItems = _backgroundPluginItems();
    if (pluginItems.isNotEmpty) {
      items.add(ContextMenuItem.divider);
      items.addAll(pluginItems);
    }

    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: _handleBackgroundMenuAction,
    );
  }

  void _handleBackgroundMenuAction(String action) {
    final store = _active;
    if (action.startsWith('plugin:')) {
      _runPluginAction(action, background: true);

      return;
    }
    if (handleSortMenuAction(store, action)) return;
    switch (action) {
      case 'paste':
        store.paste();
      case 'new_folder':
        store.startCreate();
      case 'refresh':
        store.refresh();
      case 'select_all':
        store.selectAll();
      case 'open_in_terminal':
        _openInTerminal(store.currentPath.value);
      case 'properties':
        _openFolderProperties(store.currentPath.value);
    }
  }

  Future<void> _handleContextMenu(
    FileSelectionEvent event,
    Offset position,
  ) async {
    final store = _active;
    store.onContextMenu(event);

    final entries = store.selectedEntries;
    final count = entries.length;
    final isSingleFolder =
        count == 1 && entries.first.type == FileItemType.folder;
    final isSingleFile = count == 1 && entries.first.type == FileItemType.file;
    final hasNetworkPath = entries.any(
      (entry) => PlatformPaths.isNetworkPath(entry.realPath),
    );
    final canVerifyChecksum =
        isSingleFile &&
        !PlatformPaths.isRemoteUri(entries.first.realPath) &&
        !FileSystemService.isInsideArchive(entries.first.realPath);
    final canCreateManifest =
        entries.isNotEmpty &&
        entries.every(
          (e) =>
              e.type == FileItemType.file &&
              !PlatformPaths.isRemoteUri(e.realPath) &&
              !PlatformPaths.isNetworkPath(e.realPath) &&
              !FileSystemService.isInsideArchive(e.realPath),
        );
    final canVerifyManifest =
        isSingleFile && isChecksumManifestPath(entries.first.realPath);
    final canSplit =
        entries.isNotEmpty &&
        entries.every(
          (e) =>
              e.type == FileItemType.file &&
              !PlatformPaths.isRemoteUri(e.realPath) &&
              !PlatformPaths.isNetworkPath(e.realPath) &&
              !FileSystemService.isInsideArchive(e.realPath),
        );
    final canCombine = isSingleFile && isSplitPartPath(entries.first.realPath);
    final isRecursive = store.searchActive.value && store.searchRecursive.value;
    final canTag = entries.every(
      (e) =>
          !PlatformPaths.isRemoteUri(e.path) &&
          !PlatformPaths.isNetworkPath(e.path) &&
          !FileSystemService.isInsideArchive(e.realPath),
    );
    final canHide =
        entries.isNotEmpty &&
        entries.every(
          (e) =>
              !PlatformPaths.isRemoteUri(e.path) &&
              !PlatformPaths.isNetworkPath(e.path) &&
              !FileSystemService.isInsideArchive(e.realPath),
        );

    final openWithItems = isSingleFile
        ? _openWithItemsFor(entries.first)
        : const <ContextMenuItem>[];

    final archiveEntries = entries
        .where(
          (e) =>
              e.type == FileItemType.file &&
              ArchivePath.isArchiveName(e.name) &&
              !FileSystemService.isInsideArchive(e.path),
        )
        .toList();
    final canExtract =
        archiveEntries.isNotEmpty && archiveEntries.length == count;
    final canCompress =
        entries.isNotEmpty &&
        entries.every((e) => !FileSystemService.isInsideArchive(e.path));
    final compressBase = count == 1
        ? (entries.first.type == FileItemType.folder
              ? entries.first.name
              : p.basenameWithoutExtension(entries.first.name))
        : _sanitizeArchiveBase(
            p.basename(store.currentPath.value),
            store.currentPath.value,
          );
    final compressItem = canCompress
        ? ContextMenuItem(
            icon: MyExplorerIconsRegular.fileZip,
            label: t.menu.compress,
            action: 'compress',
            children: [
              ContextMenuItem(
                icon: MyExplorerIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.zip'),
                action: 'compress_zip',
              ),
              ContextMenuItem(
                icon: MyExplorerIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.tar.gz'),
                action: 'compress_targz',
              ),
              ContextMenuItem.divider,
              ContextMenuItem(
                icon: MyExplorerIconsRegular.slidersHorizontal,
                label: t.menu.compressOptions,
                action: 'compress_options',
              ),
            ],
          )
        : null;

    final extractItem = canExtract
        ? ContextMenuItem(
            icon: MyExplorerIconsRegular.archive,
            label: t.menu.extract,
            action: 'extract',
            children: [
              ContextMenuItem(
                icon: MyExplorerIconsRegular.arrowLineDown,
                label: t.menu.extractHere,
                action: 'extract_here',
              ),
              ContextMenuItem(
                icon: MyExplorerIconsRegular.folderPlus,
                label: count == 1
                    ? t.menu.extractToFolder(
                        name: FileSystemService.archiveBaseName(
                          archiveEntries.first.name,
                        ),
                      )
                    : t.menu.extractEach,
                action: 'extract_to_folder',
              ),
            ],
          )
        : null;

    if (store.isTrashView) {
      final binItems = <ContextMenuItem>[
        if (store.canRestoreFromTrash)
          ContextMenuItem(
            icon: MyExplorerIconsRegular.arrowCounterClockwise,
            label: count == 1
                ? t.menu.restore
                : t.menu.restoreItems(count: count),
            action: 'restore',
          ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.trash,
          label: count == 1
              ? t.menu.deletePermanently
              : t.menu.deletePermanentlyItems(count: count),
          action: 'delete_permanent_bin',
          danger: true,
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ];
      showContextMenu(
        context: context,
        position: position,
        items: binItems,
        onSelect: _handleMenuAction,
      );

      return;
    }

    final items = <ContextMenuItem>[
      if (count == 1 && !isSingleFile)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.folderOpen,
          label: t.menu.open,
          action: 'open',
        ),
      ...openWithItems,
      ?extractItem,
      ?compressItem,
      if ((isRecursive || store.isTagView) && count == 1)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.arrowSquareOut,
          label: t.menu.openLocation,
          action: 'open_location',
        ),
      if (isSingleFolder) ...[
        ContextMenuItem(
          icon: MyExplorerIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.terminal,
          label: t.menu.openInTerminal,
          action: 'open_in_terminal',
        ),
      ],
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: MyExplorerIconsRegular.copy,
        label: t.menu.copy,
        action: 'copy',
      ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.scissors,
        label: t.menu.cut,
        action: 'cut',
      ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.copy,
        label: t.menu.duplicate,
        action: 'duplicate',
        shortcut: AppShortcuts.getById('duplicate').displayKeys,
      ),
      if (count == 1) ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
      if (canVerifyChecksum)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.checkSquare,
          label: t.menu.verifyChecksum,
          action: 'verify_checksum',
        ),
      if (canVerifyManifest)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.checkSquare,
          label: t.menu.verifyChecksumManifest,
          action: 'verify_checksum_manifest',
        ),
      if (canCreateManifest)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.pencilSimple,
          label: t.menu.createChecksumManifest,
          action: 'create_checksum_manifest',
        ),
      if (canSplit)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.scissors,
          label: t.menu.splitFile,
          action: 'split_file',
        ),
      if (canCombine)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.copy,
          label: t.menu.combineParts,
          action: 'combine_parts',
        ),
      if (count >= 1 && canTag) _tagsSubmenu(entries),
      if (canHide) ...[
        ContextMenuItem(
          icon: MyExplorerIconsRegular.prohibit,
          label: t.menu.hideSelected,
          action: 'hide_selected',
        ),
      ],
      ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.pencilSimple,
          label: t.menu.rename,
          action: 'rename',
          shortcut: AppShortcuts.getById('rename').displayKeys,
        ),
      if (count >= 2)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.pencilSimple,
          label: t.menu.multiRename,
          action: 'multi_rename',
        ),
      if (!hasNetworkPath)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.trashSimple,
          label: count == 1
              ? t.menu.moveToTrash
              : t.menu.moveToTrashItems(count: count),
          action: 'trash',
        ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.trash,
        label: count == 1
            ? t.menu.deletePermanently
            : t.menu.deletePermanentlyItems(count: count),
        action: 'delete_permanent',
        danger: true,
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: MyExplorerIconsRegular.info,
        label: t.menu.properties,
        action: 'properties',
      ),
    ];

    final pluginItems = _pluginContextItems(entries);
    if (pluginItems.isNotEmpty) {
      items.add(ContextMenuItem.divider);
      items.addAll(pluginItems);
    }

    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: _handleMenuAction,
    );
  }

  ContextMenuItem _tagsSubmenu(List<FileEntry> entries) {
    final paths = [for (final e in entries) e.path];

    return ContextMenuItem(
      icon: MyExplorerIconsRegular.bookmarkSimple,
      label: t.tags.menuLabel,
      action: 'tags',
      children: [
        for (final tag in TagStore.instance.tags.value)
          ContextMenuItem(
            icon: MyExplorerIconsRegular.bookmarkSimple,
            leading: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            label: tag.name,
            action: 'tag_toggle:${tag.id}',
            isToggle: true,
            toggleSignal: computed(() {
              final assigned = _active.fileTags.value;

              return paths.isNotEmpty &&
                  paths.every((p) => assigned[p]?.contains(tag.id) ?? false);
            }),
          ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.plus,
          label: t.tags.newTagDots,
          action: 'tag_new',
        ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.x,
          label: t.tags.clear,
          action: 'tag_clear',
        ),
      ],
    );
  }

  ContextMenuItem get _openItem => ContextMenuItem(
    icon: MyExplorerIconsRegular.folderOpen,
    label: t.menu.open,
    action: 'open',
  );

  ContextMenuItem get _chooserItem => ContextMenuItem(
    icon: MyExplorerIconsRegular.dotsThreeOutline,
    label: t.menu.openWithChoose,
    action: 'open_with_choose',
  );

  /// Returns the "Open / Open with" items synchronously so the context menu
  /// can be shown immediately. The preferred-app lookup is resolved off the
  /// menu path and cached per extension; the first menu for a given type
  /// shows the generic items, subsequent ones show the resolved default app.
  List<ContextMenuItem> _openWithItemsFor(FileEntry entry) {
    _openWithEntry = entry;

    if (PlatformPaths.isWindows) {
      return [
        _openItem,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.dotsThreeOutline,
          label: t.menu.openWithChoose,
          action: 'open_with_system',
        ),
      ];
    }

    final key = entry.extension.toLowerCase();
    final cached = _openWithCache[key];
    if (cached != null) return cached;
    _warmOpenWith(entry.realPath, key);

    return [_openItem, _chooserItem];
  }

  Future<void> _warmOpenWith(String path, String key) async {
    if (!_openWithWarming.add(key)) return;
    try {
      final options = await OpenService.optionsFor(path);
      final preferred = options.defaultApp;
      _openWithCache[key] = preferred == null
          ? [_openItem, _chooserItem]
          : [
              ContextMenuItem(
                icon: MyExplorerIconsRegular.appWindow,
                label: t.menu.openWithApp(app: preferred.name),
                action: 'open',
                iconPath: preferred.iconPath,
              ),
              _chooserItem,
            ];
    } catch (e, st) {
      log.warn(
        'open-with',
        'failed to warm open-with menu',
        error: e,
        stack: st,
      );
    } finally {
      _openWithWarming.remove(key);
    }
  }

  void _handleMenuAction(String action) {
    final store = _active;
    if (action.startsWith('tag_toggle:')) {
      final id = int.tryParse(action.substring('tag_toggle:'.length));
      if (id != null) {
        final paths = [for (final e in store.selectedEntries) e.path];
        store.toggleTag(paths, id);
      }

      return;
    }
    if (action == 'tag_clear') {
      final paths = [for (final e in store.selectedEntries) e.path];
      store.clearTags(paths);

      return;
    }
    if (action == 'tag_new') {
      final paths = [for (final e in store.selectedEntries) e.path];
      showTagEditDialog(context).then((created) {
        if (!mounted) return;
        _restoreFocus();
        if (created && paths.isNotEmpty) {
          final newest = TagStore.instance.tags.value.lastOrNull;
          if (newest != null) store.toggleTag(paths, newest.id);
        }
      });

      return;
    }
    switch (action) {
      case 'open':
        store.openSelected();
      case 'open_with_choose':
        final entry = _openWithEntry;
        if (entry != null) {
          showOpenWithDialog(
            context: context,
            entry: entry,
          ).then((_) => _restoreFocus());
        }
      case 'open_with_system':
        final entry = _openWithEntry;
        if (entry != null) {
          OpenService.systemOpenWithDialog(entry.realPath);
        }
      case 'copy':
        store.copySelected();
        final count = store.selectedPaths.value.length;
        if (count > 0) {
          showToast(
            context: context,
            message: t.toast.copiedItems(count: count),
          );
        }
      case 'cut':
        store.cutSelected();
        final count = store.selectedPaths.value.length;
        if (count > 0) {
          showToast(
            context: context,
            message: t.toast.cutItems(count: count),
          );
        }
      case 'compress_zip':
        _quickCompress(ArchiveFormat.zip);
      case 'compress_targz':
        _quickCompress(ArchiveFormat.tarGz);
      case 'compress_options':
        _compressWithOptions();
      case 'extract_here':
        _extractSelected(toOwnFolder: false);
      case 'extract_to_folder':
        _extractSelected(toOwnFolder: true);
      case 'paste':
        store.paste();
      case 'duplicate':
        unawaited(_duplicateSelected(store));
      case 'copy_path':
        store.copySelectedPaths();
      case 'verify_checksum':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.file) {
          showChecksumDialog(
            context: context,
            entry: entries.first,
          ).then((_) => _restoreFocus());
        }
      case 'verify_checksum_manifest':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.file) {
          showVerifyChecksumManifestDialog(
            context: context,
            manifestPath: entries.first.realPath,
          ).then((_) => _restoreFocus());
        }
      case 'create_checksum_manifest':
        final entries = store.selectedEntries;
        showCreateChecksumManifestDialog(
          context: context,
          entries: entries,
        ).then((_) => _restoreFocus());
      case 'split_file':
        final entries = store.selectedEntries;
        showSplitDialog(
          context: context,
          operationStore: _operationStore,
          entries: entries,
        ).then((_) => _restoreFocus());
      case 'combine_parts':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.file) {
          final parts = siblingParts(entries.first.realPath);
          if (parts.length >= 2) {
            _operationStore.enqueueCombine(parts);
          }
        }
      case 'rename':
        store.startRename();
      case 'multi_rename':
        _multiRename(store);
      case 'trash':
        _confirmAndDelete(forceTrash: true);
      case 'delete_permanent':
        _confirmAndDelete(forcePermanent: true);
      case 'restore':
        store.restoreSelectedFromTrash();
      case 'hide_selected':
        _hideSelectedFromList();
      case 'delete_permanent_bin':
        store.deletePermanentlySelectedFromTrash();
      case 'open_in_terminal':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.folder) {
          _openInTerminal(entries.first.path);
        }
      case 'open_location':
        final entries = store.selectedEntries;
        if (entries.length == 1) {
          store.revealInFolder(entries.first.path);
        }
      case 'open_in_new_tab':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.folder) {
          _shell.activePane.value!.tabs.addTab(entries.first.path);
        }
      case 'properties':
        _openPropertiesFromMenu(store);
      default:
        if (action.startsWith('plugin:')) _runPluginAction(action);
    }
  }

  void _hideSelectedFromList() {
    final store = _active;
    final paths = [for (final e in store.selectedEntries) e.realPath];
    if (paths.isEmpty) return;
    unawaited(() async {
      await HiddenListStore.instance.addPaths(paths);
      await store.refresh();
      if (mounted) _restoreFocus();
    }());
  }

  Widget _buildViewMenu() {
    return SignalBuilder(
      builder: (_) {
        if (!_shell.ready.value) return const SizedBox.shrink();
        final store = _active;
        final selectedCount = store.selectedCount.value;
        final hasVisibleFiles = store.visibleFiles.value.isNotEmpty;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TitleMenuButton(
              label: t.menu.view,
              items: [
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.list,
                  label: t.toolbar.listView,
                  action: 'view_list',
                  toggleSignal: computed(
                    () => SettingsStore.instance.fileViewMode.value == 'list',
                  ),
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.treeStructure,
                  label: t.toolbar.treeView,
                  action: 'view_tree',
                  toggleSignal: computed(
                    () => SettingsStore.instance.fileViewMode.value == 'tree',
                  ),
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.squaresFour,
                  label: t.toolbar.gridView,
                  action: 'view_grid',
                  toggleSignal: computed(
                    () => SettingsStore.instance.fileViewMode.value == 'grid',
                  ),
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.eye,
                  label: t.menu.showHidden,
                  action: 'toggle_hidden',
                  isToggle: true,
                  toggleSignal: SettingsStore.instance.showHiddenDefault,
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.prohibit,
                  label: t.menu.hiddenList,
                  action: 'open_hidden_list',
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.copy,
                  label: t.menu.findDuplicates,
                  action: 'find_duplicates',
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.palette,
                  label: t.menu.colorRules,
                  action: 'color_rules',
                ),
              ],
              onSelect: (action) {
                switch (action) {
                  case 'view_list':
                    SettingsStore.instance.fileViewMode.value = 'list';
                  case 'view_tree':
                    SettingsStore.instance.fileViewMode.value = 'tree';
                  case 'view_grid':
                    SettingsStore.instance.fileViewMode.value = 'grid';
                  case 'toggle_hidden':
                    _toggleShowHiddenGlobal();
                  case 'open_hidden_list':
                    showHiddenListDialog(context);
                  case 'find_duplicates':
                    showDuplicateFinderDialog(
                      context: context,
                      root: _active.currentPath.value,
                      operationStore: _operationStore,
                    );
                  case 'color_rules':
                    showColorRulesDialog(context);
                }
              },
            ),
            TitleMenuButton(
              label: t.keybindings.categories.selection,
              items: [
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.selectionAll,
                  label: t.menu.selectAll,
                  action: 'select_all',
                  shortcut: AppShortcuts.getById('select_all').displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.selectionAll,
                  label: t.menu.selectByPattern,
                  action: 'select_pattern',
                  shortcut: AppShortcuts.getById('select_pattern').displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.selectionAll,
                  label: t.menu.deselectAll,
                  action: 'deselect_all',
                  shortcut: AppShortcuts.getById('deselect_all').displayKeys,
                  enabled: selectedCount > 0,
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.arrowsLeftRight,
                  label: t.menu.invertSelection,
                  action: 'invert_selection',
                  shortcut: AppShortcuts.getById(
                    'invert_selection',
                  ).displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.floppyDisk,
                  label: t.menu.saveSelection,
                  action: 'save_selection',
                  shortcut: AppShortcuts.getById('save_selection').displayKeys,
                  enabled: selectedCount > 0,
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.fileTxt,
                  label: t.menu.loadSelection,
                  action: 'load_selection',
                  shortcut: AppShortcuts.getById('load_selection').displayKeys,
                  enabled: hasVisibleFiles,
                ),
              ],
              onSelect: _handleSelectionMenuAction,
            ),
            TitleMenuButton(
              label: t.keybindings.categories.terminal,
              items: [
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.terminal,
                  label: t.menu.toggleTerminal,
                  action: 'terminal_toggle',
                  shortcut: AppShortcuts.getById('toggle_terminal').displayKeys,
                  isToggle: true,
                  toggleSignal: computed(
                    () =>
                        _shell.ready.value &&
                        _shell
                            .terminalVisible
                            .value[_terminalSlotForActivePane()],
                  ),
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.plus,
                  label: t.menu.newTerminalTab,
                  action: 'terminal_new_tab',
                  shortcut: AppShortcuts.getById(
                    'new_terminal_tab',
                  ).displayKeys,
                ),
                ContextMenuItem(
                  icon: MyExplorerIconsRegular.x,
                  label: t.menu.closeTerminalTab,
                  action: 'terminal_close_tab',
                  shortcut: AppShortcuts.getById(
                    'close_terminal_tab',
                  ).displayKeys,
                ),
              ],
              onSelect: (action) {
                if (!_shell.ready.value) return;
                final slot = _terminalSlotForActivePane();
                switch (action) {
                  case 'terminal_toggle':
                    _toggleTerminalSlot(slot);
                  case 'terminal_new_tab':
                    _newTerminalTab(slot);
                  case 'terminal_close_tab':
                    final tab = _shell.activeTerminalForSlot(slot);
                    if (tab != null) _closeTerminalTab(tab.id);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSelectionMenuAction(String action) {
    final store = _active;
    switch (action) {
      case 'select_all':
        store.selectAll();
      case 'select_pattern':
        _openSelectPattern();
      case 'deselect_all':
        store.deselectAll();
      case 'invert_selection':
        store.invertSelection();
      case 'save_selection':
        _saveSelectionToFile();
      case 'load_selection':
        _loadSelectionFromFile();
    }
  }
}
