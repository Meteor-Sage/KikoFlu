import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_reviews_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/server_utils.dart';
import '../utils/l10n_extensions.dart';
import 'add_to_playlist_dialog.dart';
import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';

/// 通用的收藏状态编辑对话框组件
///
/// 根据屏幕方向自动选择：
/// - 横屏：显示Dialog（3+3两列布局）
/// - 竖屏：显示BottomSheet（单列列表）
///
/// 返回值：
/// - Map包含：'progress': String?, 'rating': int?
/// - progress为'__REMOVE__'表示移除标记
/// - null 表示取消操作
class ReviewProgressDialog {
  /// 显示收藏状态编辑对话框
  ///
  /// [context] - 上下文
  /// [currentProgress] - 当前的进度状态值
  /// [currentRating] - 当前的评分值(1-5)
  /// [title] - 对话框标题，默认为"标记作品"
  /// [showLoading] - 是否显示加载指示器（用于更新状态时）
  /// [workId] - 作品ID，用于添加到播放列表
  /// [workTitle] - 作品标题，用于添加到播放列表
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    String? currentProgress,
    int? currentRating,
    String? title,
    bool showLoading = false,
    int? workId,
    String? workTitle,
  }) async {
    final filters = [
      MyReviewFilter.marked,
      MyReviewFilter.listening,
      MyReviewFilter.listened,
      MyReviewFilter.replay,
      MyReviewFilter.postponed,
    ];

    final authState = ProviderScope.containerOf(context).read(authProvider);
    final isOfficialServer = ServerUtils.isOfficialServer(authState.host);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final resolvedTitle = title ?? S.of(context).markWork;

    String? selectedProgress = currentProgress;
    int? selectedRating = currentRating;

    if (isLandscape) {
      // 横屏模式：使用对话框形式，3+3两列布局
      return showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BottomSheetHeader(title: resolvedTitle),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            ..._buildRatingButtons(
                              context: context,
                              selectedRating: selectedRating,
                              onSelected: (value) {
                                setState(() {
                                  selectedRating =
                                      selectedRating == value ? null : value;
                                });
                              },
                              iconSize: 24,
                              minButtonSize: 32,
                            ),
                            const Spacer(),
                            if (workId != null &&
                                workTitle != null &&
                                isOfficialServer)
                              IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () async {
                                  await AddToPlaylistDialog.show(
                                    context: context,
                                    workId: workId,
                                    workTitle: workTitle,
                                  );
                                },
                                tooltip: S.of(context).addToPlaylist,
                              ),
                            if (showLoading)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // 内容区域 - 3+3两列布局，支持滚动
                      Flexible(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RadioGroup<String>(
                                  groupValue: selectedProgress,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedProgress = value;
                                    });
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 左列：前3个选项
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (final filter
                                                in filters.take(3))
                                              RadioListTile<String>(
                                                title: Text(
                                                  filter
                                                      .localizedLabel(context),
                                                ),
                                                value: filter.value!,
                                                selected: selectedProgress ==
                                                    filter.value,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const VerticalDivider(width: 1),
                                      // 右列：后2个选项 + 移除按钮
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (final filter
                                                in filters.skip(3))
                                              RadioListTile<String>(
                                                title: Text(
                                                  filter
                                                      .localizedLabel(context),
                                                ),
                                                value: filter.value!,
                                                selected: selectedProgress ==
                                                    filter.value,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                              ),
                                            if (currentProgress != null ||
                                                currentRating != null) ...[
                                              const Divider(height: 1),
                                              InkWell(
                                                onTap: () {
                                                  Navigator.of(dialogContext)
                                                      .pop({
                                                    'progress': '__REMOVE__',
                                                    'rating': null,
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 12),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 40,
                                                        child: Icon(
                                                          Icons.delete_outline,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        S.of(context).remove,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      BottomSheetActionBar(
                        secondaryLabel: S.of(context).cancel,
                        onSecondaryPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        primaryLabel: S.of(context).confirm,
                        onPrimaryPressed: () {
                          Navigator.of(dialogContext).pop({
                            'progress': selectedProgress,
                            'rating': selectedRating,
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      // 竖屏模式：使用底部弹窗
      return showResponsiveBottomSheet<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BottomSheetHeader(title: resolvedTitle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        ..._buildRatingButtons(
                          context: context,
                          selectedRating: selectedRating,
                          onSelected: (value) {
                            setState(() {
                              selectedRating =
                                  selectedRating == value ? null : value;
                            });
                          },
                          iconSize: 22,
                          minButtonSize: 28,
                        ),
                        const Spacer(),
                        if (workId != null &&
                            workTitle != null &&
                            isOfficialServer)
                          IconButton(
                            icon: const Icon(Icons.playlist_add),
                            onPressed: () async {
                              await AddToPlaylistDialog.show(
                                context: context,
                                workId: workId,
                                workTitle: workTitle,
                              );
                            },
                            tooltip: S.of(context).addToPlaylist,
                          ),
                        if (showLoading)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // 进度选项
                  ...filters.map((filter) {
                    final isSelected = selectedProgress == filter.value;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(filter.localizedLabel(context)),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          selectedProgress = filter.value;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  if (currentProgress != null || currentRating != null)
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        S.of(context).remove,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, {
                          'progress': '__REMOVE__',
                          'rating': null,
                        });
                      },
                    ),
                  BottomSheetActionBar(
                    secondaryLabel: S.of(context).cancel,
                    onSecondaryPressed: () => Navigator.pop(context),
                    primaryLabel: S.of(context).confirm,
                    onPrimaryPressed: () {
                      Navigator.pop(context, {
                        'progress': selectedProgress,
                        'rating': selectedRating,
                      });
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  static List<Widget> _buildRatingButtons({
    required BuildContext context,
    required int? selectedRating,
    required ValueChanged<int> onSelected,
    required double iconSize,
    required double minButtonSize,
  }) {
    return List.generate(5, (index) {
      final starValue = index + 1;
      final isSelected = selectedRating != null && starValue <= selectedRating;
      return IconButton(
        icon: Icon(
          isSelected ? Icons.star : Icons.star_border,
          color: isSelected ? Colors.amber : null,
          size: iconSize,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: minButtonSize,
          minHeight: minButtonSize,
        ),
        onPressed: () => onSelected(starValue),
        tooltip: S.of(context).nStars(starValue),
      );
    });
  }

  /// 获取状态标签（需要 BuildContext 以支持多语言）
  static String getProgressLabel(String? value, BuildContext context) {
    if (value == null) return S.of(context).markButton;
    final found = [
      MyReviewFilter.marked,
      MyReviewFilter.listening,
      MyReviewFilter.listened,
      MyReviewFilter.replay,
      MyReviewFilter.postponed,
    ].firstWhere(
      (f) => f.value == value,
      orElse: () => MyReviewFilter.all,
    );
    return found.localizedLabel(context);
  }

  /// 获取状态对应的图标
  static IconData getProgressIcon(String? progress) {
    if (progress == null) return Icons.bookmark_border;

    switch (progress) {
      case 'marked':
        return Icons.bookmark;
      case 'listening':
        return Icons.headphones;
      case 'listened':
        return Icons.check_circle;
      case 'replay':
        return Icons.replay;
      case 'postponed':
        return Icons.schedule;
      default:
        return Icons.bookmark;
    }
  }

  /// @deprecated 使用 getProgressLabel 替代
  static String getLabelForProgress(String? value, BuildContext context) =>
      getProgressLabel(value, context);
}
