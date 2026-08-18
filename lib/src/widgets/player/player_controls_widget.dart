import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../providers/audio_provider.dart';
import '../../providers/floating_lyric_provider.dart';
import '../../providers/lyric_provider.dart';
import '../../providers/player_buttons_provider.dart';
import '../../utils/string_utils.dart';
import '../responsive_dialog.dart';
import '../subtitle_adjustment_dialog.dart';
import '../volume_control.dart';
import 'sleep_timer_button.dart';
import 'sleep_timer_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// 播放器控制组件
class PlayerControlsWidget extends ConsumerStatefulWidget {
  final bool isLandscape;
  final AudioPlayerState audioState;
  final bool isPlaying;
  final AsyncValue<Duration> position;
  final AsyncValue<Duration?> duration;
  final bool isSeekingManually;
  final double seekValue;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final Duration? seekingPosition;
  final int? workId;
  final String? currentProgress;
  final VoidCallback? onMarkPressed;
  final VoidCallback? onDetailPressed;

  const PlayerControlsWidget({
    super.key,
    required this.isLandscape,
    required this.audioState,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.isSeekingManually,
    required this.seekValue,
    required this.onSeekChanged,
    required this.onSeekEnd,
    this.seekingPosition,
    this.workId,
    this.currentProgress,
    this.onMarkPressed,
    this.onDetailPressed,
  });

  @override
  ConsumerState<PlayerControlsWidget> createState() =>
      _PlayerControlsWidgetState();
}

