import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../widgets/radio_option_group.dart';
import '../widgets/settings_section.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  Future<void> _resetToDefault(BuildContext context, WidgetRef ref) async {
    await confirmAndRestoreSettingsDefaults(
      context: context,
      restore: ref.read(themeSettingsProvider.notifier).resetToDefault,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);

    return SettingsSubpageScaffold(
      title: S.of(context).themeSettings,
      onRestoreDefaults: () => _resetToDefault(context, ref),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题模式选择
          SettingsSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    S.of(context).themeMode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                RadioOptionGroup<AppThemeMode>(
                  groupValue: themeSettings.themeMode,
                  options: [
                    RadioOption(
                      value: AppThemeMode.system,
                      title: Text(S.of(context).themeModeSystem),
                      subtitle: Text(S.of(context).themeModeSystemDesc),
                    ),
                    RadioOption(
                      value: AppThemeMode.light,
                      title: Text(S.of(context).themeModeLight),
                      subtitle: Text(S.of(context).themeModeLightDesc),
                    ),
                    RadioOption(
                      value: AppThemeMode.dark,
                      title: Text(S.of(context).themeModeDark),
                      subtitle: Text(S.of(context).themeModeDarkDesc),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(themeSettingsProvider.notifier)
                        .setThemeMode(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 颜色方案选择
          SettingsSectionCard(
            child: RadioGroup<ColorSchemeType>(
              groupValue: themeSettings.colorSchemeType,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setColorSchemeType(value);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      S.of(context).colorTheme,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildColorSchemeOption(
                    context,
                    ref,
                    themeSettings,
                    ColorSchemeType.oceanBlue,
                    S.of(context).colorSchemeOceanBlue,
                    S.of(context).colorSchemeOceanBlueDesc,
                    const Color(0xFF146683),
                  ),
                  _buildColorSchemeOption(
                    context,
                    ref,
                    themeSettings,
                    ColorSchemeType.sakuraPink,
                    S.of(context).colorSchemeSakuraPink,
                    S.of(context).colorSchemeSakuraPinkDesc,
                    const Color(0xFFB4276E),
                  ),
                  _buildColorSchemeOption(
                    context,
                    ref,
                    themeSettings,
                    ColorSchemeType.sunsetOrange,
                    S.of(context).colorSchemeSunsetOrange,
                    S.of(context).colorSchemeSunsetOrangeDesc,
                    const Color(0xFF904D00),
                  ),
                  _buildColorSchemeOption(
                    context,
                    ref,
                    themeSettings,
                    ColorSchemeType.lavenderPurple,
                    S.of(context).colorSchemeLavenderPurple,
                    S.of(context).colorSchemeLavenderPurpleDesc,
                    const Color(0xFF6750A4),
                  ),
                  _buildColorSchemeOption(
                    context,
                    ref,
                    themeSettings,
                    ColorSchemeType.forestGreen,
                    S.of(context).colorSchemeForestGreen,
                    S.of(context).colorSchemeForestGreenDesc,
                    const Color(0xFF3A6F41),
                  ),
                  const SettingsDivider(),
                  InkWell(
                    onTap: () {
                      ref
                          .read(themeSettingsProvider.notifier)
                          .setColorSchemeType(ColorSchemeType.dynamic);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // 彩色渐变圆圈
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE91E63), // Pink
                                  Color(0xFF9C27B0), // Purple
                                  Color(0xFF2196F3), // Blue
                                  Color(0xFF4CAF50), // Green
                                  Color(0xFFFFEB3B), // Yellow
                                  Color(0xFFFF5722), // Orange
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: themeSettings.colorSchemeType ==
                                        ColorSchemeType.dynamic
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: themeSettings.colorSchemeType ==
                                    ColorSchemeType.dynamic
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).colorSchemeDynamic,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight:
                                            themeSettings.colorSchemeType ==
                                                    ColorSchemeType.dynamic
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  S.of(context).colorSchemeDynamicDesc,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Radio<ColorSchemeType>(
                            value: ColorSchemeType.dynamic,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 预览卡片
          SettingsSectionCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).themePreview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              S.of(context).primaryContainer,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              S.of(context).secondaryContainer,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              S.of(context).tertiaryContainer,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              S.of(context).surfaceColor,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSchemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings themeSettings,
    ColorSchemeType type,
    String title,
    String subtitle,
    Color previewColor,
  ) {
    final isSelected = themeSettings.colorSchemeType == type;

    return InkWell(
      onTap: () {
        ref.read(themeSettingsProvider.notifier).setColorSchemeType(type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 颜色预览圆圈
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: previewColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // 标题和副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            // 选中的单选按钮
            Radio<ColorSchemeType>(
              value: type,
            ),
          ],
        ),
      ),
    );
  }
}
