import 'package:flutter/material.dart';

import '../utils/ui_tokens.dart';

/// Shared layout for ordinary loading, empty, and error states.
///
/// The caller owns every visual child. This widget only standardizes placement
/// and spacing, so existing colors, materials, and action button choices stay
/// unchanged.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.icon,
    this.title,
    this.message,
    this.action,
    this.padding = EdgeInsets.zero,
    this.iconToTitleSpacing = UiSpacing.medium,
    this.titleToMessageSpacing = UiSpacing.small,
    this.messageToActionSpacing = UiSpacing.xLarge,
  });

  final Widget icon;
  final Widget? title;
  final Widget? message;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final double iconToTitleSpacing;
  final double titleToMessageSpacing;
  final double messageToActionSpacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[icon];
    if (title != null) {
      children
        ..add(SizedBox(height: iconToTitleSpacing))
        ..add(title!);
    }
    if (message != null) {
      children
        ..add(
          SizedBox(
            height: title == null ? iconToTitleSpacing : titleToMessageSpacing,
          ),
        )
        ..add(message!);
    }
    if (action != null) {
      children
        ..add(
          SizedBox(
            height: message == null
                ? iconToTitleSpacing
                : messageToActionSpacing,
          ),
        )
        ..add(action!);
    }

    return Center(
      child: Padding(
        padding: padding,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
