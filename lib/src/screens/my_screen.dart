import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_reviews_provider.dart';
import '../providers/my_tabs_display_provider.dart';
import '../providers/works_provider.dart' show LayoutType;
import '../providers/auth_provider.dart';
import '../utils/server_utils.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/works_grid_view.dart';
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

  @override
  bool get wantKeepAlive => true; // 保持状态不被销毁

  List<_TabInfo> _buildTabList(MyTabsDisplaySettings settings) {
    final tabs = <_TabInfo>[];
    final authState = ref.watch(authProvider);
    final isOfficialServer = ServerUtils.isOfficialServer(authState.host);

    if (settings.showOnlineMarks) {
      tabs.add(_TabInfo(
        title: S.of(context).onlineMarks,
        index: 0,
        widget: _buildOnlineBookmarksTab(),
        showFab: true,
        fabWidget: const DownloadFab(),
      ));
    }

    // 历史记录
    tabs.add(_TabInfo(
      title: S.of(context).historyRecord,
      index: tabs.length,
      widget: const HistoryScreen(),
    ));

    if (settings.showPlaylists && isOfficialServer) {
      tabs.add(_TabInfo(
        title: S.of(context).playlists,
        index: 1,
        widget: const PlaylistsScreen(),
      ));
    }

    // 已下载始终显示
    tabs.add(_TabInfo(
      title: S.of(context).downloaded,
      index: 2,
      widget: const LocalDownloadsScreen(),
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
        index: 3,
        widget: const SubtitleLibraryScreen(),
      ));
    }

    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // 只在首次加载时获取数据，如果已有数据则不重新加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myState = ref.read(myReviewsProvider);
      if (myState.works.isEmpty) {
        ref.read(myReviewsProvider.notifier).load(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToDownloads() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DownloadsScreen(),
      ),
    );
  }

  Icon _getLayoutIcon(MyReviewLayoutType layoutType) {
    switch (layoutType) {
      case MyReviewLayoutType.bigGrid:
        return const Icon(Icons.grid_3x3);
      case MyReviewLayoutType.smallGrid:
        return const Icon(Icons.view_list);
      case MyReviewLayoutType.list:
        return const Icon(Icons.view_agenda);
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

  Icon _getSubtitleFilterIcon(int subtitleFilter) {
    final mode = SubtitleFilterMode.fromValue(subtitleFilter);
    return Icon(
      mode == SubtitleFilterMode.withSubtitles
          ? Icons.closed_caption
          : Icons.closed_caption_disabled,
      color: mode.isActive ? Theme.of(context).colorScheme.primary : null,
    );
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

  Widget _buildFilterButton({
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
          onTap: onTap,
          borderRadius: buttonBorderRadius,
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
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          _scrollToTop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以保持状态

    final tabsSettings = ref.watch(myTabsDisplayProvider);
    final tabs = _buildTabList(tabsSettings);

    // 如果标签数量变化，需要重新创建 TabController
    if (_tabController.length != tabs.length) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
      // 尝试恢复之前的位置，但不超出新的范围
      if (oldIndex < tabs.length) {
        _tabController.index = oldIndex;
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: tabs.map((tab) => Tab(text: tab.title)).toList(),
        ),
      ),
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
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((tab) => tab.widget).toList(),
      ),
    );
  }

  Widget _buildOnlineBookmarksTab() {
    final state = ref.watch(myReviewsProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? 24.0 : 8.0;

    return Column(
      children: [
        // 筛选和布局切换工具栏
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          child: Row(
            children: [
              // 可滚动的筛选按钮
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 4),
                  child: Row(
                    children: [
                      for (int i = 0; i < MyReviewFilter.values.length; i++)
                        _buildFilterButton(
                          icon: _getFilterIcon(MyReviewFilter.values[i]),
                          label:
                              MyReviewFilter.values[i].localizedLabel(context),
                          isSelected: state.filter == MyReviewFilter.values[i],
                          onTap: () {
                            ref
                                .read(myReviewsProvider.notifier)
                                .changeFilter(MyReviewFilter.values[i]);
                            _scrollToTop();
                          },
                          index: i,
                          total: MyReviewFilter.values.length,
                        ),
                    ],
                  ),
                ),
              ),
              // 布局切换按钮
              Padding(
                padding: EdgeInsets.only(right: horizontalPadding - 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sort),
                      iconSize: 22,
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: _showSortDialog,
                      tooltip: S.of(context).sort,
                    ),
                    IconButton(
                      icon: _getSubtitleFilterIcon(state.subtitleFilter),
                      iconSize: 22,
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () {
                        ref
                            .read(myReviewsProvider.notifier)
                            .toggleSubtitleFilter();
                        _scrollToTop();
                      },
                      tooltip: SubtitleFilterMode.fromValue(
                        state.subtitleFilter,
                      ).localizedTooltip(context),
                    ),
                    IconButton(
                      icon: _getLayoutIcon(state.layoutType),
                      iconSize: 22,
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => ref
                          .read(myReviewsProvider.notifier)
                          .toggleLayoutType(),
                      tooltip: _getLayoutTooltip(state.layoutType),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: _buildBody(state),
        ),
      ],
    );
  }

  Widget _buildBody(MyReviewsState state) {
    final layoutType = switch (state.layoutType) {
      MyReviewLayoutType.bigGrid => LayoutType.bigGrid,
      MyReviewLayoutType.smallGrid => LayoutType.smallGrid,
      MyReviewLayoutType.list => LayoutType.list,
    };

    return WorksGridView(
      works: state.works,
      layoutType: layoutType,
      scrollController: _scrollController,
      pageStorageKey: PageStorageKey(
        'my-reviews-${state.filter.name}-${state.layoutType.name}',
      ),
      isLoading: state.isLoading,
      isRefreshing: state.isRefreshing,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      error: state.error,
      loadMoreError: state.loadMoreError,
      onRetry: () => ref.read(myReviewsProvider.notifier).refresh(),
      onRefresh: () => ref.read(myReviewsProvider.notifier).refresh(),
      onLoadMore: () => ref.read(myReviewsProvider.notifier).loadMore(),
      showEndMessage: state.works.isNotEmpty,
      emptyBuilder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noWorks,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to organize tab information
class _TabInfo {
  final String title;
  final int index;
  final Widget widget;
  final bool showFab;
  final Widget? fabWidget;

  const _TabInfo({
    required this.title,
    required this.index,
    required this.widget,
    this.showFab = false,
    this.fabWidget,
  });
}
