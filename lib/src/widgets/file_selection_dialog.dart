import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../models/download_task.dart';
import '../models/work.dart';
import '../services/download_file_path_service.dart';
import '../services/download_service.dart';
import '../utils/string_utils.dart';
import '../utils/file_icon_utils.dart';
import '../utils/snackbar_util.dart';
import '../providers/auth_provider.dart';
import 'responsive_dialog.dart';

class FileSelectionDialog extends ConsumerStatefulWidget {
  final Work work;

  const FileSelectionDialog({super.key, required this.work});

  @override
  ConsumerState<FileSelectionDialog> createState() =>
      _FileSelectionDialogState();
}

class _FileSelectionDialogState extends ConsumerState<FileSelectionDialog> {
  final Map<String, bool> _selectedFiles = {}; // hash -> selected
  final Map<String, bool> _downloadedFiles = {}; // hash -> downloaded
  final Map<String, bool> _queuedFiles =
      {}; // hash -> pending/downloading/paused
  final Set<String> _expandedFolders = {}; // 展开的文件夹路径
  bool _isCheckingDownloads = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
    _checkDownloadedFiles();
  }

  void _initializeSelection() {
    void processChildren(List<AudioFile> children) {
      for (final file in children) {
        if (file.type == 'file' && file.hash != null) {
          _selectedFiles[file.hash!] = false;
          _downloadedFiles[file.hash!] = false;
          _queuedFiles[file.hash!] = false;
        }
        if (file.children != null) {
          processChildren(file.children!);
        }
      }
    }

    if (widget.work.children != null) {
      processChildren(widget.work.children!);
    }
  }

  // 检查已下载的文件
  Future<void> _checkDownloadedFiles() async {
    final downloadService = DownloadService.instance;
    final workTasks = await downloadService.getWorkTasks(widget.work.id);
    final queuedHashes = workTasks
        .where(
          (task) =>
              task.hash != null &&
              (task.status == DownloadStatus.pending ||
                  task.status == DownloadStatus.downloading ||
                  task.status == DownloadStatus.paused),
        )
        .map((task) => task.hash!)
        .toSet();

    // 创建副本以避免并发修改错误
    final hashesToCheck = List<String>.from(_downloadedFiles.keys);

    for (final hash in hashesToCheck) {
      final filePath = await downloadService.getDownloadedFilePath(
        widget.work.id,
        hash,
      );
      if (filePath != null) {
        _downloadedFiles[hash] = true;
      } else if (queuedHashes.contains(hash)) {
        _queuedFiles[hash] = true;
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingDownloads = false;
      });
    }
  }

  bool _isUnavailable(String hash) {
    return (_downloadedFiles[hash] ?? false) || (_queuedFiles[hash] ?? false);
  }

  // 生成文件/文件夹的唯一路径
  String _getItemPath(String parentPath, AudioFile item) {
    final title = item.title;
    return parentPath.isEmpty ? title : '$parentPath/$title';
  }

  // 切换文件夹展开/折叠
  void _toggleFolder(String path) {
    setState(() {
      if (_expandedFolders.contains(path)) {
        _expandedFolders.remove(path);
      } else {
        _expandedFolders.add(path);
      }
    });
  }

  // 切换文件选中状态
  void _toggleFile(String hash) {
    setState(() {
      _selectedFiles[hash] = !(_selectedFiles[hash] ?? false);
    });
  }

  // 切换文件夹选中状态（递归）
  void _toggleFolderSelection(String path, bool selected) {
    void selectInChildren(List<AudioFile> items, String parentPath) {
      for (final item in items) {
        final itemPath = _getItemPath(parentPath, item);

        if (item.type == 'file' && item.hash != null) {
          // 只选择未下载的文件
          if (!_isUnavailable(item.hash!)) {
            _selectedFiles[item.hash!] = selected;
          }
        } else if (item.type == 'folder' && item.children != null) {
          selectInChildren(item.children!, itemPath);
        }
      }
    }

    // 找到目标文件夹并递归选择其中的所有文件
    void findAndSelect(List<AudioFile> items, String currentPath) {
      for (final item in items) {
        final itemPath = _getItemPath(currentPath, item);

        if (itemPath == path && item.children != null) {
          selectInChildren(item.children!, itemPath);
          return;
        }

        if (item.type == 'folder' && item.children != null) {
          findAndSelect(item.children!, itemPath);
        }
      }
    }

    setState(() {
      if (widget.work.children != null) {
        findAndSelect(widget.work.children!, '');
      }
    });
  }

  // 全选/取消全选
  void _toggleSelectAll() {
    // 只考虑未下载的文件
    final availableFiles = _selectedFiles.keys
        .where((hash) => !_isUnavailable(hash))
        .toList();

    if (availableFiles.isEmpty) return;

    final allSelected = availableFiles.every(
      (hash) => _selectedFiles[hash] ?? false,
    );
    setState(() {
      for (final hash in availableFiles) {
        _selectedFiles[hash] = !allSelected;
      }
    });
  }

  // 获取文件夹的选中状态（全选/部分选中/未选中）
  bool? _getFolderSelectionState(AudioFile folder) {
    if (folder.children == null || folder.children!.isEmpty) {
      return false;
    }

    int selectedCount = 0;
    int totalCount = 0;

    void countSelection(List<AudioFile> items) {
      for (final item in items) {
        if (item.type == 'file' && item.hash != null) {
          // 排除已下载的文件
          if (!_isUnavailable(item.hash!)) {
            totalCount++;
            if (_selectedFiles[item.hash!] ?? false) {
              selectedCount++;
            }
          }
        }
        if (item.children != null) {
          countSelection(item.children!);
        }
      }
    }

    countSelection(folder.children!);

    if (totalCount == 0) {
      return false; // 文件夹中所有文件都已下载
    } else if (selectedCount == 0) {
      return false;
    } else if (selectedCount == totalCount) {
      return true;
    } else {
      return null; // 部分选中
    }
  }

  // 获取选中的文件及其相对路径
  Map<AudioFile, String> _getSelectedFilesWithPaths() {
    final selected = <AudioFile, String>{};

    void processChildren(List<AudioFile> children, String parentPath) {
      for (final file in children) {
        if (file.type == 'file') {
          if (_selectedFiles[file.hash ?? ''] ?? false) {
            selected[file] = parentPath;
          }
        } else if (file.children != null) {
          // 文件夹，递归处理子项
          final folderPath = parentPath.isEmpty
              ? file.title
              : '$parentPath/${file.title}';
          processChildren(file.children!, folderPath);
        }
      }
    }

    if (widget.work.children != null) {
      processChildren(widget.work.children!, '');
    }

    return selected;
  }

  List<AudioFile> _getSelectedFiles() {
    return _getSelectedFilesWithPaths().keys.toList();
  }

  Future<void> _startDownload() async {
    if (_isSubmitting) return;
    final selectedFilesWithPaths = _getSelectedFilesWithPaths();
    if (selectedFilesWithPaths.isEmpty) {
      if (mounted) {
        SnackBarUtil.showWarning(context, S.of(context).selectAtLeastOneFile);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final downloadService = DownloadService.instance;

    // 获取封面URL
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final coverUrl = widget.work.getCoverImageUrl(host, token: token);

    // 保存作品元数据用于离线预览，包含完整文件树
    final workJson = widget.work.toJson();
    // 保留 children 字段用于离线文件浏览
    final workMetadata = Map<String, dynamic>.from(workJson);
    final children = workMetadata['children'];
    final annotatedChildren = children is List
        ? DownloadFilePathService.annotateFileTreeWithLocalPaths(
            List<dynamic>.from(children),
          )
        : const <dynamic>[];
    if (annotatedChildren.isNotEmpty) {
      workMetadata['children'] = annotatedChildren;
    }
    final localPathsByHash = DownloadFilePathService.localRelativePathsByHash(
      annotatedChildren,
    );

    try {
      for (final entry in selectedFilesWithPaths.entries) {
        final file = entry.key;
        final relativePath = entry.value;

        // 构建完整的文件名（包含路径）
        final fullFileName = relativePath.isEmpty
            ? file.title
            : '$relativePath/${file.title}';
        final localFileName = file.hash != null
            ? localPathsByHash[file.hash!]
            : null;

        // 处理下载 URL
        String downloadUrl = file.mediaDownloadUrl ?? '';
        if (downloadUrl.isNotEmpty) {
          // 如果是相对路径，拼接 Host
          if (downloadUrl.startsWith('/') && host.isNotEmpty) {
            String normalizedHost = host;
            if (!host.startsWith('http://') && !host.startsWith('https://')) {
              if (host.contains('localhost') ||
                  host.startsWith('127.0.0.1') ||
                  host.startsWith('192.168.')) {
                normalizedHost = 'http://$host';
              } else {
                normalizedHost = 'https://$host';
              }
            }
            downloadUrl = '$normalizedHost$downloadUrl';
          }

          // 如果 URL 中没有 token 且 token 存在，追加 token
          if (token.isNotEmpty && !downloadUrl.contains('token=')) {
            if (downloadUrl.contains('?')) {
              downloadUrl = '$downloadUrl&token=$token';
            } else {
              downloadUrl = '$downloadUrl?token=$token';
            }
          }
        } else if (host.isNotEmpty && file.hash != null) {
          // 如果没有 mediaDownloadUrl，尝试构造默认下载链接
          String normalizedHost = host;
          if (!host.startsWith('http://') && !host.startsWith('https://')) {
            if (host.contains('localhost') ||
                host.startsWith('127.0.0.1') ||
                host.startsWith('192.168.')) {
              normalizedHost = 'http://$host';
            } else {
              normalizedHost = 'https://$host';
            }
          }
          downloadUrl =
              '$normalizedHost/api/media/download/${file.hash}/${Uri.encodeComponent(file.title)}?token=$token';
        }

        await downloadService.addTask(
          workId: widget.work.id,
          workTitle: widget.work.title,
          fileName: localFileName ?? fullFileName, // 使用包含路径的本地文件名
          downloadUrl: downloadUrl,
          hash: file.hash,
          totalBytes: file.size,
          workMetadata: workMetadata,
          coverUrl: coverUrl,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtil.showSuccess(
          context,
          S
              .of(context)
              .addedNFilesToDownloadQueue(selectedFilesWithPaths.length),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      // 横屏模式：紧凑布局，最大化文件列表空间
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              leading: const Icon(Icons.download),
              title: widget.work.title,
              subtitle: _isCheckingDownloads
                  ? null
                  : S
                        .of(context)
                        .downloadedAndSelected(
                          _downloadedFiles.values.where((v) => v).length,
                          _selectedFiles.values.where((v) => v).length,
                        ),
              trailing: [
                TextButton.icon(
                  icon: const Icon(Icons.select_all, size: 16),
                  label: Text(S.of(context).selectAll),
                  onPressed: _toggleSelectAll,
                ),
              ],
            ),

            const Divider(height: 1),

            // 文件列表：最大化显示空间
            Flexible(
              child: _isCheckingDownloads
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(S.of(context).checkingDownloadedFiles),
                        ],
                      ),
                    )
                  : widget.work.children == null ||
                        widget.work.children!.isEmpty
                  ? Center(child: Text(S.of(context).noDownloadableFiles))
                  : ListView(
                      children: _buildFileTree(widget.work.children!, 0, ''),
                    ),
            ),
            BottomSheetActionBar(
              secondaryLabel: S.of(context).cancel,
              onSecondaryPressed: () => Navigator.of(context).pop(),
              primaryLabel: S.of(context).downloadN(_getSelectedFiles().length),
              onPrimaryPressed: _isSubmitting
                  ? null
                  : () {
                      _startDownload();
                    },
            ),
          ],
        ),
      );
    }

    // 竖屏模式：保持原有布局
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: 800,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHeader(
            leading: const Icon(Icons.download),
            title: S.of(context).selectFilesToDownload,
            subtitle: widget.work.title,
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.select_all, size: 18),
                  label: Text(S.of(context).selectAll),
                  onPressed: _toggleSelectAll,
                ),
                if (!_isCheckingDownloads)
                  Expanded(
                    child: Text(
                      S
                          .of(context)
                          .downloadedAndSelected(
                            _downloadedFiles.values.where((v) => v).length,
                            _selectedFiles.values.where((v) => v).length,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // File List
          Flexible(
            child: _isCheckingDownloads
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(S.of(context).checkingDownloadedFiles),
                      ],
                    ),
                  )
                : widget.work.children == null || widget.work.children!.isEmpty
                ? Center(child: Text(S.of(context).noDownloadableFiles))
                : ListView(
                    shrinkWrap: true,
                    children: _buildFileTree(widget.work.children!, 0, ''),
                  ),
          ),

          BottomSheetActionBar(
            secondaryLabel: S.of(context).cancel,
            onSecondaryPressed: () => Navigator.of(context).pop(),
            primaryLabel: S.of(context).downloadN(_getSelectedFiles().length),
            onPrimaryPressed: _isSubmitting
                ? null
                : () {
                    _startDownload();
                  },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFileTree(
    List<AudioFile> files,
    int level,
    String parentPath,
  ) {
    final widgets = <Widget>[];
    final theme = Theme.of(context);

    for (final file in files) {
      final itemPath = _getItemPath(parentPath, file);

      if (file.type == 'folder' && file.children != null) {
        final isExpanded = _expandedFolders.contains(itemPath);
        final selectionState = _getFolderSelectionState(file);

        // 文件夹行
        widgets.add(
          InkWell(
            onTap: () => _toggleFolder(itemPath),
            child: Padding(
              padding: EdgeInsets.only(left: 4.0 + (level * 16.0), right: 4.0),
              child: Row(
                children: [
                  // 展开/折叠图标
                  SizedBox(
                    width: 32,
                    height: 40,
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: theme.colorScheme.onSurface.withAlpha(153),
                      size: 20,
                    ),
                  ),
                  // 复选框
                  SizedBox(
                    width: 32,
                    height: 40,
                    child: Checkbox(
                      value: selectionState,
                      tristate: true,
                      onChanged: (value) {
                        _toggleFolderSelection(itemPath, value ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 文件夹图标
                  Icon(
                    FileIconUtils.getFileIcon(file),
                    color: FileIconUtils.getFileIconColor(file),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // 文件夹名称
                  Expanded(
                    child: Text(
                      file.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 如果展开,显示子项
        if (isExpanded) {
          widgets.addAll(_buildFileTree(file.children!, level + 1, itemPath));
        }
      } else if (file.type == 'file') {
        // 文件行
        final hash = file.hash ?? '';
        final isDownloaded = _downloadedFiles[hash] ?? false;
        final isQueued = _queuedFiles[hash] ?? false;
        final isUnavailable = isDownloaded || isQueued;
        final isSelected = _selectedFiles[hash] ?? false;

        widgets.add(
          InkWell(
            onTap: isUnavailable ? null : () => _toggleFile(hash),
            child: Padding(
              padding: EdgeInsets.only(left: 4.0 + (level * 16.0), right: 4.0),
              child: Row(
                children: [
                  // 占位（与文件夹的箭头对齐）
                  const SizedBox(width: 32, height: 40),
                  // 复选框或已下载标识
                  SizedBox(
                    width: 32,
                    height: 40,
                    child: isUnavailable
                        ? Icon(
                            isDownloaded ? Icons.check_circle : Icons.schedule,
                            color: isDownloaded ? Colors.green : Colors.orange,
                            size: 20,
                          )
                        : Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleFile(hash),
                          ),
                  ),
                  const SizedBox(width: 4),
                  // 文件图标
                  Icon(
                    FileIconUtils.getFileIcon(file),
                    color: FileIconUtils.getFileIconColor(file),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // 文件名和大小
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                file.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isUnavailable
                                      ? theme.colorScheme.onSurface.withAlpha(
                                          153,
                                        )
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnavailable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isDownloaded
                                              ? Colors.green
                                              : Colors.orange)
                                          .withAlpha(51),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isDownloaded
                                      ? S.of(context).downloaded
                                      : S.of(context).downloadStatusPending,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDownloaded
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (file.size != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            formatBytes(file.size!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
