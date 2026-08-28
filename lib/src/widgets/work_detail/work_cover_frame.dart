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
    this.overlayLayers = const <Widget>[],
    this.showSubtitleBadge = false,
    this.showAgeRating = false,
    this.age,
    this.onTap,
  });

  final Object heroTag;
  final bool isLandscape;
  final List<Widget> layers;

  /// Additional visual layers kept inside the Hero subtree. Callers should
  /// pass a stable wrapper when a layer is loaded asynchronously.
  final List<Widget> overlayLayers;
  final bool showSubtitleBadge;
  final bool showAgeRating;
  final String? age;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);

    final heroChild = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isLandscape ? null : double.infinity,
        constraints: BoxConstraints(
          maxHeight: isLandscape ? mediaSize.height * 0.8 : 500,
          maxWidth: isLandscape ? mediaSize.width * 0.45 : double.infinity,
        ),
        child: PrivacyBlurCover(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              ...layers,
              if (overlayLayers.isNotEmpty)
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: overlayLayers,
                  ),
                ),
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
    );

    final cover = Hero(
      tag: heroTag,
      // Keep the source subtree for both directions so the transition uses
      // the exact image already visible in the card or detail page.
      flightShuttleBuilder: (_, __, ___, fromHeroContext, ____) {
        return (fromHeroContext.widget as Hero).child;
      },
      placeholderBuilder: (context, size, child) =>
          SizedBox.fromSize(size: size),
      child: heroChild,
    );

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: cover,
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