class _PlayerControlsWidgetState extends ConsumerState<PlayerControlsWidget> {
  void _showSpeedDialog(
      BuildContext context, WidgetRef ref, double currentSpeed) {
    double localSpeed = currentSpeed;

    showDialog(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        title: Text(S.of(context).playbackSpeed),
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
            child: Text(S.of(context).confirm),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final config = isDesktop
        ? ref.read(playerButtonsConfigDesktopProvider)
        : ref.read(playerButtonsConfigMobileProvider);
    final moreButtons = config.getMoreButtons(isDesktop);

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...moreButtons.map((buttonType) {
                return _buildMenuItemForButton(
                    context, ref, buttonType, setState);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemForButton(
      BuildContext context, WidgetRef ref, PlayerButtonType buttonType,
      [StateSetter? setState]) {
    switch (buttonType) {
      case PlayerButtonType.seekBackward:
        return ListTile(
          leading: const Icon(Icons.replay_10),
          title: Text(S.of(context).backward10s),
          onTap: () {
            Navigator.pop(context);
            ref
                .read(audioPlayerControllerProvider.notifier)
                .seekBackward(const Duration(seconds: 10));
          },
        );
      case PlayerButtonType.seekForward:
        return ListTile(
          leading: const Icon(Icons.forward_10),
          title: Text(S.of(context).forward10s),
          onTap: () {
            Navigator.pop(context);
            ref
                .read(audioPlayerControllerProvider.notifier)
                .seekForward(const Duration(seconds: 10));
          },
        );
      case PlayerButtonType.sleepTimer:
        final timerState = ref.watch(sleepTimerProvider);
        return ListTile(
          leading: Icon(
            timerState.isActive ? Icons.timer : Icons.timer_outlined,
            color: timerState.isActive
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text(S.of(context).sleepTimer),
          trailing: timerState.isActive && timerState.remainingTime != null
              ? Text(
                  timerState.formattedTime,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            SleepTimerDialog.show(context);
          },
        );
      case PlayerButtonType.speed:
        return ListTile(
          leading: const Icon(Icons.speed),
          title: Text(S.of(context).playbackSpeed),
          trailing: Text(
            '${widget.audioState.speed.toStringAsFixed(1)}x',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          onTap: () {
            Navigator.pop(context);
            _showSpeedDialog(context, ref, widget.audioState.speed);
          },
        );
      case PlayerButtonType.repeat:
        return ListTile(
          leading: Icon(
            switch (widget.audioState.repeatMode) {
              LoopMode.off => Icons.repeat,
              LoopMode.one => Icons.repeat_one,
              LoopMode.all => Icons.repeat_on,
            },
            color: widget.audioState.repeatMode != LoopMode.off
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text(S.of(context).repeatMode),
          trailing: Text(
            switch (widget.audioState.repeatMode) {
              LoopMode.off => S.of(context).repeatOff,
              LoopMode.one => S.of(context).repeatOne,
              LoopMode.all => S.of(context).repeatAll,
            },
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.audioState.repeatMode != LoopMode.off
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
          ),
          onTap: () {
            final nextMode = switch (widget.audioState.repeatMode) {
              LoopMode.off => LoopMode.one,
              LoopMode.one => LoopMode.all,
              LoopMode.all => LoopMode.off,
            };
            ref
                .read(audioPlayerControllerProvider.notifier)
                .setRepeatMode(nextMode);
            Navigator.pop(context);
          },
        );
      case PlayerButtonType.mark:
        return ListTile(
          leading: Icon(
            widget.currentProgress != null
                ? Icons.bookmark
                : Icons.bookmark_border,
            color: widget.currentProgress != null
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text(S.of(context).addMark),
          trailing: widget.currentProgress != null
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            if (widget.onMarkPressed != null) {
              widget.onMarkPressed!();
            }
          },
        );
      case PlayerButtonType.detail:
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(S.of(context).viewDetail),
          onTap: () {
            Navigator.pop(context);
            if (widget.onDetailPressed != null) {
              widget.onDetailPressed!();
            }
          },
        );
      case PlayerButtonType.volume:
        // 使用局部变量跟踪当前音量值以实现实时反馈
        final currentVolume = ref.read(audioPlayerControllerProvider).volume;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: Text(S.of(context).volume),
              trailing: Text(
                '${(currentVolume * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_down,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Slider(
                      value: currentVolume,
                      onChanged: (value) {
                        ref
                            .read(audioPlayerControllerProvider.notifier)
                            .setVolume(value);
                        // 触发菜单重建以更新显示
                        if (setState != null) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  Icon(
                    Icons.volume_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        );
      case PlayerButtonType.subtitleAdjustment:
        final lyricState = ref.watch(lyricControllerProvider);
        final hasOffset = lyricState.timelineOffset != Duration.zero;
        return ListTile(
          leading: Icon(
            Icons.tune,
            color: hasOffset ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(S.of(context).subtitleTimingAdjustment),
          trailing: hasOffset
              ? Text(
                  '${lyricState.timelineOffset.inMilliseconds}ms',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (context) => const SubtitleAdjustmentDialog(),
            );
          },
        );
      case PlayerButtonType.floatingLyric:
        return Consumer(
          builder: (context, ref, child) {
            final isEnabled = ref.watch(floatingLyricEnabledProvider);
            return ListTile(
              leading: Icon(
                Icons.picture_in_picture_alt,
                color: isEnabled ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(S.of(context).floatingSubtitle),
              trailing: Transform.scale(
                scale: 0.8,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    ref.read(floatingLyricEnabledProvider.notifier).toggle();
                  },
                ),
              ),
              onTap: () {
                ref.read(floatingLyricEnabledProvider.notifier).toggle();
              },
            );
          },
        );
    }
  }

  Widget _buildButton(BuildContext context, WidgetRef ref,
      PlayerButtonType buttonType, bool isLandscape) {
    final iconSize = isLandscape ? 24.0 : null;

    switch (buttonType) {
      case PlayerButtonType.seekBackward:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                ref
                    .read(audioPlayerControllerProvider.notifier)
                    .seekBackward(const Duration(seconds: 10));
              },
              icon: const Icon(Icons.replay_10),
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.seekForward:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                ref
                    .read(audioPlayerControllerProvider.notifier)
                    .seekForward(const Duration(seconds: 10));
              },
              icon: const Icon(Icons.forward_10),
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.sleepTimer:
        return SleepTimerButton(iconSize: iconSize);
      case PlayerButtonType.volume:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VolumeControl(
              volume: widget.audioState.volume,
              onVolumeChanged: (value) {
                ref
                    .read(audioPlayerControllerProvider.notifier)
                    .setVolume(value);
              },
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.speed:
        return SizedBox(
          height: isLandscape ? 40 : 62, // 固定高度确保对齐
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    _showSpeedDialog(context, ref, widget.audioState.speed);
                  },
                  icon: Icon(
                    Icons.speed,
                    color: widget.audioState.speed != 1.0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  iconSize: iconSize,
                  padding: isLandscape ? EdgeInsets.zero : null,
                  constraints: isLandscape
                      ? const BoxConstraints(minWidth: 36, minHeight: 36)
                      : null,
                  visualDensity: isLandscape
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                ),
                if (widget.audioState.speed != 1.0)
                  Text(
                    '${widget.audioState.speed.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.0,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                if (widget.audioState.speed == 1.0)
                  SizedBox(height: isLandscape ? 4 : 14),
              ],
            ),
          ),
        );
      case PlayerButtonType.repeat:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                final nextMode = switch (widget.audioState.repeatMode) {
                  LoopMode.off => LoopMode.one,
                  LoopMode.one => LoopMode.all,
                  LoopMode.all => LoopMode.off,
                };
                ref
                    .read(audioPlayerControllerProvider.notifier)
                    .setRepeatMode(nextMode);
              },
              icon: Icon(
                switch (widget.audioState.repeatMode) {
                  LoopMode.off => Icons.repeat,
                  LoopMode.one => Icons.repeat_one,
                  LoopMode.all => Icons.repeat_on,
                },
                color: widget.audioState.repeatMode != LoopMode.off
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.mark:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.onMarkPressed,
              icon: Icon(
                widget.currentProgress != null
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: widget.currentProgress != null
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.detail:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.onDetailPressed,
              icon: const Icon(Icons.info_outline),
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.subtitleAdjustment:
        final lyricState = ref.watch(lyricControllerProvider);
        final hasOffset = lyricState.timelineOffset != Duration.zero;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) => const SubtitleAdjustmentDialog(),
                );
              },
              icon: Badge(
                isLabelVisible: hasOffset,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.tune),
              ),
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
      case PlayerButtonType.floatingLyric:
        final isEnabled = ref.watch(floatingLyricEnabledProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                ref.read(floatingLyricEnabledProvider.notifier).toggle();
              },
              icon: Icon(
                isEnabled
                    ? Icons.picture_in_picture_alt
                    : Icons.picture_in_picture_alt_outlined,
                color: isEnabled ? Theme.of(context).colorScheme.primary : null,
              ),
              iconSize: iconSize,
            ),
            if (!isLandscape) const SizedBox(height: 14),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.isLandscape ? 24.0 : 48.0;
    final playButtonSize = widget.isLandscape ? 64.0 : 72.0;
    final playIconSize = widget.isLandscape ? 32.0 : 36.0;

    return Column(
      children: [
        // Progress slider
        Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final pos = widget.position.value ?? Duration.zero;
                final dur = widget.duration.value ?? Duration.zero;

                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // 增强未播放部分的可见度，使其与背景区分
                    inactiveTrackColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.15),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: (widget.isSeekingManually
                            ? widget.seekValue
                            : dur.inMilliseconds > 0
                                ? pos.inMilliseconds / dur.inMilliseconds
                                : 0.0)
                        .clamp(0.0, 1.0),
                    onChanged: widget.onSeekChanged,
                    onChangeEnd: widget.onSeekEnd,
                  ),
                );
              },
            ),
            // Time labels
            Consumer(
              builder: (context, ref, child) {
                final pos = widget.position.value ?? Duration.zero;
                final dur = widget.duration.value ?? Duration.zero;

                final displayPos = widget.isSeekingManually
                    ? Duration(
                        milliseconds:
                            (widget.seekValue * dur.inMilliseconds).round())
                    : pos;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(displayPos, padHours: false),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatDuration(dur, padHours: false),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: widget.isLandscape ? 20 : 16),
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
              iconSize: iconSize,
            ),
            Container(
              width: playButtonSize,
              height: playButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: IconButton(
                onPressed: () {
                  if (widget.isPlaying) {
                    ref.read(audioPlayerControllerProvider.notifier).pause();
                  } else {
                    ref.read(audioPlayerControllerProvider.notifier).play();
                  }
                },
                icon: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                iconSize: playIconSize,
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(audioPlayerControllerProvider.notifier).skipToNext();
              },
              icon: Consumer(
                builder: (context, ref, child) {
                  final canSkipNext = ref.watch(canSkipNextProvider);
                  final baseColor = Theme.of(context).colorScheme.onSurface;
                  return Icon(
                    Icons.skip_next,
                    color:
                        canSkipNext ? null : baseColor.withValues(alpha: 0.3),
                  );
                },
              ),
              iconSize: iconSize,
            ),
          ],
        ),
        SizedBox(height: widget.isLandscape ? 16 : 12),
        // Additional controls
        Consumer(
          builder: (context, ref, child) {
            final isDesktop = !Platform.isAndroid && !Platform.isIOS;
            final config = isDesktop
                ? ref.watch(playerButtonsConfigDesktopProvider)
                : ref.watch(playerButtonsConfigMobileProvider);
            final visibleButtons = config.getVisibleButtons(isDesktop);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...visibleButtons.map((type) =>
                    _buildButton(context, ref, type, widget.isLandscape)),
                // More menu button (always visible)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        _showMoreMenu(context, ref);
                      },
                      icon: Builder(
                        builder: (context) {
                          final moreButtons = config.getMoreButtons(isDesktop);
                          final hasSpeedInMore =
                              moreButtons.contains(PlayerButtonType.speed);
                          final hasRepeatInMore =
                              moreButtons.contains(PlayerButtonType.repeat);
                          final hasSleepTimerInMore =
                              moreButtons.contains(PlayerButtonType.sleepTimer);
                          final hasSubtitleAdjustmentInMore = moreButtons
                              .contains(PlayerButtonType.subtitleAdjustment);
                          final hasFloatingLyricInMore = moreButtons
                              .contains(PlayerButtonType.floatingLyric);
                          final timerState = ref.watch(sleepTimerProvider);
                          final lyricState = ref.watch(lyricControllerProvider);
                          final isFloatingLyricEnabled =
                              ref.watch(floatingLyricEnabledProvider);

                          final shouldShowBadge = (hasSpeedInMore &&
                                  widget.audioState.speed != 1.0) ||
                              (hasRepeatInMore &&
                                  widget.audioState.repeatMode !=
                                      LoopMode.off) ||
                              (hasSleepTimerInMore && timerState.isActive) ||
                              (hasSubtitleAdjustmentInMore &&
                                  lyricState.timelineOffset != Duration.zero) ||
                              (hasFloatingLyricInMore &&
                                  isFloatingLyricEnabled);

                          return Badge(
                            isLabelVisible: shouldShowBadge,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.more_horiz),
                          );
                        },
                      ),
                      iconSize: widget.isLandscape ? 24 : null,
                    ),
                    if (!widget.isLandscape) const SizedBox(height: 14),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
