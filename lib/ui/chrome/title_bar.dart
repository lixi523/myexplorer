import 'dart:io' show File, Process, ProcessStartMode;

import 'package:signals/signals_flutter.dart';
import '../window/move_window.dart';
import '../window/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../app/app_info.dart';
import '../../app/waydir_app.dart';
import '../../core/database/app_database.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../features/command_palette/command_palette_launcher.dart';
import '../../features/help/changelog_dialog.dart';
import '../../features/help/help_dialog.dart';
import '../../features/navigation/shortcut_bar_store.dart';
import '../../features/navigation/shortcut_icon_loader.dart';
import '../../features/plugins/plugin_icons.dart';
import '../../features/plugins/plugin_models.dart';
import '../../features/settings/keybindings_help_view.dart';
import '../../features/settings/panes/about_pane.dart';
import '../../features/settings/panes/diagnostics_pane.dart';
import '../../features/settings/panes/plugins_pane.dart';
import '../../features/settings/preferences_view.dart';
import '../../i18n/strings.g.dart';
import '../dialogs/shortcut_bar_config_dialog.dart';
import '../overlays/context_menu.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

void _openPreferences() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showPreferencesDialog(ctx);
}

void _openKeybindingsHelp() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showKeybindingsHelp(ctx);
}

void _openInAppTutorial() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showHelpDialog(ctx);
}

void _openChangelog() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showChangelogDialog(ctx);
}

void _openPlugins() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showPluginsDialog(ctx);
}

void _openDiagnostics() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showDiagnosticsDialog(ctx);
}

void _openAbout() {
  final ctx = waydirNavigatorKey.currentContext;
  if (ctx != null) showWaydirAboutDialog(ctx);
}

void _openUrl(String url) {
  Process.start('explorer', [url], mode: ProcessStartMode.detached);
}

void _openRepository() {
  _openUrl('https://github.com/Waydir/Waydir');
}

void _openIssue() {
  _openUrl('https://github.com/Waydir/Waydir/issues/new');
}

class TitleBar extends StatelessWidget {
  final Widget child;
  final Widget? menuTrailing;
  final List<PluginContribution> pluginContributions;
  final ValueChanged<String>? onPluginAction;
  final ValueChanged<String>? onShortcutAction;

  const TitleBar({
    super.key,
    required this.child,
    this.menuTrailing,
    this.pluginContributions = const [],
    this.onPluginAction,
    this.onShortcutAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TitleBarRow(
          menuTrailing: menuTrailing,
          pluginContributions: pluginContributions,
          onPluginAction: onPluginAction,
        ),
        if (onShortcutAction != null) ShortcutBar(onAction: onShortcutAction!),
        Expanded(child: child),
      ],
    );
  }
}

class _TitleBarRow extends StatelessWidget {
  final Widget? menuTrailing;
  final List<PluginContribution> pluginContributions;
  final ValueChanged<String>? onPluginAction;

