import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/works_provider.dart';

class SortDialog extends ConsumerWidget {
  const SortDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worksState = ref.watch(worksProvider);
    final worksNotifier = ref.read(worksProvider.notifier);

    return AlertDialog(
      title: const Text('排序选项'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 排序字段选择
            const Text(
              '排序字段',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...SortOption.values.map((option) {
              return RadioListTile<SortOption>(
                title: Text(option.label),
                value: option,
                groupValue: worksState.sortOption,
                onChanged: (value) {
                  if (value != null) {
                    worksNotifier.setSortOption(value);
                  }
                },
                dense: true,
              );
            }),
            const Divider(),
            // 排序方向选择
            const Text(
              '排序方向',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...SortDirection.values.map((direction) {
              return RadioListTile<SortDirection>(
                title: Text(direction.label),
                value: direction,
                groupValue: worksState.sortDirection,
                onChanged: (value) {
                  if (value != null) {
                    worksNotifier.setSortDirection(value);
                  }
                },
                dense: true,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
