import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../utils/design_tokens.dart';

class WorkDetailErrorBanner extends StatelessWidget {
  const WorkDetailErrorBanner({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: AppIconSize.small,
            color: colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(S.of(context).retry)),
        ],
      ),
    );
  }
}
