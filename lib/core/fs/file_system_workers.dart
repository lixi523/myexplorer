part of 'file_system_service.dart';

void copyWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  final allPaths = <String>[];
  final fileSizes = <String, int>{};
  final sourceRoots = <String>{};
  final visitedDirs = <String>{};
  int totalBytes = 0;
  int totalFiles = 0;
  final conflicts = <ConflictInfo>[];
  Map<String, ConflictResolution> resolutions = {};
  final runtimeResolutions = <String, ConflictResolution>{};
  final pendingConflicts = <String, ConflictInfo>{};
  final promptedSet = <String>{};
  ConflictResolution? runtimeApplyAll;
  Completer<void>? decisionWaker;
  final errors = <TaskError>[];
  String? destination;
  int processedBytes = 0;
  int processedFiles = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;
  var isDuplicate = false;
  var autoOverwriteOlder = false;
  var autoSkipSameSize = false;
  final duplicateRootDest = <String, String>{};

  String rootTargetPath(String src, String dest) {
    final name = src.split(Platform.pathSeparator).last;
    final base = '$dest${Platform.pathSeparator}$name';
    if (!isDuplicate) return base;

    return duplicateRootDest[src] ??= _uniqueName(base);
  }

  void emitPrompt(ConflictInfo info) {
    if (promptedSet.add(info.sourcePath)) {
      mainSendPort.send(ConflictPromptMessage(conflict: info));
    }
  }

  void wakeDecisions() {
    final w = decisionWaker;
    decisionWaker = null;
    w?.complete();
  }

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: processedBytes,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  Future<void> scanEntity(String src, String dest) async {
    final name = src.split(Platform.pathSeparator).last;
    final targetPath = rootTargetPath(src, dest);

    final type = FileSystemEntity.typeSync(src);
    if (type == FileSystemEntityType.notFound) {
      errors.add(TaskError(path: src, message: t.errors.notFound));
      mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));

      return;
    }
    if (type == FileSystemEntityType.directory) {
      allPaths.add(src);
      totalFiles++;
      await _scanDirForCopy(
        Directory(src),
        targetPath,
        visitedDirs,
        (path, bytes, conflict) {
          allPaths.add(path);
          fileSizes[path] = bytes;
          totalFiles++;
          totalBytes += bytes;
          if (conflict != null) conflicts.add(conflict);
        },
        (errorPath, errorMsg) {
          errors.add(TaskError(path: errorPath, message: errorMsg));
          mainSendPort.send(ErrorMessage(path: errorPath, message: errorMsg));
        },
        () => cancelled,
      );
    } else {
      try {
        final sourceStat = FileStat.statSync(src);
        final size = sourceStat.size;
        allPaths.add(src);
        fileSizes[src] = size;
        totalFiles++;
        totalBytes += size;
        final targetStat = FileStat.statSync(targetPath);
        if (targetStat.type != FileSystemEntityType.notFound) {
          conflicts.add(
            ConflictInfo(
              sourcePath: src,
              targetPath: targetPath,
              name: name,
              sourceSize: size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            ),
          );
        }
      } catch (e) {
        errors.add(TaskError(path: src, message: _friendlyError(e)));
        mainSendPort.send(ErrorMessage(path: src, message: _friendlyError(e)));
      }
    }
  }

  String mapDestination(String srcPath, String dest) {
    final sep = Platform.pathSeparator;
    final srcRoot = _findSourceRoot(srcPath, sourceRoots);
    if (srcRoot != null) {
      final relative = srcPath.substring(srcRoot.length);
      if (isDuplicate && duplicateRootDest[srcRoot] != null) {
        return '${duplicateRootDest[srcRoot]}$relative';
      }
      final srcName = srcRoot.split(sep).last;

      return '$dest$sep$srcName$relative';
    }
    final name = srcPath.split(sep).last;

    return '$dest$sep$name';
  }

  Future<bool> processCopyItem(
    String srcPath, {
    bool useAsyncIo = false,
  }) async {
    var resolution =
        runtimeApplyAll ?? runtimeResolutions[srcPath] ?? resolutions[srcPath];
    if (resolution == ConflictResolution.skip) {
      return true;
    }

    var dstPath = mapDestination(srcPath, destination!);
    if (resolution == ConflictResolution.rename) {
      dstPath = _uniqueName(dstPath);
    }

    try {
      final linkType = FileSystemEntity.typeSync(srcPath, followLinks: false);
      if (linkType == FileSystemEntityType.link) {
        final dstDir = dstPath.substring(
          0,
          dstPath.lastIndexOf(Platform.pathSeparator),
        );
        if (!Directory(dstDir).existsSync()) {
          Directory(dstDir).createSync(recursive: true);
        }
        _deleteExistingEntity(dstPath);
        Link(dstPath).createSync(Link(srcPath).targetSync());

        return true;
      }
      final type = linkType;
      if (type == FileSystemEntityType.notFound) {
        errors.add(TaskError(path: srcPath, message: t.errors.notFound));

        return true;
      } else if (type == FileSystemEntityType.file) {
        final targetExists =
            FileSystemEntity.typeSync(dstPath) != FileSystemEntityType.notFound;
        if (resolution != ConflictResolution.overwrite && targetExists) {
          final size = File(srcPath).lengthSync();
          final targetStat = FileStat.statSync(dstPath);
          final sourceStat = FileStat.statSync(srcPath);
          final info = ConflictInfo(
            sourcePath: srcPath,
            targetPath: dstPath,
            name: srcPath.split(Platform.pathSeparator).last,
            sourceSize: size,
            targetSize: targetStat.size,
            sourceModified: sourceStat.modified,
            targetModified: targetStat.modified,
          );

          // Automatic conflict policies (TC parity): resolve without
          // prompting when the user enabled them.
          if (autoSkipSameSize && size == targetStat.size) {
            return true; // skip silently
          }
          if (autoOverwriteOlder) {
            if (sourceStat.modified.isAfter(targetStat.modified) ||
                sourceStat.modified == targetStat.modified) {
              // fall through to overwrite
            } else {
              return true; // source is older → skip
            }
          } else {
            pendingConflicts[srcPath] = info;
            emitPrompt(info);

            return false;
          }
        }

        final dstDir = dstPath.substring(
          0,
          dstPath.lastIndexOf(Platform.pathSeparator),
        );
        if (!Directory(dstDir).existsSync()) {
          Directory(dstDir).createSync(recursive: true);
        }

        final fileName = srcPath.split(Platform.pathSeparator).last;
        await _copyFile(
          File(srcPath),
          dstPath,
          onProgress: (n) {
            processedBytes += n;
            maybeReport(fileName);
          },
          isCancelled: () => cancelled,
          useAsyncIo: useAsyncIo,
        );
      } else if (type == FileSystemEntityType.directory) {
        if (!Directory(dstPath).existsSync()) {
          Directory(dstPath).createSync(recursive: true);
        }
      }
    } catch (e) {
      errors.add(TaskError(path: srcPath, message: _friendlyError(e)));
    }

    return true;
  }

  Future<void> executeCopy() async {
    for (final c in conflicts) {
      pendingConflicts[c.sourcePath] = c;
      if (!resolutions.containsKey(c.sourcePath)) {
        emitPrompt(c);
      }
    }
    while (!cancelled &&
        pendingConflicts.keys.any(
          (s) =>
              runtimeApplyAll == null &&
              runtimeResolutions[s] == null &&
              resolutions[s] == null,
        )) {
      decisionWaker = Completer<void>();
      await decisionWaker!.future;
    }

    final permits = FileSystemService._copyConcurrency;
    var available = permits;
    final waitQueue = <(int, Completer<void>)>[];

    Future<void> acquire(int weight) {
      if (available >= weight) {
        available -= weight;

        return Future<void>.value();
      }
      final c = Completer<void>();
      waitQueue.add((weight, c));

      return c.future;
    }

    void releasePermit(int weight) {
      available += weight;
      while (waitQueue.isNotEmpty && available >= waitQueue.first.$1) {
        final (w, c) = waitQueue.removeAt(0);
        available -= w;
        c.complete();
      }
    }

    final inFlight = <Future<void>>[];
    for (final srcPath in allPaths) {
      if (cancelled) break;

      if (pendingConflicts.containsKey(srcPath) &&
          runtimeApplyAll == null &&
          runtimeResolutions[srcPath] == null &&
          resolutions[srcPath] == null) {
        continue;
      }

      final effRes =
          runtimeApplyAll ??
          runtimeResolutions[srcPath] ??
          resolutions[srcPath];
      final exclusive =
          (fileSizes[srcPath] ?? 0) >= FileSystemService._largeCopyBytes ||
          effRes == ConflictResolution.rename;
      final weight = exclusive ? permits : 1;
      await acquire(weight);
      if (cancelled) {
        releasePermit(weight);
        break;
      }

      inFlight.add(() async {
        try {
          final handled = await processCopyItem(
            srcPath,
            useAsyncIo: !exclusive,
          );
          if (handled) {
            pendingConflicts.remove(srcPath);
            processedFiles++;
            maybeReport(srcPath.split(Platform.pathSeparator).last);
          }
        } finally {
          releasePermit(weight);
        }
      }());
    }
    await Future.wait(inFlight);

    while (pendingConflicts.isNotEmpty && !cancelled) {
      final resolvable = pendingConflicts.keys
          .where(
            (s) =>
                runtimeApplyAll != null ||
                runtimeResolutions[s] != null ||
                resolutions[s] != null,
          )
          .toList();
      if (resolvable.isEmpty) {
        decisionWaker = Completer<void>();
        await decisionWaker!.future;
        continue;
      }
      for (final srcPath in resolvable) {
        if (cancelled) break;
        final handled = await processCopyItem(srcPath);
        if (handled) {
          pendingConflicts.remove(srcPath);
          processedFiles++;
          maybeReport(srcPath.split(Platform.pathSeparator).last);
          if (processedFiles % 4 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
      }
    }

    mainSendPort.send(
      ProgressMessage(
        processedFiles: processedFiles,
        processedBytes: processedBytes,
        currentFile: '',
      ),
    );
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) async {
    try {
      if (msg is StartCommand) {
        destination = msg.destination;
        if (destination == null || destination!.isEmpty) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: true,
              errors: [TaskError(path: '', message: 'missing destination')],
            ),
          );
          workerReceivePort.close();

          return;
        }
        isDuplicate = msg.options['duplicate'] == '1';
        autoOverwriteOlder = msg.options['autoOverwriteOlder'] == '1';
        autoSkipSameSize = msg.options['autoSkipSameSize'] == '1';
        for (final src in msg.sources) {
          if (cancelled) break;
          sourceRoots.add(src);
          await scanEntity(src, destination!);
        }
        if (cancelled) {
          mainSendPort.send(TaskDoneMessage(cancelled: true, errors: errors));
          workerReceivePort.close();

          return;
        }
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: totalBytes,
            allPaths: allPaths,
            conflicts: conflicts,
          ),
        );
      } else if (msg is ExecuteCommand) {
        resolutions = msg.resolutions;
        unawaited(
          executeCopy().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: _friendlyError(e)),
                ],
              ),
            );
            workerReceivePort.close();
          }),
        );
      } else if (msg is ConflictDecisionCommand) {
        if (msg.applyToAll) runtimeApplyAll = msg.resolution;
        runtimeResolutions[msg.sourcePath] = msg.resolution;
        wakeDecisions();
      } else if (msg is CancelCommand) {
        cancelled = true;
        wakeDecisions();
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

void moveWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  final allPaths = <String>[];
  final sourceRoots = <String>{};
  final sourceRootOrder = <String>[];
  final sourceRootCounts = <String, int>{};
  final sourceRootBytes = <String, int>{};
  final visitedDirs = <String>{};
  int totalFiles = 0;
  int totalBytes = 0;
  int processedBytes = 0;
  final conflicts = <ConflictInfo>[];
  Map<String, ConflictResolution> resolutions = {};
  final runtimeResolutions = <String, ConflictResolution>{};
  final pendingConflicts = <String, ConflictInfo>{};
  final promptedSet = <String>{};
  ConflictResolution? runtimeApplyAll;
  Completer<void>? decisionWaker;
  final errors = <TaskError>[];
  String? destination;
  int processedFiles = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void emitPrompt(ConflictInfo info) {
    if (promptedSet.add(info.sourcePath)) {
      mainSendPort.send(ConflictPromptMessage(conflict: info));
    }
  }

  void wakeDecisions() {
    final w = decisionWaker;
    decisionWaker = null;
    w?.complete();
  }

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: processedBytes,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  Future<void> scanEntity(String src, String dest) async {
    final name = src.split(Platform.pathSeparator).last;
    final targetPath = '$dest${Platform.pathSeparator}$name';

    final type = FileSystemEntity.typeSync(src);
    if (type == FileSystemEntityType.notFound) {
      errors.add(TaskError(path: src, message: t.errors.notFound));
      mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));

      return;
    }
    if (type == FileSystemEntityType.directory) {
      allPaths.add(src);
      totalFiles++;
      var rootBytes = 0;
      await _scanDirForMove(
        Directory(src),
        targetPath,
        visitedDirs,
        (path, _) {
          allPaths.add(path);
          totalFiles++;
          if (FileSystemEntity.typeSync(path, followLinks: false) ==
              FileSystemEntityType.file) {
            try {
              final sz = FileStat.statSync(path).size;
              rootBytes += sz;
              totalBytes += sz;
            } catch (e) {
              final msg = _friendlyError(e);
              errors.add(TaskError(path: path, message: msg));
              mainSendPort.send(ErrorMessage(path: path, message: msg));
            }
          }
        },
        (errorPath, errorMsg) {
          errors.add(TaskError(path: errorPath, message: errorMsg));
          mainSendPort.send(ErrorMessage(path: errorPath, message: errorMsg));
        },
        () => cancelled,
      );
      final dirTargetStat = FileStat.statSync(targetPath);
      if (dirTargetStat.type != FileSystemEntityType.notFound) {
        try {
          final targetStat = dirTargetStat;
          final sourceStat = FileStat.statSync(src);
          conflicts.add(
            ConflictInfo(
              sourcePath: src,
              targetPath: targetPath,
              name: name,
              sourceSize: sourceStat.size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            ),
          );
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
      }
      sourceRootBytes[src] = rootBytes;
    } else {
      try {
        allPaths.add(src);
        totalFiles++;
        try {
          final sz = FileStat.statSync(src).size;
          sourceRootBytes[src] = sz;
          totalBytes += sz;
        } catch (e) {
          final msg = _friendlyError(e);
          errors.add(TaskError(path: src, message: msg));
          mainSendPort.send(ErrorMessage(path: src, message: msg));
        }
        final targetStat = FileStat.statSync(targetPath);
        if (targetStat.type != FileSystemEntityType.notFound) {
          final sourceStat = FileStat.statSync(src);
          conflicts.add(
            ConflictInfo(
              sourcePath: src,
              targetPath: targetPath,
              name: name,
              sourceSize: sourceStat.size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            ),
          );
        }
      } catch (e) {
        errors.add(TaskError(path: src, message: _friendlyError(e)));
        mainSendPort.send(ErrorMessage(path: src, message: _friendlyError(e)));
      }
    }
  }

  String mapDestination(String srcPath, String dest) {
    final sep = Platform.pathSeparator;
    final srcRoot = _findSourceRoot(srcPath, sourceRoots);
    if (srcRoot != null) {
      final srcName = srcRoot.split(sep).last;
      final relative = srcPath.substring(srcRoot.length);

      return '$dest$sep$srcName$relative';
    }
    final name = srcPath.split(sep).last;

    return '$dest$sep$name';
  }

  ConflictInfo buildConflictInfo(String src, String dst) {
    final targetStat = FileStat.statSync(dst);
    final sourceStat = FileStat.statSync(src);

    return ConflictInfo(
      sourcePath: src,
      targetPath: dst,
      name: src.split(Platform.pathSeparator).last,
      sourceSize: sourceStat.size,
      targetSize: targetStat.size,
      sourceModified: sourceStat.modified,
      targetModified: targetStat.modified,
    );
  }

  Future<bool> processMoveRoot(String srcPath) async {
    var resolution =
        runtimeApplyAll ?? runtimeResolutions[srcPath] ?? resolutions[srcPath];
    if (resolution == ConflictResolution.skip) {
      return true;
    }

    var dstPath = mapDestination(srcPath, destination!);
    if (resolution == ConflictResolution.rename) {
      dstPath = _uniqueName(dstPath);
    }

    final credit = sourceRootBytes[srcPath] ?? 0;
    void onBytes(int d) {
      processedBytes += d;
      maybeReport(srcPath.split(Platform.pathSeparator).last);
    }

    try {
      final targetType = FileSystemEntity.typeSync(dstPath, followLinks: false);
      if (resolution != ConflictResolution.overwrite &&
          targetType != FileSystemEntityType.notFound) {
        final info = buildConflictInfo(srcPath, dstPath);
        pendingConflicts[srcPath] = info;
        emitPrompt(info);

        return false;
      }
      if (resolution == ConflictResolution.overwrite &&
          targetType != FileSystemEntityType.notFound) {
        final tempDstPath = SafeFileReplace.temporarySiblingPath(dstPath);
        await _moveEntity(
          srcPath,
          tempDstPath,
          () => cancelled,
          null,
          renameCreditBytes: credit,
          onBytes: onBytes,
        );
        if (cancelled) return true;
        if (targetType == FileSystemEntityType.file ||
            targetType == FileSystemEntityType.link) {
          SafeFileReplace.replaceWithFile(tempDstPath, dstPath);
        } else {
          _deleteExistingEntity(dstPath);
          await _moveEntity(tempDstPath, dstPath, () => false, null);
        }

        return true;
      }
      final dstDir = dstPath.substring(
        0,
        dstPath.lastIndexOf(Platform.pathSeparator),
      );
      if (!Directory(dstDir).existsSync()) {
        Directory(dstDir).createSync(recursive: true);
      }
      await _moveEntity(
        srcPath,
        dstPath,
        () => cancelled,
        null,
        renameCreditBytes: credit,
        onBytes: onBytes,
      );
    } catch (e) {
      errors.add(TaskError(path: srcPath, message: _friendlyError(e)));
    }

    return true;
  }

  Future<void> executeMove() async {
    for (final c in conflicts) {
      pendingConflicts[c.sourcePath] = c;
      if (!resolutions.containsKey(c.sourcePath)) {
        emitPrompt(c);
      }
    }
    while (!cancelled &&
        pendingConflicts.keys.any(
          (s) =>
              runtimeApplyAll == null &&
              runtimeResolutions[s] == null &&
              resolutions[s] == null,
        )) {
      decisionWaker = Completer<void>();
      await decisionWaker!.future;
    }

    for (final srcPath in sourceRootOrder) {
      if (cancelled) break;

      if (pendingConflicts.containsKey(srcPath) &&
          runtimeApplyAll == null &&
          runtimeResolutions[srcPath] == null &&
          resolutions[srcPath] == null) {
        continue;
      }

      final handled = await processMoveRoot(srcPath);
      if (handled) {
        pendingConflicts.remove(srcPath);
        processedFiles += sourceRootCounts[srcPath] ?? 1;
        if (processedFiles > totalFiles) processedFiles = totalFiles;
        maybeReport(srcPath.split(Platform.pathSeparator).last);
        await Future.delayed(Duration.zero);
      }
    }

    while (pendingConflicts.isNotEmpty && !cancelled) {
      final resolvable = pendingConflicts.keys
          .where(
            (s) =>
                runtimeApplyAll != null ||
                runtimeResolutions[s] != null ||
                resolutions[s] != null,
          )
          .toList();
      if (resolvable.isEmpty) {
        decisionWaker = Completer<void>();
        await decisionWaker!.future;
        continue;
      }
      for (final srcPath in resolvable) {
        if (cancelled) break;
        final handled = await processMoveRoot(srcPath);
        if (handled) {
          pendingConflicts.remove(srcPath);
          processedFiles += sourceRootCounts[srcPath] ?? 1;
          if (processedFiles > totalFiles) processedFiles = totalFiles;
          maybeReport(srcPath.split(Platform.pathSeparator).last);
          await Future.delayed(Duration.zero);
        }
      }
    }

    mainSendPort.send(
      ProgressMessage(
        processedFiles: processedFiles,
        processedBytes: processedBytes,
        currentFile: '',
      ),
    );
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) async {
    try {
      if (msg is StartCommand) {
        destination = msg.destination;
        if (destination == null || destination!.isEmpty) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: true,
              errors: [TaskError(path: '', message: 'missing destination')],
            ),
          );
          workerReceivePort.close();

          return;
        }
        for (final src in msg.sources) {
          if (cancelled) break;
          sourceRoots.add(src);
          sourceRootOrder.add(src);
          final before = totalFiles;
          await scanEntity(src, destination!);
          sourceRootCounts[src] = totalFiles - before;
        }
        if (cancelled) {
          mainSendPort.send(TaskDoneMessage(cancelled: true, errors: errors));
          workerReceivePort.close();

          return;
        }
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: totalBytes,
            allPaths: allPaths,
            conflicts: conflicts,
          ),
        );
      } else if (msg is ExecuteCommand) {
        resolutions = msg.resolutions;
        unawaited(
          executeMove().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: _friendlyError(e)),
                ],
              ),
            );
            workerReceivePort.close();
          }),
        );
      } else if (msg is ConflictDecisionCommand) {
        if (msg.applyToAll) runtimeApplyAll = msg.resolution;
        runtimeResolutions[msg.sourcePath] = msg.resolution;
        wakeDecisions();
      } else if (msg is CancelCommand) {
        cancelled = true;
        wakeDecisions();
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

void deleteWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  final allPaths = <String>[];
  final allPathSet = <String>{};
  final pathTypes = <String, FileSystemEntityType>{};
  int totalFiles = 0;
  List<TaskError> errors = [];
  int processedFiles = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: 0,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  void addDeletePath(String path, FileSystemEntityType type) {
    if (!allPathSet.add(path)) return;
    allPaths.add(path);
    pathTypes[path] = type;
    totalFiles++;
  }

  void scanForDelete(List<String> sources) {
    for (final src in sources) {
      final type = FileSystemEntity.typeSync(src, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        errors.add(TaskError(path: src, message: t.errors.notFound));
        mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));
      } else if (type == FileSystemEntityType.directory) {
        final native = MyExplorerCoreLoader.enumerate(src, postorder: false);
        if (native == null) {
          errors.add(
            TaskError(
              path: src,
              message: _friendlyError(
                FileSystemException(t.errors.directoryNotReadable, src),
              ),
            ),
          );
          mainSendPort.send(
            ErrorMessage(path: src, message: t.errors.notFound),
          );
          continue;
        }
        for (final e in FileEntryCodec.decode(native)) {
          addDeletePath(
            e.path,
            e.type == FileItemType.folder
                ? FileSystemEntityType.directory
                : FileSystemEntityType.file,
          );
        }
        addDeletePath(src, FileSystemEntityType.directory);
      } else {
        addDeletePath(src, type);
      }
    }
  }

  Future<void> executeDelete() async {
    final byDepth = <int, List<String>>{};
    for (final path in allPaths) {
      (byDepth[p.split(path).length] ??= <String>[]).add(path);
    }
    final depths = byDepth.keys.toList()..sort((a, b) => b.compareTo(a));

    Future<void> deletePath(String path) async {
      try {
        await _withTransientRetry(() async {
          final type = pathTypes[path];
          if (type == FileSystemEntityType.link) {
            await Link(path).delete();
          } else if (type == FileSystemEntityType.directory) {
            await Directory(path).delete(recursive: false);
          } else if (type == FileSystemEntityType.file) {
            await File(path).delete();
          }
        });
      } catch (e) {
        errors.add(TaskError(path: path, message: _friendlyError(e)));
      }

      processedFiles++;
      maybeReport(path.split(Platform.pathSeparator).last);
    }

    for (final depth in depths) {
      if (cancelled) break;
      final paths = byDepth[depth]!;
      var next = 0;

      Future<void> run() async {
        while (!cancelled && next < paths.length) {
          final path = paths[next++];
          await deletePath(path);
        }
      }

      await Future.wait([
        for (
          var i = 0;
          i < FileSystemService._deleteConcurrency && i < paths.length;
          i++
        )
          run(),
      ]);
    }

    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        scanForDelete(msg.sources);
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: null,
            allPaths: allPaths,
            conflicts: [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeDelete().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

void trashWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  List<String> sources = const [];
  final errors = <TaskError>[];
  int processedFiles = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: 0,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  Future<void> executeTrash() async {
    final service = TrashService.instance;
    if (!cancelled) {
      try {
        final failures = await service.trashAll(sources);
        for (final failure in failures) {
          final message = _friendlyError(
            FileSystemException(failure.message, failure.path),
          );
          errors.add(TaskError(path: failure.path, message: message));
          mainSendPort.send(ErrorMessage(path: failure.path, message: message));
        }
      } catch (e) {
        for (final src in sources) {
          final message = _friendlyError(e);
          errors.add(TaskError(path: src, message: message));
          mainSendPort.send(ErrorMessage(path: src, message: message));
        }
      }
      processedFiles = sources.length;
      maybeReport('');
    }
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        sources = msg.sources;
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: sources.length,
            totalBytes: null,
            allPaths: sources,
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeTrash().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

void trashEntryWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  var type = TaskType.trashDelete;
  var entries = const <TrashEntry>[];
  var cancelled = false;
  final errors = <TaskError>[];
  var processedFiles = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: 0,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  Future<void> executeTrashEntries() async {
    if (PlatformPaths.isWindows && !cancelled) {
      final nativeEntries = entries
          .where((entry) => entry.nativeId != null)
          .toList();
      final ids = [for (final entry in nativeEntries) entry.nativeId!];
      final failures = type == TaskType.trashRestore
          ? MyExplorerCoreLoader.trashRestore(ids)
          : MyExplorerCoreLoader.trashPurge(ids);
      final entriesById = {
        for (final entry in nativeEntries) entry.nativeId!: entry,
      };
      for (final failure in failures) {
        final entry = entriesById[failure.path];
        final path = entry?.virtualPath ?? kTrashPath;
        final message = _friendlyError(
          FileSystemException(failure.message, path),
        );
        errors.add(TaskError(path: path, message: message));
        mainSendPort.send(ErrorMessage(path: path, message: message));
      }
      processedFiles = nativeEntries.length;
      maybeReport('');
    } else {
      final repo = TrashRepository.instance;
      for (final entry in entries) {
        if (cancelled) break;
        try {
          if (type == TaskType.trashRestore) {
            await repo.restore(entry);
          } else {
            await repo.deletePermanently(entry);
          }
        } catch (e) {
          final message = _friendlyError(e);
          errors.add(TaskError(path: entry.virtualPath, message: message));
          mainSendPort.send(
            ErrorMessage(path: entry.virtualPath, message: message),
          );
        }
        processedFiles++;
        maybeReport(entry.displayName);
        if (processedFiles % 4 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    }

    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        type = msg.type;
        entries = _decodeTrashEntries(msg.options['entries'] ?? '[]');
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: entries.length,
            totalBytes: null,
            allPaths: [for (final e in entries) e.virtualPath],
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeTrashEntries().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

List<TrashEntry> _decodeTrashEntries(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];

  return [
    for (final item in decoded)
      if (item is Map)
        TrashEntry(
          virtualPath: item['virtualPath'] as String? ?? '',
          displayName: item['displayName'] as String? ?? '',
          realDataPath: item['realDataPath'] as String? ?? '',
          originalPath: item['originalPath'] as String?,
          deletedAt: DateTime.fromMillisecondsSinceEpoch(
            item['deletedAt'] as int? ?? 0,
          ),
          size: item['size'] as int? ?? 0,
          isDirectory: item['isDirectory'] as bool? ?? false,
          infoPath: item['infoPath'] as String?,
          nativeId: item['nativeId'] as String?,
        ),
  ];
}

void extractWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  List<String> sources = const [];
  String? destination;
  int totalFiles = 0;
  final errors = <TaskError>[];
  int processedFiles = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;
  final conflicts = <ConflictInfo>[];
  final conflictKeys = <String>{};
  Map<String, ConflictResolution> resolutions = {};
  final runtimeResolutions = <String, ConflictResolution>{};
  final promptedSet = <String>{};
  ConflictResolution? runtimeApplyAll;
  Completer<void>? decisionWaker;

  String keyOf(String src, String epath) => '$src\u{0}$epath';

  void wakeDecisions() {
    final w = decisionWaker;
    decisionWaker = null;
    w?.complete();
  }

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: 0,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  bool unresolved(String key) =>
      runtimeApplyAll == null &&
      runtimeResolutions[key] == null &&
      resolutions[key] == null;

  Future<void> executeExtract() async {
    for (final c in conflicts) {
      if (promptedSet.add(c.sourcePath) && unresolved(c.sourcePath)) {
        mainSendPort.send(ConflictPromptMessage(conflict: c));
      }
    }
    while (!cancelled && conflictKeys.any(unresolved)) {
      decisionWaker = Completer<void>();
      await decisionWaker!.future;
    }
    if (cancelled) {
      mainSendPort.send(TaskDoneMessage(cancelled: true, errors: errors));
      workerReceivePort.close();

      return;
    }

    final dest = destination!;
    for (final src in sources) {
      if (cancelled) break;
      try {
        ArchiveReader.extractAllResolved(
          src,
          (epath, isDir) {
            final target = '$dest/$epath';
            if (isDir) return target;
            final key = keyOf(src, epath);
            if (!conflictKeys.contains(key)) return target;
            final res =
                runtimeApplyAll ??
                runtimeResolutions[key] ??
                resolutions[key] ??
                ConflictResolution.overwrite;

            return switch (res) {
              ConflictResolution.skip => null,
              ConflictResolution.rename => _uniqueName(target),
              ConflictResolution.overwrite => target,
            };
          },
          isCancelled: () => cancelled,
          onEntry: (name) {
            processedFiles++;
            maybeReport(name.split('/').last);
          },
        );
      } catch (e) {
        errors.add(TaskError(path: src, message: _friendlyError(e)));
        mainSendPort.send(ErrorMessage(path: src, message: _friendlyError(e)));
      }
      await Future.delayed(Duration.zero);
    }
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        sources = msg.sources;
        destination = msg.destination;
        if (destination == null || destination!.isEmpty) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: true,
              errors: [TaskError(path: '', message: 'missing destination')],
            ),
          );
          workerReceivePort.close();

          return;
        }
        final dest = destination!;
        for (final src in sources) {
          try {
            final entries = ArchiveReader.listEntries(src);
            totalFiles += entries.length;
            for (final e in entries) {
              if (e.isDir) continue;
              final target = '$dest/${e.path}';
              final stat = FileStat.statSync(target);
              if (stat.type == FileSystemEntityType.notFound) continue;
              final key = keyOf(src, e.path);
              conflictKeys.add(key);
              conflicts.add(
                ConflictInfo(
                  sourcePath: key,
                  targetPath: target,
                  name: e.path.split('/').last,
                  sourceSize: e.size,
                  targetSize: stat.size,
                  sourceModified: e.mtimeSeconds > 0
                      ? DateTime.fromMillisecondsSinceEpoch(
                          e.mtimeSeconds * 1000,
                        )
                      : stat.modified,
                  targetModified: stat.modified,
                ),
              );
            }
          } catch (e) {
            final msg = _friendlyError(e);
            errors.add(TaskError(path: src, message: msg));
            mainSendPort.send(ErrorMessage(path: src, message: msg));
          }
        }
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: null,
            allPaths: sources,
            conflicts: conflicts,
          ),
        );
      } else if (msg is ExecuteCommand) {
        resolutions = {...resolutions, ...msg.resolutions};
        unawaited(
          executeExtract().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: _friendlyError(e)),
                ],
              ),
            );
            workerReceivePort.close();
          }),
        );
      } else if (msg is ConflictDecisionCommand) {
        if (msg.applyToAll) runtimeApplyAll = msg.resolution;
        runtimeResolutions[msg.sourcePath] = msg.resolution;
        wakeDecisions();
      } else if (msg is CancelCommand) {
        cancelled = true;
        wakeDecisions();
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

void compressWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  List<String> sources = const [];
  String? destination;
  var format = ArchiveFormat.zip;
  var level = CompressionLevel.normal;
  int totalFiles = 0;
  int totalBytes = 0;
  final errors = <TaskError>[];
  int processedFiles = 0;
  int processedBytes = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: processedBytes,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  Future<void> executeCompress() async {
    try {
      ArchiveWriter.create(
        sources,
        destination!,
        format,
        level,
        isCancelled: () => cancelled,
        onEntry: (name) {
          processedFiles++;
          maybeReport(name.split('/').last);
        },
        onPhase: (label) {
          mainSendPort.send(
            ProgressMessage(
              processedFiles: processedFiles,
              processedBytes: processedBytes,
              currentFile: label,
            ),
          );
        },
        onBytes: (name, bytes) {
          processedBytes += bytes;
          maybeReport(name.split('/').last);
        },
      );
    } catch (e) {
      final message = _friendlyError(e);
      errors.add(TaskError(path: destination ?? '', message: message));
      mainSendPort.send(
        ErrorMessage(path: destination ?? '', message: message),
      );
    }
    if (cancelled || errors.isNotEmpty) {
      try {
        final f = File(destination!);
        if (f.existsSync()) f.deleteSync();
      } catch (e) {
        final msg = _friendlyError(e);
        errors.add(TaskError(path: destination ?? '', message: msg));
        mainSendPort.send(ErrorMessage(path: destination ?? '', message: msg));
      }
    }
    mainSendPort.send(
      ProgressMessage(
        processedFiles: processedFiles,
        processedBytes: processedBytes,
        currentFile: '',
      ),
    );
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        sources = msg.sources;
        destination = msg.destination;
        if (destination == null || destination!.isEmpty) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: true,
              errors: [TaskError(path: '', message: 'missing destination')],
            ),
          );
          workerReceivePort.close();

          return;
        }
        format = ArchiveFormat.values.byName(msg.options['format'] ?? 'zip');
        level = CompressionLevel.values.byName(
          msg.options['level'] ?? 'normal',
        );
        totalFiles = ArchiveWriter.planCount(sources);
        totalBytes = ArchiveWriter.planWorkBytes(sources, format);
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: totalBytes,
            allPaths: sources,
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeCompress().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

void archiveEditWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  List<String> addSources = const [];
  String archivePath = '';
  String addInner = '';
  List<String> deleteInner = const [];
  String? renameFrom;
  String? renameTo;
  int totalFiles = 0;
  final errors = <TaskError>[];
  int processedFiles = 0;
  int processedBytes = 0;
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: processedBytes,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  Future<void> executeEdit() async {
    try {
      ArchiveWriter.mutate(
        archivePath,
        addSources: addSources,
        addInner: addInner,
        deleteInner: deleteInner,
        renameFromInner: renameFrom,
        renameToName: renameTo,
        isCancelled: () => cancelled,
        onEntry: (name) {
          processedFiles++;
          maybeReport(name.split('/').last);
        },
        onPhase: (label) {
          mainSendPort.send(
            ProgressMessage(
              processedFiles: processedFiles,
              processedBytes: processedBytes,
              currentFile: label,
            ),
          );
        },
        onBytes: (name, bytes) {
          processedBytes += bytes;
          maybeReport(name.split('/').last);
        },
      );
    } catch (e) {
      final message = _friendlyError(e);
      errors.add(TaskError(path: archivePath, message: message));
      mainSendPort.send(ErrorMessage(path: archivePath, message: message));
    }
    mainSendPort.send(
      ProgressMessage(
        processedFiles: processedFiles,
        processedBytes: processedBytes,
        currentFile: '',
      ),
    );
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        addSources = msg.sources;
        archivePath = msg.options['archive'] ?? '';
        addInner = msg.options['addInner'] ?? '';
        final del = msg.options['deleteInner'] ?? '';
        deleteInner = del.isEmpty ? const [] : del.split('\n');
        renameFrom = msg.options['renameFrom'];
        renameTo = msg.options['renameTo'];
        totalFiles = ArchiveWriter.editPlanCount(archivePath, addSources);
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: null,
            allPaths: addSources,
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeEdit().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

Future<void> _copyFile(
  File src,
  String dstPath, {
  void Function(int bytes)? onProgress,
  bool Function()? isCancelled,
  bool useAsyncIo = false,
}) async {
  await _withTransientRetry(
    () => SafeFileReplace.copyFile(
      src,
      dstPath,
      onProgress: onProgress,
      isCancelled: isCancelled,
      useAsyncIo: useAsyncIo,
    ),
  );
}

Future<void> _scanDirForCopy(
  Directory dir,
  String dest,
  Set<String> visited,
  void Function(String path, int bytes, ConflictInfo? conflict) onFile,
  void Function(String path, String message) onError,
  bool Function() isCancelled,
) async {
  if (isCancelled()) return;
  final canonical = _resolveCanonical(dir.path);
  if (!visited.add(canonical)) return;
  try {
    var counter = 0;
    for (final entity in dir.listSync(followLinks: false)) {
      if (isCancelled()) return;
      final name = entity.path.split(Platform.pathSeparator).last;
      final targetPath = '$dest${Platform.pathSeparator}$name';
      if (entity is Link) {
        onFile(entity.path, 0, null);
      } else if (entity is Directory) {
        onFile(entity.path, 0, null);
        await _scanDirForCopy(
          entity,
          targetPath,
          visited,
          onFile,
          onError,
          isCancelled,
        );
      } else if (entity is File) {
        try {
          final sourceStat = FileStat.statSync(entity.path);
          final size = sourceStat.size;
          ConflictInfo? conflict;
          final targetStat = FileStat.statSync(targetPath);
          if (targetStat.type != FileSystemEntityType.notFound) {
            conflict = ConflictInfo(
              sourcePath: entity.path,
              targetPath: targetPath,
              name: name,
              sourceSize: size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            );
          }
          onFile(entity.path, size, conflict);
        } catch (e) {
          onError(entity.path, _friendlyError(e));
        }
      }
      if ((++counter & 0x3F) == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  } catch (e) {
    onError(dir.path, _friendlyError(e));
  }
}

Future<void> _scanDirForMove(
  Directory dir,
  String dest,
  Set<String> visited,
  void Function(String path, ConflictInfo? conflict) onEntry,
  void Function(String path, String message) onError,
  bool Function() isCancelled,
) async {
  if (isCancelled()) return;
  final canonical = _resolveCanonical(dir.path);
  if (!visited.add(canonical)) return;
  try {
    var counter = 0;
    for (final entity in dir.listSync(followLinks: false)) {
      if (isCancelled()) return;
      final name = entity.path.split(Platform.pathSeparator).last;
      final targetPath = '$dest${Platform.pathSeparator}$name';
      if (entity is Link) {
        onEntry(entity.path, null);
        continue;
      } else if (entity is Directory) {
        await _scanDirForMove(
          entity,
          targetPath,
          visited,
          onEntry,
          onError,
          isCancelled,
        );
      } else {
        try {
          ConflictInfo? conflict;
          final targetStat = FileStat.statSync(targetPath);
          if (targetStat.type != FileSystemEntityType.notFound) {
            final sourceStat = FileStat.statSync(entity.path);
            conflict = ConflictInfo(
              sourcePath: entity.path,
              targetPath: targetPath,
              name: name,
              sourceSize: sourceStat.size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            );
          }
          onEntry(entity.path, conflict);
        } catch (e) {
          onError(entity.path, _friendlyError(e));
        }
      }
      if ((++counter & 0x3F) == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  } catch (e) {
    onError(dir.path, _friendlyError(e));
  }
}

String? _findSourceRoot(String path, Set<String> sourceRoots) {
  final sep = Platform.pathSeparator;
  String? best;
  for (final candidate in sourceRoots) {
    if (path == candidate) {
      return candidate;
    }
    if (path.startsWith(candidate) &&
        path.length > candidate.length &&
        path[candidate.length] == sep) {
      if (best == null || candidate.length > best.length) {
        best = candidate;
      }
    }
  }

  return best;
}

Future<void> _moveEntity(
  String src,
  String dst,
  bool Function() isCancelled,
  void Function(String currentName)? onProgress, {
  int renameCreditBytes = 0,
  void Function(int delta)? onBytes,
}) async {
  final type = FileSystemEntity.typeSync(src, followLinks: false);
  if (type == FileSystemEntityType.link) {
    await _withTransientRetry(() {
      final target = Link(src).targetSync();
      Link(dst).createSync(target);
      Link(src).deleteSync();
    });

    return;
  }
  if (type == FileSystemEntityType.directory) {
    try {
      await _withTransientRetry(
        () => Directory(src).renameSync(dst),
        retryCrossDevice: false,
      );
      onBytes?.call(renameCreditBytes);
    } on FileSystemException {
      await _copyDirectory(
        Directory(src),
        Directory(dst),
        isCancelled,
        onProgress,
        onBytes,
      );
      if (isCancelled()) return;
      await _withTransientRetry(
        () => Directory(src).deleteSync(recursive: true),
      );
    }
  } else {
    try {
      await _withTransientRetry(
        () => File(src).renameSync(dst),
        retryCrossDevice: false,
      );
      onBytes?.call(renameCreditBytes);
    } on FileSystemException {
      await _copyFile(
        File(src),
        dst,
        onProgress: onBytes == null ? null : (n) => onBytes(n),
        isCancelled: isCancelled,
      );
      if (isCancelled()) {
        return;
      }
      await _withTransientRetry(() => File(src).deleteSync());
    }
  }
}

void _deleteExistingEntity(String path) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.link) {
    Link(path).deleteSync();
  } else if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else if (type == FileSystemEntityType.file) {
    File(path).deleteSync();
  }
}

Future<void> _copyDirectory(
  Directory src,
  Directory dst,
  bool Function() isCancelled,
  void Function(String currentName)? onProgress, [
  void Function(int delta)? onBytes,
]) async {
  if (!dst.existsSync()) dst.createSync(recursive: true);
  int counter = 0;
  for (final entity in src.listSync(followLinks: false)) {
    if (isCancelled()) return;
    final name = entity.path.split(Platform.pathSeparator).last;
    final newPath = '${dst.path}${Platform.pathSeparator}$name';
    if (entity is Link) {
      try {
        Link(newPath).createSync(entity.targetSync());
      } catch (e) {
        throw FileSystemException(_friendlyError(e), newPath);
      }
    } else if (entity is Directory) {
      await _copyDirectory(
        entity,
        Directory(newPath),
        isCancelled,
        onProgress,
        onBytes,
      );
    } else if (entity is File) {
      await _copyFile(
        entity,
        newPath,
        onProgress: onBytes == null ? null : (n) => onBytes(n),
        isCancelled: isCancelled,
      );
      onProgress?.call(name);
    }
    if ((++counter & 0x3F) == 0) {
      await Future.delayed(Duration.zero);
    }
  }
}

String _resolveCanonical(String path) {
  try {
    return File(path).resolveSymbolicLinksSync();
  } catch (e, st) {
    log.warn('fs', 'canonical path resolution failed', error: e, stack: st);

    return path;
  }
}

String _uniqueName(String path) {
  if (!File(path).existsSync() && !Directory(path).existsSync()) return path;
  final dir = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
  final name = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
  final dotIndex = name.lastIndexOf('.');
  for (int counter = 1; counter <= 10000; counter++) {
    final newName = dotIndex > 0
        ? '${name.substring(0, dotIndex)} ($counter)${name.substring(dotIndex)}'
        : '$name ($counter)';
    final newPath = '$dir${Platform.pathSeparator}$newName';
    if (!File(newPath).existsSync() && !Directory(newPath).existsSync()) {
      return newPath;
    }
  }

  return '$dir${Platform.pathSeparator}$name.${DateTime.now().microsecondsSinceEpoch}';
}

Future<T> _withTransientRetry<T>(
  FutureOr<T> Function() operation, {
  bool retryCrossDevice = false,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await Future<T>.sync(operation);
    } on FileSystemException catch (e) {
      if (attempt >= 2 || !_isTransientFsError(e, retryCrossDevice)) {
        rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 40 * (attempt + 1)));
    }
  }
}

bool _isTransientFsError(FileSystemException e, bool retryCrossDevice) {
  final code = e.osError?.errorCode;
  if (code == 1 || code == 93) return true;
  if (code == 18) return retryCrossDevice;
  final msg = e.toString();
  if (msg.contains('errno = 1') || msg.contains('errno = 93')) return true;
  if (msg.contains('errno = 18')) return retryCrossDevice;

  return false;
}

String _friendlyError(Object e) {
  final msg = e.toString();
  if (_isPermissionError(e, msg)) return t.errors.permissionDenied;
  if (e is FileSystemException) {
    if (msg.contains('No space left') ||
        msg.contains('errno = 28') ||
        msg.contains('ERROR_DISK_FULL') ||
        msg.contains('There is not enough space')) {
      return t.errors.noSpace;
    }
    if (msg.contains('Read-only file system') ||
        msg.contains('errno = 30') ||
        msg.contains('ERROR_WRITE_PROTECT')) {
      return t.errors.readOnly;
    }
    if (msg.contains('No such file') ||
        msg.contains('errno = 2') ||
        msg.contains('ERROR_FILE_NOT_FOUND') ||
        msg.contains('ERROR_PATH_NOT_FOUND') ||
        msg.contains('The system cannot find')) {
      return t.errors.notFound;
    }
    if (msg.contains('Directory not empty') ||
        msg.contains('errno = 39') ||
        msg.contains('ERROR_DIR_NOT_EMPTY')) {
      return t.errors.notEmpty;
    }
    if (msg.contains('cross-device') ||
        msg.contains('errno = 18') ||
        msg.contains('ERROR_NOT_SAME_DEVICE')) {
      return t.errors.crossDevice;
    }
    if (e.message.isNotEmpty) return e.message;
  }
  if (msg.length > 120) return '${msg.substring(0, 117)}...';

  return msg;
}

bool _isPermissionError(Object e, String msg) {
  final lower = msg.toLowerCase();
  if (e is FileSystemException) {
    final code = e.osError?.errorCode;
    if (code == 1 || code == 5 || code == 13) return true;
  }

  return lower.contains('permission denied') ||
      lower.contains('access is denied') ||
      lower.contains('access denied') ||
      lower.contains('operation not permitted') ||
      lower.contains('error_access_denied') ||
      lower.contains('unauthorizedaccessexception') ||
      lower.contains('eacces') ||
      lower.contains('eperm') ||
      lower.contains('errno = 1') ||
      lower.contains('errno = 13');
}

/// Splits a single file into numbered parts (`name.001`, `name.002`, …)
/// plus a `name.crc` manifest. Requires [StartCommand] options:
/// `partSize` (bytes). Destination is the output directory.
void splitFileWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  List<String> sources = const [];
  String? destination;
  int partSize = 0;
  int totalBytes = 0;
  int processedFiles = 0;
  int processedBytes = 0;
  final errors = <TaskError>[];
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: processedBytes,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  void reportFinal() {
    mainSendPort.send(
      ProgressMessage(
        processedFiles: processedFiles,
        processedBytes: processedBytes,
        currentFile: '',
      ),
    );
  }

  Future<void> executeSplit() async {
    try {
      for (final src in sources) {
        if (cancelled) break;
        final name = src.split(Platform.pathSeparator).last;
        final base = destination ?? p.dirname(src);
        final partPaths = <String>[];
        final buffer = <int>[];
        var partIndex = 1;
        File partFile = File(
          p.join(base, '$name.${partIndex.toString().padLeft(3, '0')}'),
        );
        IOSink partSink = partFile.openWrite();
        final subscription = File(src).openRead().listen(null);
        try {
          await for (final bytes in File(src).openRead()) {
            if (cancelled) break;
            buffer.addAll(bytes);
            processedBytes += bytes.length;
            while (buffer.length >= partSize) {
              final head = buffer.sublist(0, partSize);
              buffer.removeRange(0, partSize);
              partSink.add(head);
              await partSink.flush();
              await partSink.close();
              await partSink.done;
              partPaths.add(partFile.path);
              partIndex++;
              partFile = File(
                p.join(base, '$name.${partIndex.toString().padLeft(3, '0')}'),
              );
              partSink = partFile.openWrite();
            }
            maybeReport(name);
          }
          if (buffer.isNotEmpty) {
            partSink.add(buffer);
          }
          await partSink.close();
          await partSink.done;
          partPaths.add(partFile.path);
          processedFiles++;
        } finally {
          await subscription.cancel();
        }

        if (cancelled) {
          for (final partPath in partPaths) {
            try {
              if (File(partPath).existsSync()) File(partPath).deleteSync();
            } catch (_) {}
          }
        } else {
          // Write .crc manifest (md5 per part, GNU coreutils format).
          final crc = StringBuffer();
          for (final partPath in partPaths) {
            final digest = await _md5OfFile(partPath);
            crc.writeln(
              '$digest  ${partPath.split(Platform.pathSeparator).last}',
            );
          }
          await File(
            p.join(base, '$name.crc'),
          ).writeAsString(crc.toString(), flush: true);
        }
      }
    } catch (e) {
      final message = _friendlyError(e);
      errors.add(TaskError(path: destination ?? '', message: message));
      mainSendPort.send(
        ErrorMessage(path: destination ?? '', message: message),
      );
    }
    reportFinal();
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        sources = msg.sources;
        destination = msg.destination;
        if (destination == null || destination!.isEmpty) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: true,
              errors: [TaskError(path: '', message: 'missing destination')],
            ),
          );
          workerReceivePort.close();

          return;
        }
        partSize = int.tryParse(msg.options['partSize'] ?? '') ?? 0;
        if (partSize <= 0) {
          final err = TaskError(
            path: sources.firstOrNull ?? '',
            message: t.errors.invalidPartSize,
          );
          errors.add(err);
          mainSendPort.send(ErrorMessage(path: err.path, message: err.message));
          reportFinal();
          mainSendPort.send(
            TaskDoneMessage(cancelled: cancelled, errors: errors),
          );
          workerReceivePort.close();

          return;
        }
        totalBytes = 0;
        for (final s in sources) {
          try {
            totalBytes += File(s).lengthSync();
          } catch (_) {}
        }
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: sources.length,
            totalBytes: totalBytes,
            allPaths: sources,
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeSplit().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

