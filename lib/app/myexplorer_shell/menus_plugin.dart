part of '../myexplorer_shell.dart';

/// Plugin execution domain: running Lua contributions, applying their
/// effects, driving plugin-initiated file operations and long-running tasks.
/// Split out of `menus.dart` so menu construction stays focused on the UI.
mixin _MyExplorerPluginMixin
    on
        State<MyExplorerShell>,
        _MyExplorerStateBase,
        _MyExplorerActionsMixin,
        _MyExplorerTerminalMixin {
  final Map<String, String> _pluginCustomOperationIds = {};

  List<ContextMenuItem> _backgroundPluginItems() {
    final contributions = PluginStore.instance.backgroundContributions();

    return [
      for (final c in contributions)
        ContextMenuItem(
          icon: pluginGlyph(c.icon),
          label: c.title,
          action: c.fullActionId,
          iconPath: _pluginIconPath(c),
        ),
    ];
  }

  List<ContextMenuItem> _pluginContextItems(List<FileEntry> entries) {
    final contributions = PluginStore.instance.contextContributionsFor(entries);
    ContextMenuItem leaf(PluginContribution c) => ContextMenuItem(
      icon: pluginGlyph(c.icon),
      label: c.title,
      action: c.fullActionId,
      iconPath: _pluginIconPath(c),
    );

    final items = <ContextMenuItem>[];
    final groupIndex = <String, int>{};
    for (final c in contributions) {
      final group = c.group;
      if (group == null) {
        items.add(leaf(c));
        continue;
      }
      final at = groupIndex[group];
      if (at == null) {
        groupIndex[group] = items.length;
        items.add(
          ContextMenuItem(
            icon: pluginGlyph(c.icon),
            label: group,
            action: 'plugin-group:$group',
            iconPath: _pluginIconPath(c),
            children: [leaf(c)],
          ),
        );
      } else {
        final parent = items[at];
        items[at] = ContextMenuItem(
          icon: parent.icon,
          label: parent.label,
          action: parent.action,
          iconPath: parent.iconPath,
          children: [...parent.children!, leaf(c)],
        );
      }
    }

    return items;
  }

  String? _pluginIconPath(PluginContribution c) => c.iconPath;

  /// Guards against a plugin that re-emits `dialog` on every pass, which would
  /// otherwise loop modals forever.
  static const int _maxPluginDialogDepth = 8;

  Future<void> _runPluginAction(
    String fullActionId, {
    bool background = false,
    Map<String, dynamic>? form,
    int depth = 0,
  }) async {
    final contribution = PluginStore.instance.contributionByFullId(
      fullActionId,
    );
    if (contribution == null) return;
    try {
      final store = _active;
      final paths = background
          ? const <String>[]
          : store.selectedEntries.map((e) => e.realPath).toList();
      final effects = await PluginStore.instance.invoke(
        contribution,
        paths: paths,
        dir: store.currentPath.value,
        form: form,
        otherPane: _otherPaneContext(store),
        panes: _allPaneContexts(store),
      );
      if (!mounted) return;
      await _applyPluginEffects(
        effects,
        contribution,
        background: background,
        depth: depth,
      );
    } catch (e, st) {
      log.error(
        'plugins',
        'action ${contribution.fullActionId} failed: $e\n$st',
      );
      if (mounted) _notifyPluginError(contribution, '$e');
    }
  }

  Map<String, dynamic> _paneContext(NavigationStore store) {
    return {
      'dir': store.currentPath.value,
      'paths': store.selectedEntries.map((e) => e.realPath).toList(),
    };
  }

  /// The active tab's store for each open pane, tagged with `active`, so a
  /// plugin can target either side of a dual-pane layout.
  List<Map<String, dynamic>> _allPaneContexts(NavigationStore active) {
    return [
      for (final pane in _shell.panes.value)
        {
          ..._paneContext(pane.tabs.activeTab.value.store),
          'active': identical(pane.tabs.activeTab.value.store, active),
        },
    ];
  }

  /// The inactive pane's context in a dual-pane layout, or null when only one
  /// pane is open. Lets plugins implement copy-to-other-pane, compare, sync.
  Map<String, dynamic>? _otherPaneContext(NavigationStore active) {
    for (final pane in _shell.panes.value) {
      final store = pane.tabs.activeTab.value.store;
      if (!identical(store, active)) return _paneContext(store);
    }

    return null;
  }

  /// Reactive `navigate` and `selection_change` plugin events. Each fires for
  /// the active pane, debounced so rapid cursor/selection changes coalesce.
  void _installPluginEventEffects() {
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        _active.currentPath.value;
        _navEventTimer?.cancel();
        _navEventTimer = Timer(
          const Duration(milliseconds: 120),
          () => _dispatchPluginEvent('navigate'),
        );
      }),
    );
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        _active.selectedPaths.value;
        _selectionEventTimer?.cancel();
        _selectionEventTimer = Timer(
          const Duration(milliseconds: 200),
          () => _dispatchPluginEvent('selection_change'),
        );
      }),
    );
  }

  Future<void> _dispatchPluginEvent(String event) async {
    if (!mounted) return;
    final contributions = PluginStore.instance.eventContributions(event);
    if (contributions.isEmpty) return;
    final store = _active;
    final paths = store.selectedEntries.map((e) => e.realPath).toList();
    final dir = store.currentPath.value;
    final otherPane = _otherPaneContext(store);
    final panes = _allPaneContexts(store);
    for (final c in contributions) {
      try {
        final effects = await PluginStore.instance.invoke(
          c,
          paths: paths,
          dir: dir,
          otherPane: otherPane,
          panes: panes,
        );
        if (!mounted) return;
        await _applyPluginEffects(effects, c, background: true);
      } catch (e, st) {
        log.error(
          'plugins',
          'event $event for ${c.fullActionId} failed: $e\n$st',
        );
      }
    }
  }

  void _notifyPluginError(PluginRuntimeTarget c, String? message) {
    final clean = _cleanPluginError(message);
    _notificationStore.add(
      AppNotification(
        title: c.manifest.name,
        message: clean.isNotEmpty ? clean : t.preferences.plugins.actionFailed,
        type: NotificationType.autoDismiss,
        icon: MyExplorerIconsRegular.gearSix,
        accentColor: AppColors.danger,
      ),
    );
  }

  String _cleanPluginError(String? raw) {
    if (raw == null) return '';
    final firstLine = raw.split('\n').first.trim();

    return firstLine.replaceFirst(RegExp(r'^runtime error:\s*'), '');
  }

  Future<void> _applyPluginEffects(
    List<PluginEffect> effects,
    PluginRuntimeTarget contribution, {
    required bool background,
    int depth = 0,
  }) async {
    for (final effect in effects) {
      switch (effect.type) {
        case 'toast':
          if (effect.message != null) {
            showToast(context: context, message: effect.message!);
          }
        case 'notify':
          _notifyFromPlugin(contribution, effect);
        case 'refresh':
          _active.refresh();
        case 'log':
          log.warn('plugins', effect.message ?? '');
        case 'error':
          _notifyPluginError(contribution, effect.message);
        case 'set_setting':
          final key = effect.data['key'] as String?;
          if (key != null) {
            await PluginSettingsStore.instance.set(
              contribution.pluginId,
              key,
              effect.data['value'],
            );
          }
        case 'operation':
          await _runPluginOperation(effect);
        case 'custom_operation_start':
          _startPluginCustomOperation(contribution, effect);
        case 'custom_operation_update':
          _updatePluginCustomOperation(contribution, effect);
        case 'custom_operation_finish':
          _finishPluginCustomOperation(contribution, effect);
        case 'task':
          _runPluginTask(contribution, effect);
        case 'dialog':
          if (contribution is PluginContribution) {
            await _showPluginDialog(
              contribution,
              effect,
              background: background,
              depth: depth,
            );
          }
      }
      if (!mounted) return;
    }
  }

  void _notifyFromPlugin(PluginRuntimeTarget c, PluginEffect effect) {
    final level = (effect.data['level'] as String? ?? 'info').toLowerCase();
    final persistent = effect.data['persistent'] == true;
    Color? accent;
    switch (level) {
      case 'success':
        accent = AppColors.success;
      case 'warn':
      case 'warning':
        accent = AppColors.warning;
      case 'error':
        accent = AppColors.danger;
    }
    _notificationStore.add(
      AppNotification(
        title: effect.data['title'] as String? ?? c.manifest.name,
        message: effect.message ?? '',
        type: persistent
            ? NotificationType.persistent
            : NotificationType.autoDismiss,
        icon: MyExplorerIconsRegular.gearSix,
        accentColor: accent,
      ),
    );
  }

  Future<void> _runPluginOperation(PluginEffect effect) async {
    final op = effect.data['op'] as String?;
    final src = effect.data['src'] as String?;
    final dst = effect.data['dst'] as String?;
    if (src == null) return;
    switch (op) {
      case 'copy':
        if (dst != null) _operationStore.enqueueCopy([src], dst);
        break;
      case 'move':
        if (dst != null) _operationStore.enqueueMove([src], dst);
        break;
      case 'delete':
        if (await _confirmPluginDelete(src, permanent: true)) {
          _operationStore.enqueueDelete([src]);
        }
        break;
      case 'trash':
        if (await _confirmPluginDelete(src, permanent: false)) {
          _operationStore.enqueueTrash([src]);
        }
        break;
    }
  }

  String? _pluginCustomOperationKey(
    PluginRuntimeTarget contribution,
    PluginEffect effect,
  ) {
    final id = effect.data['id'] as String?;
    if (id == null || id.trim().isEmpty) return null;

    return '${contribution.pluginId}:${id.trim()}';
  }

  void _startPluginCustomOperation(
    PluginRuntimeTarget contribution,
    PluginEffect effect,
  ) {
    final key = _pluginCustomOperationKey(contribution, effect);
    if (key == null) return;

    final existing = _pluginCustomOperationIds.remove(key);
    if (existing != null) {
      _operationStore.finishPluginTask(
        existing,
        success: false,
        cancelled: true,
      );
    }

    final title = effect.data['title'] as String? ?? contribution.manifest.name;
    final task = _operationStore.beginPluginTask(
      title: title,
      totalBytes: (effect.data['total_bytes'] as num?)?.toInt(),
      totalFiles: (effect.data['total_files'] as num?)?.toInt() ?? 0,
    );
    _pluginCustomOperationIds[key] = task.id;
  }

  void _updatePluginCustomOperation(
    PluginRuntimeTarget contribution,
    PluginEffect effect,
  ) {
    final key = _pluginCustomOperationKey(contribution, effect);
    if (key == null) return;
    final taskId = _pluginCustomOperationIds[key];
    if (taskId == null) return;

    final progress = (effect.data['progress'] as num?)?.toDouble();
    _operationStore.updatePluginTask(
      taskId,
      progress: progress,
      processedBytes: (effect.data['processed_bytes'] as num?)?.toInt(),
      totalBytes: (effect.data['total_bytes'] as num?)?.toInt(),
      bytesPerSecond: (effect.data['bytes_per_second'] as num?)?.toDouble(),
      processedFiles: (effect.data['processed_files'] as num?)?.toInt(),
      totalFiles: (effect.data['total_files'] as num?)?.toInt(),
      currentFile: effect.data['message'] as String?,
    );
  }

  void _finishPluginCustomOperation(
    PluginRuntimeTarget contribution,
    PluginEffect effect,
  ) {
    final key = _pluginCustomOperationKey(contribution, effect);
    if (key == null) return;
    final taskId = _pluginCustomOperationIds.remove(key);
    if (taskId == null) return;

    _operationStore.finishPluginTask(
      taskId,
      success: effect.data['success'] != false,
      cancelled: effect.data['cancelled'] == true,
      error: effect.data['error'] as String? ?? '',
    );
  }

  /// Plugins can request destructive ops; gate them behind the same confirm
  /// the UI uses. Permanent deletes always confirm; trash respects the
  /// confirmDelete setting.
  Future<bool> _confirmPluginDelete(
    String path, {
    required bool permanent,
  }) async {
    if (!permanent && !SettingsStore.instance.confirmDelete.value) return true;
    final name = p.basename(path);
    final actionLabel = permanent ? t.dialog.delete : t.dialog.moveToTrash;
    final result = await showCustomDialog<String>(
      context: context,
      title: permanent
          ? t.dialog.confirmDeleteTitle
          : t.dialog.confirmTrashTitle,
      icon: permanent
          ? MyExplorerIconsRegular.trash
          : MyExplorerIconsRegular.trashSimple,
      iconColor: AppColors.danger,
      body: Text(
        permanent
            ? t.dialog.confirmDeleteSingle(name: name)
            : t.dialog.confirmTrashSingle(name: name),
        style: context.txt.body.copyWith(height: 1.4),
      ),
      actions: [
        DialogAction(label: t.dialog.cancel, color: AppColors.fgMuted),
        DialogAction(label: actionLabel, color: AppColors.danger),
      ],
    );

    return result == actionLabel;
  }

  Future<void> _runPluginTask(
    PluginRuntimeTarget c,
    PluginEffect effect,
  ) async {
    final cmd = effect.data['cmd'] as String?;
    if (cmd == null) return;
    final title = effect.data['title'] as String? ?? c.manifest.name;
    final args = (effect.data['args'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final cwd = effect.data['cwd'] as String?;
    if (effect.data['operation'] == true) {
      await _runPluginOperationTask(effect, cmd, args, cwd, title);

      return;
    }
    final notifId =
        'plugin-task-${c.pluginId}-${DateTime.now().microsecondsSinceEpoch}';
    _notificationStore.add(
      AppNotification(
        id: notifId,
        title: title,
        message: t.preferences.plugins.taskRunning,
        type: NotificationType.persistent,
        icon: MyExplorerIconsRegular.gearSix,
      ),
    );
    try {
      final process = await Process.start(
        cmd,
        args,
        workingDirectory: cwd != null && cwd.isNotEmpty ? cwd : null,
      );
      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        _pluginTaskTimeoutFor(effect),
        onTimeout: () {
          timedOut = true;
          process.kill();

          return -1;
        },
      );
      if (!mounted) return;
      final ok = !timedOut && exitCode == 0;
      _notificationStore.add(
        AppNotification(
          id: notifId,
          title: title,
          message: timedOut
              ? t.preferences.plugins.taskTimeout
              : ok
              ? t.preferences.plugins.taskDone
              : t.preferences.plugins.taskFailed(code: exitCode),
          type: NotificationType.autoDismiss,
          icon: MyExplorerIconsRegular.gearSix,
          accentColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
      if (ok) _active.refresh();
    } catch (e) {
      if (!mounted) return;
      _notificationStore.add(
        AppNotification(
          id: notifId,
          title: title,
          message: t.preferences.plugins.taskFailedError(error: '$e'),
          type: NotificationType.autoDismiss,
          icon: MyExplorerIconsRegular.gearSix,
          accentColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _runPluginOperationTask(
    PluginEffect effect,
    String cmd,
    List<String> args,
    String? cwd,
    String title,
  ) async {
    final progress = (effect.data['progress'] as Map?)?.cast<String, dynamic>();
    final usePty = effect.data['pty'] == true;

    Process? process;
    final task = _operationStore.beginPluginTask(
      title: title,
      totalBytes: (progress?['total_bytes'] as num?)?.toInt(),
      totalFiles: (progress?['total_files'] as num?)?.toInt() ?? 0,
      onCancel: () => process?.kill(),
    );

    final stderrTail = StringBuffer();
    void rememberError(String chunk) {
      if (chunk.trim().isEmpty) return;
      stderrTail.write(chunk);
      final text = stderrTail.toString();
      if (text.length > 4096) {
        stderrTail.clear();
        stderrTail.write(text.substring(text.length - 4096));
      }
    }

    void handleOutput(String chunk, {required bool stderr}) {
      if (stderr) rememberError(chunk);
      _updatePluginOperationProgress(task.id, chunk, progress);
    }

    try {
      var runCmd = cmd;
      var runArgs = args;

      try {
        process = await Process.start(
          runCmd,
          runArgs,
          workingDirectory: cwd != null && cwd.isNotEmpty ? cwd : null,
        );
      } on ProcessException catch (e) {
        if (!usePty || runCmd == cmd) rethrow;
        log.warn(
          'plugins',
          'pty wrapper unavailable, running plugin task without pty: $e',
        );
        process = await Process.start(
          cmd,
          args,
          workingDirectory: cwd != null && cwd.isNotEmpty ? cwd : null,
        );
      }
      final stdoutSub = process.stdout
          .transform(utf8.decoder)
          .listen((chunk) => handleOutput(chunk, stderr: false));
      final stderrSub = process.stderr
          .transform(utf8.decoder)
          .listen((chunk) => handleOutput(chunk, stderr: true));

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        _pluginTaskTimeoutFor(effect),
        onTimeout: () {
          timedOut = true;
          process?.kill();

          return -1;
        },
      );
      await stdoutSub.cancel();
      await stderrSub.cancel();

      if (!mounted) return;
      final current = _pluginTaskById(task.id);
      final cancelled = timedOut || current?.status == TaskStatus.cancelling;
      final ok = !cancelled && exitCode == 0;
      _operationStore.finishPluginTask(
        task.id,
        success: ok,
        cancelled: cancelled,
        error: ok ? '' : _pluginTaskError(exitCode, timedOut, stderrTail),
      );
      if (ok) _active.refresh();
    } catch (e) {
      if (!mounted) return;
      _operationStore.finishPluginTask(
        task.id,
        success: false,
        cancelled: false,
        error: e.toString(),
      );
    }
  }

  FileTask? _pluginTaskById(String id) {
    for (final task in _operationStore.tasks.value) {
      if (task.id == id) return task;
    }

    return null;
  }

  String _pluginTaskError(
    int exitCode,
    bool timedOut,
    StringBuffer stderrTail,
  ) {
    if (timedOut) return t.preferences.plugins.taskTimeout;
    final detail = stderrTail.toString().trim();
    if (detail.isNotEmpty) return detail;

    return t.preferences.plugins.taskFailed(code: exitCode);
  }

  void _updatePluginOperationProgress(
    String taskId,
    String chunk,
    Map<String, dynamic>? progress,
  ) {
    if (progress == null) return;
    for (final raw in chunk.split(RegExp(r'[\r\n]+'))) {
      final line = raw
          .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
          .trim();
      if (line.isEmpty) continue;

      final pct = _regexDouble(line, progress['percent_regex'] as String?);
      if (pct != null) {
        _operationStore.updatePluginTask(taskId, progress: pct / 100);
      }

      final message = _regexString(line, progress['message_regex'] as String?);
      final bytes = _regexByteAmount(line, progress['bytes_regex'] as String?);
      final speed = _regexByteAmount(line, progress['speed_regex'] as String?);
      if (message != null || bytes != null || speed != null) {
        _operationStore.updatePluginTask(
          taskId,
          processedBytes: bytes,
          bytesPerSecond: speed?.toDouble(),
          currentFile: message,
        );
      }
    }
  }

  String? _regexString(String line, String? pattern) {
    if (pattern == null || pattern.isEmpty) return null;
    final match = RegExp(pattern).firstMatch(line);
    if (match == null) return null;

    return (match.groupCount >= 1 ? match.group(1) : match.group(0))?.trim();
  }

  double? _regexDouble(String line, String? pattern) {
    final value = _regexString(line, pattern);
    if (value == null) return null;

    return double.tryParse(value);
  }

  int? _regexByteAmount(String line, String? pattern) {
    final value = _regexString(line, pattern);
    if (value == null) return null;

    return _parsePluginByteAmount(value);
  }

  int? _parsePluginByteAmount(String raw) {
    final match = RegExp(
      r'([0-9]+(?:\.[0-9]+)?)\s*([KMGTPE]?)(i?)B',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) return null;
    final prefix = (match.group(2) ?? '').toUpperCase();
    final binary = (match.group(3) ?? '').isNotEmpty;
    final base = binary ? 1024.0 : 1000.0;
    final power = switch (prefix) {
      'K' => 1,
      'M' => 2,
      'G' => 3,
      'T' => 4,
      'P' => 5,
      'E' => 6,
      _ => 0,
    };
    var multiplier = 1.0;
    for (var i = 0; i < power; i++) {
      multiplier *= base;
    }

    return (value * multiplier).round();
  }

  /// Default time budget for a plugin `run_task`, used when the task does not
  /// declare its own `timeout` (seconds). Clamped to [_pluginTaskTimeoutMax].
  static const Duration _pluginTaskTimeout = Duration(minutes: 10);
  static const Duration _pluginTaskTimeoutMax = Duration(hours: 6);

  Duration _pluginTaskTimeoutFor(PluginEffect effect) {
    final secs = (effect.data['timeout'] as num?)?.toInt();
    if (secs == null || secs <= 0) return _pluginTaskTimeout;
    final requested = Duration(seconds: secs);

    return requested > _pluginTaskTimeoutMax
        ? _pluginTaskTimeoutMax
        : requested;
  }

  Future<void> _showPluginDialog(
    PluginContribution c,
    PluginEffect effect, {
    required bool background,
    required int depth,
  }) async {
    if (depth >= _maxPluginDialogDepth) {
      log.warn('plugins', 'dialog depth limit reached for ${c.fullActionId}');

      return;
    }
    final spec = (effect.data['dialog'] as Map?)?.cast<String, dynamic>();
    if (spec == null) return;
    final fields = PluginFormField.listFromJson(spec['fields']);
    final result = await showPluginFormDialog(
      context: context,
      title: spec['title'] as String? ?? c.title,
      fields: fields,
    );
    if (result == null || !mounted) return;
    await _runPluginAction(
      c.fullActionId,
      background: background,
      form: result,
      depth: depth + 1,
    );
  }
}
