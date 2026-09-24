import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/fs/checksum_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/file_entry.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/myexplorer_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_toggle_chip.dart';
import 'checksum_manifest.dart';

/// Creates `.md5` / `.sha256` manifest files for the selected files. One
/// manifest is written per unique parent directory, named after that
/// directory (TC convention: `foldername.md5`).
Future<void> showCreateChecksumManifestDialog({
  required BuildContext context,
  required List<FileEntry> entries,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.bg.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _CreateManifestDialog(entries: entries),
      ),
    ),
  );
}

/// Verifies the files listed in an existing `.md5` / `.sha256` manifest.
Future<void> showVerifyChecksumManifestDialog({
  required BuildContext context,
  required String manifestPath,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.bg.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _VerifyManifestDialog(manifestPath: manifestPath),
      ),
    ),
  );
}

bool isChecksumManifestPath(String path) {
  final lower = path.toLowerCase();

  return lower.endsWith('.md5') || lower.endsWith('.sha256');
}

ChecksumAlgorithm? checksumAlgorithmForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.md5')) return ChecksumAlgorithm.md5;
  if (lower.endsWith('.sha256')) return ChecksumAlgorithm.sha256;

  return null;
}

String manifestFileName(ChecksumAlgorithm algorithm, String dirPath) {
  final folderName = p.basename(dirPath).isEmpty
      ? 'checksums'
      : p.basename(dirPath);

  return '$folderName.${algorithm.name}';
}

class _CreateManifestDialog extends StatefulWidget {
  final List<FileEntry> entries;

  const _CreateManifestDialog({required this.entries});

  @override
  State<_CreateManifestDialog> createState() => _CreateManifestDialogState();
}

class _CreateManifestDialogState extends State<_CreateManifestDialog> {
  ChecksumAlgorithm _algorithm = ChecksumAlgorithm.md5;
  bool _running = false;
  String? _error;
  List<String> _writtenFiles = const [];
  int _generation = 0;

