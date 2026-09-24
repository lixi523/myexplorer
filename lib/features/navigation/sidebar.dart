import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myexplorer/ui/icons/myexplorer_icons.dart';
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../core/database/app_database.dart';
import '../../core/logging/app_logger.dart';
import 'bookmark_store.dart';
import 'navigation_store.dart';
import 'sidebar_store.dart';
import '../hidden/hidden_list_store.dart';
import '../drives/drive_store.dart';
import '../drives/drive_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/dialogs/password_dialog.dart';
import '../../ui/dialogs/rename_dialog.dart';
import '../../ui/dialogs/sftp_credentials_dialog.dart';
import '../../ui/overlays/context_menu.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../quick_look/quick_look.dart';
import '../../i18n/strings.g.dart';
import '../../utils/drag_drop.dart';
import '../../utils/format.dart';
import '../locations/connect_to_server_dialog.dart';
import '../locations/location_resolver.dart';
import '../locations/location_uri.dart';
import '../operations/drag_hint.dart';
import '../operations/operation_store.dart';
import '../operations/operations_panel.dart';
import '../../core/models/file_operation.dart';

part 'sidebar_rows.dart';
part 'sidebar_edit.dart';
part 'sidebar_footer.dart';
part 'sidebar_header.dart';
part 'sidebar_operations.dart';

const double _sectionGap = 0;
const double _gutter = 8;
const double _expandedRightGutter = 4;
const double _rowPadH = 10;
const double _rowHeight = 30;
const double _rowHeightWithSpace = 40;
const double _railRowHeight = 34;
const double _iconSize = 16;
const double _iconGap = 10;

class _SidebarItem {
  final String label;
  final IconData icon;
  final String path;
  final String? key;
  const _SidebarItem(this.label, this.icon, this.path, {this.key});
}

/// One row's full rendering inputs, shared by normal and edit-mode rendering.
class _SidebarEntry {
  final String key;
  final _SidebarItem item;
  final bool isSelected;
  final bool isMounted;
  final DriveSpace? space;
  final String? tooltip;
  final ValueChanged<String> onTap;
  final VoidCallback? onMiddleTap;
  final void Function(List<String> paths, {bool move})? onDropFiles;
  final VoidCallback? onUnmount;
  final void Function(Offset position)? onContextMenu;

  const _SidebarEntry({
    required this.key,
    required this.item,
    required this.isSelected,
    this.isMounted = true,
    this.space,
    this.tooltip,
    required this.onTap,
    this.onMiddleTap,
    this.onDropFiles,
    this.onUnmount,
    this.onContextMenu,
  });
}

class _SidebarSection {
  final String id;
  final String title;
  final List<_SidebarEntry> entries;

  const _SidebarSection({
    required this.id,
    required this.title,
    required this.entries,
  });
}

