import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/playlist_detail_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/work_card_display_provider.dart';
import '../models/playlist.dart';
import '../models/work.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/playlist_add_works_dialog.dart';
import '../widgets/playlist_edit_dialog.dart';
import '../widgets/playlist_metadata_section.dart';
import '../widgets/scrollable_appbar.dart';
import '../utils/snackbar_util.dart';
import '../widgets/overscroll_next_page_detector.dart';
import '../utils/scroll_optimization.dart';
import '../utils/responsive_grid_helper.dart';
import '../widgets/enhanced_work_card.dart';
import '../../l10n/app_localizations.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final String? playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.playlistName,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 首次加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistDetailProvider(widget.playlistId).notifier).load();
    });
  }

  @override
  void dispose() {
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

  /// 显示删除播放列表确认对话框
  Future<void> _showDeleteConfirmDialog() async {
    final state = ref.read(playlistDetailProvider(widget.playlistId));
    final playlist = state.metadata;
    if (playlist == null) return;

    final authState = ref.read(authProvider);
    final currentUserName = authState.currentUser?.name ?? '';
    final isOwner = playlist.userName == currentUserName;

    // 系统播放列表不能删除
    if (playlist.isSystemPlaylist && isOwner) {
      SnackBarUtil.showError(context, S.of(context).systemPlaylistCannotDelete);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isOwner
            ? S.of(context).deletePlaylist
            : S.of(context).unfavoritePlaylist),
        content: Text(
          isOwner
              ? S.of(context).deletePlaylistConfirm
              : S.of(context).unfavoritePlaylistConfirm(playlist.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child:
                Text(isOwner ? S.of(context).delete : S.of(context).unfavorite),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePlaylist();
    }
  }

  /// 删除播放列表
  Future<void> _deletePlaylist() async {
    final authState = ref.read(authProvider);
    final currentUserName = authState.currentUser?.name ?? '';

    try {
      // 显示加载提示
      if (!mounted) return;
      SnackBarUtil.showLoading(context, S.of(context).deleting);

      await ref
          .read(playlistDetailProvider(widget.playlistId).notifier)
          .deletePlaylist(currentUserName);

      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示成功提示并返回上一页
      SnackBarUtil.showSuccess(context, S.of(context).deleteSuccess);

      // 延迟一点返回，让用户看到成功提示
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pop(true); // 返回 true 表示已删除
    } catch (e) {
      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示错误提示
      SnackBarUtil.showError(
          context, S.of(context).deleteFailedWithError(e.toString()));
    }
  }

  /// 显示编辑对话框
  void _showEditDialog(metadata) {
    // 检查权限：只有作者才能编辑
    final authState = ref.read(authProvider);
    final currentUserName = authState.currentUser?.name ?? '';
    final isOwner = metadata.userName == currentUserName;

    if (!isOwner) {
      SnackBarUtil.showError(context, S.of(context).onlyOwnerCanEdit);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => PlaylistEditDialog(
        initialName: metadata.displayName,
        initialPrivacy: metadata.privacy,
        initialDescription: metadata.description,
        onSave: (draft) {
          _updateMetadata(
            name: draft.name,
            privacy: draft.privacy,
            description: draft.description,
          );
        },
      ),
    );
  }

  /// 显示添加作品对话框
  void _showAddWorksDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => PlaylistAddWorksDialog(
        onAddWorks: (ids) {
          _addWorks(ids);
        },
      ),
    );
  }

  /// 添加作品到播放列表
  Future<void> _addWorks(List<String> workIds) async {
    if (workIds.isEmpty) {
      SnackBarUtil.showWarning(context, S.of(context).noValidWorkIds);
      return;
    }

    try {
      // 显示加载提示
      if (!mounted) return;
      SnackBarUtil.showLoading(
          context, S.of(context).addingNWorks(workIds.length));

      await ref
          .read(playlistDetailProvider(widget.playlistId).notifier)
          .addWorks(workIds);

      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示成功提示
      SnackBarUtil.showSuccess(
          context, S.of(context).addedNWorksSuccess(workIds.length));
    } catch (e) {
      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示错误提示
      SnackBarUtil.showError(
          context, S.of(context).addFailedWithError(e.toString()));
    }
  }

  /// 显示移除作品确认对话框
  Future<void> _showRemoveWorkConfirmDialog(Work work) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).removeWork),
        content: Text(S.of(context).removeWorkConfirm(work.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(S.of(context).remove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeWork(work.id);
    }
  }

  /// 移除作品
  Future<void> _removeWork(int workId) async {
    try {
      // 乐观更新，UI会立即反应，不需要显示"正在移除"的阻塞式提示
      // 这样可以避免快速操作时SnackBar堆积导致显示延迟

      await ref
          .read(playlistDetailProvider(widget.playlistId).notifier)
          .removeWork(workId);

      if (!mounted) return;

      // 清除之前的提示，避免堆积
      SnackBarUtil.clearAll(context);

      // 显示成功提示，缩短显示时间
      SnackBarUtil.showSuccess(context, S.of(context).removeSuccess,
          duration: const Duration(seconds: 1));
    } catch (e) {
      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示错误提示
      SnackBarUtil.showError(
          context, S.of(context).removeFailedWithError(e.toString()));
    }
  }

  /// 更新播放列表元数据
  Future<void> _updateMetadata({
    required String name,
    required int privacy,
    required String description,
  }) async {
    try {
      // 显示加载提示
      if (!mounted) return;
      SnackBarUtil.showLoading(context, S.of(context).saving);

      await ref
          .read(playlistDetailProvider(widget.playlistId).notifier)
          .updateMetadata(
            name: name,
            privacy: privacy,
            description: description,
          );

      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示成功提示
      SnackBarUtil.showSuccess(context, S.of(context).saveSuccess);
    } catch (e) {
      if (!mounted) return;

      // 隐藏加载提示
      SnackBarUtil.hide(context);

      // 显示错误提示
      SnackBarUtil.showError(
          context, S.of(context).saveFailedWithError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistDetailProvider(widget.playlistId));

    return Scaffold(
      appBar: ScrollableAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(playlistDetailProvider(widget.playlistId).notifier)
                  .refresh();
            },
            tooltip: S.of(context).refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorksDialog,
        tooltip: S.of(context).addWorks,
        child: const Icon(Icons.add),
      ),
      body: ScrollNotificationObserver(
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(PlaylistDetailState state) {
    // 错误状态
    if (state.error != null && state.metadata == null) {
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
              onPressed: () => ref
                  .read(playlistDetailProvider(widget.playlistId).notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    // 加载中且无数据
    if (state.isLoading && state.metadata == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 空状态
    if (state.works.isEmpty && !state.isLoading) {
      return RefreshIndicator(
        onRefresh: () async => ref
            .read(playlistDetailProvider(widget.playlistId).notifier)
            .refresh(),
        child: CustomScrollView(
          slivers: [
            if (state.metadata != null) _buildMetadataSection(state.metadata!),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).noWorks,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).playlistNoWorksDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 与主页一致的响应式瀑布流列数（竖屏2列，横屏3-4列，可按用户设置缩放）
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = ref
        .watch(workCardDisplayProvider)
        .applyCardSize(
          ResponsiveGridHelper.getBigGridCrossAxisCount(context),
        );

    return RefreshIndicator(
      onRefresh: () async => ref
          .read(playlistDetailProvider(widget.playlistId).notifier)
          .refresh(),
      child: OverscrollNextPageDetector(
        hasNextPage: state.hasMore,
        isLoading: state.isLoading,
        onNextPage: () async {
          await ref
              .read(playlistDetailProvider(widget.playlistId).notifier)
              .nextPage();
          // 等待一帧后滚动到顶部，确保内容已加载
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToTop();
          });
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: ScrollOptimization.cacheExtent,
          physics: ScrollOptimization.physics,
          slivers: [
            // 元数据信息
            if (state.metadata != null) _buildMetadataSection(state.metadata!),

            // 作品列表 - 瀑布流（与主页一致）
            SliverPadding(
              padding: EdgeInsets.all(isLandscape ? 24 : 8),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: isLandscape ? 24 : 8,
                crossAxisSpacing: isLandscape ? 24 : 8,
                childCount: state.works.length,
                itemBuilder: (context, index) {
                  final work = state.works[index];
                  final authState = ref.watch(authProvider);
                  final currentUserName = authState.currentUser?.name ?? '';
                  final isOwner = state.metadata?.userName == currentUserName;

                  return _buildPlaylistWorkCard(
                    work,
                    isOwner,
                    crossAxisCount: crossAxisCount,
                  );
                },
              ),
            ),

            // 分页控件
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 24 : 8,
                isLandscape ? 24 : 8,
                isLandscape ? 24 : 8,
                24,
              ),
              sliver: SliverToBoxAdapter(
                child: PaginationBar(
                  currentPage: state.currentPage,
                  totalCount: state.totalCount,
                  pageSize: state.pageSize,
                  hasMore: state.hasMore,
                  isLoading: state.isLoading,
                  onPreviousPage: () {
                    ref
                        .read(
                            playlistDetailProvider(widget.playlistId).notifier)
                        .previousPage();
                    _scrollToTop();
                  },
                  onNextPage: () {
                    ref
                        .read(
                            playlistDetailProvider(widget.playlistId).notifier)
                        .nextPage();
                    _scrollToTop();
                  },
                  onGoToPage: (page) {
                    ref
                        .read(
                            playlistDetailProvider(widget.playlistId).notifier)
                        .goToPage(page);
                    _scrollToTop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(Playlist metadata) {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) {
          final authState = ref.watch(authProvider);
          final currentUserName = authState.currentUser?.name ?? '';

          return PlaylistMetadataSection(
            metadata: metadata,
            isOwner: metadata.userName == currentUserName,
            onEdit: () => _showEditDialog(metadata),
            onDelete: _showDeleteConfirmDialog,
          );
        },
      ),
    );
  }

  // 瀑布流风格的作品卡片（与主页 EnhancedWorkCard 一致，保留移除按钮）
  Widget _buildPlaylistWorkCard(
    Work work,
    bool isOwner, {
    required int crossAxisCount,
  }) {
    return Stack(
      children: [
        EnhancedWorkCard(work: work, crossAxisCount: crossAxisCount),
        // 移除按钮（仅作者可见）
        if (isOwner)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                color: Colors.white,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                onPressed: () => _showRemoveWorkConfirmDialog(work),
                tooltip: S.of(context).removeFromPlaylist,
              ),
            ),
          ),
      ],
    );
  }
}
