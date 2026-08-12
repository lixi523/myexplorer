import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Brightness;
import 'package:signals/signals.dart';
import '../../core/archive/archive_path.dart';
import '../../core/archive/archive_reader.dart';
import '../../core/models/file_entry.dart';
import '../../core/fs/file_sort.dart';
import '../../core/fs/file_system_service.dart';
import '../../core/fs/fs_worker_pool.dart';
import '../../core/fs/directory_watcher_service.dart';
import '../../core/fs/recursive_search.dart';
import '../../core/fs/sftp_fs.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../locations/location_resolver.dart';
import '../locations/location_uri.dart';
import '../../core/settings/settings_store.dart';
import '../../core/settings/color_rule_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../files/row_decorations.dart';
import '../git/git_status_store.dart';
import '../hidden/hidden_list_store.dart';
import '../operations/operation_store.dart';
import '../tags/tag_path.dart';
import '../tags/tag_store.dart';
import 'clipboard_controller.dart';
import 'filter_query.dart';
import 'folder_size_scanner.dart';
import 'remote_resolver.dart';
import 'search_controller.dart';
import 'selection_controller.dart';

export 'clipboard_controller.dart' show ClipboardMode;

part 'navigation_rename_ops.dart';

const String kPendingCreatePath = '__pending_create__';

abstract class NavigationStoreHost {
  Signal<String> get currentPath;
  Signal<Set<String>> get selectedPaths;
  Signal<int> get cursorIndex;
  Signal<int> get anchorIndex;
  Signal<String?> get renamingPath;
  Signal<String?> get renameError;
  Signal<FileEntry?> get pendingCreate;
  Signal<int> get fileListFocusRequest;
  Signal<int> get renameAttempt;
  Signal<bool> get searchActive;
  Signal<bool> get searchRecursive;
  Signal<List<FileEntry>> get searchResults;
  OperationStore get operationStore;
  List<FileEntry> get selectedEntries;
  List<FileEntry> get _vf;
  bool get isTrashView;
  String _physical(String p);
  Future<ArchiveLocation?> _archiveLocationFor(String path);
  Future<void> refresh();
}

class NavigationStore extends NavigationStoreHost with NavigationRenameOps {
  @override
  final currentPath = signal('');
  final files = signal<List<FileEntry>>([]);
  final showHidden = signal(false);
  @override
  final selectedPaths = signal<Set<String>>({});

  /// Paths added to the selection via right-button multi-select (NC mode).
  /// These render highlighted but not bold, unlike left-click selections.
  final secondarySelectedPaths = signal<Set<String>>({});
  @override
  final cursorIndex = signal(-1);
  @override
  final anchorIndex = signal(-1);
  final history = signal<List<String>>([]);
  final historyIndex = signal(0);
  final isLoading = signal(false);
  @override
  final OperationStore operationStore;
  final gitStatus = GitStatusStore();
  Future<SmbCredentials?> Function(String logical)? requestSmbCredentials;
  Future<SftpCredentials?> Function(String logical)? requestSftpCredentials;
  final loadError = signal<String?>(null);
  final trashAccessDenied = signal<bool>(false);
  final accessDenied = signal<bool>(false);
  late final RemoteResolver _remoteResolver = RemoteResolver(
    requestSmbCredentials: (logical) async {
      final request = requestSmbCredentials;

      return request == null ? null : request(logical);
    },
    requestSftpCredentials: (logical) async {
      final request = requestSftpCredentials;

      return request == null ? null : request(logical);
    },
    setLoadError: (message) => loadError.value = message,
  );
  @override
  final renamingPath = signal<String?>(null);
  @override
  final renameError = signal<String?>(null);
  @override
  final pendingCreate = signal<FileEntry?>(null);
  @override
  final fileListFocusRequest = signal(0);
  final _trashEntries = <String, TrashEntry>{};
  int _loadToken = 0;
  String? _pendingInitialSelect;

  /// Effective sort for the current folder (per-folder, falls back to the
  /// global defaults in [SettingsStore]).
  final sortKey = signal<SortKey>(SortKey.name);
  final sortAscending = signal<bool>(true);
  final foldersFirst = signal<bool>(true);
  final folderSizes = FolderSizeScanner();
  final decorations = RowDecorationStore();
  final fileTags = signal<Map<String, Set<int>>>({});
  int _sortLoadToken = 0;
  void Function()? _sortDefaultsDisposer;
  void Function()? _gitStatusDisposer;
  void Function()? _fileTagsDisposer;

  @override
  bool get isTrashView => isTrashPath(currentPath.value);
  bool get isTagView => isTagPath(currentPath.value);
  bool get isTrashRoot => currentPath.value == kTrashPath;

  @override
  String _physical(String p) => _remoteResolver.physical(p);
  List<String> _physicalList(Iterable<String> ps) =>
      _remoteResolver.physicalList(ps);

  Future<String?> resolveForOperation(String logical) =>
      _resolvePhysicalDestination(logical);

  @override
  Future<ArchiveLocation?> _archiveLocationFor(String path) async {
    if (PlatformPaths.isSmbUri(path)) {
      final physical = await _resolvePhysicalDestination(path);
      if (physical == null) return null;

      return ArchivePath.resolve(physical);
    }

    return ArchivePath.resolve(path);
  }

  Future<String?> _resolvePhysicalDestination(String logical) =>
      _remoteResolver.resolvePhysicalDestination(logical);

  Future<ResolveResult> _resolveSmb(String logical) =>
      _remoteResolver.resolveSmb(logical);

  Future<ResolveResult> _resolveSftp(String logical) =>
      _remoteResolver.resolveSftp(logical);

  Future<List<FileEntry>> _listSmbHostShares(String logical, LocationUri uri) =>
      _remoteResolver.listSmbHostShares(logical, uri);

  Future<List<FileEntry>> _listWindowsUncShares(String path, String host) =>
      _remoteResolver.listWindowsUncShares(path, host);

  final DirectoryWatcherService _watcher = DirectoryWatcherService();

  final _folderStateCache = <String, _FolderState>{};

  final pathBarFocusRequest = signal(0);
  @override
  final renameAttempt = signal(0);
  final gridColumns = signal(1);
  final treeExpandedPaths = signal<Set<String>>({});
  final treeLoadingPaths = signal<Set<String>>({});
  final treeChildren = signal<Map<String, List<FileEntry>>>({});
  final ClipboardController _clipboardController = ClipboardController();
  late final SearchController _searchController = SearchController(
    currentPath: () => currentPath.value,
    files: () => files.value,
    showHidden: () => showHidden.value,
    isTagView: () => isTagView,
    resolvePhysicalDestination: _resolvePhysicalDestination,
    filterByTags: _filterByTags,
    cursorIndex: cursorIndex,
    anchorIndex: anchorIndex,
  );
  late final SelectionController _selectionController = SelectionController(
    selectedPaths: selectedPaths,
    cursorIndex: cursorIndex,
    anchorIndex: anchorIndex,
    gridColumns: gridColumns,
    visibleFiles: () => _selectionFiles,
  );