class Sidebar extends StatefulWidget {
  final NavigationStore store;
  final OperationStore operationStore;
  final void Function(String path)? onOpenInNewTab;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  const Sidebar({
    super.key,
    required this.store,
    required this.operationStore,
    this.onOpenInNewTab,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final List<_SidebarItem> _favorites;
  late final Future<SmbCredentials?> Function(String logical)
  _credentialsRequester;
  late final Future<SftpCredentials?> Function(String logical)
  _sftpCredentialsRequester;
  final _bookmarkStore = BookmarkStore.instance;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _credentialsRequester = _requestSmbCredentials;
    _sftpCredentialsRequester = _requestSftpCredentials;
    final h = PlatformPaths.homePath;
    _favorites = [
      _SidebarItem(
        t.sidebar.home,
        MyExplorerIconsRegular.house,
        h,
        key: 'home',
      ),
      _SidebarItem(
        t.sidebar.desktop,
        MyExplorerIconsRegular.desktop,
        PlatformPaths.desktopPath,
        key: 'desktop',
      ),
      _SidebarItem(
        t.sidebar.documents,
        MyExplorerIconsRegular.notebook,
        PlatformPaths.documentsPath,
        key: 'documents',
      ),
      _SidebarItem(
        t.sidebar.downloads,
        MyExplorerIconsRegular.downloadSimple,
        PlatformPaths.downloadsPath,
        key: 'downloads',
      ),
      _SidebarItem(
        t.sidebar.pictures,
        MyExplorerIconsRegular.image,
        PlatformPaths.picturesPath,
        key: 'pictures',
      ),
      _SidebarItem(
        t.sidebar.music,
        MyExplorerIconsRegular.musicNote,
        PlatformPaths.musicPath,
        key: 'music',
      ),
      _SidebarItem(
        t.sidebar.videos,
        MyExplorerIconsRegular.videoCamera,
        PlatformPaths.videosPath,
        key: 'videos',
      ),
      if (PlatformPaths.canOpenTrash)
        _SidebarItem(
          t.sidebar.trash,
          MyExplorerIconsRegular.trashSimple,
          kTrashPath,
          key: 'trash',
        ),
    ];
    final trashDir = PlatformPaths.trashPath;
    if (trashDir != null) {
      try {
        Directory(trashDir).createSync(recursive: true);
      } catch (e, st) {
        log.warn(
          'navigation',
          'failed to create trash directory',
          error: e,
          stack: st,
        );
      }
    }
    _bookmarkStore.load();
    widget.store.requestSmbCredentials = _credentialsRequester;
    widget.store.requestSftpCredentials = _sftpCredentialsRequester;
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      if (oldWidget.store.requestSmbCredentials == _credentialsRequester) {
        oldWidget.store.requestSmbCredentials = null;
      }
      widget.store.requestSmbCredentials = _credentialsRequester;
      if (oldWidget.store.requestSftpCredentials == _sftpCredentialsRequester) {
        oldWidget.store.requestSftpCredentials = null;
      }
      widget.store.requestSftpCredentials = _sftpCredentialsRequester;
    }
  }

