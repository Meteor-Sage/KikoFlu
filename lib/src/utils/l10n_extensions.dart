import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../models/search_type.dart';
import '../models/sort_options.dart';
import '../models/playlist.dart';
import '../models/audio_tap_playlist_mode.dart';
import '../providers/settings_provider.dart';
import '../providers/works_provider.dart';
import '../providers/my_reviews_provider.dart';
import '../providers/player_buttons_provider.dart';
import '../providers/floating_lyric_style_provider.dart';
import '../services/proxy_config.dart';
import 'subtitle_filter.dart';

// ============================================================
// ProxyMode
// ============================================================

extension ProxyModeL10n on ProxyMode {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      ProxyMode.direct => s.proxyModeDirect,
      ProxyMode.system => s.proxyModeSystem,
      ProxyMode.manual => s.proxyModeManual,
    };
  }

  String localizedDescription(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      ProxyMode.direct => s.proxyModeDirectDescription,
      ProxyMode.system => s.proxyModeSystemDescription,
      ProxyMode.manual => s.proxyModeManualDescription,
    };
  }
}

// ============================================================
// SearchType
// ============================================================

extension SearchTypeL10n on SearchType {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SearchType.keyword => s.searchTypeKeyword,
      SearchType.tag => s.searchTypeTag,
      SearchType.va => s.searchTypeVa,
      SearchType.circle => s.searchTypeCircle,
      SearchType.rjNumber => s.searchTypeRjNumber,
    };
  }

  String localizedHint(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SearchType.keyword => s.searchHintKeyword,
      SearchType.tag => s.searchHintTag,
      SearchType.va => s.searchHintVa,
      SearchType.circle => s.searchHintCircle,
      SearchType.rjNumber => s.searchHintRjNumber,
    };
  }
}

// ============================================================
// AgeRating
// ============================================================

extension AgeRatingL10n on AgeRating {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      AgeRating.all => s.ageRatingAll,
      AgeRating.general => s.ageRatingGeneral,
      AgeRating.r15 => s.ageRatingR15,
      AgeRating.adult => s.ageRatingAdult,
    };
  }
}

// ============================================================
// SortOrder
// ============================================================

extension SortOrderL10n on SortOrder {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SortOrder.release => s.sortRelease,
      SortOrder.createAt => s.sortCreateAt,
      SortOrder.createDate => s.sortCreateDate,
      SortOrder.rating => s.sortRating,
      SortOrder.review => s.sortReviewCount,
      SortOrder.randomSeed => s.sortRandom,
      SortOrder.dlCount => s.sortDlCount,
      SortOrder.price => s.sortPrice,
      SortOrder.nsfw => s.sortNsfw,
      SortOrder.updatedAt => s.sortUpdatedAt,
      SortOrder.downloadDate => s.sortDownloadDate,
      SortOrder.workId => s.sortWorkId,
    };
  }
}

// ============================================================
// SortDirection
// ============================================================

extension SortDirectionL10n on SortDirection {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SortDirection.asc => s.sortAsc,
      SortDirection.desc => s.sortDesc,
    };
  }
}

// ============================================================
// DisplayMode
// ============================================================

extension DisplayModeL10n on DisplayMode {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      DisplayMode.all => s.displayModeAll,
      DisplayMode.popular => s.displayModePopular,
      DisplayMode.recommended => s.displayModeRecommended,
    };
  }
}

// ============================================================
// SubtitleFilterMode
// ============================================================

extension SubtitleFilterModeL10n on SubtitleFilterMode {
  String localizedTooltip(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SubtitleFilterMode.all => s.showOnlySubtitled,
      SubtitleFilterMode.withSubtitles => s.showAllWorks,
    };
  }
}

// ============================================================
// SubtitleLibraryPriority
// ============================================================

extension SubtitleLibraryPriorityL10n on SubtitleLibraryPriority {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SubtitleLibraryPriority.highest => s.subtitlePriorityHighest,
      SubtitleLibraryPriority.lowest => s.subtitlePriorityLowest,
    };
  }
}

// ============================================================
// AudioTapPlaylistMode
// ============================================================

extension AudioTapPlaylistModeL10n on AudioTapPlaylistMode {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      AudioTapPlaylistMode.replaceQueue => s.audioTapPlaylistModeReplace,
      AudioTapPlaylistMode.appendDirectory =>
        s.audioTapPlaylistModeAppendDirectory,
      AudioTapPlaylistMode.appendSingle => s.audioTapPlaylistModeAppendSingle,
    };
  }

  String localizedDescription(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      AudioTapPlaylistMode.replaceQueue =>
        s.audioTapPlaylistModeReplaceDescription,
      AudioTapPlaylistMode.appendDirectory =>
        s.audioTapPlaylistModeAppendDirectoryDescription,
      AudioTapPlaylistMode.appendSingle =>
        s.audioTapPlaylistModeAppendSingleDescription,
    };
  }

  String? localizedChipLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      AudioTapPlaylistMode.replaceQueue => null,
      AudioTapPlaylistMode.appendDirectory => s.audioTapPlaylistModeAppendChip,
      AudioTapPlaylistMode.appendSingle =>
        s.audioTapPlaylistModeAppendSingleChip,
    };
  }
}

