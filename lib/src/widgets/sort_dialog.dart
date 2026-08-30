import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../models/sort_options.dart';
import '../utils/l10n_extensions.dart';
import 'radio_option_group.dart';
import 'responsive_dialog.dart';
import 'settings_option_dialog.dart';

/// 通用排序对话框
///
/// 支持两种使用模式：
/// 1. 回调模式：提供 currentOption, currentDirection 和 onSort 回调
/// 2. 直接模式：选择后自动关闭对话框并触发回调
///
/// 自动适配横屏/竖屏布局：
/// - 横屏：两列布局（左：排序字段，右：排序方向）
/// - 竖屏：单列布局
class CommonSortDialog extends StatefulWidget {
  final SortOrder currentOption;
  final SortDirection currentDirection;
  final Function(SortOrder, SortDirection) onSort;
  final String? title;
  final bool autoClose;
  final List<SortOrder>? availableOptions;

  const CommonSortDialog({
    super.key,
    required this.currentOption,
    required this.currentDirection,
    required this.onSort,
    this.title,
    this.autoClose = true,
    this.availableOptions,
  });

  @override
  State<CommonSortDialog> createState() => _CommonSortDialogState();
}

class _CommonSortDialogState extends State<CommonSortDialog> {
  late SortOrder _currentOption;
  late SortDirection _currentDirection;

  @override
  void initState() {
    super.initState();
    _currentOption = widget.currentOption;
    _currentDirection = widget.currentDirection;
  }

  void _handleSort(SortOrder option, SortDirection direction) {
    setState(() {
      _currentOption = option;
      _currentDirection = direction;
    });
    widget.onSort(option, direction);
    if (widget.autoClose) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final options = widget.availableOptions ?? SortOrder.values;
    final orderSection = _SortSection<SortOrder>(
      key: const ValueKey('sort-field-section'),
      title: S.of(context).sortField,
      value: _currentOption,
      options: options,
      labelBuilder: (option) => option.localizedLabel(context),
      onChanged: (value) => _handleSort(value, _currentDirection),
    );
    final directionSection = _SortSection<SortDirection>(
      key: const ValueKey('sort-direction-section'),
      title: S.of(context).sortDirection,
      value: _currentDirection,
      options: SortDirection.values,
      labelBuilder: (direction) => direction.localizedLabel(context),
      onChanged: (value) => _handleSort(_currentOption, value),
    );

    return ResponsiveDialog(
      maxWidth: isLandscape ? 640 : 420,
      titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: Row(
        children: [
          Icon(
            Icons.sort,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title ?? S.of(context).sortOptions,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: S.of(context).close,
          ),
        ],
      ),
      content: SizedBox(
        width: isLandscape ? 600 : 360,
        child: isLandscape
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: orderSection),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: VerticalDivider(width: 1),
                    ),
                    Expanded(child: directionSection),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  orderSection,
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  directionSection,
                ],
              ),
      ),
    );
  }
}

class _SortSection<T> extends StatelessWidget {
  const _SortSection({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CompactRadioOptionGroup<T>(
          groupValue: value,
          options: [
            for (final option in options)
              RadioOption(value: option, title: Text(labelBuilder(option))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