  void Function()? _showHiddenDisposer;

  late final canGoBack = computed(() => historyIndex.value > 0);
  late final canGoForward = computed(
    () => historyIndex.value < history.value.length - 1,
  );
  late final visibleFiles = computed(() {
    final pending = pendingCreate.value;
    if (searchActive.value && (searchRecursive.value || searchContent.value)) {
      var results = searchResults.value;
      if (SettingsStore.instance.searchMode.value == filterSearchMode) {
        final parsed = parseFilterQuery(searchQuery.value);
        final filter = parsed.query;
        results = filter == null
            ? const []
            : _filterByTags(
                results.where((f) => filter.matches(f)).toList(),
                filter,
              );
      }
      final sorted = sortEntries(
        results,
        key: sortKey.value,
        ascending: sortAscending.value,
        foldersFirst: foldersFirst.value,
        naturalSort: SettingsStore.instance.naturalSort.value,
        sortFolders: SettingsStore.instance.sortFolders.value,
        folderSize: _folderSizeFor,
      );

      return pending != null ? [pending, ...sorted] : sorted;
    }
    var list = showHidden.value
        ? files.value
        : files.value.where((f) => !f.isHidden).toList();
    HiddenListStore.instance.paths.value; // reactive dependency
    if (HiddenListStore.instance.isLoaded) {
      list = list
          .where((f) => !HiddenListStore.instance.isHidden(f.realPath))
          .toList();
    }
    final q = searchQuery.value.trim();
    if (searchActive.value && q.isNotEmpty) {
      if (SettingsStore.instance.searchMode.value == filterSearchMode) {
        final parsed = parseFilterQuery(q);
        final filter = parsed.query;
        if (filter != null) {
          list = _filterByTags(
            list.where((f) => filter.matches(f)).toList(),
            filter,
          );
        } else {
          list = const [];
        }
      } else {
        final matcher = SearchController.localMatcher(
          q,
          _searchController.currentSearchMode(),
        );
        if (matcher != null) {
          list = list.where((f) => matcher(f.name)).toList();
        } else {
          list = const [];
        }
      }
    }
    list = sortEntries(
      list,
      key: sortKey.value,
      ascending: sortAscending.value,
      foldersFirst: foldersFirst.value,
      naturalSort: SettingsStore.instance.naturalSort.value,
      sortFolders: SettingsStore.instance.sortFolders.value,
      folderSize: _folderSizeFor,
    );

    return pending != null ? [pending, ...list] : list;
  });
  late final treeRows = computed(() {
    final expanded = treeExpandedPaths.value;
    final loading = treeLoadingPaths.value;
    final children = treeChildren.value;
    final rows = <FileTreeRow>[];

    void append(FileEntry entry, int depth) {
      final isFolder = entry.type == FileItemType.folder;
      final path = entry.path;
      final isExpanded = isFolder && expanded.contains(path);
      rows.add(
        FileTreeRow(
          entry: entry,
          depth: depth,
          expanded: isExpanded,
          loading: loading.contains(path),
        ),
      );
      if (!isExpanded) return;
      final rawChildren = children[path] ?? const <FileEntry>[];
      var visibleChildren = showHidden.value
          ? rawChildren
          : rawChildren.where((f) => !f.isHidden).toList();
      HiddenListStore.instance.paths.value; // reactive dependency
      if (HiddenListStore.instance.isLoaded) {
        visibleChildren = visibleChildren
            .where((f) => !HiddenListStore.instance.isHidden(f.realPath))
            .toList();
      }
      final sortedChildren = sortCurrent(visibleChildren);
      for (final child in sortedChildren) {
        append(child, depth + 1);
      }
    }

    for (final entry in visibleFiles.value) {
      append(entry, 0);
    }

    return rows;
  });
  late final folderCount = computed(
    () => visibleFiles.value.where((f) => f.type == FileItemType.folder).length,
  );
  late final fileCount = computed(
    () => visibleFiles.value.where((f) => f.type == FileItemType.file).length,
  );
  late final totalItems = computed(() => visibleFiles.value.length);
  late final cursorEntry = computed<FileEntry?>(() {
    final files = visibleFiles.value;
    final idx = cursorIndex.value;
    if (idx >= 0 && idx < files.length) return files[idx];
    final sel = selectedPaths.value;
    if (sel.length == 1) {
      for (final f in files) {
        if (f.path == sel.first) return f;
      }
    }

    return null;
  });
  late final selectedCount = computed(() => selectedPaths.value.length);
  Signal<Set<String>> get clipboardPaths => _clipboardController.clipboardPaths;
  Signal<ClipboardMode?> get clipboardMode =>
      _clipboardController.clipboardMode;
  Computed<bool> get canPaste => _clipboardController.canPaste;
  @override
  Signal<bool> get searchActive => _searchController.searchActive;
  Signal<String> get searchQuery => _searchController.searchQuery;
  @override
  Signal<bool> get searchRecursive => _searchController.searchRecursive;
  Signal<bool> get searchContent => _searchController.searchContent;
  @override
  Signal<List<FileEntry>> get searchResults => _searchController.searchResults;
  Signal<bool> get isSearching => _searchController.isSearching;
  Signal<int> get searchScannedDirs => _searchController.searchScannedDirs;
  Signal<String?> get searchCurrentDir => _searchController.searchCurrentDir;
  Signal<int> get searchFocusRequest => _searchController.searchFocusRequest;
  Signal<String?> get searchPatternError =>
      _searchController.searchPatternError;

  NavigationStore({
    required this.operationStore,
    String? initialPath,
    String? initialSelect,
  }) {
    final startPath = initialPath ?? PlatformPaths.homePath;
    currentPath.value = startPath;
    history.value = [startPath];
    showHidden.value = SettingsStore.instance.showHiddenDefault.value;
    _pendingInitialSelect = initialSelect;
    _loadSortFor(startPath);
    loadDirectory(startPath);
    _setupShowHiddenEffect();
    _setupSortDefaultsEffect();
    _setupGitStatusEffect();
    _setupTagsEffect();
    _setupFileTagsEffect();
    _setupColorRuleLayer();
  }

  late final _tagDecorations = computed<Map<String, RowDecoration>>(() {
    final assigned = fileTags.value;
    final defs = TagStore.instance.tags.value;
    final deco = <String, RowDecoration>{};
    for (final entry in assigned.entries) {
      final colors = <Color>[];
      for (final def in defs) {
        if (entry.value.contains(def.id)) colors.add(def.color);
      }
      if (colors.isEmpty) continue;
      deco[entry.key] = RowDecoration(
        tint: const Color(0x00000000),
        badgeColors: colors,
      );
    }

    return deco;
  });

  void _setupTagsEffect() {
    decorations.addReactiveLayer(_tagDecorations);
  }