/// Combines numbered parts (`name.001`, …) back into the original file.
/// The first source must be `name.001`; the output is written next to it.
void combineFileWorker(List<dynamic> args) {
  final mainSendPort = args.first as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  bool cancelled = false;
  List<String> sources = const [];
  String? destination;
  int totalBytes = 0;
  int processedFiles = 0;
  int processedBytes = 0;
  final errors = <TaskError>[];
  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void maybeReport(String currentFile) {
    if (reportClock.elapsedMilliseconds - lastReportMs >=
        FileSystemService._progressReportIntervalMs) {
      mainSendPort.send(
        ProgressMessage(
          processedFiles: processedFiles,
          processedBytes: processedBytes,
          currentFile: currentFile,
        ),
      );
      lastReportMs = reportClock.elapsedMilliseconds;
    }
  }

  void reportFinal() {
    mainSendPort.send(
      ProgressMessage(
        processedFiles: processedFiles,
        processedBytes: processedBytes,
        currentFile: '',
      ),
    );
  }

  Future<void> executeCombine() async {
    try {
      if (sources.isEmpty) throw StateError('no sources');
      final first = sources.first;
      final name = first.substring(
        0,
        first.length - 4, // strip .001
      );
      final outPath = p.join(destination ?? p.dirname(first), p.basename(name));
      final output = File(outPath).openWrite();
      try {
        for (final src in sources) {
          if (cancelled) break;
          final bytes = await File(src).readAsBytes();
          output.add(bytes);
          processedBytes += bytes.length;
          processedFiles++;
          maybeReport(p.basename(src));
        }
      } finally {
        await output.close();
      }
      if (cancelled) {
        try {
          if (File(outPath).existsSync()) File(outPath).deleteSync();
        } catch (_) {}
      }
    } catch (e) {
      final message = _friendlyError(e);
      errors.add(TaskError(path: destination ?? '', message: message));
      mainSendPort.send(
        ErrorMessage(path: destination ?? '', message: message),
      );
    }
    reportFinal();
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        sources = msg.sources;
        destination = msg.destination;
        if (destination == null || destination!.isEmpty) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: true,
              errors: [TaskError(path: '', message: 'missing destination')],
            ),
          );
          workerReceivePort.close();

          return;
        }
        totalBytes = 0;
        for (final s in sources) {
          try {
            totalBytes += File(s).lengthSync();
          } catch (_) {}
        }
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: sources.length,
            totalBytes: totalBytes,
            allPaths: sources,
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeCombine().catchError((e, st) {
          mainSendPort.send(
            TaskDoneMessage(
              cancelled: cancelled,
              errors: [
                ...errors,
                TaskError(path: '', message: _friendlyError(e)),
              ],
            ),
          );
          workerReceivePort.close();
        });
      } else if (msg is CancelCommand) {
        cancelled = true;
      }
    } catch (e) {
      mainSendPort.send(
        TaskDoneMessage(
          cancelled: cancelled,
          errors: [
            ...errors,
            TaskError(path: '', message: _friendlyError(e)),
          ],
        ),
      );
      workerReceivePort.close();
    }
  });
}

Future<String> _md5OfFile(String path) async {
  final output = _Md5Sink();
  final input = md5.startChunkedConversion(output);
  await for (final chunk in File(path).openRead()) {
    input.add(chunk);
  }
  input.close();

  return output.value.toString();
}

class _Md5Sink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) {
    _value = data;
  }

  @override
  void close() {}
}
