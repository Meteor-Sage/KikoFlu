import 'package:flutter/material.dart';

import '../utils/ui_tokens.dart';

/// Shared geometry for conditions shown on the search form and results page.
/// Colors and icons stay owned by each caller so their existing semantics are
/// preserved.
class SearchConditionChip extends StatelessWidget {
  const SearchConditionChip({
    super.key,
    required this.label,
    required this.avatar,
    required this.backgroundColor,
    this.onDeleted,
  });

  final String label;
  final Widget avatar;
  final Color backgroundColor;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: avatar,
      label: Text(label, style: UiTextStyles.filterChipLabel),
      backgroundColor: backgroundColor,
      onDeleted: onDeleted,
      deleteIcon: onDeleted == null
          ? null
          : const Icon(Icons.close, size: UiIconSize.small),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(
        horizontal: UiSpacing.small,
        vertical: UiSpacing.xSmall,
      ),
      labelPadding: EdgeInsets.only(
        left: UiSpacing.xSmall,
        right: onDeleted == null ? UiSpacing.xSmall : 2,
      ),
    );
  }
}
