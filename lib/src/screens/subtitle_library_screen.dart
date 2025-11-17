import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subtitle_library_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/text_preview_screen.dart';

/// 字幕库界面
class SubtitleLibraryScreen extends ConsumerStatefulWidget {
  const SubtitleLibraryScreen({super.key});

  @override
  ConsumerState<SubtitleLibraryScreen> createState() =>
      _SubtitleLibraryScreenState();
}

class _SubtitleLibraryScreenState extends ConsumerState<SubtitleLibraryScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  String? _errorMessage;
  LibraryStats? _stats;
  final Set<String> _expandedFolders = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedPaths = {}; // 选中的文件/文件夹路径

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPaths.clear();
      }
    });
  }

  void _toggleItemSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPaths.clear();
      _collectAllPaths(_files, _selectedPaths);
    });
  }

  void _collectAllPaths(List<Map<String, dynamic>> items, Set<String> paths) {
    for (final item in items) {
      paths.add(item['path'] as String);
      if (item['type'] == 'folder' && item['children'] != null) {
        _collectAllPaths(item['children'], paths);
      }
    }
  }

  void _deselectAll() {
    setState(() {
      _selectedPaths.clear();
    });
  }

  Future<void> _openSubtitleLibraryFolder() async {
    try {
      final libraryDir =
          await SubtitleLibraryService.getSubtitleLibraryDirectory();
      final path = libraryDir.path;

      if (Platform.isWindows || Platform.isMacOS) {
        final uri = Uri.file(path);
        await launchUrl(uri);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开文件夹失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedPaths.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedPaths.length} 项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int successCount = 0;
    for (final path in _selectedPaths) {
      final success = await SubtitleLibraryService.delete(path);
      if (success) successCount++;
    }

    if (!mounted) return;

    setState(() {
      _isSelectionMode = false;
      _selectedPaths.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 $successCount/${_selectedPaths.length} 项'),
        backgroundColor: successCount > 0 ? Colors.green : Colors.red,
      ),
    );

    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await SubtitleLibraryService.getSubtitleFiles();
      final stats = await SubtitleLibraryService.getStats();

      setState(() {
        _files = files;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importFile() async {
    final result = await SubtitleLibraryService.importSubtitleFile();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );

    if (result.success) {
      _loadFiles();
    }
  }

  Future<void> _importFolder() async {
    final result = await SubtitleLibraryService.importFolder();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );

    if (result.success) {
      _loadFiles();
    }
  }

  Future<void> _importArchive() async {
    final result = await SubtitleLibraryService.importArchive();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );

    if (result.success) {
      _loadFiles();
    }
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('导入字幕文件'),
              subtitle: const Text('支持 .srt, .vtt, .lrc 等字幕格式'),
              onTap: () {
                Navigator.pop(context);
                _importFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('导入文件夹'),
              subtitle: const Text('保留文件夹结构，仅导入字幕文件'),
              onTap: () {
                Navigator.pop(context);
                _importFolder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('导入压缩包'),
              subtitle: const Text('支持无密码 ZIP 压缩包'),
              onTap: () {
                Navigator.pop(context);
                _importArchive();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(Map<String, dynamic> item, String path) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item['type'] == 'text')
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('预览'),
                onTap: () {
                  Navigator.pop(context);
                  _previewFile(path);
                },
              ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('打开'),
              onTap: () {
                Navigator.pop(context);
                _openFile(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('移动到'),
              onTap: () {
                Navigator.pop(context);
                _moveItem(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(context);
                _renameItem(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteItem(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _previewFile(String path) async {
    try {
      if (!mounted) return;

      // 使用 file:// 协议作为本地文件的 URL
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextPreviewScreen(
            title: path.split(Platform.pathSeparator).last,
            textUrl: 'file://$path',
            workId: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('预览失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openFile(String path) async {
    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renameItem(Map<String, dynamic> item) async {
    final controller = TextEditingController(text: item['title']);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == item['title']) {
      return;
    }

    final success = await SubtitleLibraryService.rename(item['path'], newName);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '重命名成功' : '重命名失败'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadFiles();
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
            '确定要删除 "${item['title']}" 吗？${item['type'] == 'folder' ? '\n\n此操作将删除文件夹内的所有内容。' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await SubtitleLibraryService.delete(item['path']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '删除成功' : '删除失败'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadFiles();
    }
  }

  Future<void> _moveItem(Map<String, dynamic> item) async {
    final folders = await SubtitleLibraryService.getAvailableFolders();

    // 如果是移动文件夹，需要过滤掉自身和自身的子文件夹
    final availableFolders = item['type'] == 'folder'
        ? folders.where((folder) {
            final folderPath = folder['path'] as String;
            final itemPath = item['path'] as String;
            return folderPath != itemPath &&
                !folderPath.startsWith('$itemPath${Platform.pathSeparator}');
          }).toList()
        : folders;

    if (!mounted) return;

    final selectedFolder = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableFolders.length,
            itemBuilder: (context, index) {
              final folder = availableFolders[index];
              final name = folder['name'] as String;
              final path = folder['path'] as String;

              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.amber),
                title: Text(name),
                onTap: () => Navigator.pop(context, path),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedFolder == null) return;

    final success =
        await SubtitleLibraryService.move(item['path'], selectedFolder);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '移动成功' : '移动失败'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadFiles();
    }
  }

  void _toggleFolder(String path) {
    setState(() {
      if (_expandedFolders.contains(path)) {
        _expandedFolders.remove(path);
      } else {
        _expandedFolders.add(path);
      }
    });
  }

  List<Widget> _buildFileTree(
      List<Map<String, dynamic>> items, String parentPath,
      {int level = 0}) {
    final children = <Widget>[];

    for (final item in items) {
      final isFolder = item['type'] == 'folder';
      final path = item['path'] as String;
      final isExpanded = _expandedFolders.contains(path);

      children.add(
        InkWell(
          onTap: () {
            if (isFolder) {
              _toggleFolder(path);
            } else {
              _showFileOptions(item, path);
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0 + (level * 20.0),
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                // 展开/折叠箭头（文件夹）或占位符（文件）
                SizedBox(
                  width: 20,
                  child: isFolder
                      ? Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                // 文件/文件夹图标
                SizedBox(
                  width: 24,
                  child: Icon(
                    isFolder
                        ? (isExpanded ? Icons.folder_open : Icons.folder)
                        : Icons.text_snippet,
                    color: isFolder ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // 文件名和大小
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isFolder && item['size'] != null)
                        Text(
                          _formatSize(item['size']),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // 更多选项按钮
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onPressed: () => _showFileOptions(item, path),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      );

      if (isFolder && isExpanded && item['children'] != null) {
        children.addAll(_buildFileTree(
          item['children'],
          path,
          level: level + 1,
        ));
      }
    }

    return children;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听刷新触发器（例如下载路径更改时）
    ref.listen<int>(subtitleLibraryRefreshTriggerProvider, (previous, next) {
      if (previous != next) {
        _loadFiles();
      }
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showImportOptions,
        tooltip: '导入字幕',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 顶部工具栏
          _buildTopBar(),
          // 内容区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFiles,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _files.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.library_books_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '字幕库为空',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击右下角 + 按钮导入字幕',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFiles,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 80),
                              children: [
                                ..._buildFileTree(_files, '', level: 0),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? 24.0 : 8.0;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.5),
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
                    tooltip: '退出选择',
                  ),
                ),
                // 选中数量显示
                Text(
                  '已选择 ${_selectedPaths.length} 项',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                // 统计信息（非选择模式下显示）
                if (_stats != null && !_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_stats!.totalFiles} 个文件 • ${_stats!.sizeFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                // 全选/取消全选按钮
                IconButton(
                  icon: Icon(
                    _selectedPaths.isEmpty ? Icons.select_all : Icons.deselect,
                  ),
                  iconSize: 22,
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: _selectedPaths.isEmpty ? _selectAll : _deselectAll,
                  tooltip: _selectedPaths.isEmpty ? '全选' : '取消全选',
                ),
                // 删除按钮
                if (_selectedPaths.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: _deleteSelectedItems,
                    tooltip: '删除 (${_selectedPaths.length})',
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
                    // 刷新按钮
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('重载'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.5),
                        ),
                        onPressed: _loadFiles,
                      ),
                    ),
                    // 打开文件夹按钮（仅 Windows 和 macOS）
                    if (Platform.isWindows || Platform.isMacOS)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          icon: const Icon(Icons.folder_open, size: 20),
                          label: const Text('打开文件夹'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.5),
                          ),
                          onPressed: _openSubtitleLibraryFolder,
                        ),
                      ),
                    // 统计信息
                    if (_stats != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 4),
                        child: Text(
                          '${_stats!.totalFiles} 个文件 • ${_stats!.sizeFormatted}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    // 帮助图标
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: '字幕库用于存放导入的外部字幕文件',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('字幕库用于存放导入的外部字幕文件'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
