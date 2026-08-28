import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../utils/age_rating.dart';
import '../age_rating_chip.dart';
import '../privacy_blur_cover.dart';

const double _coverBadgeInset = 12;

class WorkCoverFrame extends StatelessWidget {
  const WorkCoverFrame({
    super.key,
    required this.heroTag,
    required this.isLandscape,
    required this.layers,
    this.showSubtitleBadge = false,
    this.showAgeRating = false,
    this.age,
    this.onTap,
  });

  final Object heroTag;
  final bool isLandscape;
  final List<Widget> layers;
  final bool showSubtitleBadge;
  final bool showAgeRating;
  final String? age;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Hero(
          tag: heroTag,
          // The default shuttle uses the destination child. When a work is
          // opened before the detail image has loaded, that child is the
          // loading placeholder and briefly puts a spinner in the flight.
          // Reuse the already visible source cover for both directions so
          // the Hero remains stable until the destination is ready.
          flightShuttleBuilder: (_, __, ___, fromHeroContext, _____) =>
              (fromHeroContext.widget as Hero).child,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: isLandscape ? null : double.infinity,
              constraints: BoxConstraints(
                maxHeight: isLandscape ? mediaSize.height * 0.8 : 500,
                maxWidth:
                    isLandscape ? mediaSize.width * 0.45 : double.infinity,
              ),
              child: PrivacyBlurCover(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    ...layers,
                    if (showAgeRating && AgeRatingFormatter.hasValue(age))
                      Positioned(
                        left: _coverBadgeInset,
                        bottom: _coverBadgeInset,
                        child: AgeRatingChip(
                          key: const ValueKey('work-cover-age-badge'),
                          age: age,
                          compact: true,
                        ),
                      ),
                    if (showSubtitleBadge) const _SubtitleBadge(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtitleBadge extends StatelessWidget {
  const _SubtitleBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      right: _coverBadgeInset,
      bottom: _coverBadgeInset,
      child: Container(
        key: const ValueKey('work-cover-subtitle-badge'),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          S.of(context).subtitleBadge,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