// ============================================================
// PreloadThresholdMode
// ============================================================

extension PreloadThresholdModeL10n on PreloadThresholdMode {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      PreloadThresholdMode.off => s.preloadOptionOff,
      PreloadThresholdMode.seconds10 => s.preloadOptionSeconds(10),
      PreloadThresholdMode.seconds20 => s.preloadOptionSeconds(20),
      PreloadThresholdMode.seconds30 => s.preloadOptionSeconds(30),
      PreloadThresholdMode.custom => s.preloadOptionCustom,
    };
  }
}

// ============================================================
// TranslationSource
// ============================================================

extension TranslationSourceL10n on TranslationSource {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      TranslationSource.google => s.translationSourceGoogle,
      TranslationSource.youdao => s.translationSourceYoudao,
      TranslationSource.microsoft => s.translationSourceMicrosoft,
      TranslationSource.llm => s.translationSourceLlm,
    };
  }
}

extension TranslationTargetLanguageL10n on TranslationTargetLanguage {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      TranslationTargetLanguage.followApp => s.translationLanguageFollowApp,
      TranslationTargetLanguage.zhHans => s.translationLanguageZhHans,
      TranslationTargetLanguage.zhHant => s.translationLanguageZhHant,
      TranslationTargetLanguage.english => s.translationLanguageEnglish,
      TranslationTargetLanguage.japanese => s.translationLanguageJapanese,
      TranslationTargetLanguage.russian => s.translationLanguageRussian,
      TranslationTargetLanguage.custom => s.translationLanguageCustom,
    };
  }
}

// ============================================================
// MyReviewFilter
// ============================================================

extension MyReviewFilterL10n on MyReviewFilter {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      MyReviewFilter.all => s.all,
      MyReviewFilter.marked => s.marked,
      MyReviewFilter.listening => s.listening,
      MyReviewFilter.listened => s.listened,
      MyReviewFilter.replay => s.replayMark,
      MyReviewFilter.postponed => s.postponed,
    };
  }
}

// ============================================================
// PlaylistPrivacy
// ============================================================

extension PlaylistPrivacyL10n on PlaylistPrivacy {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      PlaylistPrivacy.private => s.playlistPrivacyPrivate,
      PlaylistPrivacy.unlisted => s.playlistPrivacyUnlisted,
      PlaylistPrivacy.public => s.playlistPrivacyPublic,
    };
  }

  String localizedDescription(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      PlaylistPrivacy.private => s.playlistPrivacyPrivateDesc,
      PlaylistPrivacy.unlisted => s.playlistPrivacyUnlistedDesc,
      PlaylistPrivacy.public => s.playlistPrivacyPublicDesc,
    };
  }
}

// ============================================================
// SalesRange
// ============================================================

extension SalesRangeL10n on SalesRange {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      SalesRange.all => s.all,
      _ => label,
    };
  }
}

// ============================================================
// PlayerButtonType
// ============================================================

extension PlayerButtonTypeL10n on PlayerButtonType {
  String localizedLabel(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      PlayerButtonType.seekBackward => s.backward10s,
      PlayerButtonType.seekForward => s.forward10s,
      PlayerButtonType.sleepTimer => s.sleepTimer,
      PlayerButtonType.mark => s.markWork,
      PlayerButtonType.volume => s.volume,
      PlayerButtonType.speed => s.playbackSpeed,
      PlayerButtonType.repeat => s.repeatMode,
      PlayerButtonType.detail => s.viewDetail,
      PlayerButtonType.subtitleAdjustment => s.subtitleTimingAdjustment,
      PlayerButtonType.floatingLyric => s.desktopFloatingLyric,
    };
  }
}

// ============================================================
// FloatingLyricStylePreset
// ============================================================

extension FloatingLyricStylePresetL10n on FloatingLyricStylePreset {
  String localizedName(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      FloatingLyricStylePreset.dynamic => s.lyricPresetDynamic,
      FloatingLyricStylePreset.classic => s.lyricPresetClassic,
      FloatingLyricStylePreset.modern => s.lyricPresetModern,
      FloatingLyricStylePreset.minimal => s.lyricPresetMinimal,
      FloatingLyricStylePreset.vibrant => s.lyricPresetVibrant,
      FloatingLyricStylePreset.elegant => s.lyricPresetElegant,
    };
  }

  String localizedDescription(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      FloatingLyricStylePreset.dynamic => s.lyricPresetDynamicDesc,
      FloatingLyricStylePreset.classic => s.lyricPresetClassicDesc,
      FloatingLyricStylePreset.modern => s.lyricPresetModernDesc,
      FloatingLyricStylePreset.minimal => s.lyricPresetMinimalDesc,
      FloatingLyricStylePreset.vibrant => s.lyricPresetVibrantDesc,
      FloatingLyricStylePreset.elegant => s.lyricPresetElegantDesc,
    };
  }
}
