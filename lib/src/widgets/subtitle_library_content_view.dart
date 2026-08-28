import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/design_tokens.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = this.errorMessage;
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppControlSize.standard,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onRetry,
                child: Text(S.of(context).retry),
              ),
            ],
          ],
        ),
      );
    }

    if (empty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              S.of(context).subtitleLibraryEmpty,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              S.of(context).tapToImportSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return child;
  }
}
