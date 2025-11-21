import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/floating_lyric_style_provider.dart';
import '../widgets/scrollable_appbar.dart';

class FloatingLyricStyleScreen extends ConsumerWidget {
  const FloatingLyricStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(floatingLyricStyleProvider);

    return Scaffold(
      appBar: const ScrollableAppBar(
        title: Text('悬浮歌词样式', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 预览卡片
          _buildPreviewCard(context, style),
          const SizedBox(height: 24),

          // 预设样式
          _buildPresetsCard(context, ref),
          const SizedBox(height: 24),

          // 字体大小
          _buildFontSizeCard(context, ref, style),
          const SizedBox(height: 16),

          // 不透明度
          _buildOpacityCard(context, ref, style),
          const SizedBox(height: 16),

          // 颜色设置
          _buildColorsCard(context, ref, style),
          const SizedBox(height: 16),

          // 圆角和内边距
          _buildShapeCard(context, ref, style),
          const SizedBox(height: 16),

          // 重置按钮
          _buildResetButton(context, ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, FloatingLyricStyle style) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: style.paddingHorizontal,
                  vertical: style.paddingVertical,
                ),
                decoration: BoxDecoration(
                  color: style.backgroundColorWithOpacity,
                  borderRadius: BorderRadius.circular(style.cornerRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '♪ 示例歌词内容 ♪',
                  style: TextStyle(
                    color: style.textColor,
                    fontSize: style.fontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预设样式',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FloatingLyricStylePreset.values.map((preset) {
                return ActionChip(
                  label: Text(preset.name),
                  onPressed: () {
                    ref
                        .read(floatingLyricStyleProvider.notifier)
                        .applyPreset(preset);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeCard(
      BuildContext context, WidgetRef ref, FloatingLyricStyle style) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '字体大小',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${style.fontSize.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Slider(
              value: style.fontSize,
              min: 12,
              max: 28,
              divisions: 16,
              label: '${style.fontSize.toInt()}',
              onChanged: (value) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updateFontSize(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpacityCard(
      BuildContext context, WidgetRef ref, FloatingLyricStyle style) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '不透明度',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${(style.opacity * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Slider(
              value: style.opacity,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              label: '${(style.opacity * 100).toInt()}%',
              onChanged: (value) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updateOpacity(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorsCard(
      BuildContext context, WidgetRef ref, FloatingLyricStyle style) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '颜色设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildColorPicker(
              context,
              '文字颜色',
              style.textColor,
              [
                Colors.white,
                Colors.black,
                const Color(0xFFE3F2FD),
                const Color(0xFFFFF9C4),
                const Color(0xFFFFCDD2),
                const Color(0xFFC8E6C9),
              ],
              (color) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updateTextColor(color);
              },
            ),
            const SizedBox(height: 16),
            _buildColorPicker(
              context,
              '背景颜色',
              style.backgroundColor,
              [
                Colors.black,
                const Color(0xFF1A237E),
                const Color(0xFF0D47A1),
                const Color(0xFF1B5E20),
                const Color(0xFFE91E63),
                const Color(0xFF6A1B9A),
              ],
              (color) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updateBackgroundColor(color);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    String label,
    Color currentColor,
    List<Color> colors,
    Function(Color) onColorSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = color.value == currentColor.value;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShapeCard(
      BuildContext context, WidgetRef ref, FloatingLyricStyle style) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '形状设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('圆角半径', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${style.cornerRadius.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Slider(
              value: style.cornerRadius,
              min: 0,
              max: 24,
              divisions: 24,
              label: '${style.cornerRadius.toInt()}',
              onChanged: (value) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updateCornerRadius(value);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('水平内边距', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${style.paddingHorizontal.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Slider(
              value: style.paddingHorizontal,
              min: 12,
              max: 40,
              divisions: 28,
              label: '${style.paddingHorizontal.toInt()}',
              onChanged: (value) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updatePaddingHorizontal(value);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('垂直内边距', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${style.paddingVertical.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Slider(
              value: style.paddingVertical,
              min: 6,
              max: 20,
              divisions: 14,
              label: '${style.paddingVertical.toInt()}',
              onChanged: (value) {
                ref
                    .read(floatingLyricStyleProvider.notifier)
                    .updatePaddingVertical(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('重置样式'),
            content: const Text('确定要恢复默认样式吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(floatingLyricStyleProvider.notifier).reset();
                  Navigator.pop(context);
                },
                child: const Text('重置'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.restore),
      label: const Text('恢复默认样式'),
    );
  }
}
