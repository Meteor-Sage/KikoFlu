import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/work_card_display_provider.dart';
import '../widgets/settings_section.dart';

class WorkCardDisplaySettingsScreen extends ConsumerWidget {
  const WorkCardDisplaySettingsScreen({super.key});

  Future<void> _resetToDefault(BuildContext context, WidgetRef ref) async {
    await confirmAndRestoreSettingsDefaults(
      context: context,
      restore: ref.read(workCardDisplayProvider.notifier).resetToDefault,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(workCardDisplayProvider);
    final notifier = ref.read(workCardDisplayProvider.notifier);

    return SettingsSubpageScaffold(
      title: S.of(context).workCardDisplaySettings,
      onRestoreDefaults: () => _resetToDefault(context, ref),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSectionList(
            children: [
              _SegmentedSettingTile<WorkCardSize>(
                icon: Icons.photo_size_select_large,
                title: S.of(context).cardSize,
                subtitle: S.of(context).workCardSizeSubtitle,
                selected: settings.cardSize,
                options: {
                  WorkCardSize.normal: S.of(context).cardSizeNormal,
                  WorkCardSize.large: S.of(context).cardSizeLarge,
                  WorkCardSize.extraLarge: S.of(context).cardSizeExtraLarge,
                },
                onSelected: notifier.updateCardSize,
              ),
              _SegmentedSettingTile<WorkCardFontScale>(
                icon: Icons.format_size,
                title: S.of(context).workCardFontSize,
                subtitle: S.of(context).workCardFontSizeSubtitle,
                selected: settings.fontScale,
                options: {
                  WorkCardFontScale.normal: S.of(context).fontSizeNormal,
                  WorkCardFontScale.large: S.of(context).fontSizeLarge,
                  WorkCardFontScale.extraLarge:
                      S.of(context).fontSizeExtraLarge,
                },
                onSelected: notifier.updateFontScale,
              ),
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
                subtitle: S.of(context).showWorkTotalDuration,
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
                icon: Icons.calendar_today,
                title: S.of(context).releaseDateInfo,
                subtitle: S.of(context).showWorkReleaseDate,
                value: settings.showReleaseDate,
                onChanged: (_) => notifier.toggleReleaseDate(),
              ),
              SettingsSwitchTile(
                icon: Icons.group,
                title: S.of(context).circleInfo,
                subtitle: S.of(context).showWorkCircle,
                value: settings.showCircle,
                onChanged: (_) => notifier.toggleCircle(),
              ),
              SettingsSwitchTile(
                icon: Icons.closed_caption,
                title: S.of(context).subtitleTagLabel,
                subtitle: S.of(context).showSubtitleTagOnCard,
                value: settings.showSubtitleTag,
                onChanged: (_) => notifier.toggleSubtitleTag(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedSettingTile<T> extends StatelessWidget {
  const _SegmentedSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T selected;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<T>(
                showSelectedIcon: false,
                segments: [
                  for (final entry in options.entries)
                    ButtonSegment<T>(
                      value: entry.key,
                      label: Text(entry.value),
                    ),
                ],
                selected: {selected},
                onSelectionChanged: (selection) {
                  onSelected(selection.single);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
