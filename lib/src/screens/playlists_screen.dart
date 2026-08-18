import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/playlists_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/playlist_card.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../models/playlist.dart' show PlaylistPrivacy;
import 'playlist_detail_screen.dart';

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

  /// 显示创建播放列表对话框
  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkController = TextEditingController();
    PlaylistPrivacy selectedPrivacy = PlaylistPrivacy.private;
    bool isCreateMode = true; // true: 创建模式, false: 添加链接模式

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            isCreateMode
                                ? S.of(context).createPlaylist
                                : S.of(context).addPlaylist,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),

                    // 模式切换
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(S.of(context).create),
                            icon: const Icon(Icons.add),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(S.of(context).add),
                            icon: const Icon(Icons.link),
                          ),
                        ],
                        selected: {isCreateMode},
                        onSelectionChanged: (Set<bool> selected) {
                          setDialogState(() {
                            isCreateMode = selected.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 内容区域
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: isCreateMode
                            ? [
                                // 创建模式的输入框
                                // 名称输入
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: S.of(context).playlistName,
                                    hintText: S.of(context).enterPlaylistName,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.title),
                                  ),
                                  autofocus: true,
                                  maxLength: 50,
                                ),
                                const SizedBox(height: 16),

                                // 隐私设置
                                DropdownButtonFormField<PlaylistPrivacy>(
                                  initialValue: selectedPrivacy,
                                  decoration: InputDecoration(
                                    labelText: S.of(context).privacySetting,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    helperText: selectedPrivacy
                                        .localizedDescription(context),
                                    helperMaxLines: 2,
                                  ),
                                  items: PlaylistPrivacy.values.map((privacy) {
                                    return DropdownMenuItem<PlaylistPrivacy>(
                                      value: privacy,
                                      child:
                                          Text(privacy.localizedLabel(context)),
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
                                  decoration: InputDecoration(
                                    labelText:
                                        S.of(context).playlistDescription,
                                    hintText: S.of(context).addDescription,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.description),
                                  ),
                                  maxLines: 1,
                                  maxLength: 200,
                                ),
                                const SizedBox(height: 8),
                              ]
                            : [
                                // 添加链接模式的输入框
                                TextField(
                                  controller: linkController,
                                  decoration: InputDecoration(
                                    labelText: S.of(context).playlistLink,
                                    hintText: S.of(context).playlistLinkHint,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.link),
                                  ),
                                  autofocus: true,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 8),
                              ],
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
                            child: Text(S.of(context).cancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              if (isCreateMode) {
                                if (nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(S
                                          .of(context)
                                          .enterPlaylistNameWarning),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                              } else {
                                if (linkController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(S.of(context).enterPlaylistLink),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                              }
                              Navigator.pop(context, true);
                            },
                            child: Text(isCreateMode
                                ? S.of(context).create
                                : S.of(context).add),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // 先保存值，再释放 controller
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final link = linkController.text.trim();

    // 延迟释放 controller，等待对话框关闭动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      nameController.dispose();
      descriptionController.dispose();
      linkController.dispose();
    });

    if (result == true && mounted) {
      if (isCreateMode) {
        await _createPlaylist(
          name: name,
          privacy: selectedPrivacy,
          description: description,
        );
      } else {
        await _addPlaylistByLink(link);
      }
    }
  }

  /// 通过链接添加播放列表
  Future<void> _addPlaylistByLink(String link) async {
    try {
      // 解析链接中的 ID
      String? playlistId;

      // 支持多种链接格式（不限域名）
      final patterns = [
        RegExp(r'playlist\?id=([a-f0-9-]+)',
            caseSensitive: false), // 匹配 ?id= 参数
        RegExp(r'playlist/([a-f0-9-]+)',
            caseSensitive: false), // 匹配 /playlist/ 路径
        RegExp(r'^([a-f0-9-]+)$', caseSensitive: false), // 直接输入 ID
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(link);
        if (match != null) {
          playlistId = match.group(1);
          break;
        }
      }

      if (playlistId == null || playlistId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).unrecognizedPlaylistLink),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 显示加载提示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(S.of(context).addingPlaylist),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      final apiService = ref.read(kikoeruApiServiceProvider);
      await apiService.likePlaylist(playlistId);

      if (!mounted) return;

      // 隐藏加载提示
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).playlistAddedSuccess),
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

      // 解析错误信息
      String errorMessage = S.of(context).addFailed;
      final errorString = e.toString();

      if (errorString.contains('playlist.playlistNotFound') ||
          errorString.contains('404')) {
        errorMessage = S.of(context).playlistNotFound;
      } else if (errorString.contains('401') || errorString.contains('403')) {
        errorMessage = S.of(context).noPermissionToAccessPlaylist;
      } else if (errorString.contains('Network') ||
          errorString.contains('connect')) {
        errorMessage = S.of(context).networkConnectionFailed;
      } else {
        errorMessage = S.of(context).addFailedWithError(errorString.length > 50
            ? '${errorString.substring(0, 50)}...'
            : errorString);
      }

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
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
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(S.of(context).creatingPlaylist),
            ],
          ),
          duration: const Duration(seconds: 30),
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
          content: Text(S.of(context).playlistCreatedSuccess(name)),
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
          content: Text(S.of(context).createFailedWithError(e.toString())),
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

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: S.of(context).createPlaylist,
        child: const Icon(Icons.add),
      ),
      body: _buildListView(state),
    );
  }

  Widget _buildListView(PlaylistsState state) {
    return VirtualizedSliverCollection(
      controller: _scrollController,
      pageStorageKey: const PageStorageKey('playlists-feed'),
      items: state.playlists,
      itemId: (playlist) => playlist.id,
      isInitialLoading: state.isLoading && state.playlists.isEmpty,
      isRefreshing: state.isRefreshing,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      error: state.playlists.isEmpty ? state.error : null,
      loadMoreError: state.loadMoreError,
      onRefresh: ref.read(playlistsProvider.notifier).refresh,
      onLoadMore: ref.read(playlistsProvider.notifier).loadMore,
      onRetry: ref.read(playlistsProvider.notifier).refresh,
      emptyBuilder: (context) => Center(
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
              S.of(context).noPlaylists,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).noPlaylistsDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      sliversBefore: [
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
                  S.of(context).myPlaylists,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                const Spacer(),
                Text(
                  S.of(context).totalNItems(state.totalCount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, playlist, index) => PlaylistCard(
        key: ValueKey(playlist.id),
        playlist: playlist,
        onTap: () async {
          final deleted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(
                playlistId: playlist.id,
                playlistName: playlist.displayName,
              ),
            ),
          );
          if (deleted == true) {
            ref.read(playlistsProvider.notifier).refresh();
          }
        },
      ),
    );
  }
}
