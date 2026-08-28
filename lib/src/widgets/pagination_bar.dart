import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../utils/design_tokens.dart';
import '../utils/snackbar_util.dart';

/// 通用分页控制栏组件
class PaginationBar extends StatefulWidget {
  /// 当前页码（从1开始）
  final int currentPage;

  /// 每页大小
  final int pageSize;

  /// 总条目数
  final int totalCount;

  /// 是否有更多数据
  final bool hasMore;

  /// 是否正在加载
  final bool isLoading;

  /// 上一页回调
  final VoidCallback? onPreviousPage;

  /// 下一页回调
  final VoidCallback? onNextPage;

  /// 跳转到指定页回调
  final void Function(int page)? onGoToPage;

  /// 滚动到顶部回调（可选）
  final VoidCallback? onScrollToTop;

  /// 到底提示文字
  final String? endMessage;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    required this.isLoading,
    this.onPreviousPage,
    this.onNextPage,
    this.onGoToPage,
    this.onScrollToTop,
    this.endMessage,
  });

  @override
  State<PaginationBar> createState() => _PaginationBarState();
}

class _PaginationBarState extends State<PaginationBar> {
  final TextEditingController _pageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _maxPage =>
      widget.totalCount > 0 ? (widget.totalCount / widget.pageSize).ceil() : 1;

  /// 构建到底提示
  Widget _buildEndMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.listItem),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: AppIconSize.small,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              widget.endMessage ?? S.of(context).reachedEnd,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分页按钮
  Widget _buildPageButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback? onPressed,
    bool iconOnRight = false,
  }) {
    final iconWidget = Icon(
      icon,
      size: AppIconSize.compact,
      color: enabled
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );

    final textWidget = Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: enabled
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );

    return Material(
      color: enabled
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconOnRight
                ? [
                    textWidget,
                    const SizedBox(width: AppSpacing.xxs),
                    iconWidget,
                  ]
                : [
                    iconWidget,
                    const SizedBox(width: AppSpacing.xxs),
                    textWidget,
                  ],
          ),
        ),
      ),
    );
  }

  /// 构建页码跳转按钮
  Widget _buildPageJumpButton() {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: () => _showPageJumpDialog(),
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_location_alt,
                size: AppIconSize.compact,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                S.of(context).jumpTo,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示页码跳转对话框
  void _showPageJumpDialog() {
    _pageController.text = widget.currentPage.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).goToPageTitle),
        content: TextField(
          controller: _pageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: S.of(context).pageNumberRange(_maxPage),
            hintText: S.of(context).enterPageNumber,
          ),
          autofocus: true,
          onSubmitted: (_) => _handleJump(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => _handleJump(context),
            child: Text(S.of(context).jumpTo),
          ),
        ],
      ),
    );
  }

  /// 处理跳转
  void _handleJump(BuildContext dialogContext) {
    final pageStr = _pageController.text.trim();
    if (pageStr.isEmpty) {
      SnackBarUtil.showWarning(context, S.of(context).enterPageNumber);
      return;
    }

    final targetPage = int.tryParse(pageStr);
    if (targetPage == null || targetPage < 1 || targetPage > _maxPage) {
      SnackBarUtil.showWarning(
        context,
        S.of(context).enterValidPageNumber(_maxPage),
      );
      return;
    }

    if (targetPage == widget.currentPage) {
      Navigator.pop(dialogContext);
      return;
    }

    Navigator.pop(dialogContext);
    widget.onGoToPage?.call(targetPage);
    widget.onScrollToTop?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 如果总数小于等于一页的大小，显示到底提示
    if (widget.totalCount <= widget.pageSize) {
      return _buildEndMessage();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.listItem),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 页码和总数信息
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                S.of(context).pageNOfTotal(widget.currentPage, _maxPage),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.tag),
                ),
                child: Text(
                  S.of(context).totalNItems(widget.totalCount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 上一页
              _buildPageButton(
                icon: Icons.chevron_left,
                label: S.of(context).previousPage,
                enabled: widget.currentPage > 1 && !widget.isLoading,
                onPressed: widget.onPreviousPage,
              ),
              // 跳转输入
              _buildPageJumpButton(),
              // 下一页
              _buildPageButton(
                label: S.of(context).nextPage,
                icon: Icons.chevron_right,
                enabled: widget.hasMore && !widget.isLoading,
                iconOnRight: true,
                onPressed: widget.onNextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
