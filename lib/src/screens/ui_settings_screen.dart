import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';
import '../../l10n/app_localizations.dart';
import 'player_buttons_settings_screen.dart';
import 'player_lyric_style_screen.dart';
import 'work_detail_display_settings_screen.dart';
import 'work_card_display_settings_screen.dart';
import 'my_tabs_display_settings_screen.dart';
import '../widgets/settings_section.dart';
import '../providers/settings_provider.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageSize = ref.watch(pageSizeProvider);
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    final useLegacyAppleGlass = ref.watch(legacyAppleGlassTestProvider);
    final fallbackGlassTransparency =
        ref.watch(fallbackGlassTransparencyProvider);

    return SettingsSubpageScaffold(
      title: S.of(context).uiSettings,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSectionList(
            children: [
              SettingsNavigationTile(
                icon: Icons.tune,
                title: S.of(context).playerButtonSettings,
                subtitle: S.of(context).playerButtonSettingsSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PlayerButtonsSettingsScreen(),
                    ),
                  );
                },
              ),
              SettingsNavigationTile(
                icon: Icons.lyrics,
                title: S.of(context).playerLyricStyle,
                subtitle: S.of(context).playerLyricStyleSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PlayerLyricStyleScreen(),
                    ),
                  );
                },
              ),
              SettingsNavigationTile(
                icon: Icons.visibility,
                title: S.of(context).workDetailDisplaySettings,
                subtitle: S.of(context).workDetailDisplaySubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const WorkDetailDisplaySettingsScreen(),
                    ),
                  );
                },
              ),
              SettingsNavigationTile(
                icon: Icons.grid_view,
                title: S.of(context).workCardDisplaySettings,
                subtitle: S.of(context).workCardDisplaySubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const WorkCardDisplaySettingsScreen(),
                    ),
                  );
                },
              ),
              SettingsNavigationTile(
                icon: Icons.tab,
                title: S.of(context).myTabsDisplaySettings,
                subtitle: S.of(context).myTabsDisplaySubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyTabsDisplaySettingsScreen(),
                    ),
                  );
                },
              ),
              SettingsSwitchTile(
                icon: Icons.blur_on,
                title: S.of(context).liquidGlassNavigation,
                subtitle: S.of(context).liquidGlassNavigationDesc,
                value: useLiquidGlass,
                onChanged: (value) {
                  ref
                      .read(liquidGlassNavigationProvider.notifier)
                      .setEnabled(value);
                },
              ),
              if (useLiquidGlass && LegacyAppleGlassTestNotifier.isAvailable)
                SettingsSwitchTile(
                  icon: Icons.layers_outlined,
                  title: S.of(context).legacyAppleGlassTest,
                  subtitle: S.of(context).legacyAppleGlassTestDesc,
                  value: useLegacyAppleGlass,
                  onChanged: ref
                      .read(legacyAppleGlassTestProvider.notifier)
                      .setEnabled,
                ),
              if (useLiquidGlass && !LiquidGlass.isNativePlatform)
                _FallbackGlassTransparencyTile(
                  value: fallbackGlassTransparency,
                  onChanged: ref
                      .read(fallbackGlassTransparencyProvider.notifier)
                      .previewTransparency,
                  onChangeEnd: ref
                      .read(fallbackGlassTransparencyProvider.notifier)
                      .setTransparency,
                ),
              SettingsListTile(
                icon: Icons.format_list_numbered,
                title: S.of(context).pageSizeSettings,
                subtitle: S.of(context).pageSizeCurrent(pageSize),
                trailing: DropdownButton<int>(
                  value: pageSize,
                  underline: const SizedBox(),
                  items: [20, 40, 60, 100].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      ref
                          .read(pageSizeProvider.notifier)
                          .updatePageSize(newValue);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FallbackGlassTransparencyTile extends StatelessWidget {
  const _FallbackGlassTransparencyTile({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(Icons.opacity, color: colorScheme.primary),
      title: Text(S.of(context).fallbackGlassTransparency),
      trailing: SizedBox(
        width: 48,
        child: Text(
          '$percentage%',
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).fallbackGlassTransparencyDesc),
          Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$percentage%',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
