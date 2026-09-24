part of 'sidebar.dart';

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final bool editing;
  final VoidCallback? onToggle;
  final VoidCallback? onToggleEdit;

  const _SidebarHeader({
    required this.collapsed,
    required this.editing,
    required this.onToggle,
    required this.onToggleEdit,
  });

  @override
  Widget build(BuildContext context) {
    final toggle = _HeaderButton(
      icon: collapsed
          ? MyExplorerIconsRegular.sidebarSimple
          : MyExplorerIconsRegular.caretLeft,
      tooltip: collapsed ? t.sidebar.expand : t.sidebar.collapse,
      onTap: onToggle,
    );

    return Container(
      height: 32,
      padding: EdgeInsets.only(
        left: collapsed ? 0 : 6,
        right: collapsed ? 0 : 10,
      ),
      child: collapsed
          ? Center(child: toggle)
          : Row(
              children: [
                if (onToggleEdit != null)
                  _HeaderButton(
                    icon: editing
                        ? MyExplorerIconsRegular.check
                        : MyExplorerIconsRegular.slidersHorizontal,
                    tooltip: editing
                        ? t.sidebar.editDone
                        : t.sidebar.editLayout,
                    active: editing,
                    onTap: onToggleEdit,
                  ),
                const Spacer(),
                toggle,
              ],
            ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? AppColors.fgAccent
        : (_hovered ? AppColors.fg : AppColors.fgMuted);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.active
                  ? AppColors.bgSelectedMuted
                  : (_hovered ? AppColors.bgHover : Colors.transparent),
              borderRadius: BorderRadius.zero,
            ),
            child: SizedBox(
              width: 26,
              height: 26,
              child: Center(child: Icon(widget.icon, size: 14, color: color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionRailDivider extends StatelessWidget {
  const _SectionRailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Container(height: 1, color: AppColors.bgDivider),
    );
  }
}
