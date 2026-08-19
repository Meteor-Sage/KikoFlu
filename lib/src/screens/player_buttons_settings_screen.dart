import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/player_buttons_provider.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/settings_section.dart';

/// 播放器按钮设置页面
class PlayerButtonsSettingsScreen extends ConsumerWidget {
  const PlayerButtonsSettingsScreen({super.key});

  IconData _getButtonIcon(PlayerButtonType type) {
    switch (type) {
      case PlayerButtonType.seekBackward:
        return Icons.replay_10;
      case PlayerButtonType.seekForward:
        return Icons.forward_10;
      case PlayerButtonType.sleepTimer:
        return Icons.timer;
      case PlayerButtonType.volume:
        return Icons.volume_up;
      case PlayerButtonType.mark:
        return Icons.bookmark_border;
      case PlayerButtonType.detail:
        return Icons.info_outline;
      case PlayerButtonType.speed:
        return Icons.speed;
      case PlayerButtonType.repeat:
        return Icons.repeat;
      case PlayerButtonType.subtitleAdjustment:
        return Icons.tune;
      case PlayerButtonType.floatingLyric:
        return Icons.picture_in_picture_alt;
    }
  }

  Future<void> _resetToDefault(
    BuildContext context,
    WidgetRef ref, {
    required bool isDesktop,
  }) async {
    await confirmAndRestoreSettingsDefaults(
      context: context,
      message: S.of(context).confirmRestoreButtonOrder,
      restore: () => isDesktop
          ? ref
              .read(playerButtonsConfigDesktopProvider.notifier)
              .resetToDefault()
          : ref
              .read(playerButtonsConfigMobileProvider.notifier)
              .resetToDefault(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final provider = isDesktop
        ? playerButtonsConfigDesktopProvider
        : playerButtonsConfigMobileProvider;
    final config = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final maxVisible = isDesktop ? 5 : 4;

    return SettingsReorderablePage<PlayerButtonType>(
      title: S.of(context).playerButtonSettings,
      infoTitle: S.of(context).buttonDisplayRules,
      infoDescription: S.of(context).buttonDisplayRulesDesc(maxVisible),
      items: config.buttonOrder,
      itemKey: (button) => button,
      onOrderChanged: notifier.updateButtonOrder,
      onRestoreDefaults: () =>
          _resetToDefault(context, ref, isDesktop: isDesktop),
      itemBuilder: (context, button, index) {
        final isVisible = index < maxVisible;
        final foregroundColor = isVisible
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant;

        return ListTile(
          leading: Icon(_getButtonIcon(button), color: foregroundColor),
          title: Text(button.localizedLabel(context)),
          subtitle: Text(
            isVisible
                ? S.of(context).shownInPlayer
                : S.of(context).shownInMoreMenu,
            style: TextStyle(color: foregroundColor),
          ),
          trailing: ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
