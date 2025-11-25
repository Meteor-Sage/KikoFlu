import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_format_settings_screen.dart';
import '../models/sort_options.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/sort_dialog.dart';

/// 偏好设置页面
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  void _showSubtitleLibraryPriorityDialog(BuildContext context, WidgetRef ref) {
    final currentPriority = ref.read(subtitleLibraryPriorityProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '字幕库优先级',
          style: TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择字幕库在自动加载中的优先级：',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...SubtitleLibraryPriority.values.map((priority) {
              return RadioListTile<SubtitleLibraryPriority>(
                title: Text(priority.displayName),
                subtitle: Text(
                  priority == SubtitleLibraryPriority.highest
                      ? '优先查找字幕库，再查找在线/下载'
                      : '优先查找在线/下载，再查找字幕库',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                value: priority,
                groupValue: currentPriority,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(subtitleLibraryPriorityProvider.notifier)
                        .updatePriority(value);
                    Navigator.pop(context);
                    SnackBarUtil.showSuccess(
                      context,
                      '已设置为: ${value.displayName}',
                    );
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
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
        title: '默认排序设置',
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
            '默认排序已更新',
          );
        },
        autoClose: false,
      ),
    );
  }

  void _showTranslationSourceDialog(BuildContext context, WidgetRef ref) {
    final currentSource = ref.read(translationSourceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '翻译源设置',
          style: TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择翻译服务提供商：',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...TranslationSource.values.map((source) {
              return RadioListTile<TranslationSource>(
                title: Text(source.displayName),
                subtitle: Text(
                  source == TranslationSource.google
                      ? 'Google 翻译 (需要网络环境支持)'
                      : '有道翻译 (无需 API Key)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                value: source,
                groupValue: currentSource,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(translationSourceProvider.notifier)
                        .updateSource(value);
                    Navigator.pop(context);
                    SnackBarUtil.showSuccess(
                      context,
                      '已设置为: ${value.displayName}',
                    );
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priority = ref.watch(subtitleLibraryPriorityProvider);
    final defaultSort = ref.watch(defaultSortProvider);
    final translationSource = ref.watch(translationSourceProvider);

    return Scaffold(
      appBar: const ScrollableAppBar(
        title: Text('偏好设置', style: TextStyle(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.library_books,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('字幕库优先级'),
                  subtitle: Text('当前: ${priority.displayName}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showSubtitleLibraryPriorityDialog(context, ref);
                  },
                ),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                ListTile(
                  leading: Icon(Icons.sort,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('首页默认排序方式'),
                  subtitle: Text(
                      '${defaultSort.order.label} - ${defaultSort.direction.label}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDefaultSortDialog(context, ref);
                  },
                ),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                ListTile(
                  leading: Icon(Icons.translate,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('翻译源'),
                  subtitle: Text('当前: ${translationSource.displayName}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showTranslationSourceDialog(context, ref);
                  },
                ),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                ListTile(
                  leading: Icon(Icons.audio_file,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('音频格式偏好'),
                  subtitle: const Text('设置音频格式的优先级顺序'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AudioFormatSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
