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
  final TextEditingController _pageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showPagination = false;

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
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 使用防抖机制,避免频繁调用
    if (!_scrollController.hasClients) return;

    final worksState = ref.read(worksProvider);
    final isNearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;

    // 全部模式:显示/隐藏分页控件
    if (worksState.displayMode == DisplayMode.all) {
      if (isNearBottom != _showPagination) {
        setState(() {
          _showPagination = isNearBottom;
        });
      }
    }
    // 热门/推荐模式:自动加载更多
    else {
      if (isNearBottom && !worksState.isLoading && worksState.hasMore) {
        ref.read(worksProvider.notifier).loadWorks();
      }
      // 确保分页控件隐藏
      if (_showPagination) {
        setState(() {
          _showPagination = false;
        });
      }
    }
  }

  void _showSortDialog(BuildContext context) {
    final displayMode = ref.read(worksProvider).displayMode;
    final isRecommendMode = displayMode == DisplayMode.popular ||
        displayMode == DisplayMode.recommended;

    if (isRecommendMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              displayMode == DisplayMode.popular ? '热门推荐模式不支持排序' : '推荐模式不支持排序'),
          duration: const Duration(seconds: 2),
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
    final isRecommendMode = worksState.displayMode == DisplayMode.popular ||
        worksState.displayMode == DisplayMode.recommended;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              // ===== 左侧模式切换按钮组 =====
              _buildModeButtons(context, worksState),

              const Spacer(), // 👈 推动右侧按钮到最右
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: _getLayoutIcon(worksState.layoutType),
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () =>
                ref.read(worksProvider.notifier).toggleSubtitleFilter(),
            tooltip: worksState.subtitleFilter == 1 ? '显示全部作品' : '仅显示带字幕作品',
          ),
          IconButton(
            icon: Icon(
              Icons.sort,
              color: isRecommendMode ? Colors.grey : null,
            ),
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: isRecommendMode ? null : () => _showSortDialog(context),
            tooltip: isRecommendMode ? '推荐模式不支持排序' : '排序',
          ),
        ],
      ),
      body: _buildBody(worksState),
    );
  }

  /// ===== 构建「全部 / 热门 / 推荐」按钮组 =====
  Widget _buildModeButtons(BuildContext context, WorksState worksState) {
    final notifier = ref.read(worksProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeButton(
          context: context,
          icon: Icons.grid_view,
          label: '全部',
          isSelected: worksState.displayMode == DisplayMode.all,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
          onTap: () {
            notifier.setDisplayMode(DisplayMode.all);
            _scrollToTop();
          },
        ),
        _buildModeButton(
          context: context,
          icon: Icons.local_fire_department,
          label: '热门',
          isSelected: worksState.displayMode == DisplayMode.popular,
          onTap: () {
            notifier.setDisplayMode(DisplayMode.popular);
            _scrollToTop();
          },
        ),
        _buildModeButton(
          context: context,
          icon: Icons.auto_awesome,
          label: '推荐',
          isSelected: worksState.displayMode == DisplayMode.recommended,
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(6)),
          onTap: () {
            notifier.setDisplayMode(DisplayMode.recommended);
            _scrollToTop();
          },
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
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.zero,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: borderRadius ?? BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
              child: SizedBox(
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
    final isAllMode = worksState.displayMode == DisplayMode.all;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8), // 统一为8
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8, // 统一为8
            mainAxisSpacing: 8, // 统一为8
            childCount: worksState.works.length +
                (!isAllMode && worksState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 热门/推荐模式:在底部显示加载指示器
              if (!isAllMode && index == worksState.works.length) {
                return const SizedBox(
                  height: 100, // 统一加载指示器高度
                  child: Center(child: CircularProgressIndicator()),
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

        // 热门/推荐模式:到底提示
        if (!isAllMode && worksState.isLastPage)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '已经到底啦~杂库~',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 全部模式:分页控件(集成在瀑布流中)
        if (isAllMode && _showPagination)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), // 统一左右padding为8
            sliver: SliverToBoxAdapter(
              child: _buildPaginationBar(worksState),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(WorksState worksState) {
    final isAllMode = worksState.displayMode == DisplayMode.all;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // 热门/推荐模式:加载指示器
                if (!isAllMode &&
                    index == worksState.works.length &&
                    worksState.hasMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // 热门/推荐模式:到底提示
                if (!isAllMode &&
                    index == worksState.works.length &&
                    worksState.isLastPage) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '已经到底啦~杂库~',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final work = worksState.works[index];
                return EnhancedWorkCard(
                  work: work,
                  crossAxisCount: 1, // 列表视图
                );
              },
              childCount: worksState.works.length +
                  (!isAllMode && worksState.hasMore ? 1 : 0) +
                  (!isAllMode && worksState.isLastPage ? 1 : 0),
            ),
          ),
        ),

        // 全部模式:分页控件(集成在列表中)
        if (isAllMode && _showPagination)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), // 统一左右padding为8
            sliver: SliverToBoxAdapter(
              child: _buildPaginationBar(worksState),
            ),
          ),
      ],
    );
  }

  // 分页控制栏(仅全部模式使用)
  Widget _buildPaginationBar(WorksState worksState) {
    final maxPage = worksState.totalCount > 0
        ? (worksState.totalCount / worksState.pageSize).ceil()
        : 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 页码和总数信息
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '第 ${worksState.currentPage} / $maxPage 页',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '共 ${worksState.totalCount} 条',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 上一页
              _buildPageButton(
                icon: Icons.chevron_left,
                label: '上一页',
                enabled: worksState.currentPage > 1 && !worksState.isLoading,
                onPressed: () {
                  ref.read(worksProvider.notifier).previousPage();
                  _scrollToTop();
                },
              ),
              const SizedBox(width: 8),

              // 跳转输入
              _buildPageJumpButton(worksState, maxPage),
              const SizedBox(width: 8),

              // 下一页
              _buildPageButton(
                label: '下一页',
                icon: Icons.chevron_right,
                enabled: worksState.hasMore && !worksState.isLoading,
                iconOnRight: true, // 图标放在右边
                onPressed: () {
                  ref.read(worksProvider.notifier).nextPage();
                  _scrollToTop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 分页按钮
  Widget _buildPageButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    bool iconOnRight = false, // 图标是否在右边
  }) {
    final iconWidget = Icon(
      icon,
      size: 18,
      color: enabled
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
    );

    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: enabled
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
    );

    return Material(
      color: enabled
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconOnRight
                ? [textWidget, const SizedBox(width: 4), iconWidget]
                : [iconWidget, const SizedBox(width: 4), textWidget],
          ),
        ),
      ),
    );
  }

  // 页码跳转按钮
  Widget _buildPageJumpButton(WorksState worksState, int maxPage) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showPageJumpDialog(worksState, maxPage),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_location_alt,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '跳转',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示页码跳转对话框
  void _showPageJumpDialog(WorksState worksState, int maxPage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳转到指定页'),
        content: TextField(
          controller: _pageController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '页码',
            hintText: '输入 1-$maxPage',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.tag),
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop();
            _handlePageJump(value, maxPage);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePageJump(_pageController.text, maxPage);
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }

  // 处理页码跳转
  void _handlePageJump(String value, int maxPage) {
    final page = int.tryParse(value);
    if (page != null && page > 0 && page <= maxPage) {
      ref.read(worksProvider.notifier).goToPage(page);
      _pageController.clear();
      _scrollToTop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入 1-$maxPage 之间的页码'),
          duration: const Duration(seconds: 2),
        ),
      );
      _pageController.clear();
    }
  }

  // 滚动到顶部
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}
