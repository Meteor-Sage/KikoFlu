import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/playlists_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/playlist_card.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../utils/scroll_optimization.dart';
import '../models/playlist.dart' show PlaylistPrivacy;
import '../widgets/responsive_dialog.dart';
import '../widgets/settings_option_dialog.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({
    super.key,
    this.topInset = 0,
  });

  final double topInset;

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          return ResponsiveDialog(
            maxWidth: 600,
            titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            title: Row(
              children: [
                Icon(
                  isCreateMode ? Icons.playlist_add : Icons.link,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCreateMode
                        ? S.of(context).createPlaylist
                        : S.of(context).addPlaylist,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
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
                    setDialogState(() => isCreateMode = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                if (isCreateMode) ...[
                  TextField(
                    controller: nameController,
                    decoration: settingsDialogInputDecoration(
                      context,
                      labelText: S.of(context).playlistName,
                      hintText: S.of(context).enterPlaylistName,
                      prefixIcon: const Icon(Icons.title),
                    ),
                    autofocus: true,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PlaylistPrivacy>(
                    initialValue: selectedPrivacy,
                    decoration: settingsDialogInputDecoration(
                      context,
                      labelText: S.of(context).privacySetting,
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: selectedPrivacy.localizedDescription(context),
                      helperMaxLines: 2,
                    ),
                    items: PlaylistPrivacy.values.map((privacy) {
                      return DropdownMenuItem<PlaylistPrivacy>(
                        value: privacy,
                        child: Text(privacy.localizedLabel(context)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedPrivacy = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: settingsDialogInputDecoration(
                      context,
                      labelText: S.of(context).playlistDescription,
                      hintText: S.of(context).addDescription,
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 1,
                    maxLength: 200,
                  ),
                ] else
                  TextField(
                    controller: linkController,
                    decoration: settingsDialogInputDecoration(
                      context,
                      labelText: S.of(context).playlistLink,
                      hintText: S.of(context).playlistLinkHint,
                      prefixIcon: const Icon(Icons.link),
                    ),
                    autofocus: true,
                    maxLines: 3,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(S.of(context).cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (isCreateMode && nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(S.of(context).enterPlaylistNameWarning),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  if (!isCreateMode && linkController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(S.of(context).enterPlaylistLink),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text(
                  isCreateMode ? S.of(context).create : S.of(context).add,
                ),
              ),
            ],
          );
        },
      ),
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
        RegExp(
          r'playlist\?id=([a-f0-9-]+)',
          caseSensitive: false,
        ), // 匹配 ?id= 参数
        RegExp(
          r'playlist/([a-f0-9-]+)',
          caseSensitive: false,
        ), // 匹配 /playlist/ 路径
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
        errorMessage = S
            .of(context)
            .addFailedWithError(
              errorString.length > 50
                  ? '${errorString.substring(0, 50)}...'
                  : errorString,
            );
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
              onPressed: () => ref.read(playlistsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.playlists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.playlists.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePlaylistDialog,
          tooltip: S.of(context).createPlaylist,
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
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: S.of(context).createPlaylist,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(playlistsProvider.notifier).refresh,
        child: _buildListView(state),
      ),
    );
  }

  Widget _buildListView(PlaylistsState state) {
    return VirtualizedSliverCollection(
      controller: _scrollController,
      items: state.playlists,
      itemId: (playlist) => playlist.id,
      physics: ScrollOptimization.physics,
      isInitialLoading: state.isLoading && state.playlists.isEmpty,
      isRefreshing: false,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      error: null,
      loadMoreError: null,
      pagination: VirtualizedPagination(
        currentPage: state.currentPage,
        pageSize: state.pageSize,
        totalCount: state.totalCount,
        hasMore: state.hasMore,
        isLoading: state.isLoading || state.isRefreshing,
        onPreviousPage: ref.read(playlistsProvider.notifier).previousPage,
        onNextPage: ref.read(playlistsProvider.notifier).nextPage,
        onGoToPage: ref.read(playlistsProvider.notifier).goToPage,
        scrollDuration: const Duration(milliseconds: 500),
        scrollCurve: Curves.easeInOut,
      ),
      onRetry: ref.read(playlistsProvider.notifier).refresh,
      sliversBefore: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, widget.topInset + 16, 16, 8),
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
      padding: EdgeInsets.zero,
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
