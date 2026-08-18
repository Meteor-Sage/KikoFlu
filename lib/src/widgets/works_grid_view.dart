import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/work.dart';
import '../providers/work_card_display_provider.dart';
import '../providers/works_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_grid_helper.dart';
import '../utils/work_cover_prefetch.dart';
import 'enhanced_work_card.dart';
import 'virtualized_sliver_collection.dart';

class WorksGridView extends ConsumerWidget {
  const WorksGridView({
    super.key,
    required this.works,
    required this.layoutType,
    this.scrollController,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
    this.onRefresh,
    this.onLoadMore,
    this.onRetry,
    this.onPrefetch,
    this.emptyBuilder,
    this.endBuilder,
    this.showEndMessage = false,
    this.paginationWidget,
    this.pageStorageKey,
  });

  final List<Work> works;
  final LayoutType layoutType;
  final ScrollController? scrollController;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final Object? loadMoreError;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final VoidCallback? onRetry;
  final ValueChanged<List<Work>>? onPrefetch;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? endBuilder;
  final bool showEndMessage;
  final Widget? paginationWidget;
  final PageStorageKey<String>? pageStorageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(workCardDisplayProvider);
    final auth = ref.watch(
      authProvider.select((state) => (state.host ?? '', state.token ?? '')),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final isLandscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      final spacing = isLandscape ? 24.0 : 8.0;
      final padding = isLandscape ? 24.0 : 8.0;
      final crossAxisCount = switch (layoutType) {
        LayoutType.bigGrid => displaySettings.applyCardSize(
            ResponsiveGridHelper.getBigGridCrossAxisCount(context),
          ),
        LayoutType.smallGrid => displaySettings.applyCardSize(
            ResponsiveGridHelper.getSmallGridCrossAxisCount(context),
            minCrossAxisCount: 2,
          ),
        LayoutType.list => 1,
      };
      final isGrid = layoutType != LayoutType.list;
      final availableWidth = constraints.maxWidth - padding * 2;
      final cardWidth = isGrid
          ? (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount
          : availableWidth;
      final usesCompactCard =
          crossAxisCount >= 5 || (crossAxisCount == 3 && !isLandscape);
      final detailsHeight = usesCompactCard ? 96.0 : 225.0;

      return VirtualizedSliverCollection<Work>(
        controller: scrollController,
        pageStorageKey: pageStorageKey,
        items: works,
        itemId: (work) => work.id,
        itemBuilder: (context, work, index) => EnhancedWorkCard(
          key: ValueKey(work.id),
          work: work,
          crossAxisCount: crossAxisCount,
        ),
        layout: isGrid
            ? VirtualizedCollectionLayout.grid
            : VirtualizedCollectionLayout.list,
        gridDelegate: isGrid
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: cardWidth +
                    detailsHeight * displaySettings.fontScale.multiplier,
              )
            : null,
        padding: EdgeInsets.all(padding),
        isInitialLoading: isLoading && works.isEmpty,
        isRefreshing: isRefreshing,
        isLoadingMore: isLoadingMore,
        hasMore: hasMore,
        error: works.isEmpty ? error : null,
        loadMoreError: loadMoreError,
        onRefresh: onRefresh,
        onLoadMore: onLoadMore,
        onRetry: onRetry,
        onPrefetch: (items) {
          prefetchWorkCovers(
            context,
            items,
            host: auth.$1,
            token: auth.$2,
            crossAxisCount: crossAxisCount,
          );
          onPrefetch?.call(items);
        },
        emptyBuilder: emptyBuilder,
        endBuilder: endBuilder,
        showEndIndicator: showEndMessage && works.isNotEmpty,
        sliversAfter: paginationWidget == null
            ? const []
            : [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, spacing, padding, 24),
                  sliver: SliverToBoxAdapter(child: paginationWidget),
                ),
              ],
      );
    });
  }
}
