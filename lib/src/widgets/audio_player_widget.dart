import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lyric_provider.dart';
import 'lyric_player_screen.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  String? _lastTrackId;

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final authState = ref.watch(authProvider);
    final isMiniPlayerVisible = ref.watch(miniPlayerVisibilityProvider);

    // 启用自动歌词加载器
    ref.watch(lyricAutoLoaderProvider);

    return currentTrack.when(
      data: (track) {
        // 当播放新音轨时（并且不是因为重建导致的检查），重新显示MiniPlayer
        if (track != null && _lastTrackId != null && track.id != _lastTrackId) {
          _lastTrackId = track.id;
          // 使用addPostFrameCallback确保在build完成后再更新状态
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(miniPlayerVisibilityProvider.notifier).show();
            }
          });
        } else if (track != null && _lastTrackId == null) {
          // 首次加载或删除后，记录当前音轨但不改变可见性
          _lastTrackId = track.id;
        }

        if (track == null || !isMiniPlayerVisible)
          return const SizedBox.shrink();

        final progress = position.when(
          data: (pos) => duration.when(
            data: (dur) => dur != null && dur.inMilliseconds > 0
                ? pos.inMilliseconds / dur.inMilliseconds
                : 0.0,
            loading: () => 0.0,
            error: (_, __) => 0.0,
          ),
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

        final displayProgress = _isDragging ? _dragValue : progress;

        // Build work cover URL from host/token + track.workId
        String? workCoverUrl;
        final host = authState.host ?? '';
        final token = authState.token ?? '';
        if (track.workId != null && host.isNotEmpty) {
          var normalizedHost = host;
          if (!normalizedHost.startsWith('http://') &&
              !normalizedHost.startsWith('https://')) {
            normalizedHost = 'https://$normalizedHost';
          }
          workCoverUrl = token.isNotEmpty
              ? '$normalizedHost/api/cover/${track.workId}?token=$token'
              : '$normalizedHost/api/cover/${track.workId}';
        }

        return Dismissible(
          key: Key('miniplayer_${track.id}'),
          direction: DismissDirection.down,
          background: Container(color: Colors.transparent),
          onDismissed: (direction) {
            // Stop playback and hide the MiniPlayer
            ref.read(audioPlayerControllerProvider.notifier).stop();
            ref.read(miniPlayerVisibilityProvider.notifier).hide();
            // Reset track ID to allow re-showing when a new track is played
            _lastTrackId = null;
          },
          child: Consumer(
            builder: (context, ref, child) {
              final currentLyric = ref.watch(currentLyricTextProvider);
              final lyricState = ref.watch(lyricControllerProvider);
              final hasLyrics = lyricState.lyrics.isNotEmpty;
              final shouldShowLyric =
                  isPlaying && hasLyrics && currentLyric != null;

              return Container(
                height: shouldShowLyric ? 88 : 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Lyric display and progress bar wrapped in gesture detector
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box != null) {
                          final localPosition = details.localPosition.dx;
                          final width = box.size.width;
                          final value = (localPosition / width).clamp(0.0, 1.0);
                          setState(() {
                            _dragValue = value;
                          });
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        final dur = duration.valueOrNull;
                        if (dur != null) {
                          final seekPosition = Duration(
                            milliseconds:
                                (_dragValue * dur.inMilliseconds).round(),
                          );
                          ref
                              .read(audioPlayerControllerProvider.notifier)
                              .seek(seekPosition);
                        }
                        setState(() {
                          _isDragging = false;
                        });
                      },
                      onTapUp: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box != null) {
                          final localPosition = details.localPosition.dx;
                          final width = box.size.width;
                          final value = (localPosition / width).clamp(0.0, 1.0);
                          final dur = duration.valueOrNull;
                          if (dur != null) {
                            final seekPosition = Duration(
                              milliseconds:
                                  (value * dur.inMilliseconds).round(),
                            );
                            ref
                                .read(audioPlayerControllerProvider.notifier)
                                .seek(seekPosition);
                          }
                        }
                      },
                      child: Column(
                        children: [
                          // Lyric display (only show when playing and has lyrics)
                          Consumer(
                            builder: (context, ref, child) {
                              final currentLyric =
                                  ref.watch(currentLyricTextProvider);
                              final lyricState =
                                  ref.watch(lyricControllerProvider);
                              final hasLyrics = lyricState.lyrics.isNotEmpty;

                              // Only show when playing and has lyrics
                              if (!isPlaying ||
                                  !hasLyrics ||
                                  currentLyric == null) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                child: Text(
                                  currentLyric,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 11,
                                        height: 1.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                          // Draggable Progress bar
                          SizedBox(
                            height: 4,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 0,
                                  disabledThumbRadius: 0,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                                activeTrackColor:
                                    Theme.of(context).colorScheme.primary,
                                inactiveTrackColor: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                              ),
                              child: Slider(
                                value: displayProgress.clamp(0.0, 1.0),
                                onChanged: (value) {
                                  setState(() {
                                    _isDragging = true;
                                    _dragValue = value;
                                  });
                                },
                                onChangeEnd: (value) {
                                  final dur = duration.valueOrNull;
                                  if (dur != null) {
                                    final seekPosition = Duration(
                                      milliseconds:
                                          (value * dur.inMilliseconds).round(),
                                    );
                                    ref
                                        .read(audioPlayerControllerProvider
                                            .notifier)
                                        .seek(seekPosition);
                                  }
                                  setState(() {
                                    _isDragging = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Player controls
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // Left tap area: artwork + info opens full player
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AudioPlayerScreen()),
                                  );
                                },
                                child: Row(
                                  children: [
                                    // Album art (use work cover)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                      ),
                                      child:
                                          (workCoverUrl ?? track.artworkUrl) !=
                                                  null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    (workCoverUrl ??
                                                        track.artworkUrl)!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return const Icon(
                                                          Icons.music_note);
                                                    },
                                                  ),
                                                )
                                              : const Icon(Icons.music_note),
                                    ),
                                    const SizedBox(width: 12),
                                    // Track info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            track.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (track.artist != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              track.artist!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Controls (do not trigger navigation)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(audioPlayerControllerProvider
                                              .notifier)
                                          .skipToPrevious();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll('Exception: ', '')),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.skip_previous),
                                  iconSize: 24,
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (isPlaying) {
                                      ref
                                          .read(audioPlayerControllerProvider
                                              .notifier)
                                          .pause();
                                    } else {
                                      ref
                                          .read(audioPlayerControllerProvider
                                              .notifier)
                                          .play();
                                    }
                                  },
                                  icon: Icon(isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  iconSize: 28,
                                ),
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(audioPlayerControllerProvider
                                              .notifier)
                                          .skipToNext();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll('Exception: ', '')),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.skip_next),
                                  iconSize: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class AudioPlayerScreen extends ConsumerStatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  bool _isSeekingManually = false;
  double _seekValue = 0.0;
  bool _showLyricHint = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowLyricHint();
  }

  Future<void> _checkAndShowLyricHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('lyric_hint_has_shown') ?? false;

    // 如果从未显示过提示
    if (!hasShown) {
      setState(() {
        _showLyricHint = true;
      });

      // 标记为已显示
      await prefs.setBool('lyric_hint_has_shown', true);

      // 8秒后隐藏提示
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _showLyricHint = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final audioState = ref.watch(audioPlayerControllerProvider);
    final authState = ref.watch(authProvider);

    // 启用自动歌词加载器
    ref.watch(lyricAutoLoaderProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          currentTrack.when(
            data: (track) {
              if (track == null) {
                return const Center(
                  child: Text('没有正在播放的音频'),
                );
              }

              // Build work cover URL from host/token + track.workId
              String? workCoverUrl;
              final host = authState.host ?? '';
              final token = authState.token ?? '';
              if (track.workId != null && host.isNotEmpty) {
                var normalizedHost = host;
                if (!normalizedHost.startsWith('http://') &&
                    !normalizedHost.startsWith('https://')) {
                  normalizedHost = 'https://$normalizedHost';
                }
                workCoverUrl = token.isNotEmpty
                    ? '$normalizedHost/api/cover/${track.workId}?token=$token'
                    : '$normalizedHost/api/cover/${track.workId}';
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Album art (clickable to open lyrics if available)
                    Expanded(
                      flex: 3,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final lyricState = ref.watch(lyricControllerProvider);
                          final hasLyrics = lyricState.lyrics.isNotEmpty;

                          return GestureDetector(
                            onTap: hasLyrics
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LyricPlayerScreen(),
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: (workCoverUrl ?? track.artworkUrl) != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        (workCoverUrl ?? track.artworkUrl)!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.music_note,
                                            size: 120,
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Icon(
                                            Icons.music_note,
                                            size: 120,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.music_note,
                                      size: 120,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Track info (clickable to open lyrics if available)
                    Consumer(
                      builder: (context, ref, child) {
                        final lyricState = ref.watch(lyricControllerProvider);
                        final hasLyrics = lyricState.lyrics.isNotEmpty;

                        return GestureDetector(
                          onTap: hasLyrics
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LyricPlayerScreen(),
                                    ),
                                  );
                                }
                              : null,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (track.artist != null)
                                  Text(
                                    track.artist!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                // 歌词显示区域（如果有歌词则显示歌词，否则显示专辑名）
                                _LyricDisplay(albumName: track.album),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    // Progress slider
                    Column(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final pos = position.value ?? Duration.zero;
                            final dur = duration.value ?? Duration.zero;

                            return Slider(
                              value: (_isSeekingManually
                                      ? _seekValue
                                      : dur.inMilliseconds > 0
                                          ? pos.inMilliseconds /
                                              dur.inMilliseconds
                                          : 0.0)
                                  .clamp(0.0, 1.0),
                              onChanged: (value) {
                                setState(() {
                                  _isSeekingManually = true;
                                  _seekValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                final newPosition = Duration(
                                  milliseconds:
                                      (value * dur.inMilliseconds).round(),
                                );
                                ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .seek(newPosition);
                                setState(() {
                                  _isSeekingManually = false;
                                });
                              },
                            );
                          },
                        ),
                        // Time labels
                        Consumer(
                          builder: (context, ref, child) {
                            final pos = position.value ?? Duration.zero;
                            final dur = duration.value ?? Duration.zero;

                            // Show seek position when seeking manually
                            final displayPos = _isSeekingManually
                                ? Duration(
                                    milliseconds:
                                        (_seekValue * dur.inMilliseconds)
                                            .round())
                                : pos;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(displayPos),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    _formatDuration(dur),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Main controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(audioPlayerControllerProvider.notifier)
                                .skipToPrevious();
                          },
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 48,
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: IconButton(
                            onPressed: () {
                              if (isPlaying) {
                                ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .pause();
                              } else {
                                ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .play();
                              }
                            },
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            iconSize: 36,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(audioPlayerControllerProvider.notifier)
                                .skipToNext();
                          },
                          icon: const Icon(Icons.skip_next),
                          iconSize: 48,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Additional controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Repeat mode button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                final nextMode =
                                    switch (audioState.repeatMode) {
                                  LoopMode.off => LoopMode.one,
                                  LoopMode.one => LoopMode.all,
                                  LoopMode.all => LoopMode.off,
                                };
                                ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .setRepeatMode(nextMode);
                              },
                              icon: Icon(
                                switch (audioState.repeatMode) {
                                  LoopMode.off => Icons.repeat,
                                  LoopMode.one => Icons.repeat_one,
                                  LoopMode.all => Icons.repeat_on,
                                },
                                color: audioState.repeatMode != LoopMode.off
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            const SizedBox(
                                height: 14), // Placeholder for alignment
                          ],
                        ),
                        // Speed button with current speed display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                _showSpeedDialog(
                                    context, ref, audioState.speed);
                              },
                              icon: const Icon(Icons.speed),
                              padding: EdgeInsets.zero,
                            ),
                            SizedBox(height: audioState.speed == 1.0 ? 14 : 2),
                            if (audioState.speed != 1.0)
                              Text(
                                '${audioState.speed.toStringAsFixed(1)}x',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        // Seek backward 10s button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .seekBackward(const Duration(seconds: 10));
                              },
                              icon: const Icon(Icons.replay_10),
                            ),
                            const SizedBox(
                                height: 14), // Placeholder for alignment
                          ],
                        ),
                        // Seek forward 10s button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                ref
                                    .read(
                                        audioPlayerControllerProvider.notifier)
                                    .seekForward(const Duration(seconds: 10));
                              },
                              icon: const Icon(Icons.forward_10),
                            ),
                            const SizedBox(
                                height: 14), // Placeholder for alignment
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('错误: $error'),
            ),
          ),
          // 歌词提示横幅
          if (_showLyricHint)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  final lyricState = ref.watch(lyricControllerProvider);
                  // 只在有歌词时显示提示
                  if (lyricState.lyrics.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '点击封面或标题可以进入歌词界面',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showLyricHint = false;
                              });
                            },
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  void _showSpeedDialog(
      BuildContext context, WidgetRef ref, double currentSpeed) {
    // Use a local state variable to track the speed during dragging
    double localSpeed = currentSpeed;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('播放速度'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: localSpeed,
                  min: 0.25,
                  max: 2.5,
                  divisions: 9,
                  label: '${localSpeed.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    setState(() {
                      localSpeed = value;
                    });
                    ref
                        .read(audioPlayerControllerProvider.notifier)
                        .setSpeed(value);
                  },
                ),
                Text('${localSpeed.toStringAsFixed(1)}x'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// 歌词显示组件
class _LyricDisplay extends ConsumerWidget {
  final String? albumName;

  const _LyricDisplay({this.albumName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLyric = ref.watch(currentLyricTextProvider);
    final lyricState = ref.watch(lyricControllerProvider);

    // 如果有歌词，显示歌词
    if (lyricState.lyrics.isNotEmpty) {
      return Container(
        constraints: const BoxConstraints(
          minHeight: 23,
          maxHeight: 70,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              currentLyric ?? '♪',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    fontSize: 14,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // 没有歌词时显示专辑名
    if (albumName != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Text(
          albumName!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
