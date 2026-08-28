import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/snackbar_util.dart';
import '../utils/ui_tokens.dart';
import 'scrollable_appbar.dart';

class SettingsSubpageScaffold extends StatelessWidget {
  const SettingsSubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.onRestoreDefaults,
    this.restoreDefaultsTooltip,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onRestoreDefaults;
  final String? restoreDefaultsTooltip;

  @override
  Widget build(BuildContext context) {
    final appBarActions = <Widget>[
      if (onRestoreDefaults != null)
        IconButton(
          onPressed: onRestoreDefaults,
          icon: const Icon(Icons.restart_alt),
          tooltip:
              restoreDefaultsTooltip ?? S.of(context).restoreDefaultSettings,
        ),
      ...actions,
    ];

    return Scaffold(
      appBar: ScrollableAppBar(
        title: Text(title, style: UiTextStyles.pageTitle),
        actions: appBarActions.isEmpty ? null : appBarActions,
      ),
      body: body,
    );
  }
}

Future<bool> showSettingsResetConfirmation({
  required BuildContext context,
  required String message,
  String? title,
  String? confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title ?? S.of(dialogContext).restoreDefaultSettings),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(S.of(dialogContext).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel ?? S.of(dialogContext).confirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> confirmAndRestoreSettingsDefaults({
  required BuildContext context,
  required Future<void> Function() restore,
  Future<void> Function()? afterRestore,
  String? title,
  String? message,
  String? confirmLabel,
}) async {
  final confirmed = await showSettingsResetConfirmation(
    context: context,
    title: title,
    message: message ?? S.of(context).confirmRestoreDefaultSettings,
    confirmLabel: confirmLabel,
  );
  if (!confirmed || !context.mounted) return false;

  await restore();
  if (!context.mounted) return true;
  await afterRestore?.call();
  if (context.mounted) {
    SnackBarUtil.showSuccess(context, S.of(context).restoredToDefault);
  }
  return true;
}

typedef SettingsReorderItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

class SettingsReorderablePage<T> extends StatelessWidget {
  const SettingsReorderablePage({
    super.key,
    required this.title,
    required this.infoTitle,
    required this.infoDescription,
    required this.items,
    required this.itemKey,
    required this.itemBuilder,
    required this.onOrderChanged,
    required this.onRestoreDefaults,
  });

  final String title;
  final String infoTitle;
  final String infoDescription;
  final List<T> items;
  final Object Function(T item) itemKey;
  final SettingsReorderItemBuilder<T> itemBuilder;
  final ValueChanged<List<T>> onOrderChanged;
  final VoidCallback onRestoreDefaults;

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: title,
      onRestoreDefaults: onRestoreDefaults,
      body: Column(
        children: [
          SettingsInfoCard(
            icon: Icons.info_outline,
            title: infoTitle,
            margin: const EdgeInsets.all(16),
            child: Text(
              infoDescription,
              style: UiTextStyles.supporting,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) {
                final reordered = List<T>.of(items);
                if (newIndex > oldIndex) newIndex -= 1;
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                onOrderChanged(reordered);
              },
              itemBuilder: (context, index) {
                final item = items[index];
                return SettingsSectionCard(
                  key: ValueKey(itemKey(item)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: itemBuilder(context, item, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.child,
    this.color,
    this.margin,
    this.clipBehavior,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = theme.cardTheme.shape;
    final side = BorderSide(
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.06),
      width: 0.5,
    );

    return Card(
      color: color,
      margin: margin,
      clipBehavior: clipBehavior,
      shape: shape is RoundedRectangleBorder
          ? shape.copyWith(side: side)
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: side,
            ),
      child: child,
    );
  }
}

class SettingsSectionList extends StatelessWidget {
  const SettingsSectionList({
    super.key,
    required this.children,
    this.color,
    this.margin,
    this.clipBehavior,
  });

  final List<Widget> children;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      color: color,
      margin: margin,
      clipBehavior: clipBehavior,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SettingsDivider(),
            children[index],
          ],
        ],
      ),
    );
  }
}

class SettingsInfoCard extends StatelessWidget {
  const SettingsInfoCard({
    super.key,
    required this.icon,
    this.title,
    required this.child,
    this.color,
    this.margin,
    this.iconColor,
  });

  final IconData icon;
  final String? title;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? theme.colorScheme.primary;

    return SettingsSectionCard(
      color: color,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(UiSpacing.large),
        child: title == null
            ? Row(
                children: [
                  Icon(icon, color: resolvedIconColor),
                  const SizedBox(width: UiSpacing.medium),
                  Expanded(child: child),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: UiIconSize.standard,
                        color: resolvedIconColor,
                      ),
                      const SizedBox(width: UiSpacing.small),
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UiSpacing.medium),
                  child,
                ],
              ),
      ),
    );
  }
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleStyle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconColor,
    this.iconSize,
  }) : assert(icon != null || leading != null);

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ??
        (enabled ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: UiSpacing.large),
      leading: leading ?? Icon(icon, color: resolvedIconColor, size: iconSize),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: subtitleStyle ??
                  (enabled
                      ? null
                      : TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
      trailing: trailing,
      onTap: enabled ? onTap : null,
    );
  }
}

class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.trailingIconSize,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final double? trailingIconSize;

  @override
  Widget build(BuildContext context) {
    return SettingsListTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: trailingIconSize,
          ),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    this.icon,
    this.secondary,
    required this.title,
    this.subtitle,
    this.subtitleStyle,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.enabled = true,
  }) : assert(icon != null || secondary != null);

  final IconData? icon;
  final Widget? secondary;
  final String title;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: UiSpacing.large),
      secondary:
          secondary ?? Icon(icon, color: iconColor ?? colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!, style: subtitleStyle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({
    super.key,
    this.indent = UiControlSize.settingsLeading,
    this.endIndent = 0,
  });

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: indent,
      endIndent: endIndent,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }
}
