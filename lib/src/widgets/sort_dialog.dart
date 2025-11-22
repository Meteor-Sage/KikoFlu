import 'package:flutter/material.dart';
import '../models/sort_options.dart';
import 'responsive_dialog.dart';

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
  final String title;
  final bool autoClose;
  final List<SortOrder>? availableOptions;

  const CommonSortDialog({
    super.key,
    required this.currentOption,
    required this.currentDirection,
    required this.onSort,
    this.title = '排序选项',
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

    // 横屏时使用两列布局
    if (isLandscape) {
      return ResponsiveAlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(widget.title),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '关闭',
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左列：排序字段
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        '排序字段',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: options.map((option) {
                            return RadioListTile<SortOrder>(
                              title: Text(option.label),
                              value: option,
                              groupValue: _currentOption,
                              onChanged: (value) {
                                if (value != null) {
                                  _handleSort(value, _currentDirection);
                                }
                              },
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // 右列：排序方向
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        '排序方向',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: SortDirection.values.map((direction) {
                            return RadioListTile<SortDirection>(
                              title: Text(direction.label),
                              value: direction,
                              groupValue: _currentDirection,
                              onChanged: (value) {
                                if (value != null) {
                                  _handleSort(_currentOption, value);
                                }
                              },
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: widget.autoClose
            ? null
            : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
      );
    }

    // 竖屏时使用单列布局
    return ResponsiveAlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 排序字段选择
            const Text(
              '排序字段',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...options.map((option) {
              return RadioListTile<SortOrder>(
                title: Text(option.label),
                value: option,
                groupValue: _currentOption,
                onChanged: (value) {
                  if (value != null) {
                    _handleSort(value, _currentDirection);
                  }
                },
                dense: true,
              );
            }),
            const Divider(),
            // 排序方向选择
            const Text(
              '排序方向',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...SortDirection.values.map((direction) {
              return RadioListTile<SortDirection>(
                title: Text(direction.label),
                value: direction,
                groupValue: _currentDirection,
                onChanged: (value) {
                  if (value != null) {
                    _handleSort(_currentOption, value);
                  }
                },
                dense: true,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.autoClose ? '取消' : '关闭'),
        ),
      ],
    );
  }
}
