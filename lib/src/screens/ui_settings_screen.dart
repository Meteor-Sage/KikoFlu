import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'player_buttons_settings_screen.dart';
import 'player_lyric_style_screen.dart';
import 'work_detail_display_settings_screen.dart';
import 'work_card_display_settings_screen.dart';
import 'my_tabs_display_settings_screen.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/settings_section.dart';
import '../providers/settings_provider.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageSize = ref.watch(pageSizeProvider);

    return Scaffold(
      appBar: ScrollableAppBar(
        title: Text(
          S.of(context).uiSettings,
          style: const TextStyle(fontSize: 18),
        ),
      ),
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
