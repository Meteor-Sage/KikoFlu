import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum AgeRatingLevel { general, r15, r18, unknown }

class AgeRatingFormatter {
  const AgeRatingFormatter._();

  static String? normalize(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static bool hasValue(String? value) => normalize(value) != null;

  static AgeRatingLevel level(String? value) {
    final normalized = normalize(value);
    if (normalized == null) return AgeRatingLevel.unknown;

    final compact = normalized.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');

    if (const {
      'general',
      'all',
      'allages',
      'g',
      '全年齢',
      '全年龄',
    }.contains(compact)) {
      return AgeRatingLevel.general;
    }
    if (const {'r15', 'r15+', '15', '15+'}.contains(compact)) {
      return AgeRatingLevel.r15;
    }
    if (const {'adult', 'r18', 'r18+', '18', '18+'}.contains(compact)) {
      return AgeRatingLevel.r18;
    }
    return AgeRatingLevel.unknown;
  }

  static String? label(BuildContext context, String? value) {
    final normalized = normalize(value);
    if (normalized == null) return null;

    return switch (level(normalized)) {
      AgeRatingLevel.general => S.of(context).ageRatingGeneral,
      AgeRatingLevel.r15 => 'R15',
      AgeRatingLevel.r18 => 'R18',
      AgeRatingLevel.unknown => normalized,
    };
  }
}
