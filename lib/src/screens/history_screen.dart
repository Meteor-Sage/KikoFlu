import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../widgets/history_work_card.dart';
import '../widgets/pagination_bar.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final history = historyState.records;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: history.isEmpty && !historyState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无播放历史',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 210,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = history[index];
                        return HistoryWorkCard(record: record);
                      },
                      childCount: history.length,
                    ),
                  ),
                ),
                if (history.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80, top: 16),
                      child: PaginationBar(
                        currentPage: historyState.currentPage,
                        totalCount: historyState.totalCount,
                        pageSize: historyState.pageSize,
                        hasMore: historyState.hasMore,
                        isLoading: historyState.isLoading,
                        onGoToPage: (page) {
                          ref.read(historyProvider.notifier).goToPage(page);
                        },
                        onPreviousPage: () {
                          ref.read(historyProvider.notifier).previousPage();
                        },
                        onNextPage: () {
                          ref.read(historyProvider.notifier).nextPage();
                        },
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: history.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showClearConfirmation(context, ref),
              tooltip: '清空历史',
              child: const Icon(Icons.delete_outline),
            )
          : null,
    );
  }

  Future<void> _showClearConfirmation(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有播放历史吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clear();
    }
  }
}
