import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/work_detail_display_provider.dart';
import '../widgets/settings_section.dart';

class WorkDetailDisplaySettingsScreen extends ConsumerWidget {
  const WorkDetailDisplaySettingsScreen({super.key});

  Future<void> _resetToDefault(BuildContext context, WidgetRef ref) async {
    await confirmAndRestoreSettingsDefaults(
      context: context,
      restore: ref.read(workDetailDisplayProvider.notifier).resetToDefault,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(workDetailDisplayProvider);
    final notifier = ref.read(workDetailDisplayProvider.notifier);

    return SettingsSubpageScaffold(
      title: S.of(context).workDetailDisplaySettings,
      onRestoreDefaults: () => _resetToDefault(context, ref),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSectionList(
            children: [
              SettingsSwitchTile(
                icon: Icons.star,
                title: S.of(context).ratingInfo,
                subtitle: S.of(context).showRatingAndReviewCount,
                value: settings.showRating,
                onChanged: (_) => notifier.toggleRating(),
              ),
              SettingsSwitchTile(
                icon: Icons.attach_money,
                title: S.of(context).priceInfo,
                subtitle: S.of(context).showWorkPrice,
                value: settings.showPrice,
                onChanged: (_) => notifier.togglePrice(),
              ),
              SettingsSwitchTile(
                icon: Icons.access_time,
                title: S.of(context).durationInfo,
                subtitle: S.of(context).showWorkDuration,
                value: settings.showDuration,
                onChanged: (_) => notifier.toggleDuration(),
              ),
              SettingsSwitchTile(
                icon: Icons.shopping_cart,
                title: S.of(context).salesInfo,
                subtitle: S.of(context).showWorkSalesCount,
                value: settings.showSales,
                onChanged: (_) => notifier.toggleSales(),
              ),
              SettingsSwitchTile(
                icon: Icons.open_in_new,
                title: S.of(context).externalLinkInfo,
                subtitle: S.of(context).showExternalLinks,
                value: settings.showExternalLinks,
                onChanged: (_) => notifier.toggleExternalLinks(),
              ),
              SettingsSwitchTile(
                icon: Icons.calendar_today,
                title: S.of(context).releaseDateInfo,
                subtitle: S.of(context).showWorkReleaseDate,
                value: settings.showReleaseDate,
                onChanged: (_) => notifier.toggleReleaseDate(),
              ),
              SettingsSwitchTile(
                icon: Icons.translate,
                title: S.of(context).translateButtonLabel,
                subtitle: S.of(context).showTranslateButton,
                value: settings.showTranslateButton,
                onChanged: (_) => notifier.toggleTranslateButton(),
              ),
              SettingsSwitchTile(
                icon: Icons.closed_caption,
                title: S.of(context).subtitleTagLabel,
                subtitle: S.of(context).showSubtitleTagOnCover,
                value: settings.showSubtitleTag,
                onChanged: (_) => notifier.toggleSubtitleTag(),
              ),
              SettingsSwitchTile(
                icon: Icons.person,
                title: S.of(context).ageRatingLabel,
                subtitle: S.of(context).showAgeRatingOnDetail,
                value: settings.showAgeRating,
                onChanged: (_) => notifier.toggleAgeRating(),
              ),
              SettingsSwitchTile(
                icon: Icons.recommend_outlined,
                title: S.of(context).recommendationsLabel,
                subtitle: S.of(context).showRecommendations,
                value: settings.showRecommendations,
                onChanged: (_) => notifier.toggleRecommendations(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
