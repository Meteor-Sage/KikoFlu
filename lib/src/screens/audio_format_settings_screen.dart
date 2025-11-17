import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/scrollable_appbar.dart';

class AudioFormatSettingsScreen extends ConsumerStatefulWidget {
  const AudioFormatSettingsScreen({super.key});

  @override
  ConsumerState<AudioFormatSettingsScreen> createState() =>
      _AudioFormatSettingsScreenState();
}

class _AudioFormatSettingsScreenState
    extends ConsumerState<AudioFormatSettingsScreen> {
  late List<AudioFormat> _formatOrder;

  @override
  void initState() {
    super.initState();
    // 延迟初始化以确保provider已经加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preference = ref.read(audioFormatPreferenceProvider);
      setState(() {
        _formatOrder = List.from(preference.priority);
      });
    });
  }

  Future<void> _saveSettings() async {
    await ref
        .read(audioFormatPreferenceProvider.notifier)
        .updatePriority(_formatOrder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复默认设置'),
        content: const Text('确定要恢复默认的音频格式优先级吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(audioFormatPreferenceProvider.notifier).resetToDefault();
      final preference = ref.read(audioFormatPreferenceProvider);
      setState(() {
        _formatOrder = List.from(preference.priority);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复默认设置')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScrollableAppBar(
        title: const Text('音频格式优先级', style: TextStyle(fontSize: 18)),
        actions: [
          TextButton.icon(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.restart_alt),
            label: const Text('恢复默认'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _formatOrder.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 说明卡片
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '优先级说明',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• 打开作品详情页时，会优先展开包含优先级更高格式音频的文件夹\n'
                          '• 拖动格式卡片可以调整优先级顺序\n'
                          '• 靠前的格式优先级更高',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),

                // 格式列表
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _formatOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _formatOrder.removeAt(oldIndex);
                        _formatOrder.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final format = _formatOrder[index];
                      return Card(
                        key: ValueKey(format),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            format.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '.${format.extension}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 保存按钮
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.check),
                        label: const Text('保存设置'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
