import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/models/file_entry.dart';
import '../../i18n/strings.g.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../navigation/navigation_store.dart';
import 'code_editor.dart';
import 'image_preview.dart';
import 'info_panel.dart';
import 'markdown_preview.dart';
import 'pdf_preview.dart';
import 'quick_look_common.dart';
import 'quick_look_io.dart';

/// TC-style quick view panel (Ctrl+Q): a persistent preview strip at the
/// bottom of a pane that follows the *other* pane's cursor entry, updating
/// as the user moves the cursor. Reuses the Quick Look rendering components
/// (image / pdf / markdown / code / properties).
class QuickViewPanel extends StatefulWidget {
  /// The pane whose cursor entry is previewed.
  final NavigationStore source;

  final VoidCallback onClose;

  const QuickViewPanel({
    super.key,
    required this.source,
    required this.onClose,
  });

  @override
  State<QuickViewPanel> createState() => _QuickViewPanelState();
}

class _QuickViewPanelState extends State<QuickViewPanel> {
  final _editorActive = signal(false);
  final _editorController = CodeEditorController();
  bool _showInfo = true;
  bool _markdownRendered = true;

  @override
  void dispose() {
    _editorActive.dispose();
    _editorController.dispose();
    super.dispose();
  }

  void _toggleMarkdownRendered() =>
      setState(() => _markdownRendered = !_markdownRendered);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Column(
        children: [
          _PanelHeader(
            entry: widget.source.cursorEntry.value,
            showInfo: _showInfo,
            markdownRendered: _markdownRendered,
            onToggleInfo: () => setState(() => _showInfo = !_showInfo),
            onToggleMarkdownView: _toggleMarkdownRendered,
            onClose: widget.onClose,
          ),
          Container(height: 1, color: AppColors.bgDivider),
          Expanded(
            child: SignalBuilder(
              builder: (_) {
                final e = widget.source.cursorEntry.value;

                return _PanelBody(
                  entry: e,
                  editorActive: _editorActive,
                  editorController: _editorController,
                  showInfo: _showInfo,
                  markdownRendered: _markdownRendered,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final FileEntry? entry;
  final bool showInfo;
  final bool markdownRendered;
  final VoidCallback onToggleInfo;
  final VoidCallback onToggleMarkdownView;
  final VoidCallback onClose;

  const _PanelHeader({
    required this.entry,
    required this.showInfo,
    required this.markdownRendered,
    required this.onToggleInfo,
    required this.onToggleMarkdownView,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final hasPreview = e != null && e.type != FileItemType.folder;
    final isMarkdown = e != null && markdownExts.contains(e.extension);

    return Container(
      height: 34,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              e?.name ?? t.quickLook.noSelection,
              style: context.txt.bodyEmphasis,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isMarkdown) ...[
            _PanelIconButton(
              icon: markdownRendered
                  ? WaydirIconsRegular.code
                  : WaydirIconsRegular.eye,
              tooltip: markdownRendered
                  ? t.quickLook.viewSource
                  : t.quickLook.viewRendered,
              onTap: onToggleMarkdownView,
            ),
            const SizedBox(width: 4),
          ],
          if (hasPreview) ...[
            _PanelIconButton(
              icon: WaydirIconsRegular.info,
              active: showInfo,
              tooltip: t.menu.properties,
              onTap: onToggleInfo,
            ),
            const SizedBox(width: 4),
          ],
          _PanelIconButton(
            icon: Icons.close,
            tooltip: t.quickLook.hintClose,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _PanelIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _PanelIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  State<_PanelIconButton> createState() => _PanelIconButtonState();
}

class _PanelIconButtonState extends State<_PanelIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? AppColors.accent.withValues(alpha: 0.16)
        : _hover
        ? AppColors.bgHover
        : Colors.transparent;
    final fg = widget.active
        ? AppColors.accent
        : _hover
        ? AppColors.fg
        : AppColors.fgMuted;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(widget.icon, size: 15, color: fg),
          ),
        ),
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  final FileEntry? entry;
  final Signal<bool> editorActive;
  final CodeEditorController editorController;
  final bool showInfo;
  final bool markdownRendered;

  const _PanelBody({
    required this.entry,
    required this.editorActive,
    required this.editorController,
    required this.showInfo,
    required this.markdownRendered,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;

    Widget split(Widget preview) {
      if (!showInfo) return preview;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: preview),
          Container(width: 1, color: AppColors.bgDivider),
          SizedBox(
            width: panelWidth,
            child: InfoPanel(entry: e!),
          ),
        ],
      );
    }

    if (e == null || e.type == FileItemType.folder) {
      return PropertiesOnly(entry: e);
    }
    if (imageExts.contains(e.extension)) {
      return split(ImagePreview(path: e.realPath));
    }
    if (pdfExts.contains(e.extension)) {
      return split(PdfPreview(path: e.realPath));
    }
    if (markdownExts.contains(e.extension) && markdownRendered) {
      return split(MarkdownPreview(entry: e));
    }
    if (binaryExts.contains(e.extension)) {
      return PropertiesOnly(entry: e);
    }

    return _ProbeLoader(
      entry: e,
      editorActive: editorActive,
      editorController: editorController,
      showInfo: showInfo,
    );
  }
}

class _ProbeLoader extends StatelessWidget {
  final FileEntry entry;
  final Signal<bool> editorActive;
  final CodeEditorController editorController;
  final bool showInfo;

  const _ProbeLoader({
    required this.entry,
    required this.editorActive,
    required this.editorController,
    required this.showInfo,
  });

  @override
  Widget build(BuildContext context) {
    Widget split(Widget preview) {
      if (!showInfo) return preview;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: preview),
          Container(width: 1, color: AppColors.bgDivider),
          SizedBox(
            width: panelWidth,
            child: InfoPanel(entry: entry),
          ),
        ],
      );
    }

    return AsyncRetain<Probe>(
      cacheKey: entry.realPath,
      loader: () => probeFile(entry),
      loading: const QlCentered.spinner(),
      builder: (res) {
        switch (res.kind) {
          case QlKind.text:
            return split(
              CodeEditor(
                key: ValueKey(entry.realPath),
                path: entry.realPath,
                extension: entry.extension,
                initial: res.text,
                editorActive: editorActive,
                controller: editorController,
              ),
            );
          case QlKind.binary:
          case QlKind.tooLarge:
          case QlKind.error:
            return PropertiesOnly(entry: entry);
        }
      },
    );
  }
}
