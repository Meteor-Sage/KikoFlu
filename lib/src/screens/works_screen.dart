import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/works_provider.dart';
import '../utils/scroll_optimization.dart';
import '../widgets/sort_dialog.dart';
import '../widgets/works_grid_view.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../utils/snackbar_util.dart';
import '../widgets/floating_feed_toolbar.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/download_fab.dart';
import '../models/sort_options.dart';
import '../utils/subtitle_filter.dart';
import '../utils/l10n_extensions.dart';
import '../utils/system_ui_style.dart';

class WorksScreen extends ConsumerStatefulWidget {
  const WorksScreen({super.key});

  @override
  ConsumerState<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends ConsumerState<WorksScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  int _slideDirection = 0;
  final Map<DisplayMode, double> _scrollPositions = {
    for (final mode in DisplayMode.values) mode: 0.0,
  };

  @override
  bool get wantKeepAlive => true; // 保持状态不被销毁

  @override
  void initState() {
    super.initState();
    // 只在首次加载时获取数据，如果已有数据则不重新加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final worksState = ref.read(worksProvider);
      if (worksState.works.isEmpty) {
        ref.read(worksProvider.notifier).loadWorks(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSortDialog(BuildContext context) {
    final displayMode = ref.read(worksProvider).displayMode;
    final isRecommendMode = displayMode == DisplayMode.popular ||
        displayMode == DisplayMode.recommended;

    if (isRecommendMode) {
      SnackBarUtil.showInfo(
        context,
        displayMode == DisplayMode.popular
            ? S.of(context).popularNoSort
            : S.of(context).recommendedNoSort,
      );
      return;
    }

    final state = ref.read(worksProvider);
    showDialog(
      context: context,
      builder: (context) => CommonSortDialog(
        currentOption: state.sortOption,
        currentDirection: state.sortDirection,
        availableOptions: SortOrder.values
            .where((option) => option != SortOrder.updatedAt)
            .toList(),
        onSort: (option, direction) {
          ref.read(worksProvider.notifier).setSortOption(option);
          ref.read(worksProvider.notifier).setSortDirection(direction);
        },
        autoClose: true,
      ),
    );
  }

  IconData _getLayoutIcon(LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.bigGrid:
        return Icons.grid_3x3;
      case LayoutType.smallGrid:
        return Icons.view_list;
      case LayoutType.list:
        return Icons.view_agenda;
    }
  }

  String _getLayoutTooltip(LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.bigGrid:
        return S.of(context).switchToSmallGrid;
      case LayoutType.smallGrid:
        return S.of(context).switchToList;
      case LayoutType.list:
        return S.of(context).switchToLargeGrid;
    }
  }

  IconData _getSubtitleFilterIcon(int subtitleFilter) {
    final mode = SubtitleFilterMode.fromValue(subtitleFilter);
    return mode == SubtitleFilterMode.withSubtitles
        ? Icons.closed_caption
        : Icons.closed_caption_disabled;
  }

  void _changeDisplayMode(DisplayMode mode) {
    final currentMode = ref.read(worksProvider).displayMode;
    if (currentMode == mode) return;

    if (_scrollController.hasClients) {
      _scrollPositions[currentMode] = _scrollController.offset;
    }

    ref.read(worksProvider.notifier).setDisplayMode(mode);
  }

  void _restoreScrollPosition(DisplayMode mode) {
    final targetOffset = _scrollPositions[mode] ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final safeMax = maxExtent.isFinite ? maxExtent : targetOffset;
      final clamped = targetOffset.clamp(0.0, safeMax).toDouble();
      _scrollController.jumpTo(clamped);
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    final velocity = details.primaryVelocity!;
    final worksState = ref.read(worksProvider);

    // Sensitivity threshold
    if (velocity.abs() < 500) return;

    if (velocity < 0) {
      // Swipe Left (Next Tab)
      if (worksState.displayMode == DisplayMode.all) {
        _changeDisplayMode(DisplayMode.popular);
      } else if (worksState.displayMode == DisplayMode.popular) {
        _changeDisplayMode(DisplayMode.recommended);
      }
    } else {
      // Swipe Right (Previous Tab)
      if (worksState.displayMode == DisplayMode.recommended) {
        _changeDisplayMode(DisplayMode.popular);
      } else if (worksState.displayMode == DisplayMode.popular) {
        _changeDisplayMode(DisplayMode.all);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以保持状态
    ref.listen<WorksState>(
      worksProvider,
      (previous, next) {
        if (!mounted) return;
        if (previous == null) return;
        if (previous.displayMode == next.displayMode) return;

        final prevIndex = DisplayMode.values.indexOf(previous.displayMode);
        final nextIndex = DisplayMode.values.indexOf(next.displayMode);

        setState(() {
          _slideDirection = nextIndex >= prevIndex ? 1 : -1;
        });

        _restoreScrollPosition(next.displayMode);
      },
    );
    final worksState = ref.watch(worksProvider);
    final isRecommendMode = worksState.displayMode == DisplayMode.popular ||
        worksState.displayMode == DisplayMode.recommended;

    final horizontalPadding = FloatingToolbarLayout.horizontalPadding(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final toolbarTop = topPadding + 8;
    final contentTopPadding = toolbarTop + 56;
    final systemOverlayStyle =
        transparentSystemBarsForBrightness(Theme.of(context).brightness);

    return AnnotatedRegion(
      value: systemOverlayStyle,
      child: Scaffold(
        floatingActionButton: const DownloadFab(),
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragEnd: _handleSwipe,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final direction = _slideDirection == 0
                        ? 0.0
                        : (_slideDirection > 0 ? 0.12 : -0.12);
                    final offsetAnimation = Tween<Offset>(
                      begin: Offset(direction, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(worksState.displayMode),
                    child: _buildBody(
                      worksState,
                      EdgeInsets.fromLTRB(
                        horizontalPadding,
                        contentTopPadding,
                        horizontalPadding,
                        horizontalPadding,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ProgressiveTopBlur(height: topPadding + 72),
            ),
            Positioned(
              top: toolbarTop,
              left: horizontalPadding,
              right: horizontalPadding,
              child: FloatingFeedToolbar(
                modeActions: _buildModeActions(context, worksState),
                toolActions: _buildToolActions(
                  context,
                  worksState,
                  isRecommendMode: isRecommendMode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FloatingFeedModeAction> _buildModeActions(
    BuildContext context,
    WorksState worksState,
  ) {
    return [
      FloatingFeedModeAction(
        icon: Icons.grid_view,
        label: S.of(context).displayModeAll,
        isSelected: worksState.displayMode == DisplayMode.all,
        onPressed: () => _changeDisplayMode(DisplayMode.all),
      ),
      FloatingFeedModeAction(
        icon: Icons.local_fire_department,
        label: S.of(context).displayModePopular,
        isSelected: worksState.displayMode == DisplayMode.popular,
        onPressed: () => _changeDisplayMode(DisplayMode.popular),
      ),
      FloatingFeedModeAction(
        icon: Icons.auto_awesome,
        label: S.of(context).displayModeRecommended,
        isSelected: worksState.displayMode == DisplayMode.recommended,
        onPressed: () => _changeDisplayMode(DisplayMode.recommended),
      ),
    ];
  }

  List<FloatingFeedToolAction> _buildToolActions(
    BuildContext context,
    WorksState worksState, {
    required bool isRecommendMode,
  }) {
    final subtitleMode =
        SubtitleFilterMode.fromValue(worksState.subtitleFilter);
    return [
      FloatingFeedToolAction(
        icon: _getLayoutIcon(worksState.layoutType),
        tooltip: _getLayoutTooltip(worksState.layoutType),
        onPressed: () => ref.read(worksProvider.notifier).toggleLayoutType(),
      ),
      FloatingFeedToolAction(
        icon: _getSubtitleFilterIcon(worksState.subtitleFilter),
        tooltip: subtitleMode.localizedTooltip(context),
        isSelected: subtitleMode.isActive,
        onPressed: () =>
            ref.read(worksProvider.notifier).toggleSubtitleFilter(),
      ),
      FloatingFeedToolAction(
        icon: Icons.sort,
        tooltip: isRecommendMode
            ? S.of(context).recommendedNoSort
            : S.of(context).sort,
        onPressed: isRecommendMode ? null : () => _showSortDialog(context),
      ),
    ];
  }

  Widget _buildBody(WorksState worksState, EdgeInsetsGeometry padding) {
    return _buildLayoutView(worksState, padding);
  }

  Widget _buildLayoutView(
    WorksState worksState,
    EdgeInsetsGeometry padding,
  ) {
    final notifier = ref.read(worksProvider.notifier);
    return WorksGridView(
      works: worksState.works,
      layoutType: worksState.layoutType,
      scrollController: _scrollController,
      padding: padding,
      physics: ScrollOptimization.physics,
      isLoading: worksState.isLoading,
      isRefreshing: worksState.isLoading && worksState.works.isNotEmpty,
      isLoadingMore: worksState.isLoadingMore,
      hasMore: worksState.hasMore,
      error: worksState.error,
      loadMoreError: null,
      onLoadMore:
          worksState.displayMode == DisplayMode.all ? null : notifier.loadMore,
      onRetry: notifier.refresh,
      onRefresh: worksState.works.isEmpty ? null : notifier.refresh,
      pagination: worksState.displayMode == DisplayMode.all
          ? VirtualizedPagination(
              currentPage: worksState.currentPage,
              pageSize: worksState.pageSize,
              totalCount: worksState.totalCount,
              hasMore: worksState.hasMore,
              isLoading: worksState.isLoading || worksState.isRefreshing,
              onPreviousPage: notifier.previousPage,
              onNextPage: notifier.nextPage,
              onGoToPage: notifier.goToPage,
              nextPageOnOverscroll: true,
              scrollDuration: const Duration(milliseconds: 500),
              scrollCurve: Curves.easeInOut,
              extraBuilder: worksState.rawWorks.length > worksState.works.length
                  ? (context) => Text(
                        S.of(context).pageExcludedNWorks(
                              worksState.rawWorks.length -
                                  worksState.works.length,
                            ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      )
                  : null,
            )
          : null,
      showEndMessage:
          worksState.displayMode != DisplayMode.all && worksState.isLastPage,
      loadingBuilder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(S.of(context).loading),
          ],
        ),
      ),
      errorBuilder: (context, error, retry) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).loadFailed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      ),
      emptyBuilder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noWorks,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).checkNetworkOrRetry,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      endBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).reachedEnd,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (worksState.rawWorks.length > worksState.works.length) ...[
              const SizedBox(height: 8),
              Text(
                S.of(context).excludedNWorks(
                      worksState.rawWorks.length - worksState.works.length,
                    ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
