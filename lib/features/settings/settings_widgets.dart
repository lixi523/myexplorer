import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/settings/settings_registry.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_dropdown.dart';
import '../../ui/widgets/app_text_field.dart';

/// Anchor keys for deep-linking from the preferences search/left rail into a
/// specific section or setting row.
class PreferenceAnchors {
  final Map<String, GlobalKey> sectionKeys;
  final Map<String, GlobalKey> settingKeys;

  const PreferenceAnchors({
    required this.sectionKeys,
    required this.settingKeys,
  });

  GlobalKey? sectionKey(String id) => sectionKeys[id];
  GlobalKey? settingKey(String id) => settingKeys[id];
}

class SettingsPaneScaffold extends StatelessWidget {
  final List<Widget> children;

  const SettingsPaneScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: children,
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String? anchorId;
  final String title;
  final List<Widget> children;
  final PreferenceAnchors? anchors;

  const SettingsSection({
    super.key,
    this.anchorId,
    required this.title,
    required this.children,
    this.anchors,
  });

  @override
  Widget build(BuildContext context) {
    final anchorKey = anchorId == null ? null : anchors?.sectionKey(anchorId!);

    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: context.txt.fieldLabel.copyWith(color: AppColors.fg),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Container(height: 1, color: AppColors.bgDivider),
                children[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget control;

  final bool stretchControl;

  const SettingsRow({
    super.key,
    required this.label,
    this.hint,
    required this.control,
    this.stretchControl = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.txt.body),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!, style: context.txt.muted),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (stretchControl)
            Flexible(
              flex: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Align(alignment: Alignment.centerRight, child: control),
              ),
            )
          else
            control,
        ],
      ),
    );
  }
}

class RegistrySettingRow extends StatelessWidget {
  final AppSetting<dynamic> setting;
  final PreferenceAnchors? anchors;

  const RegistrySettingRow({super.key, required this.setting, this.anchors});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: anchors?.settingKey(setting.id),
      child: SignalBuilder(
        builder: (_) {
          final stretch = setting is ChoiceSetting || setting is TextSetting;
          final control = switch (setting) {
            ToggleSetting toggle => SettingsToggle(
              value: toggle.value,
              onChanged: (value) => toggle.value = value,
            ),
            ChoiceSetting choice => AppDropdown<dynamic>(
              value: choice.value,
              items: [
                for (final option in choice.choices)
                  AppDropdownItem<dynamic>(
                    value: option.value,
                    label: option.label(),
                    icon: option.icon,
                  ),
              ],
              onChanged: (value) => choice.value = value,
            ),
            TextSetting text => SettingsTextField(setting: text),
            _ => const SizedBox.shrink(),
          };

          return SettingsRow(
            label: setting.label(),
            hint: setting.hint?.call(),
            control: control,
            stretchControl: stretch,
          );
        },
      ),
    );
  }
}

class SettingsTextField extends StatefulWidget {
  final TextSetting setting;

  const SettingsTextField({super.key, required this.setting});

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller;
  late final void Function() _disposeEffect;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.setting.value);
    _controller.addListener(() {
      if (widget.setting.value != _controller.text) {
        widget.setting.value = _controller.text;
      }
    });
    _disposeEffect = effect(() {
      final value = widget.setting.value;
      if (_controller.text == value) return;
      _controller.value = _controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  void dispose() {
    _disposeEffect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: context.txt.body,
      decoration: appInputDecoration(hintText: widget.setting.hintText),
      cursorColor: AppColors.accent,
    );
  }
}

class SettingsToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SettingsToggle> createState() => _SettingsToggleState();
}

class SettingsActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SettingsActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<SettingsActionButton> createState() => _SettingsActionButtonState();
}

class _SettingsActionButtonState extends State<SettingsActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = _hovered ? AppColors.fg : AppColors.fgMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : AppColors.bgInput,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(widget.label, style: context.txt.body.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleState extends State<SettingsToggle> {
  @override
  Widget build(BuildContext context) {
    final on = widget.value;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!on),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: 36,
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : AppColors.bgInput,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: on ? AppColors.accent : AppColors.borderColor,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
