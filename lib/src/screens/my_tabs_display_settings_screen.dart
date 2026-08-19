import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/my_tabs_display_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/server_utils.dart';
import '../widgets/settings_section.dart';

class MyTabsDisplaySettingsScreen extends ConsumerWidget {
  const MyTabsDisplaySettingsScreen({super.key});

  Future<void> _resetToDefault(BuildContext context, WidgetRef ref) async {
    await confirmAndRestoreSettingsDefaults(
      context: context,
      restore: ref.read(myTabsDisplayProvider.notifier).resetToDefault,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(myTabsDisplayProvider);
    final notifier = ref.read(myTabsDisplayProvider.notifier);
    final authState = ref.watch(authProvider);
    final isOfficialServer = ServerUtils.isOfficialServer(authState.host);

    return SettingsSubpageScaffold(
      title: S.of(context).myTabsDisplaySettings,
      onRestoreDefaults: () => _resetToDefault(context, ref),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 显示选项卡片
          SettingsSectionList(
            children: [
              SettingsSwitchTile(
                icon: Icons.favorite,
                title: S.of(context).onlineMarks,
                subtitle: S.of(context).showOnlineMarks,
                value: settings.showOnlineMarks,
                onChanged: (value) => notifier.setShowOnlineMarks(value),
              ),
              SettingsListTile(
                enabled: false,
                icon: Icons.download,
                title: S.of(context).historyRecord,
                subtitle: S.of(context).cannotBeDisabled,
                trailing: const Switch(value: true, onChanged: null),
              ),
              if (isOfficialServer)
                SettingsSwitchTile(
                  icon: Icons.playlist_play,
                  title: S.of(context).playlists,
                  subtitle: S.of(context).showPlaylists,
                  value: settings.showPlaylists,
                  onChanged: (value) => notifier.setShowPlaylists(value),
                ),
              SettingsSwitchTile(
                icon: Icons.subtitles,
                title: S.of(context).subtitleLibrary,
                subtitle: S.of(context).showSubtitleLibrary,
                value: settings.showSubtitleLibrary,
                onChanged: (value) => notifier.setShowSubtitleLibrary(value),
              ),
              SettingsListTile(
                enabled: false,
                icon: Icons.download,
                title: S.of(context).downloaded,
                subtitle: S.of(context).cannotBeDisabled,
                trailing: const Switch(value: true, onChanged: null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
