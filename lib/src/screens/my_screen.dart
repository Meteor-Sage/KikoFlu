import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_reviews_provider.dart';
import '../providers/my_tabs_display_provider.dart';
import '../providers/works_provider.dart' show LayoutType;
import '../utils/scroll_optimization.dart';
import '../providers/auth_provider.dart';
import '../utils/server_utils.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/works_grid_view.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../widgets/floating_feed_toolbar.dart';
import '../widgets/liquid_glass_layout.dart';
import '../widgets/download_fab.dart';
import '../services/download_service.dart';
import '../models/download_task.dart';
import 'downloads_screen.dart';
import 'local_downloads_screen.dart';
import 'subtitle_library_screen.dart';
import 'playlists_screen.dart';
import 'history_screen.dart';
import '../widgets/sort_dialog.dart';
import '../models/sort_options.dart';
import '../utils/subtitle_filter.dart';
import '../utils/system_ui_style.dart';
export '../providers/my_reviews_provider.dart' show MyReviewLayoutType;

import '../../l10n/app_localizations.dart';

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  final ValueNotifier<bool> _tabSwitcherVisible = ValueNotifier(true);
  int _lastTabIndex = 0;

  @override
  bool get wantKeepAlive => true; // 保持状态不被销毁

  List<_TabInfo> _buildTabList(
    MyTabsDisplaySettings settings, {
    required double contentTop,
    required double collapsedToolbarTop,
  }) {
    final tabs = <_TabInfo>[];
    final authState = ref.watch(authProvider);
    final isOfficialServer = ServerUtils.isOfficialServer(authState.host);

    if (settings.showOnlineMarks) {
      tabs.add(_TabInfo(
        title: S.of(context).onlineMarks,
        icon: Icons.bookmark,
        index: 0,
        widget: _buildOnlineBookmarksTab(
          toolbarTop: contentTop,
          collapsedToolbarTop: collapsedToolbarTop,
        ),
        showFab: true,
        fabWidget: const DownloadFab(),
      ));
    }

    // 历史记录
    tabs.add(_TabInfo(
      title: S.of(context).historyRecord,
      icon: Icons.history,
      index: tabs.length,
      widget: HistoryScreen(topInset: contentTop),
    ));

    if (settings.showPlaylists && isOfficialServer) {
      tabs.add(_TabInfo(
        title: S.of(context).playlists,
        icon: Icons.playlist_play,
        index: 1,
        widget: PlaylistsScreen(topInset: contentTop),
      ));
    }

    // 已下载始终显示
    tabs.add(_TabInfo(
      title: S.of(context).downloaded,
      icon: Icons.download_done,
      index: 2,
      widget: LocalDownloadsScreen(
        toolbarTop: contentTop,
        collapsedToolbarTop: collapsedToolbarTop,
        primaryToolbarVisible: _tabSwitcherVisible,
      ),
      showFab: true,
      fabWidget: StreamBuilder<List<DownloadTask>>(
        stream: DownloadService.instance.tasksStream,
        builder: (context, snapshot) {
          final activeCount = DownloadService.instance.activeDownloadCount;
          return Badge(
            isLabelVisible: activeCount > 0,
            label: Text('$activeCount'),
            child: FloatingActionButton(
              onPressed: _navigateToDownloads,
              tooltip: S.of(context).downloadTasks,
              child: const Icon(Icons.download),
            ),
          );
        },
      ),
    ));

    if (settings.showSubtitleLibrary) {
      tabs.add(_TabInfo(
        title: S.of(context).subtitleLibrary,
        icon: Icons.subtitles,
        index: 3,
        widget: SubtitleLibraryScreen(
          toolbarTop: contentTop,
          collapsedToolbarTop: collapsedToolbarTop,
          primaryToolbarVisible: _tabSwitcherVisible,
        ),
      ));
    }

    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    // 只在首次加载时获取数据，如果已有数据则不重新加载
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(myReviewsProvider.notifier);
      await notifier.preferencesReady;
      if (!mounted) return;
      final myState = ref.read(myReviewsProvider);
      if (myState.works.isEmpty) {
        notifier.load(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _tabSwitcherVisible.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToDownloads() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DownloadsScreen(),
      ),
    );
  }

  void _handleTabChanged() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    _tabSwitcherVisible.value = true;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _tabSwitcherVisible.value = true;
      return false;
    }

    final scrolledPastHeader =
        notification.metrics.pixels - notification.metrics.minScrollExtent >=
            kTextTabBarHeight;

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0) {
      if (notification.scrollDelta! < 0) {
        _tabSwitcherVisible.value = true;
      } else if (scrolledPastHeader) {
        _tabSwitcherVisible.value = false;
      }
    } else if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          if (scrolledPastHeader) {
            _tabSwitcherVisible.value = false;
          }
        case ScrollDirection.forward:
          _tabSwitcherVisible.value = true;
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  IconData _getLayoutIcon(MyReviewLayoutType layoutType) {
    switch (layoutType) {
      case MyReviewLayoutType.bigGrid:
        return Icons.grid_3x3;
      case MyReviewLayoutType.smallGrid:
        return Icons.view_list;
      case MyReviewLayoutType.list:
        return Icons.view_agenda;
    }
  }

  String _getLayoutTooltip(MyReviewLayoutType layoutType) {
    switch (layoutType) {
      case MyReviewLayoutType.bigGrid:
        return S.of(context).switchToSmallGrid;
      case MyReviewLayoutType.smallGrid:
        return S.of(context).switchToList;
      case MyReviewLayoutType.list:
        return S.of(context).switchToLargeGrid;
    }
  }

  IconData _getSubtitleFilterIcon(int subtitleFilter) {
    final mode = SubtitleFilterMode.fromValue(subtitleFilter);
    return mode == SubtitleFilterMode.withSubtitles
        ? Icons.closed_caption
        : Icons.closed_caption_disabled;
  }

  IconData _getFilterIcon(MyReviewFilter filter) {
    switch (filter) {
      case MyReviewFilter.all:
        return Icons.all_inclusive;
      case MyReviewFilter.marked:
        return Icons.bookmark;
      case MyReviewFilter.listening:
        return Icons.headphones;
      case MyReviewFilter.listened:
        return Icons.check_circle;
      case MyReviewFilter.replay:
        return Icons.replay;
      case MyReviewFilter.postponed:
        return Icons.schedule;
    }
  }

  void _showSortDialog() {
    final state = ref.read(myReviewsProvider);
    showDialog(
      context: context,
      builder: (context) => CommonSortDialog(
        title: S.of(context).sortOptions,
        currentOption: state.sortType,
        currentDirection: state.sortOrder,
        availableOptions: const [
          SortOrder.updatedAt,
          SortOrder.release,
          SortOrder.review,
          SortOrder.dlCount,
        ],
        onSort: (option, direction) {
          ref.read(myReviewsProvider.notifier).changeSort(option, direction);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以保持状态

    final tabsSettings = ref.watch(myTabsDisplayProvider);
    final topPadding = MediaQuery.paddingOf(context).top;
    final horizontalPadding = FloatingToolbarLayout.horizontalPadding(context);
    final tabSwitcherTop = topPadding + 8;
    final contentTop = tabSwitcherTop + kTextTabBarHeight + 8;
    // Keep secondary toolbars clear of the top blur when the primary switcher hides.
    const collapsedToolbarClearance = 3.0;
    final collapsedToolbarTop =
        tabSwitcherTop + (topPadding > 0 ? collapsedToolbarClearance : 0);
    final tabs = _buildTabList(
      tabsSettings,
      contentTop: contentTop,
      collapsedToolbarTop: collapsedToolbarTop,
    );

    // 如果标签数量变化，需要重新创建 TabController
    if (_tabController.length != tabs.length) {
      final oldIndex = _tabController.index;
      _tabController.removeListener(_handleTabChanged);
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
      _tabController.addListener(_handleTabChanged);
      // 尝试恢复之前的位置，但不超出新的范围
      if (oldIndex < tabs.length) {
        _tabController.index = oldIndex;
      }
      _lastTabIndex = _tabController.index;
    }

    final systemOverlayStyle =
        transparentSystemBarsForBrightness(Theme.of(context).brightness);

    return AnnotatedRegion(
      value: systemOverlayStyle,
      child: Scaffold(
        floatingActionButton: AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            final currentIndex = _tabController.index;
            if (currentIndex >= 0 && currentIndex < tabs.length) {
              final currentTab = tabs[currentIndex];
              if (currentTab.showFab && currentTab.fabWidget != null) {
                return currentTab.fabWidget!;
              }
            }
            return const SizedBox.shrink();
          },
        ),
        body: LiquidGlassDockMediaQuery(
          child: Stack(
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: TabBarView(
                    controller: _tabController,
                    children: tabs.map((tab) => tab.widget).toList(),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ProgressiveTopBlur(height: topPadding + 12),
              ),
              Positioned(
                top: tabSwitcherTop,
                left: horizontalPadding,
                right: horizontalPadding,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _tabSwitcherVisible,
                  builder: (context, visible, child) => IgnorePointer(
                    ignoring: !visible,
                    child: AnimatedSlide(
                      key: const ValueKey('my-tab-switcher'),
                      offset: visible ? Offset.zero : const Offset(0, -2),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 140),
                        child: child,
                      ),
                    ),
                  ),
                  child: FloatingToolbarSurface(
                    child: SizedBox(
                      height: 40,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        splashBorderRadius: BorderRadius.circular(20),
                        tabs: tabs
                            .map(
                              (tab) => Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(tab.icon, size: 18),
                                    const SizedBox(width: 6),
                                    Text(tab.title),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineBookmarksTab({
    required double toolbarTop,
    required double collapsedToolbarTop,
  }) {
    final state = ref.watch(myReviewsProvider);
    final horizontalPadding = FloatingToolbarLayout.horizontalPadding(context);

    return Stack(
      children: [
        Positioned.fill(child: _buildBody(state, topPadding: toolbarTop + 56)),
        FloatingToolbarPositionFollower(
          primaryToolbarVisible: _tabSwitcherVisible,
          visibleTop: toolbarTop,
          hiddenTop: collapsedToolbarTop,
          left: horizontalPadding,
          right: horizontalPadding,
          child: FloatingFeedToolbar(
            modeActions: [
              for (final filter in MyReviewFilter.values)
                FloatingFeedModeAction(
                  icon: _getFilterIcon(filter),
                  label: filter.localizedLabel(context),
                  isSelected: state.filter == filter,
                  onPressed: () =>
                      ref.read(myReviewsProvider.notifier).changeFilter(filter),
                ),
            ],
            toolActions: [
              FloatingFeedToolAction(
                icon: _getLayoutIcon(state.layoutType),
                tooltip: _getLayoutTooltip(state.layoutType),
                onPressed: () =>
                    ref.read(myReviewsProvider.notifier).toggleLayoutType(),
              ),
              FloatingFeedToolAction(
                icon: _getSubtitleFilterIcon(state.subtitleFilter),
                tooltip: SubtitleFilterMode.fromValue(state.subtitleFilter)
                    .localizedTooltip(context),
                isSelected:
                    SubtitleFilterMode.fromValue(state.subtitleFilter).isActive,
                onPressed: () =>
                    ref.read(myReviewsProvider.notifier).toggleSubtitleFilter(),
              ),
              FloatingFeedToolAction(
                icon: Icons.sort,
                tooltip: S.of(context).sort,
                onPressed: _showSortDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(MyReviewsState state, {double topPadding = 0}) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(myReviewsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.works.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final layoutType = switch (state.layoutType) {
      MyReviewLayoutType.bigGrid => LayoutType.bigGrid,
      MyReviewLayoutType.smallGrid => LayoutType.smallGrid,
      MyReviewLayoutType.list => LayoutType.list,
    };

    return WorksGridView(
      works: state.works,
      layoutType: layoutType,
      scrollController: _scrollController,
      physics: ScrollOptimization.physics,
      isLoading: state.isLoading,
      isRefreshing: state.isLoading && state.works.isNotEmpty,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      error: state.error,
      loadMoreError: state.loadMoreError,
      onRetry: () => ref.read(myReviewsProvider.notifier).refresh(),
      onRefresh: () => ref.read(myReviewsProvider.notifier).refresh(),
      pagination: VirtualizedPagination(
        currentPage: state.currentPage,
        pageSize: state.layoutType == MyReviewLayoutType.list
            ? state.pageSize
            : state.effectivePageSize,
        totalCount: state.totalCount,
        hasMore: state.hasMore,
        isLoading: state.isLoading || state.isRefreshing,
        onPreviousPage: ref.read(myReviewsProvider.notifier).previousPage,
        onNextPage: ref.read(myReviewsProvider.notifier).nextPage,
        onGoToPage: ref.read(myReviewsProvider.notifier).goToPage,
        nextPageOnOverscroll: true,
        scrollDuration: const Duration(milliseconds: 500),
        scrollCurve: Curves.easeInOut,
        showWhenEmpty: true,
      ),
      fillEmptyViewport: false,
      padding: state.layoutType == MyReviewLayoutType.list
          ? EdgeInsets.fromLTRB(8, topPadding + 8, 8, 8)
          : MediaQuery.orientationOf(context) == Orientation.landscape
              ? EdgeInsets.fromLTRB(24, topPadding + 8, 24, 24)
              : EdgeInsets.fromLTRB(8, topPadding + 8, 8, 8),
    );
  }
}

// Helper class to organize tab information
class _TabInfo {
  final String title;
  final IconData icon;
  final int index;
  final Widget widget;
  final bool showFab;
  final Widget? fabWidget;

  const _TabInfo({
    required this.title,
    required this.icon,
    required this.index,
    required this.widget,
    this.showFab = false,
    this.fabWidget,
  });
}
