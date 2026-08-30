import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'player_buttons_settings_screen.dart';
import 'player_lyric_style_screen.dart';
import 'work_detail_display_settings_screen.dart';
import 'work_card_display_settings_screen.dart';
import 'my_tabs_display_settings_screen.dart';
import '../widgets/radio_option_group.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_option_dialog.dart';
import '../providers/settings_provider.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  void _showPageSizeDialog(BuildContext context, WidgetRef ref, int pageSize) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => CommonOptionDialog<int>(
        title: S.of(dialogContext).pageSizeSettings,
        icon: Icons.format_list_numbered,
        value: pageSize,
        options: [
          for (final value in [20, 40, 60, 100])
            RadioOption(
              value: value,
              title: Text(value.toString()),
            ),
        ],
        onChanged: (value) {
          ref.read(pageSizeProvider.notifier).updatePageSize(value);
          return true;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageSize = ref.watch(pageSizeProvider);

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
            ],
          ),
          const SizedBox(height: 16),
          SettingsSectionList(
            children: [
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
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPageSizeDialog(context, ref, pageSize),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
