import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../providers/works_provider.dart';
import '../widgets/enhanced_work_card.dart';
import '../widgets/sort_dialog.dart';

class WorksScreen extends ConsumerStatefulWidget {
  const WorksScreen({super.key});

  @override
  ConsumerState<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends ConsumerState<WorksScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(worksProvider.notifier).loadWorks(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final worksState = ref.read(worksProvider);
      if (!worksState.isLoading && worksState.hasMore) {
        ref.read(worksProvider.notifier).loadWorks();
      }
    }
  }

  void _showSortDialog(BuildContext context) {
    final isPopularMode =
        ref.read(worksProvider).displayMode == DisplayMode.popular;

    if (isPopularMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('热门推荐模式不支持排序'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const SortDialog(),
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
        return '切换到小网格视图';
      case LayoutType.smallGrid:
        return '切换到列表视图';
      case LayoutType.list:
        return '切换到大网格视图';
    }
  }

  @override
  Widget build(BuildContext context) {
    final worksState = ref.watch(worksProvider);
    final isPopularMode = worksState.displayMode == DisplayMode.popular;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0, // 让标题区紧贴左边
        title: LayoutBuilder(
          builder: (context, constraints) {
            // 计算单列卡片的宽度
            // 屏幕宽度 - 左右padding(16*2) - 中间间距(12) 然后除以2
            final screenWidth = MediaQuery.of(context).size.width;
            final cardWidth = (screenWidth - 16 * 2 - 12) / 2;

            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  // 左侧：显示模式切换按钮组
                  SizedBox(
                    width: cardWidth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 全部作品按钮
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(8),
                              ),
                              onTap: () => ref
                                  .read(worksProvider.notifier)
                                  .setDisplayMode(DisplayMode.all),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      worksState.displayMode == DisplayMode.all
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Colors.grey.shade200,
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.grid_view,
                                      size: 18,
                                      color: worksState.displayMode ==
                                              DisplayMode.all
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '全部',
                                      style: TextStyle(
                                        color: worksState.displayMode ==
                                                DisplayMode.all
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 热门推荐按钮
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              ),
                              onTap: () => ref
                                  .read(worksProvider.notifier)
                                  .setDisplayMode(DisplayMode.popular),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: worksState.displayMode ==
                                          DisplayMode.popular
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : Colors.grey.shade200,
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 18,
                                      color: worksState.displayMode ==
                                              DisplayMode.popular
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '热门',
                                      style: TextStyle(
                                        color: worksState.displayMode ==
                                                DisplayMode.popular
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅加空白区或 Spacer，让右侧按钮与切换区隔开
                  const Spacer(),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: _getLayoutIcon(worksState.layoutType),
            onPressed: () =>
                ref.read(worksProvider.notifier).toggleLayoutType(),
            tooltip: _getLayoutTooltip(worksState.layoutType),
          ),
          IconButton(
            icon: Icon(
              worksState.subtitleFilter == 1
                  ? Icons.closed_caption
                  : Icons.closed_caption_disabled,
              color: worksState.subtitleFilter == 1
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () =>
                ref.read(worksProvider.notifier).toggleSubtitleFilter(),
            tooltip: worksState.subtitleFilter == 1 ? '显示全部作品' : '仅显示带字幕作品',
          ),
          IconButton(
            icon: Icon(
              Icons.sort,
              color: isPopularMode ? Colors.grey : null,
            ),
            onPressed: isPopularMode ? null : () => _showSortDialog(context),
            tooltip: isPopularMode ? '热门推荐不支持排序' : '排序',
          ),
        ],
      ),
      body: _buildBody(worksState),
    );
  }

  Widget _buildBody(WorksState worksState) {
    if (worksState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              worksState.error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(worksProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (worksState.works.isEmpty && worksState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (worksState.works.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无作品', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('请检查网络连接或稍后重试', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(worksProvider.notifier).refresh(),
      child: Stack(
        children: [
          _buildLayoutView(worksState),
          // 全局加载动画 - 在有数据且正在刷新时显示
          if (worksState.isLoading && worksState.works.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                child: const LinearProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayoutView(WorksState worksState) {
    switch (worksState.layoutType) {
      case LayoutType.bigGrid:
        return _buildGridView(worksState, crossAxisCount: 2);
      case LayoutType.smallGrid:
        return _buildGridView(worksState, crossAxisCount: 3);
      case LayoutType.list:
        return _buildListView(worksState);
    }
  }

  Widget _buildGridView(WorksState worksState, {required int crossAxisCount}) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childCount: worksState.works.length + (worksState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == worksState.works.length) {
                // Loading indicator at the bottom
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final work = worksState.works[index];
              return EnhancedWorkCard(
                work: work,
                crossAxisCount: crossAxisCount,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(WorksState worksState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: worksState.works.length + (worksState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == worksState.works.length) {
          // Loading indicator at the bottom
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final work = worksState.works[index];
        return EnhancedWorkCard(
          work: work,
          crossAxisCount: 1, // 列表视图
        );
      },
    );
  }
}
