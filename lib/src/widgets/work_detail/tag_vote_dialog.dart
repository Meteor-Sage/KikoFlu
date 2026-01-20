import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/work.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../responsive_dialog.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 0
                  ? '已取消投票'
                  : newStatus == 1
                      ? '已投支持票'
                      : '已投反对票',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投票失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAlertDialog(
      title: Text(
        _currentTag.name,
        style: const TextStyle(fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 投票支持按钮
          _buildVoteButton(
            targetStatus: 1,
            icon: Icons.thumb_up,
            label: '支持',
            count: _currentTag.upvote ?? 0,
            activeColor: Colors.green,
          ),
          const SizedBox(height: 12),
          // 投票反对按钮
          _buildVoteButton(
            targetStatus: 2,
            icon: Icons.thumb_down,
            label: '反对',
            count: _currentTag.downvote ?? 0,
            activeColor: Colors.red,
          ),
          const SizedBox(height: 12),
          // 屏蔽标签按钮
          _buildBlockTagButton(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onCopyTag();
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('复制标签'),
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

    return InkWell(
      onTap: _isVoting ? null : () => _handleVote(targetStatus),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label：$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : null,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '已投票',
                  style: TextStyle(
                    fontSize: 11,
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_isVoting && !isActive)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockTagButton() {
    return InkWell(
      onTap: () {
        // 获取 notifier 和 messenger，避免在 dispose 后使用 ref 和 context
        final notifier = ref.read(blockedItemsProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);
        final tagName = _currentTag.name;

        // 添加到屏蔽列表
        notifier.addTag(tagName);
        Navigator.pop(context);

        messenger.clearSnackBars();
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text('已屏蔽标签: $tagName'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '撤销',
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.block,
              color: Colors.red,
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '屏蔽此标签',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
