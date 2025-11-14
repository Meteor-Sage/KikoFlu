import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/audio_provider.dart';
import '../responsive_dialog.dart';

/// 睡眠定时器对话框
class SleepTimerDialog extends ConsumerStatefulWidget {
  const SleepTimerDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !Platform.isIOS,
      builder: (context) => const SleepTimerDialog(),
    );
  }

  @override
  ConsumerState<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends ConsumerState<SleepTimerDialog> {
  bool _isTimeMode = false; // false: 时长模式, true: 指定时间模式
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sleepTimerProvider);

    return ResponsiveAlertDialog(
      title: const Text('睡眠定时器'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timerState.isActive) ...[
              // 当前定时器状态
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '剩余时间',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timerState.formattedTime,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 快捷调整按钮
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildAdjustButton(
                    context,
                    ref,
                    icon: Icons.add,
                    label: '+5分钟',
                    onTap: () {
                      ref
                          .read(sleepTimerProvider.notifier)
                          .addTime(const Duration(minutes: 5));
                    },
                  ),
                  _buildAdjustButton(
                    context,
                    ref,
                    icon: Icons.add,
                    label: '+10分钟',
                    onTap: () {
                      ref
                          .read(sleepTimerProvider.notifier)
                          .addTime(const Duration(minutes: 10));
                    },
                  ),
                  _buildAdjustButton(
                    context,
                    ref,
                    icon: Icons.cancel_outlined,
                    label: '取消定时',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      ref.read(sleepTimerProvider.notifier).cancelTimer();
                    },
                  ),
                ],
              ),
            ] else ...[
              // 设置新定时器
              // 模式切换
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.timer_outlined),
                    label: Text('时长'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.schedule),
                    label: Text('指定时间'),
                  ),
                ],
                selected: {_isTimeMode},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() {
                    _isTimeMode = selected.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              // 根据模式显示不同的UI
              if (_isTimeMode) ...[
                _buildTimePickerSection(context, ref),
              ] else ...[
                Text(
                  '选择定时时长',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildTimeGrid(context, ref),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildTimePickerSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          '选择停止播放的时间',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    alwaysUse24HourFormat: true,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedTime = picked;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedTime.format(context),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        fontSize: 40,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            final now = DateTime.now();
            final targetTime = DateTime(
              now.year,
              now.month,
              now.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            // 如果选择的时间已经过了，则设置为明天的这个时间
            final finalTime = targetTime.isBefore(now)
                ? targetTime.add(const Duration(days: 1))
                : targetTime;

            ref.read(sleepTimerProvider.notifier).setTimerUntil(finalTime);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(BuildContext context, WidgetRef ref) {
    final presetTimes = [
      (const Duration(minutes: 5), '5分钟', Icons.timer),
      (const Duration(minutes: 10), '10分钟', Icons.timer),
      (const Duration(minutes: 15), '15分钟', Icons.bedtime_outlined),
      (const Duration(minutes: 30), '30分钟', Icons.bedtime_outlined),
      (const Duration(hours: 1), '1小时', Icons.bedtime),
      (const Duration(hours: 2), '2小时', Icons.bedtime),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: presetTimes.map((preset) {
        final (duration, label, icon) = preset;
        return _buildTimeCard(
          context,
          ref,
          duration: duration,
          label: label,
          icon: icon,
        );
      }).toList(),
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    WidgetRef ref, {
    required Duration duration,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        ref.read(sleepTimerProvider.notifier).setTimer(duration);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color ?? Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
