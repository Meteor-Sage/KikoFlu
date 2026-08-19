import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_detail_provider.dart';
import '../providers/playlists_provider.dart';
import '../services/log_service.dart';
import '../utils/snackbar_util.dart';
import '../../l10n/app_localizations.dart';
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
    return showResponsiveBottomSheet<bool>(
      context: context,
      builder: (context) => AddToPlaylistDialog(
        workId: workId,
        workTitle: workTitle,
      ),
    );
  }

  @override
  ConsumerState<AddToPlaylistDialog> createState() =>
      _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends ConsumerState<AddToPlaylistDialog> {
  static final _log = LogService.instance;

  bool _isAdding = false;
  bool _isLoadingPlaylists = true;
  bool _isCheckingMembership = false;
  String? _loadError;

  /// 本地加载的全部播放列表（不依赖分页 provider）
  List<Playlist> _allPlaylists = [];

  /// 记录作品已存在于哪些播放列表（playlistId -> true）
  final Set<String> _inPlaylists = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadAllPlaylists());
  }

  /// 加载全部播放列表（遍历所有分页）
  Future<void> _loadAllPlaylists() async {
    setState(() {
      _isLoadingPlaylists = true;
      _loadError = null;
    });

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      final allPlaylists = <Playlist>[];
      int page = 1;
      const pageSize = 96; // API 最大数量
      const maxPages = 5;

      while (page <= maxPages) {
        final result = await apiService.getUserPlaylists(
          page: page,
          pageSize: pageSize,
          filterBy: 'all',
        );

        final List<dynamic> rawList = result['playlists'] as List? ?? [];
        final playlists = rawList
            .map((item) => Playlist.fromJson(item as Map<String, dynamic>))
            .toList();
        allPlaylists.addAll(playlists);

        if (playlists.length < pageSize) break;
        page++;
      }

      if (mounted) {
        setState(() {
          _allPlaylists = allPlaylists;
          _isLoadingPlaylists = false;
        });
        _checkWorkMembership();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlaylists = false;
          _loadError = e.toString();
        });
      }
    }
  }

  /// 检查作品在哪些播放列表中（遍历所有页以保证准确性）
  Future<void> _checkWorkMembership() async {
    if (_allPlaylists.isEmpty) return;

    setState(() => _isCheckingMembership = true);

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);

      // 并行检查所有播放列表
      final results = await Future.wait(
        _allPlaylists.map((playlist) async {
          try {
            return MapEntry(
              playlist.id,
              await _isWorkInPlaylist(apiService, playlist),
            );
          } catch (e) {
            _log.debug('检查播放列表成员失败: ${playlist.displayName}, $e',
                tag: 'Playlist');
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

  /// 遍历播放列表所有页检查作品是否存在
  Future<bool> _isWorkInPlaylist(dynamic apiService, Playlist playlist) async {
    int page = 1;
    const pageSize = 96; // API 最大数量
    const maxPages = 5;

    while (page <= maxPages) {
      final response = await apiService.getPlaylistWorks(
        playlistId: playlist.id,
        page: page,
        pageSize: pageSize,
      );

      final works = response['works'] as List;
      if (works.any((work) => work['id'] == widget.workId)) return true;

      if (works.length < pageSize) return false;
      page++;
    }
    return false;
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
          S.of(context).addedToPlaylist(playlist.displayName),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(
            context, S.of(context).addFailedWithError(e.toString()));
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
          S.of(context).removedFromPlaylist(playlist.displayName),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(
            context, S.of(context).removeFailedWithError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(
          title: S.of(context).addToPlaylist,
          subtitle: widget.workTitle,
          showCloseButton: isLandscape,
          trailing: [
            if (_isAdding)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        const Divider(height: 1),
        // 播放列表
        if (_isLoadingPlaylists)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  S.of(context).loadFailedWithError(_loadError!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadAllPlaylists,
                  icon: const Icon(Icons.refresh),
                  label: Text(S.of(context).retry),
                ),
              ],
            ),
          )
        else if (_allPlaylists.isEmpty)
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
                  S.of(context).noPlaylists,
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
              itemCount: _allPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = _allPlaylists[index];
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
                        S.of(context).nWorksCount(playlist.worksCount),
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
                            S.of(context).alreadyFavorited,
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
                              tooltip: S.of(context).removeFromPlaylist,
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _isAdding
                                  ? null
                                  : () => _addToPlaylist(playlist),
                              tooltip: S.of(context).addToPlaylist,
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
                child: Text(S.of(context).cancel),
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: content,
    );
  }
}
