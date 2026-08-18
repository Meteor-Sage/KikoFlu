import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/works_provider.dart';
import '../utils/scroll_optimization.dart';
import '../widgets/sort_dialog.dart';
import '../widgets/works_grid_view.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../utils/snackbar_util.dart';
import '../widgets/scrollable_appbar.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/download_fab.dart';
import '../models/sort_options.dart';
import '../utils/subtitle_filter.dart';
import '../utils/l10n_extensions.dart';

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
      barrierDismissible: !Platform.isIOS, // iOS 上防止点击外部区域意外关闭
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

  Icon _getLayoutIcon(LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.bigGrid:
        return const Icon(Icons.grid_3x3);
      case LayoutType.smallGrid:
        return const Icon(Icons.view_list);
      case LayoutType.list:
        return const Icon(Icons.view_agenda);
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

  Icon _getSubtitleFilterIcon(int subtitleFilter) {
    final mode = SubtitleFilterMode.fromValue(subtitleFilter);
    return Icon(
      mode == SubtitleFilterMode.withSubtitles
          ? Icons.closed_caption
          : Icons.closed_caption_disabled,
      color: mode.isActive ? Theme.of(context).colorScheme.primary : null,
    );
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

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? 24.0 : 8.0;

    return Scaffold(
      floatingActionButton: const DownloadFab(),
      appBar: ScrollableAppBar(
        toolbarHeight: 56,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              // 第一列：可滚动的模式切换按钮
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 8),
                  child: _buildModeButtons(context, worksState),
                ),
              ),
              // 分隔线
              Container(
                height: 28,
                width: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
                margin: const EdgeInsets.symmetric(horizontal: 2),
              ),
              // 第二列：布局切换按钮
              IconButton(
                icon: _getLayoutIcon(worksState.layoutType),
                iconSize: 22,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () =>
                    ref.read(worksProvider.notifier).toggleLayoutType(),
                tooltip: _getLayoutTooltip(worksState.layoutType),
              ),
              // 第三列：字幕筛选按钮
              IconButton(
                icon: _getSubtitleFilterIcon(worksState.subtitleFilter),
                iconSize: 22,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () =>
                    ref.read(worksProvider.notifier).toggleSubtitleFilter(),
                tooltip: SubtitleFilterMode.fromValue(
                  worksState.subtitleFilter,
                ).localizedTooltip(context),
              ),
              // 第四列：排序按钮
              Padding(
                padding: EdgeInsets.only(right: horizontalPadding - 6),
                child: IconButton(
                  icon: Icon(
                    Icons.sort,
                    color: isRecommendMode ? Colors.grey : null,
                  ),
                  iconSize: 22,
                  padding: const EdgeInsets.all(6),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed:
                      isRecommendMode ? null : () => _showSortDialog(context),
                  tooltip: isRecommendMode
                      ? S.of(context).recommendedNoSort
                      : S.of(context).sort,
                ),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
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
            child: _buildBody(worksState),
          ),
        ),
      ),
    );
  }

  /// ===== 构建「全部 / 热门 / 推荐」按钮组 =====
  Widget _buildModeButtons(BuildContext context, WorksState worksState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeButton(
          context: context,
          icon: Icons.grid_view,
          label: S.of(context).displayModeAll,
          isSelected: worksState.displayMode == DisplayMode.all,
          index: 0,
          total: 3,
          onTap: () => _changeDisplayMode(DisplayMode.all),
        ),
        _buildModeButton(
          context: context,
          icon: Icons.local_fire_department,
          label: S.of(context).displayModePopular,
          isSelected: worksState.displayMode == DisplayMode.popular,
          index: 1,
          total: 3,
          onTap: () => _changeDisplayMode(DisplayMode.popular),
        ),
        _buildModeButton(
          context: context,
          icon: Icons.auto_awesome,
          label: S.of(context).displayModeRecommended,
          isSelected: worksState.displayMode == DisplayMode.recommended,
          index: 2,
          total: 3,
          onTap: () => _changeDisplayMode(DisplayMode.recommended),
        ),
      ],
    );
  }

  /// ===== 单个模式按钮样式封装 =====
  Widget _buildModeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int index,
    required int total,
  }) {
    final theme = Theme.of(context);

    // 第一个按钮：左侧圆角，右侧方角
    // 最后一个按钮：左侧方角，右侧圆角
    // 中间按钮：两侧方角
    BorderRadius buttonBorderRadius;
    if (index == 0) {
      buttonBorderRadius = const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      );
    } else if (index == total - 1) {
      buttonBorderRadius = const BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );
    } else {
      buttonBorderRadius = BorderRadius.zero;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: buttonBorderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: buttonBorderRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WorksState worksState) {
    return _buildLayoutView(worksState);
  }

  Widget _buildLayoutView(WorksState worksState) {
    final notifier = ref.read(worksProvider.notifier);
    return WorksGridView(
      works: worksState.works,
      layoutType: worksState.layoutType,
      scrollController: _scrollController,
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
