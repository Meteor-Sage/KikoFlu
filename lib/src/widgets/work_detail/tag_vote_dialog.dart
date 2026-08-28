import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/work.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../responsive_dialog.dart';
import '../../utils/tag_localizer.dart';
import '../../utils/snackbar_util.dart';
import '../../utils/design_tokens.dart';

/// 标签投票对话框组件
class TagVoteDialog extends ConsumerStatefulWidget {
  final Tag tag;
  final int workId;
  final Function(Tag) onVoteChanged;
  final VoidCallback onCopyTag;

  const TagVoteDialog({
    super.key,
    required this.tag,
    required this.workId,
    required this.onVoteChanged,
    required this.onCopyTag,
  });

  @override
  ConsumerState<TagVoteDialog> createState() => _TagVoteDialogState();
}

class _TagVoteDialogState extends ConsumerState<TagVoteDialog> {
  late Tag _currentTag;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _currentTag = widget.tag;
  }

  Future<void> _handleVote(int targetStatus) async {
    if (_isVoting) return;

    setState(() {
      _isVoting = true;
    });

    try {
      // 如果点击已投的票，则取消投票
      final newStatus = _currentTag.myVote == targetStatus ? 0 : targetStatus;

      final apiService = ref.read(kikoeruApiServiceProvider);
      await apiService.voteWorkTag(
        workId: widget.workId,
        tagId: _currentTag.id,
        status: newStatus,
      );

      // 投票成功，更新本地状态
      if (mounted) {
        setState(() {
          final oldUpvote = _currentTag.upvote ?? 0;
          final oldDownvote = _currentTag.downvote ?? 0;
          int newUpvote = oldUpvote;
          int newDownvote = oldDownvote;

          // 先移除旧投票的影响
          if (_currentTag.myVote == 1) {
            newUpvote = oldUpvote - 1;
          } else if (_currentTag.myVote == 2) {
            newDownvote = oldDownvote - 1;
          }

          // 再添加新投票的影响
          if (newStatus == 1) {
            newUpvote = newUpvote + 1;
          } else if (newStatus == 2) {
            newDownvote = newDownvote + 1;
          }

          _currentTag = Tag(
            id: _currentTag.id,
            name: _currentTag.name,
            upvote: newUpvote,
            downvote: newDownvote,
            myVote: newStatus == 0 ? null : newStatus,
          );

          _isVoting = false;
        });

        // 通知父组件更新
        widget.onVoteChanged(_currentTag);

        // 显示提示
        SnackBarUtil.showInfo(
          context,
          newStatus == 0
              ? S.of(context).voteRemoved
              : newStatus == 1
              ? S.of(context).votedUp
              : S.of(context).votedDown,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });

        SnackBarUtil.showError(
          context,
          S.of(context).voteFailedWithError(e.toString()),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAlertDialog(
      title: Text(
        TagLocalizer.localize(
          _currentTag.id,
          _currentTag.name,
          Localizations.localeOf(context),
        ),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 投票支持按钮
          _buildVoteButton(
            targetStatus: 1,
            icon: Icons.thumb_up,
            label: S.of(context).voteFor,
            count: _currentTag.upvote ?? 0,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 投票反对按钮
          _buildVoteButton(
            targetStatus: 2,
            icon: Icons.thumb_down,
            label: S.of(context).voteAgainst,
            count: _currentTag.downvote ?? 0,
            activeColor: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 屏蔽标签按钮
          _buildBlockTagButton(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).close),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onCopyTag();
          },
          icon: const Icon(Icons.copy, size: AppIconSize.compact),
          label: Text(S.of(context).copyTag),
        ),
      ],
    );
  }

  Widget _buildVoteButton({
    required int targetStatus,
    required IconData icon,
    required String label,
    required int count,
    required Color activeColor,
  }) {
    final isActive = _currentTag.myVote == targetStatus;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _isVoting ? null : () => _handleVote(targetStatus),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: isActive ? activeColor : colorScheme.outlineVariant,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : colorScheme.onSurfaceVariant,
              size: AppIconSize.large,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$label：$count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : null,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.tag),
                ),
                child: Text(
                  S.of(context).voted,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_isVoting && !isActive)
              const SizedBox(
                width: AppIconSize.small,
                height: AppIconSize.small,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockTagButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // 获取 notifier 和 messenger，避免在 dispose 后使用 ref 和 context
        final notifier = ref.read(blockedItemsProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);
        final tagName = _currentTag.name;
        final blockedMessage = S.of(context).tagBlockedWithName(tagName);
        final undoLabel = S.of(context).undo;

        // 添加到屏蔽列表
        notifier.addTag(tagName);
        Navigator.pop(context);

        messenger.clearSnackBars();
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text(blockedMessage),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: undoLabel,
              onPressed: () {
                notifier.removeTag(tagName);
              },
            ),
          ),
        );

        // 强制在3秒后关闭，解决桌面端鼠标悬停导致不消失的问题
        Future.delayed(const Duration(seconds: 3), () {
          try {
            controller.close();
          } catch (_) {}
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.block,
              color: colorScheme.error,
              size: AppIconSize.large,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                S.of(context).blockThisTag,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
