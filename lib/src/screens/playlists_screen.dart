import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlists_provider.dart';
import '../providers/auth_provider.dart' show kikoeruApiServiceProvider;
import '../widgets/playlist_card.dart';
import '../widgets/pagination_bar.dart';
import '../models/playlist.dart' show PlaylistPrivacy;

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true; // 保持状态不被销毁

  @override
  void initState() {
    super.initState();
    // 首次加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistsState = ref.read(playlistsProvider);
      if (playlistsState.playlists.isEmpty && !playlistsState.isLoading) {
        ref.read(playlistsProvider.notifier).load(refresh: true);
      }
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

  /// 显示创建播放列表对话框
  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    PlaylistPrivacy selectedPrivacy = PlaylistPrivacy.private;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isLandscape =
            MediaQuery.of(dialogContext).orientation == Orientation.landscape;
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = isLandscape ? screenWidth * 0.6 : screenWidth * 0.9;

        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth.clamp(300.0, 600.0),
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          '创建播放列表',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),

                  // 内容区域
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 名称输入
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: '播放列表名称',
                              hintText: '请输入名称',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            autofocus: true,
                            maxLength: 50,
                          ),
                          const SizedBox(height: 16),

                          // 隐私设置
                          DropdownButtonFormField<PlaylistPrivacy>(
                            value: selectedPrivacy,
                            decoration: InputDecoration(
                              labelText: '隐私设置',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              helperText: selectedPrivacy.description,
                              helperMaxLines: 2,
                            ),
                            items: PlaylistPrivacy.values.map((privacy) {
                              return DropdownMenuItem<PlaylistPrivacy>(
                                value: privacy,
                                child: Text(privacy.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedPrivacy = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // 描述输入
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: '描述（可选）',
                              hintText: '添加一些描述信息',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 1,
                            maxLength: 200,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // 操作按钮
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('请输入播放列表名称'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          child: const Text('创建'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 先保存值，再释放 controller
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    // 延迟释放 controller，等待对话框关闭动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      nameController.dispose();
      descriptionController.dispose();
    });

    if (result == true && mounted) {
      await _createPlaylist(
        name: name,
        privacy: selectedPrivacy,
        description: description,
      );
    }
  }

  /// 创建播放列表
  Future<void> _createPlaylist({
    required String name,
    required PlaylistPrivacy privacy,
    String? description,
  }) async {
    try {
      // 显示加载提示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('正在创建播放列表...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final apiService = ref.read(kikoeruApiServiceProvider);
      await apiService.createPlaylist(
        name: name,
        privacy: privacy.value,
        description: description?.isNotEmpty == true ? description : null,
      );

      if (!mounted) return;

      // 隐藏加载提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('播放列表 "$name" 创建成功'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // 刷新列表
      ref.read(playlistsProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;

      // 隐藏加载提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建失败: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以保持状态

    final state = ref.watch(playlistsProvider);

    // 错误状态
    if (state.error != null && state.playlists.isEmpty) {
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
              '加载失败',
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
              onPressed: () => ref.read(playlistsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 加载中且无数据
    if (state.isLoading && state.playlists.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 空状态
    if (state.playlists.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePlaylistDialog,
          tooltip: '创建播放列表',
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.playlist_play,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无播放列表',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '您还没有创建或收藏任何播放列表',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: '创建播放列表',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(playlistsProvider.notifier).refresh(),
        child: _buildListView(state),
      ),
    );
  }

  Widget _buildListView(PlaylistsState state) {
    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: 500,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        // 顶部标题栏
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '我的播放列表',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                const Spacer(),
                Text(
                  '共 ${state.totalCount} 个',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),

        // 播放列表列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final playlist = state.playlists[index];
              return RepaintBoundary(
                child: PlaylistCard(
                  playlist: playlist,
                  onTap: () {
                    // TODO: 导航到播放列表详情页
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('点击了播放列表: ${playlist.displayName}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            },
            childCount: state.playlists.length,
          ),
        ),

        // 分页控件
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          sliver: SliverToBoxAdapter(
            child: PaginationBar(
              currentPage: state.currentPage,
              totalCount: state.totalCount,
              pageSize: state.pageSize,
              hasMore: state.hasMore,
              isLoading: state.isLoading,
              onPreviousPage: () {
                ref.read(playlistsProvider.notifier).previousPage();
                _scrollToTop();
              },
              onNextPage: () {
                ref.read(playlistsProvider.notifier).nextPage();
                _scrollToTop();
              },
              onGoToPage: (page) {
                ref.read(playlistsProvider.notifier).goToPage(page);
                _scrollToTop();
              },
            ),
          ),
        ),
      ],
    );
  }
}
