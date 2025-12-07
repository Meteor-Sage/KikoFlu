import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../privacy_blur_cover.dart';

/// 播放列表对话框
class PlaylistDialog extends ConsumerWidget {
  const PlaylistDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final authState = ref.watch(authProvider);
    final audioState = ref.watch(audioPlayerControllerProvider);

    // Get current queue synchronously as fallback
    final audioService = ref.read(audioPlayerServiceProvider);
    final currentQueue = audioService.queue;

    final borderRadius = BorderRadius.circular(18);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '播放列表',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (audioState.appendMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '追加模式',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    IconButton(
                      tooltip: '追加模式：${audioState.appendMode ? "开启" : "关闭"}',
                      icon: Icon(
                        Icons.playlist_add,
                        color: audioState.appendMode
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () async {
                        final notifier =
                            ref.read(audioPlayerControllerProvider.notifier);
                        final shouldShowHint = notifier.toggleAppendMode();
                        if (shouldShowHint && context.mounted) {
                          await _showAppendHintDialog(context);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Playlist
              Expanded(
                child: Builder(
                  builder: (context) {
                    final tracks = queueAsync.valueOrNull ?? currentQueue;

                    if (tracks.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('播放列表为空'),
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: tracks.length,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(audioPlayerControllerProvider.notifier)
                            .moveTrack(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isCurrentTrack =
                            currentTrack.valueOrNull?.id == track.id;

                        // Build work cover URL（优先使用本地文件）
                        String? workCoverUrl;
                        // 优先使用 track.artworkUrl（可能是本地文件 file://）
                        if (track.artworkUrl != null &&
                            track.artworkUrl!.startsWith('file://')) {
                          workCoverUrl = track.artworkUrl;
                        } else if (track.workId != null) {
                          final host = authState.host ?? '';
                          final token = authState.token ?? '';
                          if (host.isNotEmpty) {
                            var normalizedHost = host;
                            if (!normalizedHost.startsWith('http://') &&
                                !normalizedHost.startsWith('https://')) {
                              normalizedHost = 'https://$normalizedHost';
                            }
                            workCoverUrl = token.isNotEmpty
                                ? '$normalizedHost/api/cover/${track.workId}?token=$token'
                                : '$normalizedHost/api/cover/${track.workId}';
                          }
                        }

                        final resolvedCover = workCoverUrl ?? track.artworkUrl;

                        return LayoutBuilder(
                          key: ValueKey(track.id),
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 480;
                            final actionButtons = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrentTrack)
                                  Icon(
                                    Icons.music_note,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 18,
                                  ),
                                IconButton(
                                  tooltip: '移除',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20),
                                  onPressed: () {
                                    ref
                                        .read(audioPlayerControllerProvider
                                            .notifier)
                                        .removeTrackAt(index);
                                  },
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.drag_handle, size: 20),
                                  ),
                                ),
                              ],
                            );

                            return InkWell(
                              onTap: () async {
                                await ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .skipToIndex(index);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isCurrentTrack
                                      ? LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.4),
                                            Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.2),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ),
                                      child: resolvedCover != null
                                          ? PrivacyBlurCover(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: resolvedCover
                                                        .startsWith('file://')
                                                    ? Image.file(
                                                        File(resolvedCover
                                                            .replaceFirst(
                                                                'file://', '')),
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return const Icon(
                                                              Icons.music_note,
                                                              size: 24);
                                                        },
                                                      )
                                                    : CachedNetworkImage(
                                                        imageUrl: resolvedCover,
                                                        fit: BoxFit.cover,
                                                        errorWidget: (context,
                                                            url, error) {
                                                          return const Icon(
                                                              Icons.music_note,
                                                              size: 24);
                                                        },
                                                        placeholder:
                                                            (context, url) =>
                                                                const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      ),
                                              ),
                                            )
                                          : const Icon(Icons.music_note,
                                              size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  track.title,
                                                  style: TextStyle(
                                                    fontWeight: isCurrentTrack
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isCurrentTrack
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                        : null,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!isCompact)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 4),
                                                  child: actionButtons,
                                                ),
                                            ],
                                          ),
                                          if (track.artist != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                track.artist!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isCurrentTrack
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                ),
                                              ),
                                            ),
                                          if (isCompact)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: actionButtons,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示播放列表对话框
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !Platform.isIOS,
      builder: (context) => const PlaylistDialog(),
    );
  }

  Future<void> _showAppendHintDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('追加模式已开启'),
        content: const Text(
          '之后点击音频会追加到当前播放列表尾部，而不是替换整个列表。\n'
          '不会重复添加同一音轨。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
