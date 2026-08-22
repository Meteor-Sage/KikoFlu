import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/playlist_detail_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_display_provider.dart';
import '../providers/work_card_display_provider.dart';
import '../models/playlist.dart';
import '../models/work.dart';
import '../services/storage_service.dart';
import '../widgets/playlist_add_works_dialog.dart';
import '../widgets/playlist_edit_dialog.dart';
import '../widgets/playlist_metadata_section.dart';
import '../widgets/scrollable_appbar.dart';
import '../utils/snackbar_util.dart';
import '../screens/work_detail_screen.dart';
import '../widgets/privacy_blur_cover.dart';
import '../widgets/enhanced_work_card.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../utils/responsive_grid_helper.dart';
import '../utils/work_cover_prefetch.dart';
import '../utils/scroll_optimization.dart';
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

    if (state.isLoading && state.metadata == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final auth = ref.watch(authProvider.select(
      (value) => (
        host: value.host ?? '',
        token: value.token ?? '',
        userName: value.currentUser?.name ?? '',
      ),
    ));
    final notifier =
        ref.read(playlistDetailProvider(widget.playlistId).notifier);
    final isOwner = state.metadata?.userName == auth.userName;
    final layoutType = ref.watch(playlistDisplayProvider);
    final isMasonry = layoutType == PlaylistLayoutType.masonry;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final spacing = isLandscape ? 24.0 : 8.0;
    final crossAxisCount = isMasonry
        ? ref.watch(workCardDisplayProvider).applyCardSize(
              ResponsiveGridHelper.getBigGridCrossAxisCount(context),
            )
        : 1;
    final contentPadding = isMasonry ? spacing : 8.0;

    return VirtualizedSliverCollection(
      controller: _scrollController,
      items: state.works,
      itemId: (work) => work.id,
      layout: isMasonry
          ? VirtualizedCollectionLayout.masonry
          : VirtualizedCollectionLayout.list,
      masonryCrossAxisCount: isMasonry ? crossAxisCount : null,
      masonryMainAxisSpacing: spacing,
      masonryCrossAxisSpacing: spacing,
      padding: EdgeInsets.all(contentPadding),
      physics: ScrollOptimization.physics,
      sliversBefore: [
        if (state.metadata != null)
          _buildMetadataSection(
            state.metadata!,
            auth.userName,
            isMasonry: isMasonry,
          ),
      ],
      isInitialLoading:
          state.isLoading && state.works.isEmpty && state.metadata == null,
      isRefreshing: false,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      error: null,
      loadMoreError: null,
      onRefresh: notifier.refresh,
      pagination: VirtualizedPagination(
        currentPage: state.currentPage,
        pageSize: state.pageSize,
        totalCount: state.totalCount,
        hasMore: state.hasMore,
        isLoading: state.isLoading || state.isRefreshing,
        onPreviousPage: notifier.previousPage,
        onNextPage: notifier.nextPage,
        onGoToPage: notifier.goToPage,
        nextPageOnOverscroll: true,
        scrollDuration: const Duration(milliseconds: 500),
        scrollCurve: Curves.easeInOut,
        padding: EdgeInsets.fromLTRB(
          contentPadding,
          contentPadding,
          contentPadding,
          24,
        ),
      ),
      onRetry: notifier.refresh,
      onPrefetch: (works) => prefetchWorkCovers(
        context,
        works,
        host: auth.host,
        token: auth.token,
        crossAxisCount: isMasonry ? crossAxisCount : 1,
        isListCard: !isMasonry,
      ),
      emptyBuilder: (context) => Center(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      itemBuilder: (context, work, index) => isMasonry
          ? _buildPlaylistWorkCardMasonry(
              work,
              isOwner,
              crossAxisCount: crossAxisCount,
            )
          : Padding(
              key: ValueKey(work.id),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: _buildPlaylistWorkCard(
                work,
                isOwner,
                auth.host,
                auth.token,
              ),
            ),
    );
  }

  Widget _buildMetadataSection(
    Playlist metadata,
    String currentUserName, {
    required bool isMasonry,
  }) {
    return SliverToBoxAdapter(
      child: PlaylistMetadataSection(
        metadata: metadata,
        isOwner: metadata.userName == currentUserName,
        isMasonry: isMasonry,
        onToggleLayout: () =>
            ref.read(playlistDisplayProvider.notifier).toggleLayout(),
        onEdit: () => _showEditDialog(metadata),
        onDelete: _showDeleteConfirmDialog,
      ),
    );
  }

  Widget _buildPlaylistWorkCardMasonry(
    Work work,
    bool isOwner, {
    required int crossAxisCount,
  }) {
    return Stack(
      key: ValueKey(work.id),
      children: [
        EnhancedWorkCard(
          work: work,
          crossAxisCount: crossAxisCount,
          isListLayout: false,
        ),
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
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                onPressed: () => _showRemoveWorkConfirmDialog(work),
                tooltip: S.of(context).removeFromPlaylist,
              ),
            ),
          ),
      ],
    );
  }

  // 扁平播放列表风格的作品卡片
  Widget _buildPlaylistWorkCard(
    Work work,
    bool isOwner,
    String host,
    String token,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final httpHeaders = StorageService.serverCookieHeaders;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkDetailScreen(work: work),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 封面图 - 使用 Hero 动画和统一的图片源
            Hero(
              tag: 'work_cover_${work.id}',
              child: PrivacyBlurCover(
                borderRadius: BorderRadius.circular(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: work.getCoverImageUrl(host, token: token),
                    httpHeaders: httpHeaders,
                    cacheKey: 'work_cover_${work.id}',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Text(
                    work.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 作品编号、社团名和用户评分
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        work.displayId,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (work.name != null && work.name!.isNotEmpty)
                        Text(
                          work.name!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (work.userRating != null && work.userRating! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                color: colorScheme.onPrimaryContainer,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${work.userRating}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 移除按钮（仅作者可见）
            if (isOwner) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: colorScheme.error,
                visualDensity: VisualDensity.compact,
                onPressed: () => _showRemoveWorkConfirmDialog(work),
                tooltip: S.of(context).removeFromPlaylist,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
