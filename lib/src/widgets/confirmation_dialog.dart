import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';

/// The semantic treatment used by a confirmation action.
enum ConfirmationDialogVariant { primary, danger, warning }

/// A shared confirmation dialog for destructive and state-changing actions.
///
/// The dialog keeps the app's responsive sizing while standardizing the
/// action hierarchy: cancel is secondary and the requested action is filled.
class CommonConfirmationDialog extends StatelessWidget {
  const CommonConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.cancelLabel,
    this.variant = ConfirmationDialogVariant.primary,
    this.maxWidth,
  });

  final String title;
  final Widget content;
  final String confirmLabel;
  final String? cancelLabel;
  final ConfirmationDialogVariant variant;
  final double? maxWidth;

  ButtonStyle _confirmStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (variant) {
      case ConfirmationDialogVariant.primary:
        return FilledButton.styleFrom();
      case ConfirmationDialogVariant.danger:
        return FilledButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        );
      case ConfirmationDialogVariant.warning:
        return FilledButton.styleFrom(
          backgroundColor: colorScheme.tertiary,
          foregroundColor: colorScheme.onTertiary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ResponsiveAlertDialog(
      maxWidth: maxWidth,
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: _confirmStyle(context),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

Future<bool> showCommonConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String confirmLabel,
  String? cancelLabel,
  ConfirmationDialogVariant variant = ConfirmationDialogVariant.primary,
  double? maxWidth,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => CommonConfirmationDialog(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      variant: variant,
      maxWidth: maxWidth,
    ),
  );
  return confirmed == true;
}
