import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'audio_format_settings_screen.dart';
import 'blocked_items_screen.dart';
import 'llm_settings_screen.dart';
import '../models/audio_gain_settings.dart';
import '../models/sort_options.dart';
import '../providers/proxy_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/l10n_extensions.dart';
import '../utils/snackbar_util.dart';
import '../widgets/radio_option_group.dart';
import '../widgets/settings_section.dart';
import '../widgets/sort_dialog.dart';

/// 偏好设置页面
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  void _showSubtitleLibraryPriorityDialog(
      BuildContext pageContext, WidgetRef ref) {
    final currentPriority = ref.read(subtitleLibraryPriorityProvider);

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          S.of(dialogContext).subtitleLibraryPriority,
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(dialogContext).selectSubtitlePriority,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            RadioOptionGroup<SubtitleLibraryPriority>(
              groupValue: currentPriority,
              options: [
                for (final priority in SubtitleLibraryPriority.values)
                  RadioOption(
                    value: priority,
                    title: Text(priority.localizedName(dialogContext)),
                    subtitle: Text(
                      priority == SubtitleLibraryPriority.highest
                          ? S.of(dialogContext).subtitlePriorityHighestDesc
                          : S.of(dialogContext).subtitlePriorityLowestDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              onChanged: (value) {
                ref
                    .read(subtitleLibraryPriorityProvider.notifier)
                    .updatePriority(value);
                Navigator.pop(dialogContext);
                SnackBarUtil.showSuccess(
                  pageContext,
                  S
                      .of(pageContext)
                      .setToValue(value.localizedName(pageContext)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(dialogContext).close),
          ),
        ],
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
          SnackBarUtil.showSuccess(
            context,
            S.of(context).defaultSortUpdated,
          );
        },
        autoClose: false,
      ),
    );
  }

  void _showTranslationSourceDialog(BuildContext pageContext, WidgetRef ref) {
    final currentSource = ref.read(translationSourceProvider);

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          S.of(dialogContext).translationSourceSettings,
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(dialogContext).selectTranslationProvider,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            RadioOptionGroup<TranslationSource>(
              groupValue: currentSource,
              options: [
                for (final source in TranslationSource.values)
                  RadioOption(
                    value: source,
                    title: Text(source.localizedName(dialogContext)),
                    subtitle: Text(
                      _getTranslationSourceDescription(dialogContext, source),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == TranslationSource.llm) {
                  final llmSettings = ref.read(llmSettingsProvider);
                  if (llmSettings.apiKey.isEmpty) {
                    showDialog(
                      context: dialogContext,
                      builder: (configContext) => AlertDialog(
                        title: Text(S.of(configContext).needsConfiguration),
                        content:
                            Text(S.of(configContext).llmConfigRequiredMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(configContext),
                            child: Text(S.of(configContext).cancel),
                          ),
                          TextButton(
                            onPressed: () async {
                              final navigator = Navigator.of(configContext);
                              navigator.pop(); // Close alert dialog
                              navigator.pop(); // Close source selection dialog
                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LLMSettingsScreen(),
                                ),
                              );

                              // Check if configured successfully
                              final newSettings = ref.read(llmSettingsProvider);
                              if (newSettings.apiKey.isNotEmpty) {
                                ref
                                    .read(translationSourceProvider.notifier)
                                    .updateSource(TranslationSource.llm);
                                if (pageContext.mounted) {
                                  SnackBarUtil.showSuccess(
                                    pageContext,
                                    S.of(pageContext).autoSwitchedToLlm,
                                  );
                                }
                              }
                            },
                            child: Text(S.of(configContext).goToConfigure),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                }

                ref
                    .read(translationSourceProvider.notifier)
                    .updateSource(value);
                Navigator.pop(dialogContext);
                SnackBarUtil.showSuccess(
                  pageContext,
                  S
                      .of(pageContext)
                      .setToValue(value.localizedName(pageContext)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(dialogContext).close),
          ),
        ],
      ),
    );
  }

  void _showTranslationTargetLanguageDialog(
      BuildContext pageContext, WidgetRef ref) {
    final translationSource = ref.read(translationSourceProvider);
    final preferences = ref.read(translationLanguagePreferencesProvider);
    final customLanguageEnabled = translationSource == TranslationSource.llm;
    final currentLanguage = preferences.targetLanguage;
    final groupValue = currentLanguage == TranslationTargetLanguage.custom &&
            !customLanguageEnabled
        ? TranslationTargetLanguage.followApp
        : currentLanguage;
    const options = TranslationTargetLanguage.values;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          S.of(dialogContext).translationTargetLanguage,
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(dialogContext).selectTranslationTargetLanguage,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            RadioOptionGroup<TranslationTargetLanguage>(
              groupValue: groupValue,
              options: [
                for (final language in options)
                  RadioOption(
                    value: language,
                    enabled: customLanguageEnabled ||
                        language != TranslationTargetLanguage.custom,
                    title: Text(_languageOptionLabel(
                      dialogContext,
                      language.localizedName(dialogContext),
                      language == TranslationTargetLanguage.custom
                          ? preferences.customTargetLanguage
                          : null,
                    )),
                    subtitle: language == TranslationTargetLanguage.custom &&
                            !customLanguageEnabled
                        ? Text(
                            S
                                .of(dialogContext)
                                .translationCustomTargetRequiresLlm,
                            style: TextStyle(
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
              ],
              onChanged: (value) async {
                if (value == TranslationTargetLanguage.custom &&
                    !customLanguageEnabled) {
                  return;
                }
                if (value == TranslationTargetLanguage.custom) {
                  final customLanguage = await _showCustomLanguageDialog(
                    pageContext,
                    title: S.of(pageContext).translationCustomTargetLanguage,
                    initialValue: preferences.customTargetLanguage,
                  );
                  if (customLanguage == null) return;
                  await ref
                      .read(translationLanguagePreferencesProvider.notifier)
                      .updateCustomTargetLanguage(customLanguage);
                }

                await ref
                    .read(translationLanguagePreferencesProvider.notifier)
                    .updateTargetLanguage(value);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                SnackBarUtil.showSuccess(
                  pageContext,
                  S
                      .of(pageContext)
                      .setToValue(value.localizedName(pageContext)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(dialogContext).close),
          ),
        ],
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

  void _showPreloadThresholdDialog(BuildContext pageContext, WidgetRef ref) {
    final currentSettings = ref.read(preloadNextSettingsProvider);

    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          S.of(dialogContext).preloadNextTitle,
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(dialogContext).selectPreloadThreshold,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            RadioOptionGroup<PreloadThresholdMode>(
              groupValue: currentSettings.mode,
              options: [
                RadioOption(
                  value: PreloadThresholdMode.off,
                  title: Text(
                      PreloadThresholdMode.off.localizedName(dialogContext)),
                ),
                RadioOption(
                  value: PreloadThresholdMode.seconds10,
                  title: Text(PreloadThresholdMode.seconds10
                      .localizedName(dialogContext)),
                ),
                RadioOption(
                  value: PreloadThresholdMode.seconds20,
                  title: Text(PreloadThresholdMode.seconds20
                      .localizedName(dialogContext)),
                ),
                RadioOption(
                  value: PreloadThresholdMode.seconds30,
                  title: Text(PreloadThresholdMode.seconds30
                      .localizedName(dialogContext)),
                ),
                RadioOption(
                  value: PreloadThresholdMode.custom,
                  title: Text(
                      PreloadThresholdMode.custom.localizedName(dialogContext)),
                  subtitle: currentSettings.mode == PreloadThresholdMode.custom
                      ? Text(
                          S.of(dialogContext).preloadCustomValueLabel(
                              currentSettings.customSeconds),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(dialogContext)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        )
                      : null,
                ),
              ],
              onChanged: (value) async {
                if (value == PreloadThresholdMode.custom) {
                  final inputSeconds = await _showPreloadCustomSecondsDialog(
                    pageContext,
                    initialValue: currentSettings.customSeconds,
                  );
                  if (inputSeconds == null) {
                    return; // 用户取消输入，保持原选中项不变
                  }
                  await ref
                      .read(preloadNextSettingsProvider.notifier)
                      .updateCustomSeconds(inputSeconds);
                }

                await ref
                    .read(preloadNextSettingsProvider.notifier)
                    .updateMode(value);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                final updated = ref.read(preloadNextSettingsProvider);
                SnackBarUtil.showSuccess(
                  pageContext,
                  S.of(pageContext).setToValue(
                        _preloadValueLabel(pageContext, updated),
                      ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(dialogContext).close),
          ),
        ],
      ),
    );
  }

  Future<int?> _showPreloadCustomSecondsDialog(
    BuildContext pageContext, {
    required int initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue.toString());
    String? errorText;
    // 解析并校验输入：合法返回正整数，越界/非法返回 null 并设置 errorText
    int? validate(BuildContext context) {
      final value = int.tryParse(controller.text.trim());
      if (value == null ||
          value < PreloadNextSettings.minSeconds ||
          value > PreloadNextSettings.maxSeconds) {
        errorText = S.of(context).preloadCustomInputRangeError;
        return null;
      }
      errorText = null;
      return value;
    }

    final result = await showDialog<int>(
      context: pageContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stContext, setState) => AlertDialog(
          title: Text(S.of(stContext).preloadCustomInputTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(stContext).preloadCustomInputHint),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: S.of(stContext).preloadCustomInputHint,
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (errorText != null) {
                    setState(() => errorText = null);
                  }
                },
                onSubmitted: (_) {
                  final value = validate(stContext);
                  if (value != null) {
                    Navigator.pop(dialogContext, value);
                  } else {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.of(stContext).cancel),
            ),
            TextButton(
              onPressed: () {
                final value = validate(stContext);
                if (value != null) {
                  Navigator.pop(dialogContext, value);
                } else {
                  setState(() {});
                }
              },
              child: Text(S.of(stContext).confirm),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
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
      BuildContext context, TranslationSource source) {
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

  Future<void> _showProxyAddressDialog(
    BuildContext context,
    WidgetRef ref,
    String currentAddress,
  ) async {
    final controller = TextEditingController(text: currentAddress);
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(S.of(dialogContext).proxyAddress),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: '127.0.0.1:7890',
              helperText: S.of(dialogContext).proxyAddressFormat,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(S.of(dialogContext).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(S.of(dialogContext).save),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    if (result == null) return;
    final accepted =
        await ref.read(proxySettingsProvider.notifier).setAddress(result);
    if (!accepted && context.mounted) {
      SnackBarUtil.showError(context, S.of(context).invalidProxyAddress);
    }
  }

  Widget _buildProxySettings(BuildContext context, WidgetRef ref) {
    final proxySettings = ref.watch(proxySettingsProvider);
    return Column(
      children: [
        SettingsSwitchTile(
          icon: Icons.vpn_lock_outlined,
          title: S.of(context).useProxy,
          subtitle: proxySettings.enabled
              ? S.of(context).proxyEnabled(
                    proxySettings.address.isEmpty
                        ? S.of(context).proxyAddressNotSet
                        : proxySettings.address,
                  )
              : S.of(context).proxyHttpDescription,
          value: proxySettings.enabled,
          onChanged: (value) =>
              ref.read(proxySettingsProvider.notifier).setEnabled(value),
        ),
        if (proxySettings.enabled) ...[
          const SettingsDivider(),
          SettingsListTile(
            leading: const SizedBox(width: 24),
            title: S.of(context).proxyAddress,
            subtitle: proxySettings.address.isEmpty
                ? S.of(context).proxyAddressNotSet
                : proxySettings.address,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showProxyAddressDialog(
              context,
              ref,
              proxySettings.address,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priority = ref.watch(subtitleLibraryPriorityProvider);
    final defaultSort = ref.watch(defaultSortProvider);
    final translationSource = ref.watch(translationSourceProvider);
    final translationLanguagePreferences =
        ref.watch(translationLanguagePreferencesProvider);
    final autoSaveTranslatedLyrics =
        ref.watch(autoSaveTranslatedLyricsProvider);
    final preloadSettings = ref.watch(preloadNextSettingsProvider);

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
                subtitle: S.of(context).currentSettingLabel(
                      translationSource.localizedName(context),
                    ),
                onTap: () => _showTranslationSourceDialog(context, ref),
              ),
              SettingsNavigationTile(
                icon: Icons.language,
                title: S.of(context).translationTargetLanguage,
                subtitle: S.of(context).currentSettingLabel(
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
                subtitle: S.of(context).currentSettingLabel(
                      _preloadValueLabel(context, preloadSettings),
                    ),
                onTap: () => _showPreloadThresholdDialog(context, ref),
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
                  subtitle: Theme.of(context).platform ==
                          TargetPlatform.windows
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
                  divisions: ((maxDecibels - AudioGainSettings.minDecibels) /
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
