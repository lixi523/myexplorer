import 'dart:async';

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:signals/signals.dart';

import '../../app/launch_args.dart';
import '../../core/database/app_database.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../../core/settings/settings_store.dart';
import '../compare/compare_controller.dart';
import '../navigation/navigation_store.dart';
import '../operations/operation_store.dart';
import '../../ui/overlays/notification_store.dart';
import '../tabs/tabs_store.dart';
import 'pane_store.dart';

class ShellStore {
  /// The single live shell. Set on construction so detached UI (e.g. the
  /// preferences dialog) can open a tab without threading the store through.
  static ShellStore? current;

  /// Always true: the app is permanently in dual-pane mode and can never
  /// switch back to a single pane.
  final isDual = signal(true);
  final panes = signal<List<PaneStore>>([]);
  final activePaneIndex = signal(0);
  final splitRatio = signal(0.5);

  /// Whether each pane shows the TC-style quick view panel (Ctrl+Q) at its
  /// bottom, previewing the *other* pane's cursor entry.
  final quickViewVisible = signal<List<bool>>([false, false]);
  final OperationStore operationStore;
  final NotificationStore notificationStore;
  late final CompareController compare;
  final ready = signal(false);

  late final activePane = computed(() {
    final list = panes.value;
    if (list.isEmpty) return null;
    final idx = activePaneIndex.value;
    if (idx < 0 || idx >= list.length) return list.first;

    return list[idx];
  });

  late final activeStore = computed(() {
    return activePane.value?.tabs.activeTab.value.store;
  });

  void Function()? _persistDisposer;
  Timer? _tabPersistDebounce;

  ShellStore({required this.operationStore, required this.notificationStore}) {
    current = this;
    compare = CompareController(
      panes: panes,
      isDual: isDual,
      operationStore: operationStore,
    );
    _restoreSession();
  }

  void openInNewTab(String path) => activePane.value?.tabs.addTab(path);

  static bool _isRestorablePath(String path) {
    if (isTrashPath(path) ||
        PlatformPaths.isRemoteUri(path) ||
        PlatformPaths.isNetworkPath(path)) {
      return true;
    }
    try {
      return Directory(path).existsSync();
    } catch (e, st) {
      log.warn(
        'shell.restore',
        'restorable path probe failed',
        error: e,
        stack: st,
      );

      return false;
    }
  }

  Future<void> _restoreSession() async {
    try {
      await _buildSession();
    } catch (e, st) {
      log.error('shell.restore', 'Session restore failed', error: e, stack: st);
    }
    if (!ready.value) {
      final home = PlatformPaths.homePath;
      batch(() {
        panes.value = [
          PaneStore(operationStore: operationStore, initialPath: home),
          PaneStore(operationStore: operationStore, initialPath: home),
        ];
        activePaneIndex.value = 0;
        ready.value = true;
      });
    }
    _wirePersistence();
  }

  Future<void> _buildSession() async {
    final s = SettingsStore.instance;
    final db = s.db;

    final launch = LaunchArgs.options;
    if (launch.opensLocation) {
      _buildLaunchSession(launch);

      return;
    }

    final savedTabs = s.restoreSession.value ? await db.getTabs() : const [];

    String initialPathFor() {
      final configured = s.defaultStartingPath.value.trim();
      if (configured.isNotEmpty && Directory(configured).existsSync()) {
        return configured;
      }

      return PlatformPaths.homePath;
    }

    if (savedTabs.isEmpty) {
      final initial = initialPathFor();
      batch(() {
        panes.value = [
          PaneStore(operationStore: operationStore, initialPath: initial),
          PaneStore(operationStore: operationStore, initialPath: initial),
        ];
        ready.value = true;
      });
    } else {
      final paneMap = <int, List<String>>{};
      final activeMap = <int, int>{};
      for (final tab in savedTabs) {
        paneMap.putIfAbsent(tab.paneIndex, () => []);
        paneMap[tab.paneIndex]!.add(tab.path);
        if (tab.isActive) {
          activeMap[tab.paneIndex] = tab.tabIndex;
        }
      }

      final restored = <PaneStore>[];
      final maxPane = paneMap.keys.reduce((a, b) => a > b ? a : b);
      for (int i = 0; i <= maxPane; i++) {
        final paths = paneMap[i] ?? [];
        final validPaths = paths.where(_isRestorablePath).toList();
        restored.add(
          PaneStore.fromPaths(
            operationStore: operationStore,
            paths: validPaths.isEmpty ? [PlatformPaths.homePath] : validPaths,
            activeTabIndex: activeMap[i] ?? 0,
          ),
        );
      }

      // The app is permanently dual-pane: always restore at least two panes.
      final activeIdx = s.sessionActivePaneIndex.value;
      final restoredPanes = _withMinimumTwoPanes(restored);
      batch(() {
        panes.value = restoredPanes;
        splitRatio.value = s.sessionSplitRatio.value.clamp(0.2, 0.8);
        activePaneIndex.value = activeIdx.clamp(0, restoredPanes.length - 1);
        ready.value = true;
      });
    }
  }

