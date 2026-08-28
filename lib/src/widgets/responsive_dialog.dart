import 'package:flutter/material.dart';

/// 响应式对话框封装
/// 横屏时限制最大宽度，避免过宽
class ResponsiveDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? titlePadding;
  final double? maxWidth;

  const ResponsiveDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.titlePadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    // 横屏时限制对话框最大宽度
    // 使用 ConstrainedBox 而不是直接设置 AlertDialog 的宽度，避免布局问题
    final dialogMaxWidth = maxWidth ??
        (isLandscape
            ? screenWidth * 0.6 // 横屏时最多占60%宽度
            : screenWidth * 0.85); // 竖屏时最多占85%宽度

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: titlePadding ??
                    const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!,
                  child: title!,
                ),
              ),
            if (content != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: contentPadding ??
                      const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: content!,
                  ),
                ),
              ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: actionsPadding ??
                    const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8.0,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 响应式 AlertDialog 封装
/// 自动根据屏幕方向调整最大宽度
class ResponsiveAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? titlePadding;
  final double? maxWidth;

  const ResponsiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.titlePadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    // 横屏时限制对话框最大宽度
    final dialogMaxWidth = maxWidth ??
        (isLandscape
            ? screenWidth * 0.6 // 横屏时最多占60%宽度
            : screenWidth * 0.85); // 竖屏时最多占85%宽度

    return AlertDialog(
      title: title,
      content: content != null
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: content,
            )
          : null,
      actions: actions,
      contentPadding: contentPadding,
      actionsPadding: actionsPadding,
      titlePadding: titlePadding,
    );
  }
}

/// 响应式 BottomSheet 封装
/// 横屏时使用居中对话框样式，竖屏时使用底部弹窗
class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;

  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLandscape) {
      // 横屏时使用居中对话框样式
      return Center(
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? screenWidth * 0.6,
              maxHeight: maxHeight ?? screenHeight * 0.8,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        ),
      );
    } else {
      // 竖屏时使用底部弹窗
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight ?? screenHeight * 0.9,
          ),
          child: child,
        ),
      );
    }
  }
}

class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const [],
    this.showCloseButton = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: Theme.of(context).colorScheme.primary),
              child: leading!,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          ...trailing,
          if (showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }
}

class BottomSheetActionBar extends StatelessWidget {
  const BottomSheetActionBar({
    super.key,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.primaryLabel,
    required this.onPrimaryPressed,
  });

  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onSecondaryPressed,
                  child: Text(secondaryLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onPrimaryPressed,
                  child: Text(primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BottomSheetMenu extends StatelessWidget {
  const BottomSheetMenu({
    super.key,
    required this.children,
    this.bottomSpacing = 8,
  });

  final List<Widget> children;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...children,
          SizedBox(height: bottomSpacing),
        ],
      ),
    );
  }
}

/// 显示响应式 BottomSheet 的辅助方法
Future<T?> showResponsiveBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? maxWidth,
  double? maxHeight,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final isLandscape =
      MediaQuery.of(context).orientation == Orientation.landscape;

  if (isLandscape) {
    // 横屏时使用对话框样式
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => ResponsiveBottomSheet(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        child: builder(context),
      ),
    );
  } else {
    // 竖屏时使用底部弹窗
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => ResponsiveBottomSheet(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        child: builder(context),
      ),
    );
  }
}

Future<T?> showBottomSheetMenu<T>({
  required BuildContext context,
  required List<Widget> children,
  double? maxWidth,
  double? maxHeight,
}) {
  return showResponsiveBottomSheet<T>(
    context: context,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    builder: (context) => BottomSheetMenu(children: children),
  );
}
