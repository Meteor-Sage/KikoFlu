import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/work_cover_prefetch.dart';
import '../widgets/history_work_card.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../../l10n/app_localizations.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final history = historyState.records;
    final auth = ref.watch(authProvider.select(
      (value) => (host: value.host ?? '', token: value.token ?? ''),
    ));
    final crossAxisCount =
        (MediaQuery.sizeOf(context).width / 210).ceil().clamp(1, 8);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VirtualizedSliverCollection(
        items: history,
        itemId: (record) => record.work.id,
        pageStorageKey: const PageStorageKey('history-feed'),
        layout: VirtualizedCollectionLayout.grid,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 210,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        padding: const EdgeInsets.all(16),
        isInitialLoading: historyState.isLoading && history.isEmpty,
        isRefreshing: historyState.isRefreshing,
        isLoadingMore: historyState.isLoadingMore,
        hasMore: historyState.hasMore,
        error: history.isEmpty ? historyState.error : null,
        loadMoreError: historyState.loadMoreError,
        onRefresh: ref.read(historyProvider.notifier).refresh,
        onLoadMore: ref.read(historyProvider.notifier).loadMore,
        onRetry: ref.read(historyProvider.notifier).refresh,
        onPrefetch: (records) => prefetchWorkCovers(
          context,
          records.map((record) => record.work),
          host: auth.host,
          token: auth.token,
          crossAxisCount: crossAxisCount,
        ),
        emptyBuilder: (context) => Center(
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
                S.of(context).noPlayHistory,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context, record, index) => HistoryWorkCard(
          key: ValueKey(record.work.id),
          record: record,
        ),
      ),
      floatingActionButton: history.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showClearConfirmation(context, ref),
              tooltip: S.of(context).clearHistory,
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
        title: Text(S.of(context).clearHistoryTitle),
        content: Text(S.of(context).clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clear();
    }
  }
}
