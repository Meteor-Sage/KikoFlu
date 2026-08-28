import 'package:flutter/material.dart';

import '../utils/age_rating.dart';
import '../utils/design_tokens.dart';

class AgeRatingChip extends StatelessWidget {
  const AgeRatingChip({
    super.key,
    required this.age,
    this.compact = false,
    this.fontSize,
    this.padding,
  });

  final String? age;
  final bool compact;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final label = AgeRatingFormatter.label(context, age);
    if (label == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final level = AgeRatingFormatter.level(age);
    final (backgroundColor, foregroundColor) = switch (level) {
      AgeRatingLevel.r18 => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      AgeRatingLevel.r15 => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      AgeRatingLevel.general => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      AgeRatingLevel.unknown => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
    };

    return Container(
      padding:
          padding ??
          (compact
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
              : const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                )),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.tag : AppRadius.control,
        ),
      ),
      child: Text(
        label,
        style: (compact ? textTheme.labelSmall : textTheme.labelMedium)
            ?.copyWith(
              color: foregroundColor,
              fontSize: fontSize ?? (compact ? 10 : 12),
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
      ),
    );
  }
}
