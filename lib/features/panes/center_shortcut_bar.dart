import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../ui/theme/app_theme.dart';

/// A single icon button in the vertical center shortcut bar.
class CenterShortcutButton {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Optional reactive "active" state (e.g. current view mode); read inside
  /// a [SignalBuilder] so signal dependencies are tracked.
  final bool Function()? isActive;

  const CenterShortcutButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive,
  });
}

/// Vertical shortcut bar placed between the two panes in dual-pane mode.
/// Buttons are laid out top to bottom, mirroring Total Commander's center
/// button column.
class CenterShortcutBar extends StatelessWidget {
  final List<CenterShortcutButton> buttons;

  static const double barWidth = 46;

  const CenterShortcutBar({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CenterShortcutBar.barWidth,
      decoration: BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border.symmetric(
          vertical: BorderSide(color: AppColors.bgDivider),
        ),
      ),
      child: SignalBuilder(
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final button in buttons) ...[
                  _CenterShortcutButtonWidget(button: button),
                  const SizedBox(height: 2),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CenterShortcutButtonWidget extends StatefulWidget {
  final CenterShortcutButton button;

  const _CenterShortcutButtonWidget({required this.button});

  @override
  State<_CenterShortcutButtonWidget> createState() =>
      _CenterShortcutButtonWidgetState();
}

class _CenterShortcutButtonWidgetState
    extends State<_CenterShortcutButtonWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final button = widget.button;
    final active = button.isActive?.call() ?? false;
    final bg = active
        ? AppColors.bgSelectedMuted
        : _hovered
        ? AppColors.bgHover
        : Colors.transparent;
    final fg = active
        ? AppColors.accent
        : _hovered
        ? AppColors.fg
        : AppColors.fgMuted;

    return Tooltip(
      message: button.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: button.onTap,
          child: Container(
            width: CenterShortcutBar.barWidth - 8,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(button.icon, size: 16, color: fg),
          ),
        ),
      ),
    );
  }
}