  @override
  void dispose() {
    if (widget.store.requestSmbCredentials == _credentialsRequester) {
      widget.store.requestSmbCredentials = null;
    }
    if (widget.store.requestSftpCredentials == _sftpCredentialsRequester) {
      widget.store.requestSftpCredentials = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<SmbCredentials?> _requestSmbCredentials(String logical) async {
    final uri = LocationUri.parse(logical);
    final result = await showSmbCredentialsDialog(
      context,
      title: uri.displayLabel,
      username: uri.username,
    );
    if (result == null) return null;

    return SmbCredentials(username: result.username, password: result.password);
  }

  Future<SftpCredentials?> _requestSftpCredentials(String logical) async {
    final uri = LocationUri.parse(logical);

    return showSftpCredentialsDialog(
      context,
      title: uri.displayLabel,
      username: uri.username,
    );
  }

  Future<void> _renameBookmark(Bookmark bookmark) async {
    final label = await showRenameDialog(
      context,
      title: t.menu.rename,
      icon: MyExplorerIconsRegular.pencilSimple,
      initialValue: bookmark.label,
    );
    if (label != null && label != bookmark.label) {
      await _bookmarkStore.rename(bookmark, label);
    }
  }

  void _showBookmarkMenu(Bookmark bookmark, Offset position) {
    showContextMenu(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          icon: MyExplorerIconsRegular.folderOpen,
          label: t.menu.open,
          action: 'open',
        ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.pencilSimple,
          label: t.menu.rename,
          action: 'rename',
        ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.trash,
          label: t.menu.removeBookmark,
          action: 'remove',
          danger: true,
        ),
      ],
      onSelect: (action) {
        switch (action) {
          case 'open':
            widget.store.navigateTo(bookmark.path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(bookmark.path);
          case 'copy_path':
            _copyPath(bookmark.path);
          case 'rename':
            _renameBookmark(bookmark);
          case 'remove':
            _bookmarkStore.remove(bookmark);
        }
      },
    );
  }

  void _copyPath(String path) {
    unawaited(Clipboard.setData(ClipboardData(text: path)));
  }

  void _showProperties(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return;
    final name = PlatformPaths.fileName(path);
    final entry = FileEntry(
      name: name.isEmpty ? path : name,
      path: path,
      type: FileItemType.folder,
      size: 0,
      modified: dir.statSync().modified,
    );
    unawaited(
      showQuickLook(
        context: context,
        store: widget.store,
        explicitEntry: entry,
      ),
    );
  }

  void _showFolderMenu(String path, Offset position, {required bool isTrash}) {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: MyExplorerIconsRegular.folderOpen,
        label: t.menu.open,
        action: 'open',
      ),
      if (!isTrash && widget.onOpenInNewTab != null)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
      if (!isTrash) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.bookmarkSimple,
          label: t.menu.addBookmark,
          action: 'add_bookmark',
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ],
    ];
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        switch (action) {
          case 'open':
            widget.store.navigateTo(path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'copy_path':
            _copyPath(path);
          case 'add_bookmark':
            unawaited(_bookmarkStore.addPath(path));
          case 'properties':
            _showProperties(path);
        }
      },
    );
  }

  void _showDriveMenu(Drive drive, String path, Offset position) {
    final isMounted = drive.isMounted;
    final canUnmount = isMounted && drive.id != '/' && drive.isRemovable;
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: MyExplorerIconsRegular.folderOpen,
        label: t.menu.open,
        action: 'open',
      ),
      if (isMounted && widget.onOpenInNewTab != null)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
      if (isMounted) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
        ContextMenuItem(
          icon: MyExplorerIconsRegular.bookmarkSimple,
          label: t.menu.addBookmark,
          action: 'add_bookmark',
        ),
      ],
      if (canUnmount)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.eject,
          label: t.menu.eject,
          action: 'eject',
        ),
      if (isMounted) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ],
    ];
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        switch (action) {
          case 'open':
            unawaited(_onDriveTap(drive, path));
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'copy_path':
            _copyPath(path);
          case 'add_bookmark':
            unawaited(_bookmarkStore.addPath(path));
          case 'eject':
            unawaited(_unmountDrive(drive));
          case 'properties':
            _showProperties(path);
        }
      },
    );
  }

  void _showNetworkMenu(
    String path,
    Offset position, {
    required bool canDisconnect,
  }) {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: MyExplorerIconsRegular.folderOpen,
        label: t.menu.open,
        action: 'open',
      ),
      if (widget.onOpenInNewTab != null)
        ContextMenuItem(
          icon: MyExplorerIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: MyExplorerIconsRegular.copy,
        label: t.menu.copyPath,
        action: 'copy_path',
      ),
      ContextMenuItem(
        icon: MyExplorerIconsRegular.bookmarkSimple,
        label: t.menu.addBookmark,
        action: 'add_bookmark',
      ),
      if (canDisconnect) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: MyExplorerIconsRegular.eject,
          label: t.menu.disconnect,
          action: 'disconnect',
          danger: true,
        ),
      ],
    ];
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        switch (action) {
          case 'open':
            widget.store.navigateTo(path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'copy_path':
            _copyPath(path);
          case 'add_bookmark':
            unawaited(_bookmarkStore.addLocation(path));
          case 'disconnect':
            unawaited(_unmountLocation(path));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSidebar,
      child: Column(
        children: [
          SignalBuilder(
            builder: (context) => _SidebarHeader(
              collapsed: widget.collapsed,
              editing: !widget.collapsed && SidebarStore.instance.editing.value,
              onToggle: widget.onToggleCollapsed,
              onToggleEdit: widget.collapsed
                  ? null
                  : SidebarStore.instance.toggleEditing,
            ),
          ),
          Expanded(
            child: _SidebarDropTarget(
              onDropBookmark: _bookmarkStore.addPath,
              child: SignalBuilder(builder: _buildBody),
            ),
          ),
          _SidebarFooter(
            operationStore: widget.operationStore,
            collapsed: widget.collapsed,
            onConnect: () async {
              final uri = await openConnectToServer(context);
              if (uri != null) widget.store.navigateTo(uri);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final store = SidebarStore.instance;
    final editing = !widget.collapsed && store.editing.value;
    final collapsed = widget.collapsed;

    final currentPath = widget.store.currentPath.value;
    final currentDrives = driveStore.drives.value;
    final bookmarks = _bookmarkStore.bookmarks.value;

    final sectionOrder = store.sectionOrder.value;
    store.hiddenSections.value;
    store.collapsedSections.value;
    store.itemOrder.value;
    store.hiddenItems.value;

    final networkDrives = currentDrives.where((d) => d.isNetwork).toList();
    final devices = currentDrives.where((d) => !d.isNetwork).toList();

    final networkLocations = LocationResolver.mountedLocations();

    final byId = <String, _SidebarSection>{
      sidebarSectionFavorites: _SidebarSection(
        id: sidebarSectionFavorites,
        title: t.sidebar.places,
        entries: _favoriteEntries(currentPath),
      ),
      sidebarSectionDevices: _SidebarSection(
        id: sidebarSectionDevices,
        title: t.sidebar.devices,
        entries: _deviceEntries(devices, currentPath),
      ),
      sidebarSectionNetwork: _SidebarSection(
        id: sidebarSectionNetwork,
        title: t.sidebar.network,
        entries: _networkEntries(networkDrives, networkLocations, currentPath),
      ),
      sidebarSectionBookmarks: _SidebarSection(
        id: sidebarSectionBookmarks,
        title: t.sidebar.bookmarks,
        entries: _bookmarkEntries(bookmarks, currentPath),
      ),
    };
    final ordered = [
      for (final id in sectionOrder)
        if (byId.containsKey(id)) byId[id]!,
    ];

    return Padding(
      padding: const EdgeInsets.only(
        left: _gutter,
        right: _expandedRightGutter,
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: editing
            ? _buildEditList(ordered)
            : _buildNormalList(ordered, collapsed),
      ),
    );
  }

  bool _sectionAlwaysShown(String id) => id != sidebarSectionNetwork;

  Widget _buildNormalList(List<_SidebarSection> sections, bool collapsed) {
    final store = SidebarStore.instance;
    final children = <Widget>[];
    var first = true;
    for (final section in sections) {
      if (store.isSectionHidden(section.id)) continue;
      final visible = section.entries
          .where((e) => !store.isItemHidden(section.id, e.key))
          .toList();
      if (!_sectionAlwaysShown(section.id) && visible.isEmpty) continue;

      final sectionCollapsed =
          !collapsed && store.isSectionCollapsed(section.id);
      if (collapsed) {
        if (first) {
          children.add(const SizedBox(height: 6));
        } else {
          children.add(const _SectionRailDivider());
        }
      } else {
        if (!first) children.add(const SizedBox(height: _sectionGap));
        children.add(
          _SectionHeader(
            title: section.title,
            collapsed: sectionCollapsed,
            onToggle: () =>
                store.setSectionCollapsed(section.id, !sectionCollapsed),
          ),
        );
      }
      first = false;

      if (sectionCollapsed) continue;

      if (section.id == sidebarSectionBookmarks && !collapsed) {
        children.add(
          _BookmarkReorderList(
            entries: visible,
            onReorder: _bookmarkStore.reorder,
          ),
        );
      } else {
        for (final entry in visible) {
          children.add(_rowFor(entry, collapsed));
        }
      }
      if (section.id == sidebarSectionBookmarks &&
          visible.isEmpty &&
          !collapsed) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(_rowPadH, 2, _rowPadH, 8),
            child: Text(
              t.sidebar.dropBookmark,
              overflow: TextOverflow.ellipsis,
              style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            ),
          ),
        );
      }
    }

    children.add(const SizedBox(height: 12));

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: collapsed ? 6 : _sectionGap),
      children: children,
    );
  }

  Widget _rowFor(_SidebarEntry entry, bool collapsed) {
    return _ItemRow(
      item: entry.item,
      isSelected: entry.isSelected,
      isMounted: entry.isMounted,
      space: entry.space,
      collapsed: collapsed,
      tooltip: entry.tooltip,
      onTap: entry.onTap,
      onMiddleTap: entry.onMiddleTap,
      onDropFiles: entry.onDropFiles ?? (paths, {bool move = false}) {},
      onUnmount: entry.onUnmount,
      onContextMenu: entry.onContextMenu,
    );
  }

  Widget _buildEditList(List<_SidebarSection> sections) {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6),
      buildDefaultDragHandles: false,
      itemCount: sections.length,
      onReorder: (oldIndex, newIndex) =>
          SidebarStore.instance.reorderSections(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final section = sections[index];

        return _EditSection(
          key: ValueKey('section:${section.id}'),
          section: section,
          sectionIndex: index,
          onReorderItem: (oldI, newI) => _reorderItems(section, oldI, newI),
        );
      },
    );
  }

  void _reorderItems(_SidebarSection section, int oldIndex, int newIndex) {
    if (section.id == sidebarSectionBookmarks) {
      _bookmarkStore.reorder(oldIndex, newIndex);

      return;
    }
    SidebarStore.instance.reorderItems(
      section.id,
      oldIndex,
      newIndex,
      section.entries.map((e) => e.key).toList(),
    );
  }

  List<_SidebarEntry> _favoriteEntries(String currentPath) {
    HiddenListStore.instance.paths.value; // reactive dependency
    final visible = _favorites
        .where((item) => !HiddenListStore.instance.isHidden(item.path))
        .toList();
    final entries = visible.map((item) {
      final isRecycleBin = isTrashPath(item.path);

      return _SidebarEntry(
        key: item.key!,
        item: item,
        isSelected: isRecycleBin
            ? isTrashPath(currentPath)
            : currentPath == item.path,
        isMounted: !isRecycleBin,
        onTap: widget.store.navigateTo,
        onMiddleTap: widget.onOpenInNewTab != null && !isRecycleBin
            ? () => widget.onOpenInNewTab!(item.path)
            : null,
        onDropFiles: (paths, {bool move = false}) {
          if (isRecycleBin) {
            widget.operationStore.enqueueTrash(paths);

            return;
          }
          widget.store.dropFiles(paths, item.path, move: move);
        },
        onContextMenu: (position) =>
            _showFolderMenu(item.path, position, isTrash: isRecycleBin),
      );
    }).toList();

    return SidebarStore.instance.orderItems(
      sidebarSectionFavorites,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _deviceEntries(List<Drive> devices, String currentPath) {
    final entries = devices.map((drive) {
      final path = drive.mountPoint ?? drive.id;
      final isMounted = drive.isMounted;
      final label = drive.id == '/' ? t.sidebar.root : drive.label;
      final canUnmount = isMounted && drive.id != '/' && drive.isRemovable;

      return _SidebarEntry(
        key: drive.id,
        item: _SidebarItem(
          label,
          drive.isRemovable
              ? MyExplorerIconsRegular.usb
              : MyExplorerIconsRegular.hardDrive,
          path,
        ),
        isSelected: currentPath == path,
        isMounted: isMounted,
        space: isMounted ? drive.space : null,
        onTap: (p) => _onDriveTap(drive, p),
        onMiddleTap: widget.onOpenInNewTab != null && isMounted
            ? () => widget.onOpenInNewTab!(path)
            : null,
        onDropFiles: (paths, {bool move = false}) {
          if (isMounted) widget.store.dropFiles(paths, path, move: move);
        },
        onUnmount: canUnmount ? () => _unmountDrive(drive) : null,
        onContextMenu: (position) => _showDriveMenu(drive, path, position),
      );
    }).toList();

    return SidebarStore.instance.orderItems(
      sidebarSectionDevices,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _networkEntries(
    List<Drive> drives,
    List<String> locations,
    String currentPath,
  ) {
    final entries = <_SidebarEntry>[];
    for (final drive in drives) {
      final path = drive.mountPoint ?? drive.id;
      entries.add(
        _SidebarEntry(
          key: 'drive:${drive.id}',
          item: _SidebarItem(
            drive.label,
            MyExplorerIconsRegular.treeStructure,
            path,
          ),
          isSelected: currentPath == path || currentPath.startsWith(path),
          tooltip: drive.remoteTarget == null
              ? drive.label
              : '${drive.label}\n${drive.remoteTarget}',
          onTap: widget.store.navigateTo,
          onMiddleTap: widget.onOpenInNewTab != null
              ? () => widget.onOpenInNewTab!(path)
              : null,
          onDropFiles: (paths, {bool move = false}) =>
              widget.store.dropFiles(paths, path, move: move),
          onContextMenu: (position) =>
              _showNetworkMenu(path, position, canDisconnect: false),
        ),
      );
    }
    for (final path in locations) {
      final uri = LocationUri.parse(path);
      entries.add(
        _SidebarEntry(
          key: 'loc:$path',
          item: _SidebarItem(
            uri.displayLabel,
            MyExplorerIconsRegular.treeStructure,
            path,
          ),
          isSelected: currentPath == path || currentPath.startsWith('$path/'),
          tooltip: uri.displayLabel == path
              ? uri.displayLabel
              : '${uri.displayLabel}\n$path',
          onTap: widget.store.navigateTo,
          onMiddleTap: widget.onOpenInNewTab != null
              ? () => widget.onOpenInNewTab!(path)
              : null,
          onDropFiles: (paths, {bool move = false}) =>
              widget.store.dropFiles(paths, path, move: move),
          onUnmount: () => _unmountLocation(path),
          onContextMenu: (position) =>
              _showNetworkMenu(path, position, canDisconnect: true),
        ),
      );
    }

    return SidebarStore.instance.orderItems(
      sidebarSectionNetwork,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _bookmarkEntries(
    List<Bookmark> bookmarks,
    String currentPath,
  ) {
    HiddenListStore.instance.paths.value; // reactive dependency
    final visible = bookmarks
        .where((b) => !HiddenListStore.instance.isHidden(b.path))
        .toList();

    return visible.map((bookmark) {
      final uri = LocationUri.parse(bookmark.path);
      final icon = uri.isNetwork
          ? MyExplorerIconsRegular.treeStructure
          : MyExplorerIconsRegular.bookmarkSimple;
      final isMounted = uri.isLocal
          ? Directory(bookmark.path).existsSync()
          : true;

      return _SidebarEntry(
        key: 'bookmark:${bookmark.id}',
        item: _SidebarItem(bookmark.label, icon, bookmark.path),
        isSelected: currentPath == bookmark.path,
        isMounted: isMounted,
        onTap: widget.store.navigateTo,
        onMiddleTap: widget.onOpenInNewTab != null
            ? () => widget.onOpenInNewTab!(bookmark.path)
            : null,
        onDropFiles: (paths, {bool move = false}) =>
            widget.store.dropFiles(paths, bookmark.path, move: move),
        onContextMenu: (position) => _showBookmarkMenu(bookmark, position),
      );
    }).toList();
  }

  Future<void> _onDriveTap(Drive drive, String path) async {
    if (drive.isMounted) {
      widget.store.navigateTo(path);

      return;
    }
    try {
      await driveStore.mount(drive);
      _navigateToMounted(drive.id);
    } catch (e) {
      final error = e.toString().toLowerCase();
      if (!error.contains('not authorized') &&
          !error.contains('polkit') &&
          !error.contains('authenticate')) {
        return;
      }
      if (!mounted) return;
      final pwd = await showPasswordDialog(
        context,
        title: t.sidebar.drives.mountTitle(name: drive.label),
      );
      if (pwd == null) return;
      try {
        await driveStore.mountWithPassword(drive, pwd);
        _navigateToMounted(drive.id);
      } catch (e, st) {
        log.warn(
          'drives',
          'drive mount with password failed',
          error: e,
          stack: st,
        );
      }
    }
  }

  void _navigateToMounted(String driveId) {
    Future.microtask(() {
      final mounted = driveStore.drives.value
          .where((d) => d.id == driveId)
          .firstOrNull;
      if (mounted?.isMounted == true) {
        widget.store.navigateTo(mounted!.mountPoint!);
      }
    });
  }

  Future<void> _unmountDrive(Drive drive) async {
    final currentPath = widget.store.currentPath.value;
    final mountPoint = drive.mountPoint;
    try {
      await driveStore.unmount(drive);
      if (mountPoint != null && currentPath.startsWith(mountPoint)) {
        widget.store.navigateTo(PlatformPaths.homePath);
      }
    } catch (e, st) {
      log.warn('drives', 'drive unmount action failed', error: e, stack: st);
    }
  }

  Future<void> _unmountLocation(String path) async {
    final currentPath = widget.store.currentPath.value;
    await LocationResolver.unmount(path);
    if (mounted) setState(() {});
    if (currentPath == path || currentPath.startsWith('$path/')) {
      widget.store.navigateTo(PlatformPaths.homePath);
    }
  }
}

class _BookmarkReorderList extends StatelessWidget {
  final List<_SidebarEntry> entries;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _BookmarkReorderList({required this.entries, required this.onReorder});

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      itemCount: entries.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final entry = entries[index];

        return _ItemRow(
          key: ValueKey(entry.key),
          item: entry.item,
          isSelected: entry.isSelected,
          isMounted: entry.isMounted,
          space: entry.space,
          tooltip: entry.tooltip,
          onTap: entry.onTap,
          onMiddleTap: entry.onMiddleTap,
          onDropFiles: entry.onDropFiles ?? (paths, {bool move = false}) {},
          onUnmount: entry.onUnmount,
          onContextMenu: entry.onContextMenu,
        );
      },
    );
  }
}
