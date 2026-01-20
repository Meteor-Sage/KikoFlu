import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/work.dart';
import '../../providers/auth_provider.dart';
import '../responsive_dialog.dart';

/// 添加标签对话框组件
class AddTagDialog extends ConsumerStatefulWidget {
  final int workId;
  final List<Tag> existingTags;
  final VoidCallback onTagsAdded;

  const AddTagDialog({
    super.key,
    required this.workId,
    required this.existingTags,
    required this.onTagsAdded,
  });

  @override
  ConsumerState<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends ConsumerState<AddTagDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTags = [];
  List<Map<String, dynamic>> _filteredTags = [];
  final Set<int> _selectedTagIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAllTags();
    _searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTags() async {
    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      final data = await apiService.getAllTags();

      if (mounted) {
        setState(() {
          _allTags = List<Map<String, dynamic>>.from(data);
          // 按 count 字段从大到小排序
          _allTags.sort((a, b) => (b['count'] ?? 0).compareTo(a['count'] ?? 0));
          _filteredTags = _allTags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载标签失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTags() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredTags = _allTags;
      } else {
        _filteredTags = _allTags
            .where(
                (tag) => tag['name'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _submitTags() async {
    if (_selectedTagIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一个标签'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      await apiService.attachTagsToWork(
        workId: widget.workId,
        tagIds: _selectedTagIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTagsAdded();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('标签提交成功，等待服务器处理'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        String errorMessage = '添加标签失败: $e';

        // 检查是否需要绑定邮箱
        if (e.toString().contains('Must bind email first') ||
            e.toString().contains('vote.mustBindEmailFirst')) {
          errorMessage = '请先前往 www.asmr.one 绑定邮箱';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取已存在的标签ID集合
    final existingTagIds = widget.existingTags.map((tag) => tag.id).toSet();

    return ResponsiveAlertDialog(
      title: const Text('添加标签'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索标签...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 已选择的标签
            if (_selectedTagIds.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '已选择 ${_selectedTagIds.length} 个标签:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _selectedTagIds.map((tagId) {
                  final tag = _allTags.firstWhere((t) => t['id'] == tagId);
                  return Chip(
                    label: Text(
                      tag['name'],
                      style: const TextStyle(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedTagIds.remove(tagId);
                      });
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 标签列表
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: _filteredTags.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('没有找到匹配的标签'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredTags.length,
                        itemBuilder: (context, index) {
                          final tag = _filteredTags[index];
                          final tagId = tag['id'] as int;
                          final tagName = tag['name'] as String;
                          final count = tag['count'] ?? 0;
                          final isExisting = existingTagIds.contains(tagId);
                          final isSelected = _selectedTagIds.contains(tagId);

                          return ListTile(
                            dense: true,
                            enabled: !isExisting,
                            title: Text(
                              tagName,
                              style: TextStyle(
                                fontSize: 13,
                                color: isExisting ? Colors.grey : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isExisting)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.grey[400],
                                    size: 20,
                                  )
                                else
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedTagIds.add(tagId);
                                        } else {
                                          _selectedTagIds.remove(tagId);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            onTap: isExisting
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTagIds.remove(tagId);
                                      } else {
                                        _selectedTagIds.add(tagId);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitTags,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('添加 (${_selectedTagIds.length})'),
        ),
      ],
    );
  }
}
