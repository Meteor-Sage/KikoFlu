import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/work.dart';
import '../../utils/string_utils.dart';
import '../../utils/design_tokens.dart';

class WorkStatsSection extends StatelessWidget {
  const WorkStatsSection({
    super.key,
    required this.work,
    this.currentRating,
    this.showRating = true,
    this.showPrice = true,
    this.showDuration = true,
    this.showSales = true,
    this.onShowRatingDetails,
    this.onShowProgress,
  });

  final Work work;
  final int? currentRating;
  final bool showRating;
  final bool showPrice;
  final bool showDuration;
  final bool showSales;
  final VoidCallback? onShowRatingDetails;
  final VoidCallback? onShowProgress;

  bool get _hasRatingDetails =>
      work.rateCountDetail != null && work.rateCountDetail!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showRating) _buildRating(context),
        if (currentRating != null) _buildCurrentRating(context),
        if (showPrice && work.price != null) _buildPrice(context),
        if (showDuration && work.duration != null && work.duration! > 0)
          _buildDuration(context),
        if (showSales && work.dlCount != null && work.dlCount! > 0)
          _buildSales(context),
      ],
    );
  }

  Widget _buildRating(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: _hasRatingDetails
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _hasRatingDetails ? onShowRatingDetails : null,
        child: Tooltip(
          message: _hasRatingDetails ? S.of(context).tapToViewRatingDetail : '',
          preferBelow: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: colorScheme.tertiary,
                size: AppIconSize.standard,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                _ratingText,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '(',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${work.rateCount ?? 0}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_hasRatingDetails)
                    Icon(
                      Icons.info_outline,
                      size: AppIconSize.small,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  Text(
                    ')',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRating(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onShowProgress,
      borderRadius: BorderRadius.circular(AppRadius.listItem),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.listItem),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              color: colorScheme.onPrimaryContainer,
              size: AppIconSize.small,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(
              Icons.star,
              color: colorScheme.tertiary,
              size: AppIconSize.small,
            ),
            const SizedBox(width: 2),
            Text(
              '$currentRating',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrice(BuildContext context) {
    return Text(
      S.of(context).priceInYen(work.price!),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDuration(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          color: Theme.of(context).colorScheme.secondary,
          size: AppIconSize.small,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          formatDurationSeconds(work.duration, padHours: false),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSales(BuildContext context) {
    return Text(
      S.of(context).soldCount(_formatNumber(context, work.dlCount!)),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String get _ratingText {
    if (work.rateAverage != null &&
        work.rateCount != null &&
        (work.rateCount! > 0 || work.rateAverage! != 0)) {
      return work.rateAverage!.toStringAsFixed(1);
    }

    return '-';
  }

  String _formatNumber(BuildContext context, int number) {
    if (number >= 10000) {
      return S
          .of(context)
          .tenThousandSuffix((number / 10000).toStringAsFixed(1));
    }

    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }

    return number.toString();
  }
}