  late final _colorRuleDecorations = computed<Map<String, RowDecoration>>(() {
    final rules = ColorRuleStore.instance.rules.value; // reactive
    SettingsStore.instance.themeId.value;
    final deco = <String, RowDecoration>{};
    final list = visibleFiles.value;
    for (final entry in list) {
      if (entry.type == FileItemType.folder) {
        deco[entry.path] = RowDecoration(
          tint: const Color(0x00000000),
          nameColor: AppColors.brightness == Brightness.dark
              ? AppColors.folderNameDark
              : AppColors.folderNameLight,
        );
        continue;
      }
      if (rules.isEmpty) continue;
      final color = ColorRuleStore.instance.colorFor(entry.extension);
      if (color != null) {
        deco[entry.path] = RowDecoration(
          tint: const Color(0x00000000),
          nameColor: color,
        );
      }
    }

    return deco;
  });

  void _setupColorRuleLayer() {
    decorations.addReactiveLayer(_colorRuleDecorations);
  }

  void _setupFileTagsEffect() {
    var first = true;
    _fileTagsDisposer = effect(() {
      TagStore.instance.fileTagsRevision.value;
      if (first) {
        first = false;

        return;
      }
      unawaited(_refreshTagsForVisible());
    });
  }

  Future<void> _loadFileTags(List<FileEntry> entries) async {
    final paths = [for (final e in entries) e.path];
    final rows = await SettingsStore.instance.db.getFileTagsForPaths(paths);
    final map = <String, Set<int>>{};
    for (final row in rows) {
      (map[row.path] ??= <int>{}).add(row.tagId);
    }
    fileTags.value = map;
  }

  void _setupGitStatusEffect() {
    _gitStatusDisposer = effect(() {
      final path = currentPath.value;
      if (!PlatformPaths.isNetworkPath(path)) {
        gitStatus.unwatchPath();
        gitStatus.watchPath(path);
      }
    });
  }

  void _setupSortDefaultsEffect() {
    var first = true;
    _sortDefaultsDisposer = effect(() {
      final s = SettingsStore.instance;
      s.sortKey.value;
      s.sortAscending.value;
      s.foldersFirst.value;
      if (first) {
        first = false;

        return;
      }
      _loadSortFor(currentPath.value);
    });
  }

  void _applySort(SortKey key, bool ascending, bool foldersFirstValue) {
    batch(() {
      sortKey.value = key;
      sortAscending.value = ascending;
      foldersFirst.value = foldersFirstValue;
    });
  }

  Future<void> _loadSortFor(String path) async {
    final token = ++_sortLoadToken;
    final s = SettingsStore.instance;
    _applySort(
      sortKeyFromString(s.sortKey.value),
      s.sortAscending.value,
      s.foldersFirst.value,
    );
    if (!s.rememberFolderSort.value) return;
    if (!s.isLoaded) return;
    try {
      final pref = await s.db.getFolderPref(path);
      if (token != _sortLoadToken) return;
      if (pref != null) {
        _applySort(
          sortKeyFromString(pref.sortKey),
          pref.sortAscending,
          s.foldersFirst.value,
        );
      }
    } catch (e, st) {
      log.warn('navigation', 'failed to load folder sort', error: e, stack: st);
    }
  }

  void _persistSort() {
    final path = currentPath.value;
    if (path.isEmpty) return;
    final s = SettingsStore.instance;
    if (!s.rememberFolderSort.value) return;
    if (!s.isLoaded) return;
    s.db
        .setFolderPref(
          path,
          sortKey: sortKeyToString(sortKey.value),
          sortAscending: sortAscending.value,
          foldersFirst: foldersFirst.value,
        )
        .catchError(
          (e, st) => log.warn(
            'navigation',
            'failed to persist folder sort',
            error: e,
            stack: st,
          ),
        );
  }

  void setSortKey(SortKey key) {
    if (sortKey.value == key) return;
    sortKey.value = key;
    _persistSort();
  }

  void setSortAscending(bool ascending) {
    if (sortAscending.value == ascending) return;
    sortAscending.value = ascending;
    _persistSort();
  }

  /// Toggles direction when [key] is already active, otherwise switches to
  /// [key] ascending. Persists the choice for the current folder.
  void cycleSortColumn(SortKey key) {
    batch(() {
      if (sortKey.value == key) {
        sortAscending.value = !sortAscending.value;
      } else {
        sortKey.value = key;
        sortAscending.value = true;
      }
    });
    _persistSort();
  }

  void _setupShowHiddenEffect() {
    _showHiddenDisposer = effect(() {
      showHidden.value;
      if (searchActive.value &&
          (searchRecursive.value || searchContent.value)) {
        _searchController.scheduleRestart();
      }
    });
  }

  void focusPathBar() {
    pathBarFocusRequest.value = pathBarFocusRequest.value + 1;
  }

  void openSearch({bool recursive = false}) =>
      _searchController.openSearch(recursive: recursive);

  void closeSearch() => _searchController.closeSearch();

  void setSearchQuery(String query) => _searchController.setSearchQuery(query);

  void toggleRecursive() => _searchController.toggleRecursive();

  void toggleContent() => _searchController.toggleContent();

  void cycleSearchMode() => _searchController.cycleSearchMode();

  void setSearchMode(String mode) => _searchController.setSearchMode(mode);

  static String? validateSearchPattern(String query, SearchMode mode) =>
      SearchController.validateSearchPattern(query, mode);

