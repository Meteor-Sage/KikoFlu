import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/ui_tokens.dart';
import 'async_state_view.dart';

class SubtitleLibraryContentView extends StatelessWidget {
  const SubtitleLibraryContentView({
    super.key,
    required this.isLoading,
    required this.empty,
    required this.child,
    this.errorMessage,
    this.onRetry,
  });

  final bool isLoading;
  final bool empty;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AsyncStateView(
        icon: CircularProgressIndicator(),
        padding: EdgeInsets.zero,
      );
    }

    final errorMessage = this.errorMessage;
    if (errorMessage != null) {
      return AsyncStateView(
        icon: const Icon(Icons.error_outline, size: 48, color: Colors.red),
        message: Text(errorMessage),
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
      final color = Theme.of(context).colorScheme.onSurfaceVariant;
      return AsyncStateView(
        icon: Icon(Icons.library_books_outlined, size: 64, color: color),
        title: Text(
          S.of(context).subtitleLibraryEmpty,
          style: TextStyle(fontSize: 18, color: color),
        ),
        message: Text(
          S.of(context).tapToImportSubtitle,
          style: TextStyle(fontSize: 14, color: color),
        ),
        iconToTitleSpacing: UiSpacing.large,
      );
    }

    return child;
  }
}
