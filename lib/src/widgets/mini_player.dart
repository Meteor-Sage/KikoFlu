import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import '../models/audio_track.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lyric_provider.dart';
import '../providers/player_lyric_style_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/audio_player_screen.dart';
import '../utils/local_file_url.dart';
import 'privacy_blur_cover.dart';
import 'volume_control.dart';
import 'liquid_glass_layout.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  final bool enableArtworkHero;

  const MiniPlayer({super.key, this.enableArtworkHero = true});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  String? _lastTrackId;
  bool _isAdjustingVolume = false;
  double _tempVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isTrackLoading =
        ref.watch(isTrackLoadingProvider).valueOrNull ?? false;
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final authState = ref.watch(authProvider);
    final isMiniPlayerVisible = ref.watch(miniPlayerVisibilityProvider);
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    final fallbackGlassTransparency =
        ref.watch(fallbackGlassTransparencyProvider);

    // 启用自动字幕加载器
    ref.watch(lyricAutoLoaderProvider);

    final player = currentTrack.when(
      data: (track) {
        // A newly loaded track always re-opens a Mini Player that the user
        // previously dismissed. Dismissal clears the queue asynchronously, so
        // keeping the old id until the null event also avoids a re-show race.
        if (track == null) {
          _lastTrackId = null;
        } else if (_lastTrackId != track.id) {
          _lastTrackId = track.id;
          if (!isMiniPlayerVisible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(miniPlayerVisibilityProvider.notifier).show();
              }
            });
          }
        }

        if (track == null || !isMiniPlayerVisible) {
          return const SizedBox.shrink();
        }

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

        // Build work cover URL（优先使用本地文件）
        String? workCoverUrl;
        // 优先使用 track.artworkUrl（可能是本地文件 file://）
        if (LocalFileUrl.isLocalFileUrl(track.artworkUrl)) {
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

        return Dismissible(
          key: Key('miniplayer_${track.id}'),
          direction: DismissDirection.down,
          background: Container(color: Colors.transparent),
          onDismissed: (direction) {
            unawaited(
              ref
                  .read(audioPlayerControllerProvider.notifier)
                  .dismissMiniPlayer(),
            );
          },
          child: Consumer(
            builder: (context, ref, child) {
              final currentLyric = ref.watch(currentLyricTextProvider);
              final lyricState = ref.watch(lyricControllerProvider);
              final hasLyrics = lyricState.lyrics.isNotEmpty;
              final shouldShowLyric =
                  isPlaying && hasLyrics && currentLyric != null;

              final playerContent = Container(
                height: shouldShowLyric ? 88 : 72,
                decoration: BoxDecoration(
                  color: useLiquidGlass
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.surface,
                  border: useLiquidGlass
                      ? null
                      : Border(
                          top: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
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
                              .seekAndPersist(seekPosition);
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
                                .seekAndPersist(seekPosition);
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
                              final lyricSettings =
                                  ref.watch(playerLyricSettingsProvider);
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
                                        fontSize: lyricSettings.miniFontSize,
                                        height: lyricSettings.miniLineHeight,
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
                                    .withValues(alpha: 0.2),
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
                                        .seekAndPersist(seekPosition);
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
                                    _PlayerPageRoute(
                                      builder: (context) =>
                                          const AudioPlayerScreen(),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    // Album art (use work cover) with optional Hero animation
                                    _buildArtwork(
                                      context,
                                      track,
                                      workCoverUrl: workCoverUrl,
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
                                      if (!context.mounted) return;
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
                                if (isTrackLoading)
                                  const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Padding(
                                      padding: EdgeInsets.all(2),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5),
                                    ),
                                  )
                                else
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
                                      if (!context.mounted) return;
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
                                // Volume control (desktop platforms only)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final audioState = ref
                                        .watch(audioPlayerControllerProvider);
                                    // 使用临时音量值避免拖动时重建
                                    final displayVolume = _isAdjustingVolume
                                        ? _tempVolume
                                        : audioState.volume;
                                    return VolumeControl(
                                      volume: displayVolume,
                                      onVolumeChanged: (value) {
                                        setState(() {
                                          _isAdjustingVolume = true;
                                          _tempVolume = value;
                                        });
                                        ref
                                            .read(audioPlayerControllerProvider
                                                .notifier)
                                            .setVolume(value);
                                      },
                                      onVolumeChangeEnd: () {
                                        setState(() {
                                          _isAdjustingVolume = false;
                                        });
                                      },
                                      iconSize: 24,
                                    );
                                  },
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

              if (!useLiquidGlass) return playerContent;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LiquidGlassLayout.horizontalPadding,
                  vertical: LiquidGlassLayout.verticalPadding,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: LiquidGlassContainer(
                    shape: const LiquidGlassShape.roundedRectangle(
                      LiquidGlassLayout.cornerRadius,
                    ),
                    style: LiquidGlassStyle.regular,
                    fallbackIntensity: fallbackGlassTransparency,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        LiquidGlassLayout.cornerRadius,
                      ),
                      child: playerContent,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );

    if (!useLiquidGlass) return player;
    return LiquidGlassRouteTransitionFallback(child: player);
  }

  Widget _buildArtwork(
    BuildContext context,
    AudioTrack track, {
    String? workCoverUrl,
  }) {
    final image = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: (workCoverUrl ?? track.artworkUrl) != null
          ? PrivacyBlurCover(
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LocalFileUrl.isLocalFileUrl(
                        workCoverUrl ?? track.artworkUrl)
                    ? Image.file(
                        File(LocalFileUrl.pathFromUrl(
                            workCoverUrl ?? track.artworkUrl)!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.album, size: 32);
                        },
                      )
                    : CachedNetworkImage(
                        imageUrl: (workCoverUrl ?? track.artworkUrl)!,
                        cacheKey: track.workId != null
                            ? 'work_cover_${track.workId}'
                            : null,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.album, size: 32),
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            )
          : const Icon(
              Icons.album,
              size: 32,
            ),
    );

    if (!widget.enableArtworkHero) {
      return image;
    }

    return Hero(
      tag: 'audio_player_artwork_${track.id}',
      child: image,
    );
  }
}

/// Custom page route for the audio player that supports iOS swipe-back gesture
/// while keeping the custom Hero-friendly transition animation.
///
/// - Forward (enter): scale + fade from bottom-left, Hero flies from mini player artwork
/// - Back via swipe: Cupertino slide transition (natural iOS feel)
/// - Back via button: fade out (letting Hero fly back when available)
class _PlayerPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _PlayerPageRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // On iOS, always delegate to CupertinoRouteTransitionMixin so that
    // the back-gesture detector stays in the widget tree at all times.
    // This is critical — without it the HorizontalDragGestureRecognizer is
    // never installed and swipe-back can never trigger.
    if (Platform.isIOS) {
      // While the gesture is in progress OR we're playing the dismiss
      // animation that was started by a gesture, use the standard
      // Cupertino slide transition for a natural iOS feel.
      if (popGestureInProgress) {
        return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
          this,
          context,
          animation,
          secondaryAnimation,
          child,
        );
      }

      // Programmatic back (button): fade the page out so Hero can fly back.
      if (animation.status == AnimationStatus.reverse) {
        return FadeTransition(opacity: animation, child: child);
      }

      // Forward enter: scale + fade from bottom-left.
      if (animation.status == AnimationStatus.forward ||
          animation.status == AnimationStatus.completed) {
        const curve = Curves.easeOutCubic;
        final scale = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve))
            .evaluate(animation);
        final opacity = CurveTween(curve: Curves.easeIn).evaluate(animation);

        // Wrap with the Cupertino gesture detector so swiping can start
        // even while the forward animation is settling.
        return _wrapWithGestureDetector(
          context,
          Transform.scale(
            scale: scale,
            alignment: Alignment.bottomLeft,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      }
    }

    // Fallback / non-iOS: simple scale + fade
    const curve = Curves.easeOutCubic;
    final scale = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: curve))
        .evaluate(animation);
    final opacity = CurveTween(curve: Curves.easeIn).evaluate(animation);
    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomLeft,
      child: Opacity(opacity: opacity, child: child),
    );
  }

  /// Wraps [child] with the Cupertino back-gesture detector so that
  /// the swipe-from-left-edge gesture recognizer is always installed.
  Widget _wrapWithGestureDetector(BuildContext context, Widget child) {
    return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
      this,
      context,
      const AlwaysStoppedAnimation(1.0), // pretend fully visible
      const AlwaysStoppedAnimation(0.0), // no secondary
      child,
    );
  }
}