  Future<void> _generate() async {
    if (_running) return;
    final generation = ++_generation;
    setState(() {
      _running = true;
      _error = null;
      _writtenFiles = const [];
    });

    final byDir = <String, List<FileEntry>>{};
    for (final entry in widget.entries) {
      if (entry.type != FileItemType.file) continue;
      final dir = p.dirname(entry.realPath);
      byDir.putIfAbsent(dir, () => []).add(entry);
    }

    final written = <String>[];
    try {
      for (final MapEntry(key: dir, value: files) in byDir.entries) {
        final manifestPath = p.join(dir, manifestFileName(_algorithm, dir));
        final relativePaths = <String>[];
        for (final f in files) {
          relativePaths.add(p.relative(f.realPath, from: dir));
        }
        final digests = <String, String>{};
        for (final f in files) {
          final result = await ChecksumService.calculate(
            f.realPath,
            _algorithm,
          );
          digests[p.relative(f.realPath, from: dir)] = result.digest;
          if (!mounted || generation != _generation) return;
        }
        final content = serializeChecksumManifest(
          relativePaths,
          (rel) => digests[rel] ?? '',
        );
        await File(manifestPath).writeAsString(content, flush: true);
        written.add(manifestPath);
        if (!mounted || generation != _generation) return;
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _writtenFiles = written;
        _running = false;
      });
    } catch (e, st) {
      log.warn('checksum', 'manifest generation failed', error: e, stack: st);
      if (!mounted || generation != _generation) return;
      setState(() {
        _running = false;
        _error = t.checksum.readError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _writtenFiles.isNotEmpty;

    return AppModal(
      icon: MyExplorerIconsRegular.checkSquare,
      iconColor: AppColors.accent,
      title: t.checksum.createManifest,
      width: 520,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.checksum.createManifestFiles(count: widget.entries.length),
            style: context.txt.body.copyWith(color: AppColors.fgMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppToggleChip(
                  label: t.checksum.md5,
                  selected: _algorithm == ChecksumAlgorithm.md5,
                  onTap: () {
                    if (_running) return;
                    setState(() => _algorithm = ChecksumAlgorithm.md5);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppToggleChip(
                  label: t.checksum.sha256,
                  selected: _algorithm == ChecksumAlgorithm.sha256,
                  onTap: () {
                    if (_running) return;
                    setState(() => _algorithm = ChecksumAlgorithm.sha256);
                  },
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: context.txt.captionSmall.copyWith(color: AppColors.danger),
            ),
          ],
          if (_running) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.fgMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Text(t.checksum.calculating, style: context.txt.muted),
              ],
            ),
          ],
          if (done) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final path in _writtenFiles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        path,
                        style: context.txt.captionSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: t.dialog.close,
                color: AppColors.fgMuted,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              DialogButton(
                label: _running ? t.checksum.calculating : t.checksum.create,
                color: _running || done ? AppColors.fgSubtle : AppColors.accent,
                onTap: _running || done ? () {} : _generate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifyManifestDialog extends StatefulWidget {
  final String manifestPath;

  const _VerifyManifestDialog({required this.manifestPath});

  @override
  State<_VerifyManifestDialog> createState() => _VerifyManifestDialogState();
}

class _VerifyManifestDialogState extends State<_VerifyManifestDialog> {
  List<ManifestCheck>? _checks;
  String? _error;
  bool _running = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final generation = ++_generation;
    setState(() {
      _running = true;
      _error = null;
      _checks = null;
    });
    try {
      final content = await File(widget.manifestPath).readAsString();
      final entries = parseChecksumManifest(content);
      if (entries == null || entries.isEmpty) {
        setState(() {
          _running = false;
          _error = t.checksum.manifestEmpty;
        });

        return;
      }
      final algorithm =
          checksumAlgorithmForPath(widget.manifestPath) ??
          ChecksumAlgorithm.md5;
      final baseDir = p.dirname(widget.manifestPath);
      final checks = await ChecksumService.verifyManifest(
        entries: entries,
        baseDir: baseDir,
        algorithm: algorithm,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _checks = checks;
        _running = false;
      });
    } catch (e, st) {
      log.warn('checksum', 'manifest verify failed', error: e, stack: st);
      if (!mounted || generation != _generation) return;
      setState(() {
        _running = false;
        _error = t.checksum.readError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final checks = _checks;
    final okCount =
        checks?.where((c) => c.status == ManifestCheckStatus.ok).length ?? 0;

    return AppModal(
      icon: MyExplorerIconsRegular.checkSquare,
      iconColor: AppColors.accent,
      title: t.checksum.verifyManifest,
      width: 560,
      height: 480,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.basename(widget.manifestPath),
            style: context.txt.bodyEmphasis,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (checks != null)
            Text(
              t.checksum.verifySummary(ok: okCount, total: checks.length),
              style: context.txt.body.copyWith(
                color: okCount == checks.length
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          const SizedBox(height: 10),
          if (_error != null)
            Text(
              _error!,
              style: context.txt.captionSmall.copyWith(color: AppColors.danger),
            ),
          if (_running) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.fgMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Text(t.checksum.calculating, style: context.txt.muted),
              ],
            ),
          ],
          if (checks != null) ...[
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: checks.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.bgDivider,
                ),
                itemBuilder: (_, i) {
                  final check = checks[i];
                  final (color, icon) = switch (check.status) {
                    ManifestCheckStatus.ok => (
                      AppColors.success,
                      MyExplorerIconsRegular.check,
                    ),
                    ManifestCheckStatus.mismatch => (
                      AppColors.danger,
                      MyExplorerIconsRegular.x,
                    ),
                    ManifestCheckStatus.missing => (
                      AppColors.warning,
                      MyExplorerIconsRegular.warning,
                    ),
                    ManifestCheckStatus.error => (
                      AppColors.danger,
                      MyExplorerIconsRegular.warningCircle,
                    ),
                  };

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            check.relativePath,
                            style: context.txt.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: t.dialog.close,
                color: AppColors.fgMuted,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