  const _TitleBarRow({
    this.menuTrailing,
    required this.pluginContributions,
    required this.onPluginAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 19),
          Image.asset(AppInfo.iconAsset, width: 13, height: 13),
          const SizedBox(width: 12),
          _MenuBar(
            trailing: menuTrailing,
            pluginContributions: pluginContributions,
            onPluginAction: onPluginAction,
          ),
          const Expanded(child: MoveWindow()),
          const _CommandPaletteButton(),
          const SizedBox(width: 8),
          const _WindowButtons(),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  final Widget? trailing;
  final List<PluginContribution> pluginContributions;
  final ValueChanged<String>? onPluginAction;

  const _MenuBar({
    this.trailing,
    required this.pluginContributions,
    required this.onPluginAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TitleMenuButton(
          label: t.app.title,
          items: [
            ContextMenuItem(
              icon: WaydirIconsRegular.gearSix,
              label: t.preferences.menuLabel,
              action: 'preferences',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.info,
              label: t.preferences.categories.about,
              action: 'about',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.notebook,
              label: t.appMenu.changelog,
              action: 'changelog',
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              icon: WaydirIconsRegular.signOut,
              label: t.appMenu.quit,
              action: 'quit',
            ),
          ],
          onSelect: (action) {
            switch (action) {
              case 'preferences':
                _openPreferences();
              case 'about':
                _openAbout();
              case 'changelog':
                _openChangelog();
              case 'quit':
                SystemNavigator.pop();
            }
          },
        ),
        ?trailing,
        TitleMenuButton(
          label: t.preferences.plugins.title,
          items: [
            ContextMenuItem(
              icon: WaydirIconsRegular.gearSix,
              label: t.appMenu.managePlugins,
              action: 'manage_plugins',
            ),
            if (pluginContributions.isNotEmpty) ContextMenuItem.divider,
            for (final c in pluginContributions)
              ContextMenuItem(
                icon: pluginGlyph(c.icon),
                label: c.title,
                action: c.fullActionId,
                iconPath: c.iconPath,
                shortcut: c.shortcut,
              ),
          ],
          onSelect: (action) {
            if (action == 'manage_plugins') {
              _openPlugins();
            } else if (action.startsWith('plugin:')) {
              onPluginAction?.call(action);
            }
          },
        ),
        TitleMenuButton(
          label: t.appMenu.help,
          items: [
            ContextMenuItem(
              icon: WaydirIconsRegular.info,
              label: t.help.menuLabel,
              action: 'tutorial',
              shortcut: '?',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.keyboard,
              label: t.keybindings.menuLabel,
              action: 'keybindings',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.bug,
              label: t.preferences.diagnostics.title,
              action: 'diagnostics',
            ),
            ContextMenuItem.divider,
            ContextMenuItem(
              icon: WaydirIconsRegular.gitBranch,
              label: t.appMenu.repository,
              action: 'repository',
            ),
            ContextMenuItem(
              icon: WaydirIconsRegular.arrowSquareOut,
              label: t.appMenu.createIssue,
              action: 'issue',
            ),
          ],
          onSelect: (action) {
            switch (action) {
              case 'tutorial':
                _openInAppTutorial();
              case 'keybindings':
                _openKeybindingsHelp();
              case 'diagnostics':
                _openDiagnostics();
              case 'repository':
                _openRepository();
              case 'issue':
                _openIssue();
            }
          },
        ),
      ],
    );
  }
}

class TitleMenuButton extends StatefulWidget {
  final String label;
  final List<ContextMenuItem> items;
  final void Function(String action) onSelect;

  const TitleMenuButton({
    super.key,
    required this.label,
    required this.items,
    required this.onSelect,
  });

  @override
  State<TitleMenuButton> createState() => _TitleMenuButtonState();
}

class _TitleMenuButtonState extends State<TitleMenuButton> {
  final _key = GlobalKey();
  bool _hovered = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset(0, box.size.height));
    showContextMenu(
      context: context,
      position: pos,
      items: widget.items,
      onSelect: widget.onSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: _key,
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 24,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: context.txt.captionSmall.copyWith(
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandPaletteButton extends StatefulWidget {
  const _CommandPaletteButton();

  @override
  State<_CommandPaletteButton> createState() => _CommandPaletteButtonState();
}

class _CommandPaletteButtonState extends State<_CommandPaletteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final binding = AppShortcuts.getById('command_palette').displayKeys;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: t.commandPalette.title,
        child: GestureDetector(
          onTap: () => CommandPaletteLauncher.instance.open?.call(),
          child: Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : AppColors.bgInput,
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  WaydirIconsRegular.magnifyingGlass,
                  size: 11,
                  color: AppColors.fgSubtle,
                ),
                const SizedBox(width: 7),
                Text(binding, style: context.txt.keyCap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  static final _iconColor = AppColors.fgMuted;
  static final _iconHoverColor = AppColors.fg;

  static final _btnColors = WindowButtonColors(
    iconNormal: _iconColor,
    iconMouseOver: _iconHoverColor,
    mouseOver: AppColors.bgHover,
    mouseDown: AppColors.bgSurface,
  );

  static final _closeColors = WindowButtonColors(
    iconNormal: _iconColor,
    iconMouseOver: Colors.white,
    mouseOver: AppColors.windowCloseHover,
    mouseDown: AppColors.windowClosePressed,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinimizeWindowButton(colors: _btnColors, animate: false),
        MaximizeWindowButton(colors: _btnColors, animate: false),
        CloseWindowButton(colors: _closeColors, animate: false),
      ],
    );
  }
}

class ShortcutBar extends StatefulWidget {
  final ValueChanged<String> onAction;

  const ShortcutBar({super.key, required this.onAction});

  @override
  State<ShortcutBar> createState() => _ShortcutBarState();
}

class _ShortcutBarState extends State<ShortcutBar> {
  final _store = ShortcutBarStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  void _openItem(ShortcutBarItem item) {
    widget.onAction('custom:${item.id}');
  }

