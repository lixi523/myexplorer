part of '../myexplorer_shell.dart';

const _cursorRepeatInterval = Duration(milliseconds: 70);
const _typeAheadResetAfter = Duration(milliseconds: 1500);

mixin _MyExplorerStateBase on State<MyExplorerShell> {
  final _notificationStore = NotificationStore();
  late final _operationStore = OperationStore(
    notificationStore: _notificationStore,
  );
  late final _shell = ShellStore(
    operationStore: _operationStore,
    notificationStore: _notificationStore,
  );
  final _focusNode = FocusNode(debugLabel: 'shell-keys');
  final _effectDisposers = <void Function()>[];

  /// The file the "Open With…" chooser was opened on.
  FileEntry? _openWithEntry;

  /// Resolved "Open with default app" menu items, keyed by lowercased file
  /// extension, plus the set of extensions currently being resolved.
  final Map<String, List<ContextMenuItem>> _openWithCache = {};
  final Set<String> _openWithWarming = {};
  final _renameErrorDisposers = <NavigationStore, void Function()>{};
  final _renameFocusDisposers = <NavigationStore, void Function()>{};
  Timer? _navEventTimer;
  Timer? _selectionEventTimer;
  DateTime? _lastCursorRepeatAt;

  String _typeAheadBuffer = '';
  int _typeAheadIndex = -1;
  DateTime? _typeAheadLastAt;

  NavigationStore get _active {
    final store = _shell.activeStore.value;
    if (store != null) return store;
    for (final pane in _shell.panes.value) {
      for (final tab in pane.tabs.tabs.value) {
        return tab.store;
      }
    }
    // Extremely unlikely: no panes/tabs available. Return first known store
    // from the shell's store list to avoid crashing during transient states.
    return _shell.allStores.first;
  }

  void _installRenameErrorEffects() {
    final currentStores = <NavigationStore>{};
    for (final pane in _shell.panes.value) {
      for (final tab in pane.tabs.tabs.value) {
        final store = tab.store;
        currentStores.add(store);
        if (!_renameErrorDisposers.containsKey(store)) {
          _renameErrorDisposers[store] = effect(() {
            final error = store.renameError.value;
            if (error != null) {
              store.renameError.value = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  showToast(
                    context: context,
                    message: error,
                    duration: const Duration(seconds: 3),
                  );
                }
              });
            }
          });
        }
        if (!_renameFocusDisposers.containsKey(store)) {
          String? previousRenaming = store.renamingPath.peek();
          int previousFocusRequest = store.fileListFocusRequest.peek();
          _renameFocusDisposers[store] = effect(() {
            final current = store.renamingPath.value;
            final focusRequest = store.fileListFocusRequest.value;
            final closed = previousRenaming != null && current == null;
            final requested = focusRequest != previousFocusRequest;
            previousRenaming = current;
            previousFocusRequest = focusRequest;
            if (closed || requested) {
              _scheduleListRefocus(store);
            }
          });
        }
      }
    }
    final existingStores = _renameErrorDisposers.keys.toSet();
    for (final store in existingStores.difference(currentStores)) {
      _renameErrorDisposers.remove(store)?.call();
      _renameFocusDisposers.remove(store)?.call();
    }
  }

  void _scheduleListRefocus(NavigationStore store, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final panes = _shell.panes.peek();
      var paneIndex = -1;
      for (var i = 0; i < panes.length; i++) {
        if (panes[i].tabs.activeTab.peek().store == store) {
          paneIndex = i;
          break;
        }
      }
      if (paneIndex < 0) return;
      if (store.renamingPath.peek() != null) return;
      if (_shell.activePaneIndex.peek() != paneIndex) {
        _shell.setActivePane(paneIndex);
      }
      if (store.searchActive.peek()) return;
      _focusNode.requestFocus();
      if (attempt < 8) _scheduleListRefocus(store, attempt + 1);
    });
  }

  bool _isEditableFocused() {
    final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
    if (primaryFocus == null || primaryFocus == _focusNode) return false;
    final ctx = primaryFocus.context;
    if (ctx == null) return true;
    if (ctx.widget is EditableText) return true;
    bool found = false;
    ctx.visitAncestorElements((el) {
      if (el.widget is EditableText) {
        found = true;

        return false;
      }

      return true;
    });

    return found;
  }

  bool _isModalRouteOnTop() {
    final navigator = Navigator.maybeOf(context);

    return navigator != null && navigator.canPop();
  }

  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isEditableFocused()) return;
      _focusNode.requestFocus();
    });
  }

  VoidCallback _activatePane(int index) {
    return () {
      _shell.setActivePane(index);
      _restoreFocus();
    };
  }

  void _openInNewTab(String path) {
    final pane = _shell.activePane.value;
    if (pane != null) pane.tabs.addTab(path);
  }

  void _setShowHiddenGlobal(bool value) {
    SettingsStore.instance.showHiddenDefault.value = value;
    if (!_shell.ready.value) return;
    for (final store in _shell.allStores) {
      store.showHidden.value = value;
    }
  }

  void _toggleShowHiddenGlobal() {
    if (!_shell.ready.value) return;
    _setShowHiddenGlobal(!SettingsStore.instance.showHiddenDefault.value);
  }
}
