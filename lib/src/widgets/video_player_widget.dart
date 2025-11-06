import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart' as vp;

import '../providers/video_provider.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final currentVideo = ref.watch(currentVideoProvider);
    final isPlaying = ref.watch(isVideoPlayingProvider);
    final playerValue = ref.watch(videoPlayerValueProvider);
    final videoState = ref.watch(videoPlayerControllerProvider);
    final service = ref.watch(videoPlayerServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: videoState.isFullscreen
          ? null
          : AppBar(
              title: const Text('视频播放'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: currentVideo.when(
        data: (video) {
          if (video == null) {
            return const Center(
              child: Text(
                '没有正在播放的视频',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return playerValue.when(
            data: (value) {
              if (!value.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return Stack(
                children: [
                  // Video player
                  Center(
                    child: AspectRatio(
                      aspectRatio: value.aspectRatio,
                      child: vp.VideoPlayer(service.controller!),
                    ),
                  ),
                  // Controls overlay
                  if (videoState.controlsVisible)
                    VideoControlsOverlay(
                      video: video,
                      playerValue: value,
                      isPlaying: isPlaying,
                      onPlayPause: () {
                        if (isPlaying) {
                          ref
                              .read(videoPlayerControllerProvider.notifier)
                              .pause();
                        } else {
                          ref
                              .read(videoPlayerControllerProvider.notifier)
                              .play();
                        }
                      },
                      onSeek: (position) {
                        ref
                            .read(videoPlayerControllerProvider.notifier)
                            .seek(position);
                      },
                      onFullscreen: () {
                        ref
                            .read(videoPlayerControllerProvider.notifier)
                            .toggleFullscreen();
                        if (videoState.isFullscreen) {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);
                          SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.edgeToEdge);
                        } else {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                          SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.immersive);
                        }
                      },
                    ),
                  // Tap to toggle controls
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(videoPlayerControllerProvider.notifier)
                          .setControlsVisible(!videoState.controlsVisible);
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => Center(
              child: Text(
                '视频加载失败: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stack) => Center(
          child: Text(
            '错误: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class VideoControlsOverlay extends StatelessWidget {
  final dynamic video; // VideoTrack
  final vp.VideoPlayerValue playerValue;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final VoidCallback onFullscreen;

  const VideoControlsOverlay({
    super.key,
    required this.video,
    required this.playerValue,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onFullscreen,
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Center play button
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                Row(
                  children: [
                    Text(
                      _formatDuration(playerValue.position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: playerValue.duration.inMilliseconds > 0
                            ? playerValue.position.inMilliseconds /
                                playerValue.duration.inMilliseconds
                            : 0.0,
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds:
                                (value * playerValue.duration.inMilliseconds)
                                    .round(),
                          );
                          onSeek(newPosition);
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Text(
                      _formatDuration(playerValue.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Previous video logic would go here
                      },
                      icon:
                          const Icon(Icons.skip_previous, color: Colors.white),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: onPlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Next video logic would go here
                      },
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                  ],
                ),
              ],
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
}

class VideoThumbnailWidget extends StatelessWidget {
  final dynamic video; // VideoTrack
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          children: [
            // Thumbnail
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: video.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.video_library,
                            size: 48,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.video_library,
                      size: 48,
                    ),
            ),
            // Play overlay
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            // Duration
            if (video.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(video.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
}
