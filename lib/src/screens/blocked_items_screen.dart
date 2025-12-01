import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';
import '../providers/auth_provider.dart';

class BlockedItemsScreen extends ConsumerWidget {
  const BlockedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('屏蔽设置'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '标签'),
              Tab(text: '声优'),
              Tab(text: '社团'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BlockedList(type: _BlockedType.tag),
            _BlockedList(type: _BlockedType.cv),
            _BlockedList(type: _BlockedType.circle),
          ],
        ),
      ),
    );
  }
}

enum _BlockedType { tag, cv, circle }

class _BlockedList extends ConsumerWidget {
  final _BlockedType type;

  const _BlockedList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedItems = ref.watch(blockedItemsProvider);
    final List<String> items;
    final String label;

    switch (type) {
      case _BlockedType.tag:
        items = blockedItems.tags;
        label = '标签';
        break;
      case _BlockedType.cv:
        items = blockedItems.cvs;
        label = '声优';
        break;
      case _BlockedType.circle:
        items = blockedItems.circles;
        label = '社团';
        break;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => _AddItemDialog(type: type, label: label),
        ),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                '没有屏蔽的$label',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _removeItem(ref, type, item);
                      SnackBarUtil.showSuccess(context, '已移除屏蔽: $item');
                    },
                  ),
                );
              },
            ),
    );
  }

  void _removeItem(WidgetRef ref, _BlockedType type, String item) {
    final notifier = ref.read(blockedItemsProvider.notifier);
    switch (type) {
      case _BlockedType.tag:
        notifier.removeTag(item);
        break;
      case _BlockedType.cv:
        notifier.removeCv(item);
        break;
      case _BlockedType.circle:
        notifier.removeCircle(item);
        break;
    }
  }
}

class _AddItemDialog extends ConsumerStatefulWidget {
  final _BlockedType type;
  final String label;

  const _AddItemDialog({required this.type, required this.label});

  @override
  ConsumerState<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<_AddItemDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(kikoeruApiServiceProvider);
      List<dynamic> data = [];

      switch (widget.type) {
        case _BlockedType.tag:
          data = await api.getAllTags();
          break;
        case _BlockedType.cv:
          data = await api.getAllVas();
          break;
        case _BlockedType.circle:
          data = await api.getAllCircles();
          break;
      }

      if (mounted) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(data);
          // 按 count 字段从大到小排序
          _suggestions
              .sort((a, b) => (b['count'] ?? 0).compareTo(a['count'] ?? 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // SnackBarUtil.showError(context, '加载建议列表失败: $e');
      }
    }
  }

  void _addItem(String item) {
    final notifier = ref.read(blockedItemsProvider.notifier);
    switch (widget.type) {
      case _BlockedType.tag:
        notifier.addTag(item);
        break;
      case _BlockedType.cv:
        notifier.addCv(item);
        break;
      case _BlockedType.circle:
        notifier.addCircle(item);
        break;
    }
    Navigator.pop(context);
    SnackBarUtil.showSuccess(context, '已添加屏蔽: $item');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加屏蔽${widget.label}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const LinearProgressIndicator()
            else
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  List<Map<String, dynamic>> filteredList;
                  if (textEditingValue.text.trim().isEmpty) {
                    filteredList = _suggestions.toList();
                  } else {
                    final query = textEditingValue.text.trim().toLowerCase();
                    filteredList = _suggestions.where((option) {
                      return option['name']
                          .toString()
                          .toLowerCase()
                          .contains(query);
                    }).toList();
                  }
                  return filteredList;
                },
                displayStringForOption: (Map<String, dynamic> option) =>
                    option['name'],
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  // 同步控制器，以便在点击"添加"按钮时获取文本
                  textEditingController.addListener(() {
                    _controller.text = textEditingController.text;
                  });
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: '${widget.label}名称',
                      hintText: '请输入要屏蔽的${widget.label}',
                      suffixIcon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    autofocus: true,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addItem(value.trim());
                      }
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        width: 300, // 限制宽度
                        height: 300, // 限制高度
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Map<String, dynamic> option =
                                options.elementAt(index);
                            return ListTile(
                              title: Text(option['name']),
                              subtitle: option['count'] != null
                                  ? Text('作品数: ${option['count']}')
                                  : null,
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (Map<String, dynamic> selection) {
                  _controller.text = selection['name'];
                  // 选中后不自动提交，让用户确认
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              _addItem(text);
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}
