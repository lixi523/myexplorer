import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/settings/color_rule_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_modal.dart';

/// Color palette offered when adding/editing a rule.
const List<Color> _palette = [
  Color(0xFFE5484D), // red
  Color(0xFFB4691E), // brown
  Color(0xFF46A758), // green
  Color(0xFF11A8CD), // cyan
  Color(0xFF3E63DD), // blue
  Color(0xFF8E4EC6), // purple
  Color(0xFFF76B15), // orange
  Color(0xFFD6409F), // pink
];

/// Edits the extension → color rules used to tint file rows.
Future<void> showColorRulesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _ColorRulesDialog(),
      ),
    ),
  );
}

class _ColorRulesDialog extends StatefulWidget {
  const _ColorRulesDialog();

  @override
  State<_ColorRulesDialog> createState() => _ColorRulesDialogState();
}

class _ColorRulesDialogState extends State<_ColorRulesDialog> {
  final _extCtrl = TextEditingController();
  Color _selectedColor = _palette.first;

  @override
  void initState() {
    super.initState();
    _extCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _extCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final ext = _extCtrl.text.trim().replaceAll('.', '');
    if (ext.isEmpty) return;
    ColorRuleStore.instance.addRule(ext, _selectedColor);
    setState(() => _extCtrl.clear());
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.palette_outlined,
      iconColor: AppColors.accent,
      title: t.colorRules.title,
      width: 520,
      height: 520,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.colorRules.hint,
            style: context.txt.body.copyWith(color: AppColors.fgMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _extCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: t.colorRules.extensionHint,
                    hintStyle: context.txt.muted,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                  style: context.txt.body,
                ),
              ),
              const SizedBox(width: 10),
              for (final color in _palette) ...[
                _ColorDot(
                  color: color,
                  selected: color == _selectedColor,
                  onTap: () => setState(() => _selectedColor = color),
                ),
                const SizedBox(width: 6),
              ],
              const SizedBox(width: 4),
              DialogButton(
                label: t.colorRules.add,
                color: _extCtrl.text.trim().isEmpty
                    ? AppColors.fgSubtle
                    : AppColors.accent,
                onTap: _add,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final rules = ColorRuleStore.instance.rules.value;
                if (rules.isEmpty) {
                  return Center(
                    child: Text(t.colorRules.empty, style: context.txt.muted),
                  );
                }

                return ListView.separated(
                  itemCount: rules.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.bgDivider,
                  ),
                  itemBuilder: (_, i) {
                    final rule = rules[i];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: rule.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '.${rule.extension}',
                              style: context.txt.bodyEmphasis,
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => ColorRuleStore.instance.removeRule(
                                rule.extension,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.fgMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              DialogButton(
                label: t.colorRules.reset,
                color: AppColors.fgMuted,
                onTap: () => setState(() {
                  ColorRuleStore.instance.resetDefaults();
                }),
              ),
              const Spacer(),
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

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.fg : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
