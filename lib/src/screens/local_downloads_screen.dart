import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../l10n/app_localizations.dart';
import '../models/download_task.dart';
import '../models/sort_options.dart';
import '../models/work.dart';
import '../services/download_service.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import '../utils/string_utils.dart';
import '../utils/snackbar_util.dart';
import '../utils/scroll_optimization.dart';
import '../providers/auth_provider.dart';
import '../widgets/sort_dialog.dart';
import 'offline_work_detail_screen.dart';
import '../widgets/privacy_blur_cover.dart';
import '../widgets/virtualized_sliver_collection.dart';

final _log = LogService.instance;

/// 本地下载屏幕 - 显示已完成的下载内容
class LocalDownloadsScreen extends ConsumerStatefulWidget {
  const LocalDownloadsScreen({super.key});

  @override
  ConsumerState<LocalDownloadsScreen> createState() =>
      _LocalDownloadsScreenState();
}

class _LocalDownloadsScreenState extends ConsumerState<LocalDownloadsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isSelectionMode = false;
  final Set<int> _selectedWorkIds = {}; // 选中的作品ID
  final VirtualizedCollectionController _collectionController =
      VirtualizedCollectionController();
  int _currentPage = 1;
  static const int _pageSize = 30;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // 排序相关
  SortOrder _sortOrder = SortOrder.downloadDate;
  SortDirection _sortDirection = SortDirection.desc;

  void _showSnackBarSafe(SnackBar snackBar) {
    if (!mounted) return;

    SnackBarUtil.showFromSnackBar(
      context,
      snackBar,
      onError: (error, _) {
        _log.captureOutput('[LocalDownloads] 无法显示 SnackBar: $error');
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _collectionController.scrollToTop(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _scrollToTop();
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages) _goToPage(_currentPage + 1);
  }

  void _previousPage() {
    if (_currentPage > 1) _goToPage(_currentPage - 1);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedWorkIds.clear();
      }
    });
  }

  void _toggleWorkSelection(int workId) {
    setState(() {
      if (_selectedWorkIds.contains(workId)) {
        _selectedWorkIds.remove(workId);
      } else {
        _selectedWorkIds.add(workId);
      }
    });
  }

  void _selectAll(Map<int, List<DownloadTask>> groupedTasks) {
    setState(() {
      _selectedWorkIds.clear();
      _selectedWorkIds.addAll(groupedTasks.keys);
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedWorkIds.clear();
    });
  }

  // 打开本地下载目录
  Future<void> _openDownloadFolder() async {
    try {
      final downloadDir = await DownloadService.instance.getDownloadDirectory();
      final path = downloadDir.path;

      // 检查平台并打开文件夹
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final uri = Uri.file(path);
        final canLaunch = await canLaunchUrl(uri);

        if (canLaunch) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            _showSnackBarSafe(
              SnackBar(
                content: Text(S.of(context).cannotOpenFolder(path)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBarSafe(
          SnackBar(
            content: Text(S.of(context).openFolderFailed(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 刷新元数据
  Future<void> _refreshMetadata() async {
    if (!mounted) return;

    ScaffoldMessengerState? messenger;

    try {
      // 显示加载提示
      if (mounted) {
        try {
          messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(S.of(context).reloadingFromDisk),
                ],
              ),
              duration: const Duration(seconds: 30), // 设置较长时间，手动清除
            ),
          );
        } catch (e) {
          _log.captureOutput('[LocalDownloads] 无法显示加载提示: $e');
        }
      }

      await DownloadService.instance.reloadMetadataFromDisk();

      // 清除加载提示并显示成功消息
      if (!mounted) return;

      Future.microtask(() {
        if (mounted) {
          try {
            // 清除之前的 SnackBar
            ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
            // 显示完成消息
            _showSnackBarSafe(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(S.of(context).refreshComplete),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            _log.captureOutput('[LocalDownloads] 无法显示完成提示: $e');
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      Future.microtask(() {
        if (mounted) {
          try {
            // 清除加载提示
            ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
            // 显示错误消息
            _showSnackBarSafe(
              SnackBar(
                content: Text(S.of(context).refreshFailed(e.toString())),
                duration: const Duration(seconds: 3),
              ),
            );
          } catch (e) {
            _log.captureOutput('[LocalDownloads] 无法显示错误提示: $e');
          }
        }
      });
    }
  }

  // 删除选中的作品
  Future<void> _deleteSelectedWorks(
      Map<int, List<DownloadTask>> groupedTasks) async {
    if (_selectedWorkIds.isEmpty) return;

    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletionConfirmTitle),
        content: Text(l10n.deleteSelectedWorksConfirm(_selectedWorkIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 保存 mounted 状态和 context，避免异步后使用失效的引用
    if (!mounted) return;

    String? errorMessage;
    int successCount = 0;
    int totalCount = 0;

    try {
      for (final workId in _selectedWorkIds) {
        final tasks = groupedTasks[workId] ?? [];
        for (final task in tasks) {
          totalCount++;
          try {
            await DownloadService.instance.deleteTask(task.id);
            successCount++;
          } catch (e) {
            errorMessage ??= l10n.partialDeleteFailed(e.toString());
            _log.captureOutput('[LocalDownloads] 删除任务 ${task.id} 失败: $e');
          }
        }
      }

      // 只在 widget 仍然 mounted 时更新状态
      if (!mounted) return;

      setState(() {
        _isSelectionMode = false;
        _selectedWorkIds.clear();
      });

      // 使用 Future.microtask 延迟到下一帧显示 SnackBar
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            if (errorMessage != null && successCount > 0) {
              _showSnackBarSafe(
                SnackBar(
                    content:
                        Text(l10n.deletedNOfTotal(successCount, totalCount))),
              );
            } else if (errorMessage != null) {
              _showSnackBarSafe(
                SnackBar(content: Text(errorMessage)),
              );
            } else {
              _showSnackBarSafe(
                SnackBar(content: Text(l10n.deleted)),
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            _showSnackBarSafe(
              SnackBar(content: Text(l10n.deleteFailedWithError(e.toString()))),
            );
          }
        });
      }
    }
  }

  // 显示排序对话框
  void _showSortDialog() {
    showDialog(
      context: context,
      barrierDismissible: !Platform.isIOS,
      builder: (context) => CommonSortDialog(
        title: S.of(context).sortOptions,
        currentOption: _sortOrder,
        currentDirection: _sortDirection,
        availableOptions: const [
          SortOrder.downloadDate,
          SortOrder.workId,
        ],
        onSort: (option, direction) {
          setState(() {
            _sortOrder = option;
            _sortDirection = direction;
            _currentPage = 1;
          });
        },
        autoClose: true,
      ),
    );
  }

  // 切换搜索栏可见性
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _currentPage = 1;
      }
    });
  }

  // 过滤作品（根据搜索关键词）
  Map<int, List<DownloadTask>> _filterTasks(
      Map<int, List<DownloadTask>> groupedTasks) {
    if (_searchQuery.isEmpty) return groupedTasks;

    final query = _searchQuery.toLowerCase();
    return Map.fromEntries(
      groupedTasks.entries.where((entry) {
        final workId = entry.key;
        final tasks = entry.value;
        final firstTask = tasks.first;

        // 匹配作品标题
        if (firstTask.workTitle.toLowerCase().contains(query)) return true;

        // 匹配 RJ 号（workId）
        final rjCode = 'RJ${workId.toString().padLeft(6, '0')}';
        if (rjCode.toLowerCase().contains(query)) return true;
        if (workId.toString().contains(query)) return true;

        return false;
      }),
    );
  }

  // 排序作品
  List<int> _sortWorkIds(Map<int, List<DownloadTask>> groupedTasks) {
    final workIds = groupedTasks.keys.toList();

    workIds.sort((a, b) {
      int result;
      switch (_sortOrder) {
        case SortOrder.downloadDate:
          final aDate = groupedTasks[a]!
              .map((t) => t.completedAt ?? t.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          final bDate = groupedTasks[b]!
              .map((t) => t.completedAt ?? t.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          result = aDate.compareTo(bDate);
          break;
        case SortOrder.workId:
          result = a.compareTo(b);
          break;
        default:
          result = 0;
      }
      return _sortDirection == SortDirection.asc ? result : -result;
    });

    return workIds;
  }

  void _openWorkDetail(int workId, DownloadTask task) async {
    _log.captureOutput(
        '[LocalDownloads] 打开作品详情: workId=$workId, task=${task.id}, '
        'file=${task.fileName}, hasMetadata=${task.workMetadata != null}');

    final loadedMetadata = task.workMetadata ??
        await DownloadService.instance.getWorkMetadata(workId);

    if (!mounted) return;

    if (loadedMetadata == null) {
      _log.captureOutput(
        '[LocalDownloads] 错误：任务没有元数据，磁盘恢复也失败: workId=$workId, task=${task.id}',
      );
      _showSnackBarSafe(
        SnackBar(
          content: Text(S.of(context).noWorkMetadataForOffline),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final metadata = _sanitizeMetadata(loadedMetadata);
      final rawChildren = metadata['children'];
      _log.captureOutput(
        '[LocalDownloads] 已获得离线元数据: workId=$workId, '
        'metadataId=${metadata['id']}, sourceId=${metadata['source_id']}, '
        'localDir=${metadata['localWorkDirName']}, '
        'children=${rawChildren is List ? rawChildren.length : 0}',
      );
      final work = Work.fromJson(metadata);

      // 动态构建完整的本地路径
      final workDir = await DownloadService.instance.getWorkDirectory(
        workId,
        metadata: metadata,
      );
      final localCoverPath =
          DownloadService.instance.localCoverPathForMetadata(workDir, metadata);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OfflineWorkDetailScreen(
              work: work,
              isOffline: true,
              localCoverPath: localCoverPath,
              localCoverRelativePath: metadata['localCoverPath'] as String?,
              localWorkDirPath: workDir.path,
              fileTree:
                  rawChildren is List ? List<dynamic>.from(rawChildren) : null,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBarSafe(
          SnackBar(
            content: Text(S.of(context).openWorkDetailFailed(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    try {
      return _deepSanitize(metadata) as Map<String, dynamic>;
    } catch (e) {
      _log.captureOutput('[LocalDownloads] 清理元数据时出错: $e');
      rethrow;
    }
  }

  dynamic _deepSanitize(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return value
          .map((key, val) => MapEntry(key.toString(), _deepSanitize(val)));
    }

    if (value is List) {
      return value.map(_deepSanitize).toList();
    }

    // 处理特殊类型对象 - 直接调用toJson()方法
    if (value.runtimeType.toString() == 'Va' ||
        value.runtimeType.toString() == 'Tag' ||
        value.runtimeType.toString() == 'AudioFile' ||
        value.runtimeType.toString() == 'RatingDetail' ||
        value.runtimeType.toString() == 'OtherLanguageEdition') {
      try {
        // 尝试调用toJson方法
        final json = (value as dynamic).toJson();
        // 递归处理嵌套的children等字段
        return _deepSanitize(json);
      } catch (e) {
        _log.captureOutput('[LocalDownloads] 对象序列化失败 ${value.runtimeType}: $e');
        return null;
      }
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<DownloadTask>>(
      stream: DownloadService.instance.tasksStream,
      initialData: DownloadService.instance.tasks,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final completedTasks =
            tasks.where((t) => t.status == DownloadStatus.completed).toList();

        // 按作品分组
        final Map<int, List<DownloadTask>> allGroupedTasks = {};
        for (final task in completedTasks) {
          allGroupedTasks.putIfAbsent(task.workId, () => []).add(task);
        }

        // 应用搜索过滤
        final groupedTasks = _filterTasks(allGroupedTasks);

        // 应用排序
        final sortedWorkIds = _sortWorkIds(groupedTasks);
        final totalCount = sortedWorkIds.length;
        final totalPages = (totalCount / _pageSize).ceil();
        final currentPage = totalPages == 0 || _currentPage < 1
            ? 1
            : _currentPage > totalPages
                ? totalPages
                : _currentPage;
        final startIndex = (currentPage - 1) * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(0, totalCount);
        final currentPageWorkIds = sortedWorkIds.sublist(startIndex, endIndex);

        return Column(
          children: [
            // 顶部工具栏
            _buildTopBar(allGroupedTasks),
            // 搜索栏
            if (_isSearchVisible) _buildSearchBar(),
            // 内容区域
            Expanded(
              child: VirtualizedSliverCollection<int>(
                collectionController: _collectionController,
                pageStorageKey: const PageStorageKey('local-downloads-feed'),
                items: currentPageWorkIds,
                itemId: (workId) => workId,
                layout: VirtualizedCollectionLayout.grid,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                physics: ScrollOptimization.physics,
                pagination: totalCount == 0
                    ? null
                    : VirtualizedPagination(
                        currentPage: currentPage,
                        pageSize: _pageSize,
                        totalCount: totalCount,
                        hasMore: currentPage < totalPages,
                        isLoading: false,
                        onPreviousPage: _previousPage,
                        onNextPage: () => _nextPage(totalPages),
                        onGoToPage: _goToPage,
                        nextPageOnOverscroll: true,
                        scrollToTop: false,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      ),
                showEndIndicator: false,
                emptyBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        allGroupedTasks.isEmpty
                            ? Icons.download_outlined
                            : Icons.search_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        allGroupedTasks.isEmpty
                            ? S.of(context).noLocalDownloads
                            : S.of(context).noResults,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context, workId, index) {
                  final workTasks = groupedTasks[workId]!;
                  return _buildWorkCard(
                    workId: workId,
                    workTasks: workTasks,
                    firstTask: _preferredMetadataTask(workTasks),
                    isSelected: _selectedWorkIds.contains(workId),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(Map<int, List<DownloadTask>> groupedTasks) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? 24.0 : 8.0;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      child: _isSelectionMode
          ? Row(
              children: [
                // 退出选择按钮
                Padding(
                  padding: EdgeInsets.only(left: horizontalPadding - 8),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: _toggleSelectionMode,
                    tooltip: S.of(context).exitSelection,
                  ),
                ),
                // 选中数量显示
                Text(
                  S.of(context).selectedCount(_selectedWorkIds.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                // 全选/取消全选按钮
                IconButton(
                  icon: Icon(
                    _selectedWorkIds.length == groupedTasks.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  iconSize: 22,
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: _selectedWorkIds.length == groupedTasks.length
                      ? _deselectAll
                      : () => _selectAll(groupedTasks),
                  tooltip: _selectedWorkIds.length == groupedTasks.length
                      ? S.of(context).deselectAll
                      : S.of(context).selectAll,
                ),
                // 删除按钮
                if (_selectedWorkIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () => _deleteSelectedWorks(groupedTasks),
                    tooltip:
                        '${S.of(context).delete} (${_selectedWorkIds.length})',
                    color: Theme.of(context).colorScheme.error,
                  ),
                SizedBox(width: horizontalPadding - 8),
              ],
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 选择按钮
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.checklist, size: 20),
                        label: Text(S.of(context).select),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.5),
                        ),
                        onPressed: _toggleSelectionMode,
                      ),
                    ),
                    // 刷新按钮
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        label: Text(S.of(context).reload),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.5),
                        ),
                        onPressed: _refreshMetadata,
                      ),
                    ),
                    // 打开文件夹按钮（仅 Windows 和 macOS）
                    if (Platform.isWindows ||
                        Platform.isMacOS ||
                        Platform.isLinux)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          icon: const Icon(Icons.folder_open, size: 20),
                          label: Text(S.of(context).openFolder),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                          ),
                          onPressed: _openDownloadFolder,
                        ),
                      ),
                    // 搜索按钮
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          _isSearchVisible ? Icons.search_off : Icons.search,
                          size: 22,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: _toggleSearch,
                        tooltip: S.of(context).search,
                      ),
                    ),
                    // 排序按钮
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(Icons.sort, size: 22),
                        padding: const EdgeInsets.all(8),
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: _showSortDialog,
                        tooltip: S.of(context).sortOptions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  DownloadTask _preferredMetadataTask(List<DownloadTask> tasks) {
    for (final task in tasks) {
      if (task.workMetadata != null) return task;
    }
    return tasks.first;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: S.of(context).searchDownloads,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                  },
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 1;
          });
        },
      ),
    );
  }

  Widget _buildWorkCard({
    required int workId,
    required List<DownloadTask> workTasks,
    required DownloadTask firstTask,
    required bool isSelected,
  }) {
    final authState = ref.watch(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final totalSize = workTasks.fold<int>(
      0,
      (sum, task) => sum + (task.totalBytes ?? 0),
    );

    Work? work;
    if (firstTask.workMetadata != null) {
      try {
        final sanitized = _sanitizeMetadata(firstTask.workMetadata!);
        work = Work.fromJson(sanitized);
      } catch (e) {
        work = null;
      }
    }

    return Card(
      key: ValueKey(workId),
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleWorkSelection(workId)
            : () => _openWorkDetail(workId, firstTask),
        onLongPress: !_isSelectionMode
            ? () {
                setState(() {
                  _isSelectionMode = true;
                  _toggleWorkSelection(workId);
                });
              }
            : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面区域
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCover(workId, work, host, token, firstTask),
                      // 底部渐变遮罩，提升文字可读性
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 信息区域
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        work?.title ?? firstTask.workTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 声优信息
                      if (work?.vas != null && work!.vas!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mic,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  work.vas!.first.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // 文件信息
                      Row(
                        children: [
                          // 文件数量
                          Icon(
                            Icons.folder_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workTasks.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 文件大小
                          Icon(
                            Icons.storage,
                            size: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formatBytes(totalSize),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 选择模式的勾选标记
            if (_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isSelected ? Icons.check : Icons.circle_outlined,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.outline,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(
    int workId,
    Work? work,
    String host,
    String token,
    DownloadTask task,
  ) {
    // 优先使用本地封面
    if (task.workMetadata != null) {
      final relativeCoverPath = task.workMetadata!['localCoverPath'] as String?;
      if (relativeCoverPath != null) {
        return FutureBuilder<Directory>(
          future: DownloadService.instance.getWorkDirectory(
            workId,
            metadata: task.workMetadata,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final localCoverPath = DownloadService.instance
                  .localCoverPathForMetadata(snapshot.data!, task.workMetadata);
              if (localCoverPath != null && File(localCoverPath).existsSync()) {
                return Hero(
                  tag: 'offline_work_cover_$workId',
                  child: PrivacyBlurCover(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(localCoverPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              }
            }
            return _buildPlaceholder();
          },
        );
      }
    }

    final httpHeaders = StorageService.serverCookieHeaders;

    // 降级使用网络封面
    if (work != null && host.isNotEmpty) {
      return Hero(
        tag: 'offline_work_cover_$workId',
        child: PrivacyBlurCover(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: work.getCoverImageUrl(host, token: token),
            httpHeaders: httpHeaders,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _buildPlaceholder(),
          ),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
