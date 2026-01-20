import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_detail_provider.dart';
import '../providers/playlists_provider.dart';
import '../utils/snackbar_util.dart';
import 'responsive_dialog.dart';

/// 添加作品到播放列表的对话框
class AddToPlaylistDialog extends ConsumerStatefulWidget {
  final int workId;
  final String workTitle;

  const AddToPlaylistDialog({
    super.key,
    required this.workId,
    required this.workTitle,
  });

  static Future<bool?> show({
    required BuildContext context,
    required int workId,
    required String workTitle,
  }) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return showDialog<bool>(
        context: context,
        builder: (context) => AddToPlaylistDialog(
          workId: workId,
          workTitle: workTitle,
        ),
      );
    } else {
      return showResponsiveBottomSheet<bool>(
        context: context,
        builder: (context) => AddToPlaylistDialog(
          workId: workId,
          workTitle: workTitle,
        ),
      );
    }
  }

  @override
  ConsumerState<AddToPlaylistDialog> createState() =>
      _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends ConsumerState<AddToPlaylistDialog> {
  bool _isAdding = false;
  bool _isCheckingMembership = false;

  /// 记录作品已存在于哪些播放列表（playlistId -> true）
  final Set<String> _inPlaylists = {};

  @override
  void initState() {
    super.initState();
    // 加载播放列表
    Future.microtask(() async {
      await ref.read(playlistsProvider.notifier).load(refresh: true);
      // 加载完播放列表后，检查作品在哪些播放列表中
      _checkWorkMembership();
    });
  }

  /// 检查作品在哪些播放列表中
  Future<void> _checkWorkMembership() async {
    final playlists = ref.read(playlistsProvider).playlists;
    if (playlists.isEmpty) return;

    setState(() => _isCheckingMembership = true);

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);

      // 并行检查所有播放列表
      final results = await Future.wait(
        playlists.map((playlist) async {
          try {
            // 加载播放列表的所有作品来检查
            // 为了效率，只加载第一页，通常用户不会有太多播放列表
            final response = await apiService.getPlaylistWorks(
              playlistId: playlist.id,
              page: 1,
              pageSize: 100, // 加载较多以提高准确性
            );

            final works = response['works'] as List;
            final containsWork =
                works.any((work) => work['id'] == widget.workId);

            return MapEntry(playlist.id, containsWork);
          } catch (e) {
            return MapEntry(playlist.id, false);
          }
        }),
      );

      if (mounted) {
        setState(() {
          _inPlaylists.clear();
          for (final entry in results) {
            if (entry.value) {
              _inPlaylists.add(entry.key);
            }
          }
          _isCheckingMembership = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingMembership = false);
      }
    }
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      await apiService.addWorksToPlaylist(
        playlistId: playlist.id,
        works: ['RJ${widget.workId}'],
      );

      if (mounted) {
        // 刷新播放列表详情（如果正在查看该播放列表）
        ref.invalidate(playlistDetailProvider(playlist.id));

        // 刷新播放列表列表（更新作品数量等信息）
        ref.read(playlistsProvider.notifier).refresh();

        // 更新本地状态
        setState(() {
          _inPlaylists.add(playlist.id);
        });

        SnackBarUtil.showSuccess(
          context,
          '已添加到播放列表「${playlist.displayName}」',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '添加失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  /// 从播放列表中移除作品
  Future<void> _removeFromPlaylist(Playlist playlist) async {
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      await apiService.removeWorksFromPlaylist(
        playlistId: playlist.id,
        works: [widget.workId],
      );

      if (mounted) {
        // 刷新播放列表详情
        ref.invalidate(playlistDetailProvider(playlist.id));

        // 刷新播放列表列表
        ref.read(playlistsProvider.notifier).refresh();

        // 更新本地状态
        setState(() {
          _inPlaylists.remove(playlist.id);
        });

        SnackBarUtil.showSuccess(
          context,
          '已从播放列表「${playlist.displayName}」中移除',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '移除失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistsState = ref.watch(playlistsProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题栏
        Padding(
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 24 : 16,
            isLandscape ? 20 : 16,
            isLandscape ? 16 : 8,
            isLandscape ? 16 : 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '添加到播放列表',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.workTitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isAdding)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (isLandscape)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 播放列表
        if (playlistsState.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (playlistsState.error != null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  '加载失败: ${playlistsState.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(playlistsProvider.notifier).load(refresh: true);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          )
        else if (playlistsState.playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.playlist_add,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无播放列表',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlistsState.playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlistsState.playlists[index];
                final isInPlaylist = _inPlaylists.contains(playlist.id);

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: isInPlaylist
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Icon(
                          playlist.privacy == PlaylistPrivacy.private.value
                              ? Icons.lock
                              : playlist.privacy ==
                                      PlaylistPrivacy.unlisted.value
                                  ? Icons.link
                                  : Icons.public,
                          color: isInPlaylist
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      if (isInPlaylist)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 10,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    playlist.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '${playlist.worksCount} 个作品',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (isInPlaylist) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '已收藏',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: _isCheckingMembership
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : isInPlaylist
                          ? IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: _isAdding
                                  ? null
                                  : () => _removeFromPlaylist(playlist),
                              tooltip: '从播放列表移除',
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _isAdding
                                  ? null
                                  : () => _addToPlaylist(playlist),
                              tooltip: '添加到播放列表',
                            ),
                  enabled: !_isAdding,
                  onTap: _isAdding
                      ? null
                      : isInPlaylist
                          ? () => _removeFromPlaylist(playlist)
                          : () => _addToPlaylist(playlist),
                );
              },
            ),
          ),
        // 底部按钮（竖屏模式）
        if (!isLandscape) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ),
          ),
        ],
      ],
    );

    if (isLandscape) {
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: content,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: content,
      );
    }
  }
}
