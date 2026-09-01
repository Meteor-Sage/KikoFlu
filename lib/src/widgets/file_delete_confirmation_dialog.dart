import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'confirmation_dialog.dart';

Future<bool> showFileDeleteConfirmationDialog(
  BuildContext context, {
  required String relativePath,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => FileDeleteConfirmationDialog(
      relativePath: relativePath,
    ),
  );

  return confirmed == true;
}

class FileDeleteConfirmationDialog extends StatelessWidget {
  const FileDeleteConfirmationDialog({
    super.key,
    required this.relativePath,
  });

  final String relativePath;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return CommonConfirmationDialog(
      title: l10n.deletionConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteFilePrompt),
          const SizedBox(height: 12),
          Text(
            relativePath,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      confirmLabel: l10n.delete,
      variant: ConfirmationDialogVariant.danger,
    );
  }
}
