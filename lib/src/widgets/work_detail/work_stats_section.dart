import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/work.dart';
import '../../utils/string_utils.dart';

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
      spacing: 8,
      runSpacing: 8,
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
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                _ratingText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '(',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${work.rateCount ?? 0}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (_hasRatingDetails)
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  Text(
                    ')',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              color: colorScheme.onPrimaryContainer,
              size: 14,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              '$currentRating',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 11,
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
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.red[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
    );
  }

  Widget _buildDuration(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, color: Colors.blue, size: 16),
        const SizedBox(width: 4),
        Text(
          formatDurationSeconds(
            work.duration,
            padHours: false,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildSales(BuildContext context) {
    return Text(
      S.of(context).soldCount(_formatNumber(context, work.dlCount!)),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
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
