import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/ui_tokens.dart';
import 'async_state_view.dart';

class FileExplorerStatusView extends StatelessWidget {
  const FileExplorerStatusView({
    super.key,
    required this.isLoading,
    required this.empty,
    required this.emptyMessage,
    required this.child,
    this.errorMessage,
    this.onRetry,
  });

  final bool isLoading;
  final bool empty;
  final String emptyMessage;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AsyncStateView(
        icon: CircularProgressIndicator(),
        padding: EdgeInsets.zero,
      );
    }

    if (errorMessage != null) {
      return AsyncStateView(
        icon: const Icon(Icons.error, size: 64, color: Colors.red),
        message: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        action: onRetry == null
            ? null
            : ElevatedButton(
                onPressed: onRetry,
                child: Text(S.of(context).retry),
              ),
        iconToTitleSpacing: UiSpacing.large,
        messageToActionSpacing: UiSpacing.large,
      );
    }

    if (empty) {
      return AsyncStateView(
        icon: const Icon(Icons.folder_open, size: 64, color: Colors.grey),
        message: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
        iconToTitleSpacing: UiSpacing.large,
      );
    }

    return child;
  }
}
