import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'audio_format_settings_screen.dart';
import 'blocked_items_screen.dart';
import 'llm_settings_screen.dart';
import '../models/audio_gain_settings.dart';
import '../models/audio_tap_playlist_mode.dart';
import '../models/sort_options.dart';
import '../providers/proxy_provider.dart';
import '../providers/settings_provider.dart';
import '../services/proxy_config.dart';
import '../utils/l10n_extensions.dart';
import '../utils/snackbar_util.dart';
import '../widgets/radio_option_group.dart';
import '../widgets/responsive_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_option_dialog.dart';
import '../widgets/sort_dialog.dart';

/// 偏好设置页面
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  Future<void> _showAudioTapPlaylistModeDialog(
    BuildContext pageContext,
    WidgetRef ref,
  ) async {
    final currentMode = await ref
        .read(audioTapPlaylistModeProvider.notifier)
        .getMode();
    if (!pageContext.mounted) return;

    AudioTapPlaylistMode? selectedMode;
    await showDialog<void>(
      context: pageContext,
      builder: (dialogContext) => CommonOptionDialog<AudioTapPlaylistMode>(
        title: S.of(dialogContext).audioTapPlaylistMode,
        description: S.of(dialogContext).selectAudioTapPlaylistMode,
        icon: Icons.playlist_play,
        value: currentMode,
        options: [
          for (final mode in AudioTapPlaylistMode.values)
            RadioOption(
              value: mode,
              title: Text(mode.localizedName(dialogContext)),
              subtitle: Text(mode.localizedDescription(dialogContext)),
            ),
        ],
        onChanged: (value) async {
          selectedMode = value;
          await ref
              .read(audioTapPlaylistModeProvider.notifier)
              .updateMode(value);
          return true;
        },
      ),
    );

    if (selectedMode != null && pageContext.mounted) {
      SnackBarUtil.showSuccess(
        pageContext,
        S.of(pageContext).setToValue(selectedMode!.localizedName(pageContext)),
      );
    }
  }

  void _showSubtitleLibraryPriorityDialog(
    BuildContext pageContext,
    WidgetRef ref,
  ) {
    final currentPriority = ref.read(subtitleLibraryPriorityProvider);

    showDialog(
      context: pageContext,
      builder: (dialogContext) => CommonOptionDialog<SubtitleLibraryPriority>(
        title: S.of(dialogContext).subtitleLibraryPriority,
        icon: Icons.library_books,
        description: S.of(dialogContext).selectSubtitlePriority,
        value: currentPriority,
        options: [
          for (final priority in SubtitleLibraryPriority.values)
            RadioOption(
              value: priority,
              title: Text(priority.localizedName(dialogContext)),
              subtitle: Text(
                priority == SubtitleLibraryPriority.highest
                    ? S.of(dialogContext).subtitlePriorityHighestDesc
                    : S.of(dialogContext).subtitlePriorityLowestDesc,
              ),
            ),
        ],
        onChanged: (value) {
          ref
              .read(subtitleLibraryPriorityProvider.notifier)
              .updatePriority(value);
          SnackBarUtil.showSuccess(
            pageContext,
            S.of(pageContext).setToValue(value.localizedName(pageContext)),
          );
          return true;
        },
      ),
    );
  }

  void _showDefaultSortDialog(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(defaultSortProvider);

    showDialog(
      context: context,
      builder: (context) => CommonSortDialog(
        title: S.of(context).defaultSortSettings,
        currentOption: currentSort.order,
        currentDirection: currentSort.direction,
        availableOptions: SortOrder.values
            .where((option) => option != SortOrder.updatedAt)
            .toList(),
        onSort: (option, direction) {
          ref
              .read(defaultSortProvider.notifier)
              .updateDefaultSort(option, direction);
          SnackBarUtil.showSuccess(context, S.of(context).defaultSortUpdated);
        },
        autoClose: false,
      ),
    );
  }

  void _showTranslationSourceDialog(BuildContext pageContext, WidgetRef ref) {
    final currentSource = ref.read(translationSourceProvider);

    showDialog(
      context: pageContext,
      builder: (dialogContext) => CommonOptionDialog<TranslationSource>(
        title: S.of(dialogContext).translationSourceSettings,
        icon: Icons.translate,
        description: S.of(dialogContext).selectTranslationProvider,
        value: currentSource,
        options: [
          for (final source in TranslationSource.values)
            RadioOption(
              value: source,
              title: Text(source.localizedName(dialogContext)),
              subtitle: Text(
                _getTranslationSourceDescription(dialogContext, source),
              ),
            ),
        ],
        onChanged: (value) async {
          if (value == TranslationSource.llm) {
            final llmSettings = ref.read(llmSettingsProvider);
            if (llmSettings.apiKey.isEmpty) {
              await showDialog(
                context: dialogContext,
                builder: (configContext) => AlertDialog(
                  title: Text(S.of(configContext).needsConfiguration),
                  content: Text(S.of(configContext).llmConfigRequiredMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(configContext),
                      child: Text(S.of(configContext).cancel),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(configContext);
                        navigator.pop();
                        navigator.pop();
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (context) => const LLMSettingsScreen(),
                          ),
                        );

                        final newSettings = ref.read(llmSettingsProvider);
                        if (newSettings.apiKey.isNotEmpty &&
                            pageContext.mounted) {
                          ref
                              .read(translationSourceProvider.notifier)
                              .updateSource(TranslationSource.llm);
                          SnackBarUtil.showSuccess(
                            pageContext,
                            S.of(pageContext).autoSwitchedToLlm,
                          );
                        }
                      },
                      child: Text(S.of(configContext).goToConfigure),
                    ),
                  ],
                ),
              );
              return false;
            }
          }

          ref.read(translationSourceProvider.notifier).updateSource(value);
          SnackBarUtil.showSuccess(
            pageContext,
            S.of(pageContext).setToValue(value.localizedName(pageContext)),
          );
          return true;
        },
      ),
    );
  }

  void _showTranslationTargetLanguageDialog(
    BuildContext pageContext,
    WidgetRef ref,
  ) {
    final translationSource = ref.read(translationSourceProvider);
    final preferences = ref.read(translationLanguagePreferencesProvider);
    final customLanguageEnabled = translationSource == TranslationSource.llm;
    final currentLanguage = preferences.targetLanguage;
    final groupValue =
        currentLanguage == TranslationTargetLanguage.custom &&
            !customLanguageEnabled
        ? TranslationTargetLanguage.followApp
        : currentLanguage;
    const options = TranslationTargetLanguage.values;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => CommonOptionDialog<TranslationTargetLanguage>(
        title: S.of(dialogContext).translationTargetLanguage,
        icon: Icons.language,
        description: S.of(dialogContext).selectTranslationTargetLanguage,
        value: groupValue,
        options: [
          for (final language in options)
            RadioOption(
              value: language,
              enabled:
                  customLanguageEnabled ||
                  language != TranslationTargetLanguage.custom,
              title: Text(
                _languageOptionLabel(
                  dialogContext,
                  language.localizedName(dialogContext),
                  language == TranslationTargetLanguage.custom
                      ? preferences.customTargetLanguage
                      : null,
                ),
              ),
              subtitle:
                  language == TranslationTargetLanguage.custom &&
                      !customLanguageEnabled
                  ? Text(S.of(dialogContext).translationCustomTargetRequiresLlm)
                  : null,
            ),
        ],
        onChanged: (value) async {
          if (value == TranslationTargetLanguage.custom &&
              !customLanguageEnabled) {
            return false;
          }
          if (value == TranslationTargetLanguage.custom) {
            final customLanguage = await _showCustomLanguageDialog(
              pageContext,
              title: S.of(pageContext).translationCustomTargetLanguage,
              initialValue: preferences.customTargetLanguage,
            );
            if (customLanguage == null) return false;
            await ref
                .read(translationLanguagePreferencesProvider.notifier)
                .updateCustomTargetLanguage(customLanguage);
          }

          await ref
              .read(translationLanguagePreferencesProvider.notifier)
              .updateTargetLanguage(value);
          if (!pageContext.mounted) return false;
          SnackBarUtil.showSuccess(
            pageContext,
            S.of(pageContext).setToValue(value.localizedName(pageContext)),
          );
          return true;
        },
      ),
    );
  }

  Future<String?> _showCustomLanguageDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: S.of(dialogContext).translationCustomLanguageHint,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(dialogContext, text);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogContext, text);
              }
            },
            child: Text(S.of(dialogContext).confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  String _languageOptionLabel(
    BuildContext context,
    String label,
    String? customValue,
  ) {
    final trimmedValue = customValue?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return label;
    }
    return S.of(context).translationCustomLanguageLabel(trimmedValue);
  }

  /// 预加载阈值的当前展示文案
  String _preloadValueLabel(
    BuildContext context,
    PreloadNextSettings settings,
  ) {
    final s = S.of(context);
    switch (settings.mode) {
      case PreloadThresholdMode.off:
        return s.preloadOptionOff;
      case PreloadThresholdMode.seconds10:
        return s.preloadOptionSeconds(10);
      case PreloadThresholdMode.seconds20:
        return s.preloadOptionSeconds(20);
      case PreloadThresholdMode.seconds30:
        return s.preloadOptionSeconds(30);
      case PreloadThresholdMode.custom:
        return s.preloadCustomValueLabel(settings.customSeconds);
    }
  }

  void _showPreloadThresholdDialog(BuildContext pageContext) {
    showDialog<void>(
      context: pageContext,
      builder: (_) => _PreloadThresholdDialog(pageContext: pageContext),
    );
  }

  String _targetLanguageLabel(
    BuildContext context,
    TranslationLanguagePreferences preferences,
    bool customLanguageEnabled,
  ) {
    if (preferences.targetLanguage == TranslationTargetLanguage.custom &&
        !customLanguageEnabled) {
      return TranslationTargetLanguage.followApp.localizedName(context);
    }
    if (preferences.targetLanguage == TranslationTargetLanguage.custom &&
        preferences.customTargetLanguage.isNotEmpty) {
      return S
          .of(context)
          .translationCustomLanguageLabel(preferences.customTargetLanguage);
    }
    return preferences.targetLanguage.localizedName(context);
  }

  String _getTranslationSourceDescription(
    BuildContext context,
    TranslationSource source,
  ) {
    final s = S.of(context);
    switch (source) {
      case TranslationSource.google:
        return s.translationDescGoogle;
      case TranslationSource.youdao:
        return s.translationDescYoudao;
      case TranslationSource.microsoft:
        return s.translationDescMicrosoft;
      case TranslationSource.llm:
        return s.translationDescLlm;
    }
  }

  void _showProxySettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _ProxySettingsDialog(),
    );
  }

  Widget _buildProxySettings(BuildContext context, WidgetRef ref) {
    final proxySettings = ref.watch(proxySettingsProvider);
    return SettingsListTile(
      icon: Icons.vpn_lock_outlined,
      title: S.of(context).proxySettingsOptional,
      subtitle: proxySettings.mode.localizedDescription(context),
      trailing: Text(proxySettings.mode.localizedName(context)),
      onTap: () => _showProxySettingsDialog(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priority = ref.watch(subtitleLibraryPriorityProvider);
    final defaultSort = ref.watch(defaultSortProvider);
    final translationSource = ref.watch(translationSourceProvider);
    final translationLanguagePreferences = ref.watch(
      translationLanguagePreferencesProvider,
    );
    final autoSaveTranslatedLyrics = ref.watch(
      autoSaveTranslatedLyricsProvider,
    );
    final preloadSettings = ref.watch(preloadNextSettingsProvider);
    final audioTapPlaylistMode = ref.watch(audioTapPlaylistModeProvider);

    return SettingsSubpageScaffold(
      title: S.of(context).preferenceSettings,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSectionList(
            children: [
              SettingsNavigationTile(
                icon: Icons.translate,
                title: S.of(context).translationSource,
                subtitle: S
                    .of(context)
                    .currentSettingLabel(
                      translationSource.localizedName(context),
                    ),
                onTap: () => _showTranslationSourceDialog(context, ref),
              ),
              SettingsNavigationTile(
                icon: Icons.language,
                title: S.of(context).translationTargetLanguage,
                subtitle: S
                    .of(context)
                    .currentSettingLabel(
                      _targetLanguageLabel(
                        context,
                        translationLanguagePreferences,
                        translationSource == TranslationSource.llm,
                      ),
                    ),
                onTap: () => _showTranslationTargetLanguageDialog(context, ref),
              ),
              SettingsSwitchTile(
                icon: Icons.save_alt,
                title: S.of(context).autoSaveTranslatedLyrics,
                subtitle: S.of(context).autoSaveTranslatedLyricsDesc,
                value: autoSaveTranslatedLyrics,
                onChanged: (enabled) => ref
                    .read(autoSaveTranslatedLyricsProvider.notifier)
                    .setEnabled(enabled),
              ),
              if (translationSource == TranslationSource.llm)
                SettingsNavigationTile(
                  icon: Icons.settings_input_component,
                  title: S.of(context).llmSettings,
                  subtitle: S.of(context).llmSettingsSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LLMSettingsScreen(),
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
                icon: Icons.library_books,
                title: S.of(context).subtitleLibraryPriority,
                subtitle: S
                    .of(context)
                    .currentSettingLabel(priority.localizedName(context)),
                onTap: () => _showSubtitleLibraryPriorityDialog(context, ref),
              ),
              SettingsNavigationTile(
                icon: Icons.sort,
                title: S.of(context).defaultSortSettingTitle,
                subtitle:
                    '${defaultSort.order.localizedLabel(context)} - ${defaultSort.direction.localizedLabel(context)}',
                onTap: () => _showDefaultSortDialog(context, ref),
              ),
              SettingsNavigationTile(
                icon: Icons.block,
                title: S.of(context).blockingSettings,
                subtitle: S.of(context).blockingSettingsSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BlockedItemsScreen(),
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
                icon: Icons.playlist_play,
                title: S.of(context).audioTapPlaylistMode,
                subtitle: S.of(context).currentSettingLabel(
                      audioTapPlaylistMode.localizedName(context),
                    ),
                onTap: () => _showAudioTapPlaylistModeDialog(context, ref),
              ),
              SettingsNavigationTile(
                icon: Icons.audio_file,
                title: S.of(context).audioFormatPreference,
                subtitle: S.of(context).audioFormatSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AudioFormatSettingsScreen(),
                    ),
                  );
                },
              ),
              SettingsNavigationTile(
                icon: Icons.fast_forward,
                title: S.of(context).preloadNextTitle,
                subtitle: S
                    .of(context)
                    .currentSettingLabel(
                      _preloadValueLabel(context, preloadSettings),
                    ),
                onTap: () => _showPreloadThresholdDialog(context),
              ),
              if (_supportsAudioGain(Theme.of(context).platform))
                _AudioGainSettingsTile(ref: ref),
              SettingsSwitchTile(
                icon: Icons.screen_lock_portrait,
                title: S.of(context).keepScreenAwake,
                subtitle: S.of(context).keepScreenAwakeDesc,
                value: ref.watch(keepScreenAwakeProvider),
                onChanged: (value) {
                  ref.read(keepScreenAwakeProvider.notifier).setEnabled(value);
                },
              ),
              if (Theme.of(context).platform == TargetPlatform.android ||
                  Theme.of(context).platform == TargetPlatform.iOS)
                _AudioHapticsSettingsTile(ref: ref),
              // 仅在 Android, Windows 和 macOS 平台上显示音频直通设置
              if (Theme.of(context).platform == TargetPlatform.android ||
                  Theme.of(context).platform == TargetPlatform.windows ||
                  Theme.of(context).platform == TargetPlatform.macOS)
                SettingsSwitchTile(
                  icon: Icons.surround_sound,
                  title: S.of(context).audioPassthrough,
                  subtitle: Theme.of(context).platform == TargetPlatform.windows
                      ? S.of(context).audioPassthroughDescWindows
                      : Theme.of(context).platform == TargetPlatform.macOS
                      ? S.of(context).audioPassthroughDescMac
                      : S.of(context).audioPassthroughDescAndroid,
                  subtitleStyle: const TextStyle(fontSize: 12),
                  value: ref.watch(audioPassthroughProvider),
                  onChanged: (value) async {
                    if (value) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(S.of(context).warning),
                          content: Text(S.of(context).audioPassthroughWarning),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(S.of(context).cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(S.of(context).confirm),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;
                    }

                    ref.read(audioPassthroughProvider.notifier).toggle(value);
                    if (context.mounted) {
                      SnackBarUtil.showSuccess(
                        context,
                        value
                            ? ((Theme.of(context).platform ==
                                          TargetPlatform.windows ||
                                      Theme.of(context).platform ==
                                          TargetPlatform.macOS)
                                  ? S.of(context).exclusiveModeEnabled
                                  : S.of(context).audioPassthroughEnabled)
                            : S.of(context).audioPassthroughDisabled,
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSectionCard(child: _buildProxySettings(context, ref)),
        ],
      ),
    );
  }

  bool _supportsAudioGain(TargetPlatform platform) {
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }
}

class _AudioGainSettingsTile extends StatelessWidget {
  const _AudioGainSettingsTile({required this.ref});

  final WidgetRef ref;

  String _valueLabel(double decibels) {
    if (decibels == 0) return '0 dB';
    final digits = decibels == decibels.roundToDouble() ? 0 : 1;
    final prefix = decibels > 0 ? '+' : '';
    return '$prefix${decibels.toStringAsFixed(digits)} dB';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(audioGainSettingsProvider);
    final notifier = ref.read(audioGainSettingsProvider.notifier);
    final passthroughEnabled = ref.watch(audioPassthroughProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final platform = Theme.of(context).platform;
    final supportsPositiveGain = platform != TargetPlatform.iOS;
    final maxDecibels = supportsPositiveGain
        ? AudioGainSettings.maxDecibels
        : AudioGainSettings.defaultDecibels;
    final displayedDecibels = settings.decibels
        .clamp(AudioGainSettings.minDecibels, maxDecibels)
        .toDouble();

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.graphic_eq, color: colorScheme.primary),
          title: Text(S.of(context).audioGain),
          subtitle: Text(
            passthroughEnabled
                ? S.of(context).audioGainPassthroughDesc
                : supportsPositiveGain
                ? S.of(context).audioGainDesc
                : S.of(context).audioGainAttenuationDesc,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: displayedDecibels,
                  min: AudioGainSettings.minDecibels,
                  max: maxDecibels,
                  divisions:
                      ((maxDecibels - AudioGainSettings.minDecibels) /
                              AudioGainSettings.stepDecibels)
                          .round(),
                  label: _valueLabel(displayedDecibels),
                  onChanged: passthroughEnabled ? null : notifier.setDecibels,
                ),
              ),
              SizedBox(
                width: 58,
                child: Text(
                  _valueLabel(displayedDecibels),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudioHapticsSettingsTile extends StatelessWidget {
  const _AudioHapticsSettingsTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(audioHapticsSettingsProvider);
    final notifier = ref.read(audioHapticsSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.vibration, color: colorScheme.primary),
          title: Text(S.of(context).audioHaptics),
          subtitle: Text(S.of(context).audioHapticsDesc),
          onTap: () => notifier.setEnabled(!settings.enabled),
          trailing: Switch(
            value: settings.enabled,
            onChanged: notifier.setEnabled,
          ),
        ),
        if (settings.enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  S.of(context).audioHapticsIntensity,
                  style: const TextStyle(fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: settings.intensity,
                    min: AudioHapticsSettings.minIntensity,
                    max: AudioHapticsSettings.maxIntensity,
                    divisions: 8,
                    label: '${(settings.intensity * 100).round()}%',
                    onChanged: notifier.setIntensity,
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(settings.intensity * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PreloadThresholdDialog extends ConsumerStatefulWidget {
  const _PreloadThresholdDialog({required this.pageContext});

  final BuildContext pageContext;

  @override
  ConsumerState<_PreloadThresholdDialog> createState() =>
      _PreloadThresholdDialogState();
}

class _PreloadThresholdDialogState
    extends ConsumerState<_PreloadThresholdDialog> {
  late final TextEditingController _controller;
  late PreloadThresholdMode _selectedMode;
  late int _customSeconds;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(preloadNextSettingsProvider);
    _controller = TextEditingController(
      text: settings.customSeconds.toString(),
    );
    _selectedMode = settings.mode;
    _customSeconds = settings.customSeconds;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _validatedSeconds(BuildContext context) {
    final value = int.tryParse(_controller.text.trim());
    if (value == null ||
        value < PreloadNextSettings.minSeconds ||
        value > PreloadNextSettings.maxSeconds) {
      _errorText = S.of(context).preloadCustomInputRangeError;
      return null;
    }
    _errorText = null;
    return value;
  }

  Future<bool> _saveCustomSeconds(BuildContext context) async {
    final value = _validatedSeconds(context);
    if (value == null) return false;

    _customSeconds = value;
    final notifier = ref.read(preloadNextSettingsProvider.notifier);
    await notifier.updateCustomSeconds(value);
    await notifier.updateMode(PreloadThresholdMode.custom);
    return mounted;
  }

  Future<void> _closeDialog() async {
    final accepted = _selectedMode == PreloadThresholdMode.custom
        ? await _saveCustomSeconds(context)
        : true;
    if (!accepted) {
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pop();
    final pageContext = widget.pageContext;
    if (!pageContext.mounted) return;
    final updated = ref.read(preloadNextSettingsProvider);
    SnackBarUtil.showSuccess(
      pageContext,
      S
          .of(pageContext)
          .setToValue(_preloadValueLabelForSettings(pageContext, updated)),
    );
  }

  String _preloadValueLabelForSettings(
    BuildContext context,
    PreloadNextSettings settings,
  ) {
    final s = S.of(context);
    switch (settings.mode) {
      case PreloadThresholdMode.off:
        return s.preloadOptionOff;
      case PreloadThresholdMode.seconds10:
        return s.preloadOptionSeconds(10);
      case PreloadThresholdMode.seconds20:
        return s.preloadOptionSeconds(20);
      case PreloadThresholdMode.seconds30:
        return s.preloadOptionSeconds(30);
      case PreloadThresholdMode.custom:
        return s.preloadCustomValueLabel(settings.customSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ResponsiveDialog(
      maxWidth: 520,
      titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          Icon(Icons.fast_forward, size: 22, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).preloadNextTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: _closeDialog,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              S.of(context).selectPreloadThreshold,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          CompactRadioOptionGroup<PreloadThresholdMode>(
            groupValue: _selectedMode,
            options: [
              RadioOption(
                value: PreloadThresholdMode.off,
                title: Text(PreloadThresholdMode.off.localizedName(context)),
              ),
              RadioOption(
                value: PreloadThresholdMode.seconds10,
                title: Text(
                  PreloadThresholdMode.seconds10.localizedName(context),
                ),
              ),
              RadioOption(
                value: PreloadThresholdMode.seconds20,
                title: Text(
                  PreloadThresholdMode.seconds20.localizedName(context),
                ),
              ),
              RadioOption(
                value: PreloadThresholdMode.seconds30,
                title: Text(
                  PreloadThresholdMode.seconds30.localizedName(context),
                ),
              ),
              RadioOption(
                value: PreloadThresholdMode.custom,
                title: Text(PreloadThresholdMode.custom.localizedName(context)),
                subtitle: _selectedMode == PreloadThresholdMode.custom
                    ? Text(
                        S.of(context).preloadCustomValueLabel(_customSeconds),
                      )
                    : null,
              ),
            ],
            onChanged: (value) async {
              setState(() => _selectedMode = value);
              if (value != PreloadThresholdMode.custom) {
                await ref
                    .read(preloadNextSettingsProvider.notifier)
                    .updateMode(value);
              }
            },
          ),
          if (_selectedMode == PreloadThresholdMode.custom) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: settingsDialogInputDecoration(
                context,
                labelText: S.of(context).preloadCustomInputTitle,
                helperText: S.of(context).preloadCustomInputHint,
                errorText: _errorText,
                prefixIcon: const Icon(Icons.timer_outlined),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) async {
                await _saveCustomSeconds(context);
                if (mounted) setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ProxySettingsDialog extends ConsumerStatefulWidget {
  const _ProxySettingsDialog();

  @override
  ConsumerState<_ProxySettingsDialog> createState() =>
      _ProxySettingsDialogState();
}

class _ProxySettingsDialogState extends ConsumerState<_ProxySettingsDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late ProxyMode _proxyMode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(proxySettingsProvider);
    _controller = TextEditingController(text: settings.address);
    _focusNode = FocusNode();
    _proxyMode = settings.mode;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _saveAddress(BuildContext context) async {
    if (_proxyMode != ProxyMode.manual) return true;

    final accepted = await ref
        .read(proxySettingsProvider.notifier)
        .setAddress(_controller.text);
    if (!mounted || !context.mounted) return false;
    if (!accepted) {
      _errorText = S.of(context).invalidProxyAddress;
      return false;
    }

    _errorText = null;
    final normalizedAddress = ref.read(proxySettingsProvider).address;
    if (!_focusNode.hasFocus && _controller.text != normalizedAddress) {
      _controller.text = normalizedAddress;
    }
    return true;
  }

  Future<void> _closeDialog() async {
    _focusNode.unfocus();
    final accepted = await _saveAddress(context);
    if (!mounted) return;
    if (accepted) {
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ResponsiveDialog(
      maxWidth: 520,
      titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          Icon(Icons.vpn_lock_outlined, size: 22, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).proxySettingsOptional,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: _closeDialog,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompactRadioOptionGroup<ProxyMode>(
            groupValue: _proxyMode,
            options: [
              for (final mode in ProxyMode.values)
                RadioOption(
                  value: mode,
                  title: Text(mode.localizedName(context)),
                  subtitle: Text(mode.localizedDescription(context)),
                ),
            ],
            onChanged: (value) async {
              if (_proxyMode == ProxyMode.manual) {
                await _saveAddress(context);
              }
              await ref.read(proxySettingsProvider.notifier).setMode(value);
              if (mounted) setState(() => _proxyMode = value);
            },
          ),
          if (_proxyMode == ProxyMode.manual) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: settingsDialogInputDecoration(
                context,
                labelText: S.of(context).proxyAddress,
                hintText: '127.0.0.1:7890',
                helperText: S.of(context).proxyAddressFormat,
                errorText: _errorText,
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) async {
                await _saveAddress(context);
                if (mounted) setState(() {});
              },
              onTapOutside: (_) async {
                _focusNode.unfocus();
                await _saveAddress(context);
                if (mounted) setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }
}
