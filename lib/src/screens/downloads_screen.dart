import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/download_task.dart';
import '../services/download_service.dart';
import '../utils/string_utils.dart';
import '../utils/ui_tokens.dart';
import '../widgets/virtualized_sliver_collection.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {}; // 选中的任务ID
  final Set<int> _selectedWorkIds = {}; // 选中的作品ID

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTaskIds.clear();
        _selectedWorkIds.clear();
      }
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _toggleWorkSelection(int workId, List<DownloadTask> workTasks) {
    setState(() {
      if (_selectedWorkIds.contains(workId)) {
        // 取消选择整个作品
        _selectedWorkIds.remove(workId);
        for (final task in workTasks) {
          _selectedTaskIds.remove(task.id);
        }
      } else {
        // 选择整个作品
        _selectedWorkIds.add(workId);
        for (final task in workTasks) {
          _selectedTaskIds.add(task.id);
        }
      }
    });
  }

  void _selectAll(List<DownloadTask> tasks) {
    setState(() {
      _selectedTaskIds.clear();
      _selectedWorkIds.clear();
      for (final task in tasks) {
        _selectedTaskIds.add(task.id);
      }
      // 找出所有完整选中的作品
      final Map<int, List<DownloadTask>> groupedTasks = {};
      for (final task in tasks) {
        groupedTasks.putIfAbsent(task.workId, () => []).add(task);
      }
      for (final entry in groupedTasks.entries) {
        _selectedWorkIds.add(entry.key);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedTaskIds.clear();
      _selectedWorkIds.clear();
    });
  }

  Future<void> _pauseSelected() async {
    final taskIds = List<String>.from(_selectedTaskIds);
    if (taskIds.isEmpty) return;
    await DownloadService.instance.pauseTasks(taskIds);
  }

  Future<void> _resumeSelected() async {
    final taskIds = List<String>.from(_selectedTaskIds);
    if (taskIds.isEmpty) return;
    await DownloadService.instance.resumeTasks(taskIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: _isSelectionMode
            ? Text(S.of(context).selectedCount(_selectedTaskIds.length))
            : Text(
                S.of(context).downloadTasks,
                style: UiTextStyles.pageTitle,
              ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    final tasks = DownloadService.instance.tasks;
                    final currentTasks = tasks.where(
                      (t) =>
                          t.status == DownloadStatus.downloading ||
                          t.status == DownloadStatus.paused ||
                          t.status == DownloadStatus.pending ||
                          t.status == DownloadStatus.failed,
                    );
                    _selectAll(currentTasks.toList());
                  },
                  tooltip: S.of(context).selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.deselect),
                  onPressed: _deselectAll,
                  tooltip: S.of(context).deselectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: _selectedTaskIds.isEmpty
                      ? null
                      : () {
                          _pauseSelected();
                        },
                  tooltip: S.of(context).pause,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _selectedTaskIds.isEmpty
                      ? null
                      : () {
                          _resumeSelected();
                        },
                  tooltip: S.of(context).resume,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedTaskIds.isEmpty
                      ? null
                      : () => _confirmBatchDelete(),
                  tooltip: S.of(context).delete,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleSelectionMode,
                  tooltip: S.of(context).select,
                ),
              ],
      ),
      body: StreamBuilder<List<DownloadTask>>(
        stream: DownloadService.instance.tasksStream,
        initialData: DownloadService.instance.tasks,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];

          final downloadingTasks = tasks
              .where(
                (t) =>
                    t.status == DownloadStatus.downloading ||
                    t.status == DownloadStatus.paused ||
                    t.status == DownloadStatus.pending ||
                    t.status == DownloadStatus.failed,
              )
              .toList();

          return _buildDownloadingList(downloadingTasks);
        },
      ),
    );
  }

  Widget _buildDownloadingList(List<DownloadTask> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              S.of(context).noDownloadTasks,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 按作品分组
    final Map<int, List<DownloadTask>> groupedTasks = {};
    for (final task in tasks) {
      groupedTasks.putIfAbsent(task.workId, () => []).add(task);
    }

    final groups = groupedTasks.entries.toList(growable: false);

    return VirtualizedSliverCollection<MapEntry<int, List<DownloadTask>>>(
      items: groups,
      itemId: (entry) => entry.key,
      pageStorageKey: const PageStorageKey('active-downloads-feed'),
      showEndIndicator: false,
      itemBuilder: (context, entry, index) {
        final workId = entry.key;
        final workTasks = entry.value;
        final firstTask = workTasks.first;

        final isWorkSelected = _selectedWorkIds.contains(workId);

        return Card(
          key: ValueKey(workId),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            key: PageStorageKey('download-work-$workId'),
            leading: _isSelectionMode
                ? Checkbox(
                    value: isWorkSelected,
                    onChanged: (_) => _toggleWorkSelection(workId, workTasks),
                  )
                : const Icon(Icons.folder),
            title: Text(
              firstTask.workTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              S.of(context).nFiles(workTasks.length),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _isSelectionMode ? null : const Icon(Icons.expand_more),
            children: workTasks.map((task) => _buildTaskTile(task)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTaskTile(DownloadTask task) {
    final isSelected = _selectedTaskIds.contains(task.id);

    return ListTile(
      key: ValueKey(task.id),
      leading: _isSelectionMode
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleTaskSelection(task.id),
            )
          : _buildStatusIcon(task.status),
      title: Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: _isSelectionMode ? () => _toggleTaskSelection(task.id) : null,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.totalBytes != null && task.totalBytes! > 0) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: task.progress,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatBytes(task.downloadedBytes)} / ${formatBytes(task.totalBytes!)} (${(task.progress * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 11),
            ),
          ],
          if (task.error != null) ...[
            const SizedBox(height: 4),
            Text(
              S.of(context).errorWithMessage(task.error!),
              style: const TextStyle(fontSize: 11, color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: _buildTaskActions(task),
    );
  }

  Widget _buildStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return const Icon(Icons.schedule, color: Colors.grey);
      case DownloadStatus.downloading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DownloadStatus.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange);
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  Widget _buildTaskActions(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () => DownloadService.instance.pauseTask(task.id),
          tooltip: S.of(context).pause,
        );
      case DownloadStatus.paused:
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => DownloadService.instance.resumeTask(task.id),
              tooltip: S.of(context).resume,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(task),
              tooltip: S.of(context).delete,
            ),
          ],
        );
      default:
        return IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _confirmDelete(task),
          tooltip: S.of(context).delete,
        );
    }
  }

  Future<void> _confirmDelete(DownloadTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deletionConfirmTitle),
        content: Text(S.of(context).deleteFileConfirm(task.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DownloadService.instance.deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.of(context).deleted)));
      }
    }
  }

  Future<void> _confirmBatchDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deletionConfirmTitle),
        content: Text(
          S.of(context).deleteSelectedFilesConfirm(_selectedTaskIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final taskIds = List<String>.from(_selectedTaskIds);
      for (final taskId in taskIds) {
        await DownloadService.instance.deleteTask(taskId);
      }

      setState(() {
        _isSelectionMode = false;
        _selectedTaskIds.clear();
        _selectedWorkIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).deletedNFiles(taskIds.length))),
        );
      }
    }
  }
}