  void _openConfig() {
    final ctx = waydirNavigatorKey.currentContext;
    if (ctx != null) showShortcutBarConfigDialog(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          _ShortcutButton(
            icon: WaydirIconsRegular.arrowLeft,
            tooltip: t.keybindings.goBack,
            onTap: () => widget.onAction('go_back'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.arrowRight,
            tooltip: t.keybindings.goForward,
            onTap: () => widget.onAction('go_forward'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.arrowUp,
            tooltip: t.keybindings.goUp,
            onTap: () => widget.onAction('go_up'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.arrowClockwise,
            tooltip: t.keybindings.refresh,
            onTap: () => widget.onAction('refresh'),
          ),
          const SizedBox(width: 12),
          Container(width: 1, color: AppColors.bgDivider),
          const SizedBox(width: 12),
          _ShortcutButton(
            icon: WaydirIconsRegular.folderPlus,
            tooltip: t.keybindings.newFolder,
            onTap: () => widget.onAction('new_folder'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.copy,
            tooltip: t.keybindings.copy,
            onTap: () => widget.onAction('copy'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.scissors,
            tooltip: t.keybindings.cut,
            onTap: () => widget.onAction('cut'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.clipboard,
            tooltip: t.keybindings.paste,
            onTap: () => widget.onAction('paste'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.trashSimple,
            tooltip: t.keybindings.delete,
            onTap: () => widget.onAction('trash'),
          ),
          _ShortcutButton(
            icon: WaydirIconsRegular.info,
            tooltip: t.menu.properties,
            onTap: () => widget.onAction('properties'),
          ),
          const SizedBox(width: 12),
          Container(width: 1, color: AppColors.bgDivider),
          const SizedBox(width: 12),
          SignalBuilder(
            builder: (context) {
              final customItems = _store.items.value;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in customItems)
                    if (item.label.trim().isEmpty && item.target.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 1,
                          height: 20,
                          child: ColoredBox(color: AppColors.bgDivider),
                        ),
                      )
                    else
                      _ShortcutItemButton(
                        item: item,
                        tooltip: item.label.trim().isEmpty
                            ? item.target
                            : item.label,
                        onTap: () => _openItem(item),
                      ),
                ],
              );
            },
          ),
          const Spacer(),
          _ShortcutButton(
            icon: WaydirIconsRegular.list,
            tooltip: t.toolbar.listView,
            onTap: () => widget.onAction('toggle_view'),
          ),
          const SizedBox(width: 8),
          _ShortcutButton(
            icon: WaydirIconsRegular.magnifyingGlass,
            tooltip: t.keybindings.search,
            onTap: () => widget.onAction('search'),
          ),
          const SizedBox(width: 8),
          _ShortcutButton(
            icon: WaydirIconsRegular.plus,
            tooltip: t.preferences.shortcutBar.title,
            onTap: _openConfig,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ShortcutItemButton extends StatefulWidget {
  final ShortcutBarItem item;
  final String tooltip;
  final VoidCallback onTap;

  const _ShortcutItemButton({
    required this.item,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ShortcutItemButton> createState() => _ShortcutItemButtonState();
}

class _ShortcutItemButtonState extends State<_ShortcutItemButton> {
  bool _hovered = false;
  late final bool _isSvg;
  late final Future<ImageProvider?> _iconFuture;

  @override
  void initState() {
    super.initState();
    final spec = widget.item.icon;
    _isSvg = isSvgIconSpec(spec);
    _iconFuture = resolveShortcutIcon(spec);
  }

  Widget _glyph() {
    return Icon(
      WaydirIconsRegular.folderOpen,
      size: 16,
      color: _hovered ? AppColors.fg : AppColors.fgMuted,
    );
  }

  Widget _icon() {
    if (_isSvg) {
      final path = svgIconPath(widget.item.icon);
      if (path != null) {
        return SvgPicture.file(
          File(path),
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        );
      }
    }

    return FutureBuilder<ImageProvider?>(
      future: _iconFuture,
      builder: (context, snapshot) {
        final provider = snapshot.data;
        if (provider != null) {
          return Image(
            image: provider,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _glyph(),
          );
        }

        return _glyph();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _hovered ? AppColors.bgHover : Colors.transparent,
            ),
            child: _icon(),
          ),
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ShortcutButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ShortcutButton> createState() => _ShortcutButtonState();
}

class _ShortcutButtonState extends State<_ShortcutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _hovered ? AppColors.bgHover : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