  Future<void> _ensureSftpConnectedAndNavigate(
    String logical, {
    bool addToHistory = true,
    String? enteredPath,
  }) async {
    batch(() {
      isLoading.value = true;
      loadError.value = null;
    });
    final result = await _resolveSftp(logical);
    switch (result) {
      case ResolveSuccess():
        _doNavigate(
          result.physicalPath,
          addToHistory: addToHistory,
          enteredPath: enteredPath,
        );
      case ResolveError(:final message):
        batch(() {
          isLoading.value = false;
          loadError.value = message;
        });
      case ResolveUnsupported():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.sftpNotSupported;
        });
      case ResolveAuthenticationRequired():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.authenticationRequired;
        });
    }
  }

  Future<void> _ensureSmbMountedAndNavigate(
    String logical, {
    bool addToHistory = true,
    String? enteredPath,
  }) async {
    final uri = LocationUri.parse(logical);
    if (uri.share == null || uri.share!.isEmpty) {
      _doNavigate(
        logical,
        addToHistory: addToHistory,
        enteredPath: enteredPath,
      );

      return;
    }
    batch(() {
      isLoading.value = true;
      loadError.value = null;
    });
    final result = await _resolveSmb(logical);
    switch (result) {
      case ResolveSuccess():
        _doNavigate(
          logical,
          addToHistory: addToHistory,
          enteredPath: enteredPath,
        );
      case ResolveError(:final message):
        batch(() {
          isLoading.value = false;
          loadError.value = message;
        });
      case ResolveUnsupported():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.smbNotSupportedOnPlatform;
        });
      case ResolveAuthenticationRequired():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.authenticationRequired;
        });
    }
  }

  /// Synchronous resolution for inputs that don't need IO (local, UNC,
  /// trash, smb→UNC on Windows). Returns null for inputs that need async
  /// resolution (smb on Linux) or are unsupported (other schemes).
  String? _resolveForNavigationSync(String input) {
    final uri = LocationUri.parse(input);
    switch (uri.scheme) {
      case LocationScheme.smb:
        if (PlatformPaths.isWindows) {
          if (uri.port != null) {
            loadError.value = t.errors.smbPortsNotSupportedOnWindows;

            return null;
          }
          final unc = uri.toWindowsUnc();
          if (unc == null) {
            loadError.value = t.errors.invalidSmbUri;

            return null;
          }

          return unc;
        }

        return null;
      case LocationScheme.sftp:
        return null;
      case LocationScheme.other:
        loadError.value = t.errors.smbNotSupportedOnPlatform;

        return null;
      case LocationScheme.windowsUnc:
      case LocationScheme.local:
      case LocationScheme.trash:
        return input;
    }
  }

  void navigateTo(
    String path, {
    bool addToHistory = true,
    String? enteredPath,
  }) {
    if (isTagPath(path)) {
      _doNavigate(path, addToHistory: addToHistory, enteredPath: enteredPath);

      return;
    }
    final uri = LocationUri.parse(path);
    if (uri.scheme == LocationScheme.sftp) {
      _ensureSftpConnectedAndNavigate(
        path,
        addToHistory: addToHistory,
        enteredPath: enteredPath,
      );

      return;
    }
    if (uri.scheme == LocationScheme.smb && !PlatformPaths.isWindows) {
      _ensureSmbMountedAndNavigate(
        path,
        addToHistory: addToHistory,
        enteredPath: enteredPath,
      );

      return;
    }
    final resolved = _resolveForNavigationSync(path);
    if (resolved == null) return;
    _doNavigate(resolved, addToHistory: addToHistory, enteredPath: enteredPath);
  }

  void _doNavigate(
    String resolved, {
    bool addToHistory = true,
    String? enteredPath,
  }) {
    final normalized = isTrashPath(resolved) || isTagPath(resolved)
        ? resolved
        : PlatformPaths.normalize(resolved);
    final previous = currentPath.value;
    if (previous.isNotEmpty && previous != normalized) {
      _saveFolderState(previous);
    }
    closeSearch();
    folderSizes.cancelAll();
    _clearTreeState();
    if (addToHistory) {
      history.value = history.value.sublist(0, historyIndex.value + 1)
        ..add(normalized);
      historyIndex.value = history.value.length - 1;
    }
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
      currentPath.value = normalized;
    });
    _loadSortFor(normalized);
    loadDirectory(normalized);
    _recordEnteredPath(enteredPath);
  }

  void _recordEnteredPath(String? path) {
    if (path == null || path.trim().isEmpty) return;
    final s = SettingsStore.instance;
    if (!s.isLoaded) return;
    s.db
        .recordRecentEnteredPath(path)
        .catchError(
          (e, st) => log.warn(
            'navigation',
            'failed to record entered path',
            error: e,
            stack: st,
          ),
        );
  }

  void _saveFolderState(String path) {
    if (path.isEmpty) return;
    final s = SettingsStore.instance;
    if (!s.rememberFolderState.value) return;
    final idx = cursorIndex.value;
    final list = _vf;
    final cursorPath = (idx >= 0 && idx < list.length) ? list[idx].path : null;
    final selected = Set<String>.from(selectedPaths.value);
    _folderStateCache[path] = _FolderState(
      selectedPaths: selected,
      cursorPath: cursorPath,
    );
    if (!s.isLoaded) return;
    final encoded = selected.isEmpty ? null : jsonEncode(selected.toList());
    s.db
        .setFolderUiState(path, cursorPath: cursorPath, selectedPaths: encoded)
        .catchError(
          (e, st) => log.warn(
            'navigation',
            'failed to save folder state',
            error: e,
            stack: st,
          ),
        );
  }

  void _applyPendingSelect() {
    final target = _pendingInitialSelect;
    if (target == null) return;
    _pendingInitialSelect = null;
    final list = _vf;
    final idx = list.indexWhere((f) => f.path == target);
    batch(() {
      selectedPaths.value = {target};
      if (idx >= 0) {
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      }
    });
  }

  Future<void> _restoreFolderStateIfMatches(String path) async {
    if (_pendingInitialSelect != null) return;
    final s = SettingsStore.instance;
    if (!s.rememberFolderState.value) return;
    _FolderState? state = _folderStateCache[path];
    if (state == null && s.isLoaded) {
      try {
        final pref = await s.db.getFolderPref(path);
        if (pref == null) return;
        if (currentPath.value != path) return;
        Set<String> selected = const {};
        final raw = pref.selectedPaths;
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              selected = decoded.whereType<String>().toSet();
            }
          } catch (e, st) {
            log.warn(
              'navigation',
              'failed to decode stored folder selection',
              error: e,
              stack: st,
            );
          }
        }
        if (pref.cursorPath == null && selected.isEmpty) return;
        state = _FolderState(
          selectedPaths: selected,
          cursorPath: pref.cursorPath,
        );
        _folderStateCache[path] = state;
      } catch (e, st) {
        log.warn(
          'navigation',
          'failed to restore folder state',
          error: e,
          stack: st,
        );

        return;
      }
    }
    final resolved = state;
    if (resolved == null) return;
    final list = _vf;
    if (list.isEmpty) return;
    final visiblePaths = {for (final f in list) f.path};
    final restored = resolved.selectedPaths.intersection(visiblePaths);
    int cursor = -1;
    final cursorPath = resolved.cursorPath;
    if (cursorPath != null) {
      cursor = list.indexWhere((f) => f.path == cursorPath);
    }
    if (cursor < 0 && restored.isNotEmpty) {
      cursor = list.indexWhere((f) => f.path == restored.first);
    }
    batch(() {
      if (restored.isNotEmpty) selectedPaths.value = restored;
      if (cursor >= 0) {
        cursorIndex.value = cursor;
        anchorIndex.value = cursor;
      }
    });
  }

  Future<bool> navigateToEnteredPath(String path) async {
    final trimmed = PlatformPaths.expandTilde(
      PlatformPaths.expandEnvVars(path.trim()),
    );
    if (trimmed.isEmpty) return false;
    final uri = LocationUri.parse(trimmed);
    if (uri.scheme == LocationScheme.sftp) {
      navigateTo(trimmed, enteredPath: trimmed);

      return true;
    }
    if (uri.scheme == LocationScheme.smb && !PlatformPaths.isWindows) {
      navigateTo(trimmed, enteredPath: trimmed);

      return true;
    }
    final resolved = _resolveForNavigationSync(trimmed);
    if (resolved == null) return true;
    final normalized = isTrashPath(resolved)
        ? resolved
        : PlatformPaths.normalize(resolved);
    if (isTrashPath(normalized)) {
      navigateTo(normalized, enteredPath: trimmed);

      return true;
    }
    if (PlatformPaths.windowsUncServerRoot(normalized) != null) {
      navigateTo(normalized, enteredPath: trimmed);

      return true;
    }

    final type = FileSystemEntity.typeSync(normalized);
    if (type == FileSystemEntityType.directory) {
      navigateTo(normalized, enteredPath: trimmed);

      return true;
    }
    if (type == FileSystemEntityType.file ||
        type == FileSystemEntityType.link) {
      final parent = PlatformPaths.parentOf(normalized);
      if (parent.isEmpty || !await FileSystemService.isNavigable(parent)) {
        return false;
      }
      revealInFolder(normalized, enteredPath: trimmed);

      return true;
    }

    return false;
  }

  void goBack() {
    if (!canGoBack.value) return;
    historyIndex.value--;
    navigateTo(history.value[historyIndex.value], addToHistory: false);
  }

  void goForward() {
    if (!canGoForward.value) return;
    historyIndex.value++;
    navigateTo(history.value[historyIndex.value], addToHistory: false);
  }

  void goUp() async {
    if (isTrashView) {
      if (isTrashRoot) return;
      navigateTo(trashParentOf(currentPath.value));

      return;
    }
    final cur = currentPath.value;
    if (PlatformPaths.isSmbUri(cur)) {
      final parent = PlatformPaths.parentOf(cur);
      if (parent != cur) navigateTo(parent);

      return;
    }
    final parent = PlatformPaths.parentOf(cur);
    if (parent == cur) return;
    if (PlatformPaths.windowsUncServerRoot(parent) != null ||
        await FileSystemService.isNavigable(parent)) {
      navigateTo(parent);
    }
  }

  @override
  Future<void> refresh() => loadDirectory(currentPath.value);

  Future<void> loadDirectory(String path) async {
    final token = ++_loadToken;
    batch(() {
      isLoading.value = true;
      trashAccessDenied.value = false;
      accessDenied.value = false;
    });
    try {
      final List<FileEntry> entries;
      if (isTagPath(path)) {
        entries = await _loadTagView(path);
      } else if (isTrashPath(path)) {
        entries = await _loadTrash(path);
      } else if (PlatformPaths.isSmbUri(path)) {
        final uri = LocationUri.parse(path);
        if (uri.share == null || uri.share!.isEmpty) {
          entries = await _listSmbHostShares(path, uri);
          if (token != _loadToken) return;
          _publishEntries(entries);
          _restoreFolderStateIfMatches(path);
          _watcher.stop();

          return;
        }
        var physical = LocationResolver.logicalToPhysical(path);
        if (physical == null) {
          final r = await _resolveSmb(path);
          if (r is ResolveSuccess) {
            physical = r.physicalPath;
          } else if (r is ResolveError) {
            throw FileSystemException(r.message, path);
          } else if (r is ResolveAuthenticationRequired) {
            throw FileSystemException(t.errors.authenticationRequired, path);
          }
          if (physical == null) {
            throw FileSystemException(t.errors.smbShareNotMounted, path);
          }
        }
        final raw = await FileSystemService.listDirectory(physical);
        entries = [
          for (final e in raw)
            FileEntry.raw(
              name: e.name,
              path: '$path/${e.name}',
              realPath: e.path,
              type: e.type,
              size: e.size,
              modifiedMs: e.modifiedMs,
            ),
        ];
      } else if (PlatformPaths.windowsUncServerRoot(path) case final host?) {
        entries = await _listWindowsUncShares(path, host);
        if (token != _loadToken) return;
        _publishEntries(entries);
        _restoreFolderStateIfMatches(path);
        _watcher.stop();

        return;
      } else {
        entries = await FileSystemService.listDirectory(path);
      }
      if (token != _loadToken) return;
      _publishEntries(entries);
      _restoreFolderStateIfMatches(path);
      _applyPendingSelect();
      if (token == _loadToken) await _loadFileTags(entries);
      if (token != _loadToken) return;
      if (isTagPath(path) ||
          isTrashPath(path) ||
          PlatformPaths.isNetworkPath(path)) {
        _watcher.stop();
      } else {
        _watcher.watch(
          path,
          (changed, fullReload) => _onWatcherEvent(path, changed, fullReload),
        );
        gitStatus.watchPath(path);
      }
    } catch (e) {
      if (token != _loadToken) return;
      if (e is TrashAccessDeniedException) {
        batch(() {
          files.value = [];
          loadError.value = null;
          trashAccessDenied.value = true;
          accessDenied.value = false;
          isLoading.value = false;
        });
        _watcher.stop();

        return;
      }
      if (e is FileSystemException && _isPermissionDenied(path)) {
        batch(() {
          files.value = [];
          loadError.value = null;
          trashAccessDenied.value = false;
          accessDenied.value = true;
          isLoading.value = false;
        });
        _watcher.stop();

        return;
      }
      batch(() {
        files.value = [];
        loadError.value = switch (e) {
          ArchiveReadException() => t.errors.archiveError,
          FileSystemException(:final message) =>
            message.isNotEmpty ? message : e.toString(),
          _ => e.toString(),
        };
        trashAccessDenied.value = false;
        accessDenied.value = false;
        isLoading.value = false;
      });
      _watcher.stop();
    }
  }

  void _publishEntries(List<FileEntry> entries) {
    batch(() {
      files.value = entries;
      loadError.value = null;
      trashAccessDenied.value = false;
      isLoading.value = false;
    });
  }

  bool _isPermissionDenied(String path) {
    try {
      Directory(path).listSync(followLinks: false);

      return false;
    } on FileSystemException catch (e) {
      final code = e.osError?.errorCode;
      if (code == 1 || code == 13 || code == 5) return true;
      final msg = e.message.toLowerCase();

      return msg.contains('operation not permitted') ||
          msg.contains('permission denied') ||
          msg.contains('access is denied');
    } catch (e, st) {
      log.warn('navigation', 'permission probe failed', error: e, stack: st);

      return false;
    }
  }

  Future<List<FileEntry>> _loadTagView(String path) async {
    final id = tagIdFromPath(path);
    if (id == null) return const [];
    final paths = await SettingsStore.instance.db.getPathsForTag(id);
    final out = <FileEntry>[];
    for (final p in paths) {
      final type = FileSystemEntity.typeSync(p);
      if (type == FileSystemEntityType.notFound) continue;
      out.add(
        FileEntry.fromFileSystemEntity(
          type == FileSystemEntityType.directory ? Directory(p) : File(p),
        ),
      );
    }

    return out;
  }

  static bool isTaggablePath(String path) =>
      !PlatformPaths.isRemoteUri(path) &&
      !PlatformPaths.isNetworkPath(path) &&
      !FileSystemService.isInsideArchive(path);

  Future<void> toggleTag(Iterable<String> paths, int tagId) async {
    final taggable = paths.where(isTaggablePath).toList();
    if (taggable.isEmpty) return;
    final db = SettingsStore.instance.db;
    final allTagged = taggable.every(
      (p) => fileTags.value[p]?.contains(tagId) ?? false,
    );
    for (final p in taggable) {
      if (allTagged) {
        await db.removeFileTag(p, tagId);
      } else {
        await db.addFileTag(p, tagId);
      }
    }
    TagStore.instance.notifyFileTagsChanged();
  }

  Future<void> addTag(Iterable<String> paths, int tagId) async {
    final taggable = paths.where(isTaggablePath).toList();
    if (taggable.isEmpty) return;
    final db = SettingsStore.instance.db;
    for (final p in taggable) {
      await db.addFileTag(p, tagId);
    }
    TagStore.instance.notifyFileTagsChanged();
  }

  Future<void> clearTags(Iterable<String> paths) async {
    final taggable = paths.where(isTaggablePath).toList();
    if (taggable.isEmpty) return;
    final db = SettingsStore.instance.db;
    for (final p in taggable) {
      await db.clearFileTags(p);
    }
    TagStore.instance.notifyFileTagsChanged();
  }

  List<FileEntry> _filterByTags(List<FileEntry> list, FilterQuery filter) {
    if (filter.tagNames.isEmpty) return list;
    final ids = <int>{};
    for (final def in TagStore.instance.tags.value) {
      if (filter.tagNames.contains(def.name.toLowerCase())) ids.add(def.id);
    }
    if (ids.isEmpty) return const [];
    final assigned = fileTags.value;

    return list.where((f) {
      final tags = assigned[f.path];

      return tags != null && tags.any(ids.contains);
    }).toList();
  }

  Future<void> _refreshTagsForVisible() async {
    if (isTagView) {
      await refresh();

      return;
    }
    await _loadFileTags(files.value);
  }

  Future<List<FileEntry>> _loadTrash(String path) async {
    if (path == kTrashPath) {
      final entries = await TrashRepository.instance.listRoot();
      _trashEntries.clear();
      final out = <FileEntry>[];
      for (final e in entries) {
        _trashEntries[e.virtualPath] = e;
        out.add(
          FileEntry(
            name: e.displayName,
            path: e.virtualPath,
            realPath: e.realDataPath,
            type: e.isDirectory ? FileItemType.folder : FileItemType.file,
            size: e.size,
            modified: e.deletedAt,
          ),
        );
      }

      return out;
    }
    final children = await TrashRepository.instance.listSub(path);

    return [
      for (final c in children)
        FileEntry(
          name: c.displayName,
          path: c.virtualPath,
          realPath: c.realPath,
          type: c.isDirectory ? FileItemType.folder : FileItemType.file,
          size: c.size,
          modified: c.modified,
        ),
    ];
  }

  bool get canRestoreFromTrash => TrashRepository.instance.canRestore;

  Future<void> restoreSelectedFromTrash() async {
    final entries = _selectedTrashEntries();
    if (entries.isEmpty) return;
    operationStore.enqueueTrashRestore(entries);
    _clearTrashSelection();
  }

  Future<void> deletePermanentlySelectedFromTrash() async {
    final entries = _selectedTrashEntries();
    if (entries.isEmpty) return;
    operationStore.enqueueTrashDelete(entries);
    _clearTrashSelection();
  }

  List<TrashEntry> _selectedTrashEntries() {
    if (!isTrashView) return const [];
    final entries = <TrashEntry>[];
    for (final p in selectedPaths.value.toList()) {
      final e = _trashEntries[p];
      if (e != null) entries.add(e);
    }

    return entries;
  }

  void _clearTrashSelection() {
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
  }

  void _onWatcherEvent(
    String path,
    Set<String> changed,
    bool fullReload,
  ) async {
    if (path != currentPath.value) return;
    gitStatus.watchPath(path);
    if (fullReload) {
      _onExternalChange(path);

      return;
    }
    try {
      final patched = List<FileEntry>.of(files.value);
      final byPath = {
        for (var i = 0; i < patched.length; i++) patched[i].path: i,
      };
      var mutated = false;
      for (final childPath in changed) {
        if (childPath == path) continue;
        final entry = await FsWorkerPool.instance.stat(childPath);
        if (path != currentPath.value) return;
        final existingIdx = byPath[childPath];
        if (entry == null) {
          if (existingIdx != null) {
            patched[existingIdx] = _kTombstone;
            mutated = true;
          }
        } else if (existingIdx != null) {
          patched[existingIdx] = entry;
          mutated = true;
        } else {
          patched.add(entry);
          mutated = true;
        }
      }
      if (!mutated) return;
      patched.removeWhere(identical0);
      _applyExternalChanges(sortCurrent(_dedupeByName(patched)));
    } catch (e, st) {
      log.warn('navigation', 'incremental refresh failed', error: e, stack: st);
      _onExternalChange(path);
    }
  }

  static final FileEntry _kTombstone = FileEntry.raw(
    name: '',
    path: 'myexplorer-tombstone-sentinel',
    type: FileItemType.file,
    size: 0,
    modifiedMs: 0,
  );

  static bool identical0(FileEntry e) => identical(e, _kTombstone);

  List<FileEntry> sortCurrent(List<FileEntry> entries) => sortEntries(
    entries,
    key: sortKey.value,
    ascending: sortAscending.value,
    foldersFirst: foldersFirst.value,
    naturalSort: SettingsStore.instance.naturalSort.value,
    sortFolders: SettingsStore.instance.sortFolders.value,
    folderSize: _folderSizeFor,
  );

  bool toggleTreeCursorFolder() {
    if (SettingsStore.instance.fileViewMode.value != 'tree') return false;
    final idx = cursorIndex.value;
    final rows = treeRows.value;
    if (idx < 0 || idx >= rows.length) return false;
    final entry = rows[idx].entry;
    if (entry.type != FileItemType.folder) return false;
    toggleTreeFolder(entry);

    return true;
  }

  void toggleTreeFolder(FileEntry entry) {
    if (entry.type != FileItemType.folder) return;
    final path = entry.path;
    final expanded = Set<String>.from(treeExpandedPaths.value);
    if (expanded.remove(path)) {
      treeExpandedPaths.value = expanded;

      return;
    }
    expanded.add(path);
    treeExpandedPaths.value = expanded;
    if (!treeChildren.value.containsKey(path)) {
      _loadTreeChildren(entry);
    }
  }

  void _clearTreeState() {
    treeExpandedPaths.value = {};
    treeLoadingPaths.value = {};
    treeChildren.value = {};
  }

  Future<void> refreshTreePath(String path) async {
    if (!treeChildren.value.containsKey(path) &&
        !treeExpandedPaths.value.contains(path)) {
      return;
    }
    await _loadTreeChildrenPath(path);
  }

  Future<void> _loadTreeChildren(FileEntry entry) =>
      _loadTreeChildrenPath(entry.path);

  Future<void> _loadTreeChildrenPath(String path) async {
    if (treeLoadingPaths.value.contains(path)) return;
    treeLoadingPaths.value = {...treeLoadingPaths.value, path};
    try {
      final entries = await _listTreeChildrenPath(path);
      treeChildren.value = {...treeChildren.value, path: entries};
    } catch (e, st) {
      log.warn('navigation', 'tree child listing failed', error: e, stack: st);
      treeChildren.value = {...treeChildren.value, path: const <FileEntry>[]};
    } finally {
      final loading = Set<String>.from(treeLoadingPaths.value)..remove(path);
      treeLoadingPaths.value = loading;
    }
  }

  Future<List<FileEntry>> _listTreeChildrenPath(String path) async {
    if (isTrashPath(path)) return _loadTrash(path);
    if (PlatformPaths.isSmbUri(path)) {
      final uri = LocationUri.parse(path);
      if (uri.share == null || uri.share!.isEmpty) {
        return _listSmbHostShares(path, uri);
      }
      final physical = await _resolvePhysicalDestination(path);
      if (physical == null) return const [];
      final raw = await FileSystemService.listDirectory(physical);

      return [
        for (final e in raw)
          FileEntry.raw(
            name: e.name,
            path: '$path/${e.name}',
            realPath: e.path,
            type: e.type,
            size: e.size,
            modifiedMs: e.modifiedMs,
            createdMs: e.createdMs,
            addedMs: e.addedMs,
            mode: e.mode,
            uid: e.uid,
            gid: e.gid,
          ),
      ];
    }
    if (PlatformPaths.windowsUncServerRoot(path) case final host?) {
      return _listWindowsUncShares(path, host);
    }

    return FileSystemService.listDirectory(path);
  }

  int? _folderSizeFor(FileEntry entry) =>
      folderSizes.sizes.value[entry.realPath];

  void computeSelectedFolderSizes() {
    if (isTrashView) return;
    final entries = _vf;
    final sel = selectedPaths.value;
    final targets = <String>[];
    void consider(FileEntry e) {
      if (e.type != FileItemType.folder) return;
      final path = e.realPath;
      if (PlatformPaths.isNetworkPath(path)) return;
      if (PlatformPaths.isSftpUri(path)) return;
      targets.add(path);
    }

    if (sel.isEmpty) {
      final idx = cursorIndex.value;
      if (idx >= 0 && idx < entries.length) consider(entries[idx]);
    } else {
      for (final e in entries) {
        if (sel.contains(e.path)) consider(e);
      }
    }
    if (targets.isEmpty) return;
    folderSizes.scan(targets);
  }

  static List<FileEntry> _dedupeByName(List<FileEntry> entries) {
    final seen = <String>{};
    final out = <FileEntry>[];
    for (final e in entries) {
      final name = PlatformPaths.fileName(e.path);
      final key = PlatformPaths.isWindows ? name.toLowerCase() : name;
      if (seen.add(key)) out.add(e);
    }

    return out;
  }

  void _onExternalChange(String path) async {
    if (path != currentPath.value) return;
    try {
      final entries = await FileSystemService.listDirectory(path);
      if (path != currentPath.value) return;
      _applyExternalChanges(entries);
    } catch (e, st) {
      log.warn('navigation', 'external refresh failed', error: e, stack: st);
    }
  }

  void _applyExternalChanges(List<FileEntry> newEntries) {
    final newPaths = newEntries.map((e) => e.path).toSet();
    final filteredSelected = selectedPaths.value
        .where(newPaths.contains)
        .toSet();

    final visible = showHidden.value
        ? newEntries
        : newEntries.where((f) => !f.isHidden).toList();

    final oldCursor = cursorIndex.value;
    int newCursor = -1;
    if (oldCursor >= 0 && oldCursor < _vf.length) {
      final cursorPath = _vf[oldCursor].path;
      newCursor = visible.indexWhere((e) => e.path == cursorPath);
    }
    if (newCursor < 0 && oldCursor >= 0 && visible.isNotEmpty) {
      newCursor = oldCursor.clamp(0, visible.length - 1);
    }
    int newAnchor = -1;
    if (anchorIndex.value >= 0 && anchorIndex.value < _vf.length) {
      final anchorPath = _vf[anchorIndex.value].path;
      newAnchor = visible.indexWhere((e) => e.path == anchorPath);
    }
    if (newAnchor < 0) newAnchor = newCursor;

    batch(() {
      files.value = newEntries;
      selectedPaths.value = filteredSelected;
      cursorIndex.value = newCursor;
      anchorIndex.value = newAnchor;
    });
  }

  void dispose() {
    _showHiddenDisposer?.call();
    _showHiddenDisposer = null;
    _sortDefaultsDisposer?.call();
    _sortDefaultsDisposer = null;
    _gitStatusDisposer?.call();
    _gitStatusDisposer = null;
    _fileTagsDisposer?.call();
    _fileTagsDisposer = null;
    _tagDecorations.dispose();
    gitStatus.dispose();
    _searchController.dispose();
    _watcher.dispose();
    folderSizes.dispose();
    decorations.dispose();
  }

  List<FileEntry> get _selectionFiles =>
      SettingsStore.instance.fileViewMode.value == 'tree'
      ? [for (final row in treeRows.value) row.entry]
      : visibleFiles.value;

  @override
  List<FileEntry> get _vf => _selectionFiles;

  void onSelect(FileSelectionEvent event) {
    // A left-click selection clears the right-button (secondary) markers.
    secondarySelectedPaths.value = {};
    _selectionController.onSelect(event);
  }

  /// Adds [event]'s entry to the current selection without clearing it
  /// (right-button multi-select). Marked as secondary so the row renders
  /// highlighted but not bold.
  void addToSelection(FileSelectionEvent event) {
    secondarySelectedPaths.value = {
      ...secondarySelectedPaths.value,
      event.entry.path,
    };
    _selectionController.addToSelection(event);
  }

  void revealInFolder(String path, {String? enteredPath}) {
    final parent = PlatformPaths.parentOf(path);
    if (parent.isEmpty) return;
    closeSearch();
    navigateTo(parent, enteredPath: enteredPath);
    selectedPaths.value = {path};
  }

  /// Moves the cursor and selection to [entry] in the file list. When the entry
  /// lives in the current folder it is focused in place; otherwise its parent
  /// folder is opened and the entry is selected once the listing loads.
  void focusEntry(FileEntry entry) {
    final parent = PlatformPaths.parentOf(entry.path);
    if (parent.isEmpty) return;
    if (parent == currentPath.value) {
      closeSearch();
      final idx = _vf.indexWhere((f) => f.path == entry.path);
      if (idx < 0) return;
      batch(() {
        selectedPaths.value = {entry.path};
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    } else {
      _pendingInitialSelect = entry.path;
      navigateTo(parent);
    }
    fileListFocusRequest.value++;
  }

  void onOpen(FileEntry entry) => unawaited(_openEntry(entry));

  Future<void> _openEntry(FileEntry entry) async {
    if (entry.type == FileItemType.folder) {
      if (PlatformPaths.isWindows &&
          currentPath.value == kTrashPath &&
          isTrashPath(entry.path)) {
        return;
      }
      navigateTo(entry.path);

      return;
    }
    final loc = await _archiveLocationFor(entry.path);
    if (loc != null) {
      if (loc.isRoot) {
        navigateTo(entry.path);
      } else {
        await FileSystemService.openArchiveEntry(loc);
      }

      return;
    }
    FileSystemService.openWithDefaultApp(entry.realPath);
  }

  void openSelected() {
    FileEntry? entry;
    if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
      entry = _vf[cursorIndex.value];
    } else if (selectedPaths.value.length == 1) {
      for (final file in _vf) {
        if (file.path == selectedPaths.value.first) {
          entry = file;
          break;
        }
      }
    }
    if (entry == null) return;
    unawaited(_openEntry(entry));
  }

  void selectAll() => _selectionController.selectAll();

  List<String> selectedNamesForFile() =>
      _selectionController.selectedNamesForFile();

  int selectNamesFromFile(Iterable<String> names) =>
      _selectionController.selectNamesFromFile(names);

  int selectByPattern(String pattern) =>
      _selectionController.selectByPattern(pattern);

  int deselectByPattern(String pattern) =>
      _selectionController.deselectByPattern(pattern);

  void deselectAll() => _selectionController.deselectAll();

  void invertSelection() => _selectionController.invertSelection();

  void toggleSelectAndAdvance() =>
      _selectionController.toggleSelectAndAdvance();

  void onBackgroundTap() => deselectAll();

  void onRectSelect(Set<String> paths, {bool additive = false}) =>
      _selectionController.onRectSelect(paths, additive: additive);

  @override
  List<FileEntry> get selectedEntries => _selectionController.selectedEntries;

  void deleteSelected({bool? toTrash}) async {
    if (isTrashView) return;
    final entries = selectedEntries;
    if (entries.isEmpty) return;
    final paths = entries.map((e) => e.realPath).toList();
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    final archiveLoc = await _archiveLocationFor(currentPath.value);
    if (archiveLoc != null) {
      final inner = <String>[];
      for (final e in entries) {
        final loc = await _archiveLocationFor(e.path);
        if (loc != null && !loc.isRoot) inner.add(loc.innerPath);
      }
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: currentPath.value,
        deleteInner: inner,
      );

      return;
    }
    final hasNetworkPath = entries.any(
      (entry) => PlatformPaths.isNetworkPath(entry.realPath),
    );
    final useTrash = !hasNetworkPath && (toTrash ?? false);
    if (useTrash) {
      operationStore.enqueueTrash(paths);
    } else {
      operationStore.enqueueDelete(paths);
    }
  }

  void copySelectedPaths() {
    _clipboardController.copySelectedPaths(selectedPaths.value);
  }

  void onContextMenu(FileSelectionEvent event) =>
      _selectionController.onContextMenu(event);

  void copySelected() async {
    if (isTrashView) return;
    await _clipboardController.copyEntries(selectedEntries);
  }

  void cutSelected() async {
    if (isTrashView) return;
    await _clipboardController.cutEntries(selectedEntries);
  }

  Future<void> dropFiles(
    List<String> sourcePaths,
    String destination, {
    bool move = false,
  }) async {
    if (isTagPath(destination)) {
      final id = tagIdFromPath(destination);
      if (id != null) await addTag(sourcePaths, id);

      return;
    }
    if (isTrashPath(destination)) return;
    final sep = PlatformPaths.isSftpUri(destination)
        ? '/'
        : PlatformPaths.separator;
    final filtered = sourcePaths.where((s) {
      final parent = PlatformPaths.parentOf(s);
      if (parent == destination) return false;
      if (destination == s) return false;
      if (destination.startsWith('$s$sep')) return false;

      return true;
    }).toList();
    if (filtered.isEmpty) return;
    final archiveLoc = await _archiveLocationFor(destination);
    if (archiveLoc != null) {
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: destination,
        addSources: _physicalList(filtered),
        addInner: archiveLoc.innerPath,
      );

      return;
    }
    final physicalDest = await _resolvePhysicalDestination(destination);
    if (physicalDest == null) return;
    final physicalSources = _physicalList(filtered);
    if (move) {
      operationStore.enqueueMove(physicalSources, physicalDest);
    } else {
      operationStore.enqueueCopy(physicalSources, physicalDest);
    }
  }

  Future<bool> hasPasteableFiles() async {
    return _clipboardController.hasPasteableFiles(isTrashView: isTrashView);
  }

  void paste() async {
    if (isTrashView) return;
    if (isTagView) {
      final id = tagIdFromPath(currentPath.value);
      if (id == null) return;
      final paths = await _clipboardController.readAvailablePaths();
      if (paths.isNotEmpty) await addTag(paths, id);

      return;
    }
    final paste = await _clipboardController.readPastePayload();
    final paths = paste.paths;
    if (paths.isEmpty) return;

    final sep = PlatformPaths.isSftpUri(currentPath.value)
        ? '/'
        : PlatformPaths.separator;
    final filteredPaths = paths.where((s) {
      final parent = PlatformPaths.parentOf(s);
      if (parent == currentPath.value) return false;
      if (currentPath.value == s) return false;
      if (currentPath.value.startsWith('$s$sep')) {
        return false;
      }

      return true;
    }).toList();

    if (filteredPaths.isEmpty) {
      if (paste.isCut && paste.samePaths) {
        _clipboardController.clearInternal(mode: ClipboardMode.copy);
      }

      return;
    }

    final archiveLoc = await _archiveLocationFor(currentPath.value);
    if (archiveLoc != null) {
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: currentPath.value,
        addSources: filteredPaths,
        addInner: archiveLoc.innerPath,
      );
      if (paste.isCut && paste.samePaths) {
        _clipboardController.clearInternal();
      }

      return;
    }

    final physicalDest = await _resolvePhysicalDestination(currentPath.value);
    if (physicalDest == null) return;
    if (paste.isCut) {
      operationStore.enqueueMove(filteredPaths, physicalDest);
      if (paste.samePaths) {
        _clipboardController.clearInternal();
      }
    } else {
      operationStore.enqueueCopy(filteredPaths, physicalDest);
    }
  }

  void jumpToIndex(int index) => _selectionController.jumpToIndex(index);

  void setPageRows(int rows) => _selectionController.setPageRows(rows);

  void setGridColumns(int columns) {
    if (columns > 0) gridColumns.value = columns;
  }

  void moveCursorHorizontally(int delta) =>
      _selectionController.moveCursorHorizontally(delta);

  void moveCursor(int delta) => _selectionController.moveCursor(delta);

  void moveCursorByPage(int dir) => _selectionController.moveCursorByPage(dir);

  void moveCursorToStart() => _selectionController.moveCursorToStart();

  void moveCursorToEnd() => _selectionController.moveCursorToEnd();
}

class _FolderState {
  final Set<String> selectedPaths;
  final String? cursorPath;

  _FolderState({required this.selectedPaths, required this.cursorPath});
}
