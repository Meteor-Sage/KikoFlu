import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/player_lyric_style_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/settings_section.dart';

class PlayerLyricStyleScreen extends ConsumerWidget {
  const PlayerLyricStyleScreen({super.key});

  Future<void> _resetToDefault(BuildContext context, WidgetRef ref) async {
    final confirmed = await showSettingsResetConfirmation(
      context: context,
      title: S.of(context).resetStyle,
      message: S.of(context).resetStyleConfirm,
      confirmLabel: S.of(context).reset,
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(playerLyricSettingsProvider.notifier).reset();
    if (context.mounted) {
      SnackBarUtil.showSuccess(context, S.of(context).restoredToDefault);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(playerLyricSettingsProvider);
    final notifier = ref.read(playerLyricSettingsProvider.notifier);

    return SettingsSubpageScaffold(
      title: S.of(context).playerLyricStyle,
      onRestoreDefaults: () => _resetToDefault(context, ref),
      restoreDefaultsTooltip: S.of(context).restoreDefaultStyle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: S.of(context).miniPlayer,
            children: [
              _buildSlider(
                context,
                label: S.of(context).fontSize,
                value: settings.miniFontSize,
                min: 8,
                max: 20,
                onChanged: notifier.updateMiniFontSize,
              ),
              _buildSlider(
                context,
                label: S.of(context).lineHeight,
                value: settings.miniLineHeight,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                onChanged: notifier.updateMiniLineHeight,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: S.of(context).portraitPlayerBelowCover,
            children: [
              _buildSlider(
                context,
                label: S.of(context).fontSize,
                value: settings.smallFontSize,
                min: 10,
                max: 24,
                onChanged: notifier.updateSmallFontSize,
              ),
              _buildSlider(
                context,
                label: S.of(context).lineHeight,
                value: settings.smallLineHeight,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                onChanged: notifier.updateSmallLineHeight,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: S.of(context).fullscreenSubtitleMode,
            children: [
              _buildSlider(
                context,
                label: S.of(context).activeSubtitleFontSize,
                value: settings.fullActiveFontSize,
                min: 14,
                max: 32,
                onChanged: notifier.updateFullActiveFontSize,
              ),
              _buildSlider(
                context,
                label: S.of(context).inactiveSubtitleFontSize,
                value: settings.fullInactiveFontSize,
                min: 12,
                max: 28,
                onChanged: notifier.updateFullInactiveFontSize,
              ),
              _buildSlider(
                context,
                label: S.of(context).lineHeight,
                value: settings.fullLineHeight,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                onChanged: notifier.updateFullLineHeight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
