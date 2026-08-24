part of 'navigation_store.dart';

mixin NavigationRenameOps on NavigationStoreHost {
  void startRename() {
    if (isTrashView) return;
    final entries = selectedEntries;
    if (entries.length != 1) return;
    renamingPath.value = entries.first.path;
  }

  void startCreate({FileItemType type = FileItemType.folder}) {
    if (isTrashView) return;
    batch(() {
      pendingCreate.value = FileEntry(
        name: '',
        path: kPendingCreatePath,
        type: type,
        size: 0,
        modified: DateTime.now(),
      );
      renamingPath.value = kPendingCreatePath;
      renameError.value = null;
    });
  }

  void cancelRename() {
    batch(() {
      renamingPath.value = null;
      renameError.value = null;
      pendingCreate.value = null;
    });
    fileListFocusRequest.value++;
  }

  void commitRename(String newName) async {
    final oldPath = renamingPath.value;
    if (oldPath == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      cancelRename();

      return;
    }

    if (oldPath == kPendingCreatePath) {
      await _commitCreate(trimmed);

      return;
    }

    final renameLoc = await _archiveLocationFor(oldPath);
    if (renameLoc != null && !renameLoc.isRoot) {
      operationStore.enqueueArchiveEdit(
        archivePath: renameLoc.archivePath,
        displayDir: currentPath.value,
        renameFromInner: renameLoc.innerPath,
        renameToName: trimmed,
      );
      batch(() {
        renamingPath.value = null;
        renameError.value = null;
      });

      return;
    }

    final isSmbRename = PlatformPaths.isSmbUri(oldPath);
    if (PlatformPaths.isSftpUri(oldPath)) {
      await _commitSftpRename(oldPath, trimmed);

      return;
    }
    final physicalOld = _physical(oldPath);
    final result = FileSystemService.rename(physicalOld, trimmed);

    switch (result) {
      case RenameSuccess(:final newPath):
        final logicalNew = isSmbRename
            ? '${PlatformPaths.parentOf(oldPath)}/$trimmed'
            : newPath;
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
          selectedPaths.value = {logicalNew};
        });
        if (searchActive.value && searchRecursive.value) {
          final updated = searchResults.value.map((e) {
            if (e.path != oldPath) return e;

            return FileEntry(
              name: PlatformPaths.fileName(logicalNew),
              path: logicalNew,
              type: e.type,
              size: e.size,
              modified: e.modified,
            );
          }).toList();
          searchResults.value = updated;
          final idx = updated.indexWhere((f) => f.path == logicalNew);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        } else {
          await refresh();
          final idx = _vf.indexWhere((f) => f.path == logicalNew);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        }
        fileListFocusRequest.value++;
      case RenameAlreadyExists():
        renameError.value = t.toast.renameAlreadyExists(name: trimmed);
        renameAttempt.value = renameAttempt.value + 1;
      case RenameError(:final message):
        renameError.value = t.toast.renameError(message: message);
        renameAttempt.value = renameAttempt.value + 1;
      case RenameInvalidName():
        renameError.value = t.toast.renameInvalidName;
        renameAttempt.value = renameAttempt.value + 1;
      case RenameNoChange():
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
        });
    }
  }

  Future<void> _commitSftpRename(String oldPath, String newName) async {
    if (!PlatformPaths.isValidFileName(newName)) {
      renameError.value = t.toast.renameInvalidName;
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    if (PlatformPaths.fileName(oldPath) == newName) {
      batch(() {
        renamingPath.value = null;
        renameError.value = null;
      });

      return;
    }
    final parent = PlatformPaths.parentOf(oldPath);
    final newPath = '$parent/$newName';
    final fs = const SftpFs();
    if (await fs.exists(newPath)) {
      renameError.value = t.toast.renameAlreadyExists(name: newName);
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    try {
      await fs.rename(oldPath, newPath);
    } catch (e) {
      renameError.value = t.toast.renameError(message: e.toString());
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    batch(() {
      renamingPath.value = null;
      renameError.value = null;
      selectedPaths.value = {newPath};
    });
    await refresh();
    final idx = _vf.indexWhere((f) => f.path == newPath);
    if (idx >= 0) {
      batch(() {
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    }
  }

  Future<MultiRenameOutcome> multiRename(
    List<({String path, String newName})> renames, {
    MultiRenameProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (renames.isEmpty) return const MultiRenameOutcome.empty();
    if (isTrashView) {
      return MultiRenameOutcome(
        succeeded: 0,
        invalid: 0,
        collision: 0,
        other: renames.length,
        blocked: true,
      );
    }
    var processed = 0;
    final total = renames.length;
    var cancelled = false;

    bool shouldStop() {
      cancelled = cancelled || (isCancelled?.call() ?? false);

      return cancelled;
    }

    void report(String currentName) {
      if (total <= 0) return;
      processed++;
      if (processed > total) processed = total;
      onProgress?.call(processed, total, currentName);
    }

    final localOrSmb = <({String path, String newName})>[];
    final sftp = <({String path, String newName})>[];
    final archive = <({ArchiveLocation loc, String oldPath, String newName})>[];

    for (final r in renames) {
      if (shouldStop()) break;
      final loc = await _archiveLocationFor(r.path);
      if (loc != null && !loc.isRoot) {
        archive.add((loc: loc, oldPath: r.path, newName: r.newName));
      } else if (PlatformPaths.isSftpUri(r.path)) {
        sftp.add(r);
      } else {
        localOrSmb.add(r);
      }
    }

    final acc = _MutableOutcome();
    _multiRenameLocal(localOrSmb, acc, report, shouldStop);
    if (!shouldStop()) {
      await _multiRenameSftp(sftp, acc, report, shouldStop);
    }
    if (!shouldStop()) {
      _multiRenameArchive(archive, acc, report, shouldStop);
    }

    batch(() {
      renamingPath.value = null;
      renameError.value = null;
    });
    await refresh();
    if (acc.succeeded > 0) {
      final visiblePaths = _vf.map((f) => f.path).toSet();
      final remaining = selectedPaths.value.intersection(visiblePaths);
      batch(() {
        selectedPaths.value = remaining;
        if (remaining.isEmpty) {
          cursorIndex.value = -1;
          anchorIndex.value = -1;
        }
      });
    }

    return acc.freeze();
  }

  void _multiRenameLocal(
    List<({String path, String newName})> renames,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) {
    if (renames.isEmpty) return;

    final ops = <_LocalRenameOp>[];
    for (final r in renames) {
      if (shouldStop()) return;
      final physicalOld = _physical(r.path);
      final dir = PlatformPaths.parentOf(physicalOld);
      final physicalNew = '$dir${PlatformPaths.separator}${r.newName}';
      if (!PlatformPaths.isValidFileName(r.newName)) {
        acc.invalid++;
        report(r.newName);
        continue;
      }
      if (physicalOld == physicalNew) {
        report(r.newName);
        continue;
      }
      ops.add(
        _LocalRenameOp(
          physicalOld: physicalOld,
          physicalNew: physicalNew,
          newName: r.newName,
        ),
      );
    }

    if (ops.isEmpty) return;

    final sources = ops.map((o) => _norm(o.physicalOld)).toSet();
    final filtered = <_LocalRenameOp>[];
    for (final op in ops) {
      if (shouldStop()) return;
      final exists =
          FileSystemEntity.typeSync(op.physicalNew) !=
          FileSystemEntityType.notFound;
      if (exists && !sources.contains(_norm(op.physicalNew))) {
        acc.collision++;
        report(op.newName);
        continue;
      }
      filtered.add(op);
    }

    final needsTwoPhase = filtered.any(
      (o) => sources.contains(_norm(o.physicalNew)),
    );

    if (needsTwoPhase) {
      _applyTwoPhase(filtered, acc, report, shouldStop);
    } else {
      for (final op in filtered) {
        if (shouldStop()) return;
        _applyDirect(op, acc);
        report(op.newName);
      }
    }
  }

  void _applyDirect(_LocalRenameOp op, _MutableOutcome acc) {
    final r = FileSystemService.rename(op.physicalOld, op.newName);
    switch (r) {
      case RenameSuccess():
        acc.succeeded++;
      case RenameAlreadyExists():
        acc.collision++;
      case RenameInvalidName():
        acc.invalid++;
      case RenameError():
        acc.other++;
      case RenameNoChange():
        break;
    }
  }

  void _applyTwoPhase(
    List<_LocalRenameOp> ops,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final staged = <({String tempPath, String finalName})>[];
    for (var i = 0; i < ops.length; i++) {
      if (shouldStop()) return;
      final op = ops[i];
      final tempName = '.myexplorer-rename-$stamp-$i.tmp';
      final dir = PlatformPaths.parentOf(op.physicalOld);
      final tempPath = '$dir${PlatformPaths.separator}$tempName';
      final r = FileSystemService.rename(op.physicalOld, tempName);
      if (r is RenameSuccess) {
        staged.add((tempPath: tempPath, finalName: op.newName));
      } else {
        switch (r) {
          case RenameAlreadyExists():
            acc.collision++;
          case RenameInvalidName():
            acc.invalid++;
          case RenameError():
            acc.other++;
          default:
            acc.other++;
        }
        report(op.newName);
      }
    }
    for (final s in staged) {
      if (shouldStop()) return;
      final r = FileSystemService.rename(s.tempPath, s.finalName);
      if (r is RenameSuccess) {
        acc.succeeded++;
      } else {
        acc.other++;
      }
      report(s.finalName);
    }
  }

  Future<void> _multiRenameSftp(
    List<({String path, String newName})> renames,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) async {
    if (renames.isEmpty) return;
    final fs = const SftpFs();

    final ops = <_SftpRenameOp>[];
    for (final r in renames) {
      if (shouldStop()) return;
      if (!PlatformPaths.isValidFileName(r.newName)) {
        acc.invalid++;
        report(r.newName);
        continue;
      }
      final parent = PlatformPaths.parentOf(r.path);
      final newPath = '$parent/${r.newName}';
      if (r.path == newPath) {
        report(r.newName);
        continue;
      }
      ops.add(_SftpRenameOp(oldPath: r.path, newPath: newPath));
    }

    final sources = ops.map((o) => o.oldPath).toSet();
    final filtered = <_SftpRenameOp>[];
    for (final op in ops) {
      if (shouldStop()) return;
      if (sources.contains(op.newPath)) {
        filtered.add(op);
        continue;
      }
      if (await fs.exists(op.newPath)) {
        acc.collision++;
        report(PlatformPaths.fileName(op.newPath));
        continue;
      }
      filtered.add(op);
    }

    final needsTwoPhase = filtered.any((o) => sources.contains(o.newPath));
    if (!needsTwoPhase) {
      for (final op in filtered) {
        if (shouldStop()) return;
        try {
          await fs.rename(op.oldPath, op.newPath);
          acc.succeeded++;
        } catch (e, st) {
          log.warn('navigation', 'rename failed', error: e, stack: st);
          acc.other++;
        }
        report(PlatformPaths.fileName(op.newPath));
      }

      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final staged = <({String tempPath, String finalPath})>[];
    for (var i = 0; i < filtered.length; i++) {
      if (shouldStop()) return;
      final op = filtered[i];
      final tempPath =
          '${PlatformPaths.parentOf(op.oldPath)}/.myexplorer-rename-$stamp-$i.tmp';
      try {
        await fs.rename(op.oldPath, tempPath);
        staged.add((tempPath: tempPath, finalPath: op.newPath));
      } catch (e, st) {
        log.warn('navigation', 'rename staging failed', error: e, stack: st);
        acc.other++;
        report(PlatformPaths.fileName(op.newPath));
      }
    }
    for (final s in staged) {
      if (shouldStop()) return;
      try {
        await fs.rename(s.tempPath, s.finalPath);
        acc.succeeded++;
      } catch (e, st) {
        log.warn(
          'navigation',
          'rename finalization failed',
          error: e,
          stack: st,
        );
        acc.other++;
      }
      report(PlatformPaths.fileName(s.finalPath));
    }
  }

  void _multiRenameArchive(
    List<({ArchiveLocation loc, String oldPath, String newName})> renames,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) {
    for (final r in renames) {
      if (shouldStop()) return;
      if (!PlatformPaths.isValidFileName(r.newName)) {
        acc.invalid++;
        report(r.newName);
        continue;
      }
      operationStore.enqueueArchiveEdit(
        archivePath: r.loc.archivePath,
        displayDir: currentPath.value,
        renameFromInner: r.loc.innerPath,
        renameToName: r.newName,
      );
      acc.succeeded++;
      report(r.newName);
    }
  }

  String _norm(String path) =>
      PlatformPaths.isWindows ? path.toLowerCase() : path;

  Future<void> _commitCreate(String name) async {
    final pending = pendingCreate.value;
    if (pending == null) return;
    if (!PlatformPaths.isValidFileName(name)) {
      renameError.value = t.toast.renameInvalidName;
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    final dir = currentPath.value;
    final physicalDir = _physical(dir);
    final physicalNewPath = PlatformPaths.join(physicalDir, name);
    final logicalNewPath = PlatformPaths.isSmbUri(dir)
        ? '$dir/$name'
        : physicalNewPath;
    final exists = PlatformPaths.isSftpUri(physicalNewPath)
        ? await FsWorkerPool.instance.stat(physicalNewPath) != null
        : FileSystemEntity.typeSync(physicalNewPath) !=
              FileSystemEntityType.notFound;
    if (exists) {
      renameError.value = t.toast.renameAlreadyExists(name: name);
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    try {
      if (pending.type == FileItemType.file) {
        await FileSystemService.createFile(physicalNewPath);
      } else {
        await FileSystemService.createDirectory(physicalNewPath);
      }
    } catch (e) {
      renameError.value = t.toast.renameError(message: e.toString());
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    batch(() {
      pendingCreate.value = null;
      renamingPath.value = null;
      renameError.value = null;
    });
    await refresh();
    final idx = _vf.indexWhere((f) => f.path == logicalNewPath);
    if (idx >= 0) {
      batch(() {
        selectedPaths.value = {logicalNewPath};
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    }
    fileListFocusRequest.value++;
  }
}

class MultiRenameOutcome {
  final int succeeded;
  final int invalid;
  final int collision;
  final int other;
  final bool blocked;

  const MultiRenameOutcome({
    required this.succeeded,
    required this.invalid,
    required this.collision,
    required this.other,
    this.blocked = false,
  });

  const MultiRenameOutcome.empty()
    : succeeded = 0,
      invalid = 0,
      collision = 0,
      other = 0,
      blocked = false;

  int get failed => invalid + collision + other;
  int get total => succeeded + failed;
}

typedef MultiRenameProgressCallback =
    void Function(int processed, int total, String currentName);

class _MutableOutcome {
  int succeeded = 0;
  int invalid = 0;
  int collision = 0;
  int other = 0;

  MultiRenameOutcome freeze() => MultiRenameOutcome(
    succeeded: succeeded,
    invalid: invalid,
    collision: collision,
    other: other,
  );
}

class _LocalRenameOp {
  final String physicalOld;
  final String physicalNew;
  final String newName;

  const _LocalRenameOp({
    required this.physicalOld,
    required this.physicalNew,
    required this.newName,
  });
}

class _SftpRenameOp {
  final String oldPath;
  final String newPath;

  const _SftpRenameOp({required this.oldPath, required this.newPath});
}
