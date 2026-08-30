import 'dart:async';

import 'package:flutter/material.dart';

import 'radio_option_group.dart';
import 'responsive_dialog.dart';

/// Input decoration shared by settings dialogs that edit a value inline.
InputDecoration settingsDialogInputDecoration(
  BuildContext context, {
  required String labelText,
  Widget? prefixIcon,
  String? hintText,
  String? helperText,
  String? errorText,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.7);
  final borderRadius = BorderRadius.circular(8);

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    isDense: true,
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48),
  );
}

/// A compact, consistently styled radio list used by settings dialogs.
class CompactRadioOptionGroup<T> extends StatelessWidget {
  const CompactRadioOptionGroup({
    super.key,
    required this.groupValue,
    required this.options,
    required this.onChanged,
  });

  final T? groupValue;
  final List<RadioOption<T>> options;
  final ValueChanged<T> onChanged;

  Widget _buildOption(RadioOption<T> option, ColorScheme colorScheme) {
    final isEnabled = option.enabled ?? true;
    final isSelected = option.selected ?? option.value == groupValue;
    final titleColor = isEnabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final subtitleColor = isEnabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    final hasSubtitle = option.subtitle != null;

    return RadioListTile<T>(
      value: option.value,
      selected: isSelected,
      enabled: isEnabled,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      horizontalTitleGap: 4,
      minLeadingWidth: 32,
      minVerticalPadding: hasSubtitle ? 6 : 0,
      minTileHeight: hasSubtitle ? 68 : 44,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity(
        horizontal: -2,
        vertical: hasSubtitle ? -1 : -2,
      ),
      radioScaleFactor: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.42),
      title: DefaultTextStyle.merge(
        style: TextStyle(
          color: titleColor,
          fontSize: 17,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        child: option.title,
      ),
      subtitle: option.subtitle == null
          ? null
          : DefaultTextStyle.merge(
              style: TextStyle(
                color: subtitleColor,
                fontSize: 13,
                height: 1.25,
              ),
              child: option.subtitle!,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options) _buildOption(option, colorScheme),
        ],
      ),
    );
  }
}

/// Shared settings selection dialog.
///
/// It follows the same title, spacing, width and compact option treatment as
/// [CommonSortDialog], while allowing settings-specific option values.
class CommonOptionDialog<T> extends StatelessWidget {
  const CommonOptionDialog({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon = Icons.tune,
    this.description,
    this.maxWidth = 420,
    this.autoClose = true,
  });

  final String title;
  final IconData? icon;
  final String? description;
  final T? value;
  final List<RadioOption<T>> options;

  /// Returns whether the dialog should close after the value is handled.
  final FutureOr<bool> Function(T value) onChanged;
  final double maxWidth;
  final bool autoClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveDialog(
      maxWidth: maxWidth,
      titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: colorScheme.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          CompactRadioOptionGroup<T>(
            groupValue: value,
            options: options,
            onChanged: (nextValue) async {
              final shouldClose = await onChanged(nextValue);
              if (autoClose && shouldClose && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
