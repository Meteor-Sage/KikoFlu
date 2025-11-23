import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/audio_provider.dart';
import 'sleep_timer_dialog.dart';

/// 定时器按钮/指示器
class SleepTimerButton extends ConsumerWidget {
  final double? iconSize;

  const SleepTimerButton({
    super.key,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);
    final isLandscapeCompact =
        iconSize != null; // 在横屏模式下我们传入了固定的 iconSize，用紧凑样式防止高度溢出

    if (timerState.isActive) {
      // 定时器激活时显示带倒计时的按钮
      return SizedBox(
        height: iconSize == null ? 62 : 40, // 固定高度确保对齐
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => SleepTimerDialog.show(context),
                icon: Icon(
                  Icons.timer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                iconSize: iconSize,
                padding: isLandscapeCompact ? EdgeInsets.zero : null,
                constraints: isLandscapeCompact
                    ? const BoxConstraints(minWidth: 36, minHeight: 30, maxHeight: 30)
                    : null,
                style: isLandscapeCompact
                    ? IconButton.styleFrom(
                        minimumSize: const Size(36, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      )
                    : null,
                visualDensity: isLandscapeCompact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
              ),
              if (timerState.remainingTime != null)
                Text(
                  timerState.formattedTime,
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
            ],
          ),
        ),
      );
    } else {
      // 定时器未激活时显示普通按钮
      return SizedBox(
        height: iconSize == null ? 62 : 40, // 固定高度确保对齐
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => SleepTimerDialog.show(context),
                icon: const Icon(Icons.timer_outlined),
                iconSize: iconSize,
                padding: isLandscapeCompact ? EdgeInsets.zero : null,
                constraints: isLandscapeCompact
                    ? const BoxConstraints(minWidth: 36, minHeight: 30, maxHeight: 30)
                    : null,
                style: isLandscapeCompact
                    ? IconButton.styleFrom(
                        minimumSize: const Size(36, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      )
                    : null,
                visualDensity: isLandscapeCompact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
              ),
              SizedBox(height: iconSize == null ? 14 : 0),
            ],
          ),
        ),
      );
    }
  }
}