  /// Ensures the pane list has at least two panes (the app never runs in a
  /// single-pane layout). The second pane mirrors the first pane's active
  /// path when none was restored.
  List<PaneStore> _withMinimumTwoPanes(List<PaneStore> panes) {
    if (panes.length >= 2) return panes;
    final first = panes.first;
    final mirrorPath = first.tabs.activeTab.value.store.currentPath.value;
    final second = PaneStore(
      operationStore: operationStore,
      initialPath: mirrorPath,
    );

    return [first, second];
  }

  void _buildLaunchSession(LaunchOptions launch) {
    final specs = <TabSpec>[
      for (final folder in launch.folders) TabSpec(folder),
      if (launch.selectPath != null)
        TabSpec(PlatformPaths.parentOf(launch.selectPath!), launch.selectPath),
    ];
    if (specs.isEmpty) specs.add(TabSpec(PlatformPaths.homePath));

    // Always start in dual-pane mode: split the specs across two panes and
    // mirror the first folder when there is only one.
    final List<TabSpec> firstSpecs;
    final List<TabSpec> secondSpecs;
    if (specs.length >= 2) {
      firstSpecs = [specs.first, ...specs.skip(2)];
      secondSpecs = [specs[1]];
    } else {
      firstSpecs = specs;
      secondSpecs = [specs.first];
    }
    batch(() {
      panes.value = [
        PaneStore.fromSpecs(operationStore: operationStore, specs: firstSpecs),
        PaneStore.fromSpecs(operationStore: operationStore, specs: secondSpecs),
      ];
      activePaneIndex.value = 0;
      ready.value = true;
    });
  }

  void _wirePersistence() {
    final s = SettingsStore.instance;
    _persistDisposer = effect(() {
      panes.value;
      for (final pane in panes.value) {
        pane.tabs.tabs.value;
        pane.tabs.activeIndex.value;
        for (final tab in pane.tabs.tabs.value) {
          tab.store.currentPath.value;
        }
      }
      s.sessionIsDual.value = isDual.value;
      s.sessionSplitRatio.value = splitRatio.value;
      s.sessionActivePaneIndex.value = activePaneIndex.value;
      _scheduleTabPersist();
    });
  }

  void _scheduleTabPersist() {
    _tabPersistDebounce?.cancel();
    _tabPersistDebounce = Timer(
      const Duration(milliseconds: 200),
      _persistTabs,
    );
  }

  Future<void> _persistTabs() async {
    try {
      final db = SettingsStore.instance.db;
      final paneList = panes.value;
      final rows = <SessionTabsCompanion>[];
      for (int p = 0; p < paneList.length; p++) {
        final tabs = paneList[p].tabs.tabs.value;
        final activeIdx = paneList[p].tabs.activeIndex.value;
        for (int t = 0; t < tabs.length; t++) {
          rows.add(
            SessionTabsCompanion.insert(
              paneIndex: p,
              tabIndex: t,
              path: tabs[t].store.currentPath.value,
              isActive: Value(t == activeIdx),
            ),
          );
        }
      }
      await db.replaceTabs(rows);
    } catch (e, st) {
      log.error('shell.persist', 'Session persist failed', error: e, stack: st);
    }
  }

  void setActivePane(int index) {
    if (index >= 0 && index < panes.value.length) {
      activePaneIndex.value = index;
    }
  }

  void setSplitRatio(double ratio) {
    splitRatio.value = ratio.clamp(0.2, 0.8);
  }

  /// Toggles the quick view panel of the pane at [slot]. The panel previews
  /// the other pane's cursor entry and lives at the bottom of the pane.
  void toggleQuickView(int slot) {
    final next = [...quickViewVisible.value];
    next[slot] = !next[slot];
    quickViewVisible.value = next;
  }

  Iterable<NavigationStore> get allStores sync* {
    for (final pane in panes.value) {
      for (final tab in pane.tabs.tabs.value) {
        yield tab.store;
      }
    }
  }

  void dispose() {
    compare.dispose();
    _persistDisposer?.call();
    _persistDisposer = null;
    _tabPersistDebounce?.cancel();
    for (final pane in panes.value) {
      pane.dispose();
    }
  }
}
