import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subtitle_library_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/text_preview_screen.dart';
import '../providers/audio_provider.dart';
import '../providers/lyric_provider.dart';
import '../widgets/responsive_dialog.dart';
import '../utils/file_icon_utils.dart';
import '../utils/snackbar_util.dart';

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

  Future<void> _loadFiles({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await SubtitleLibraryService.getSubtitleFiles(
        forceRefresh: forceRefresh,
      );
      final stats = await SubtitleLibraryService.getStats(
        forceRefresh: forceRefresh,
      );

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
    // 显示简单的加载对话框（单文件导入通常很快）
    _showSimpleLoadingDialog('正在导入字幕文件...');

    final result = await SubtitleLibraryService.importSubtitleFile();

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (result.success) {
      SnackBarUtil.showSuccess(context, result.message);
      _loadFiles();
    } else {
      SnackBarUtil.showError(context, result.message);
    }
  }

  void _showSimpleLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFolder() async {
    // 显示动态进度对话框
    final updateProgress = _showProgressDialog('正在准备导入...');

    final result = await SubtitleLibraryService.importFolder(
      onProgress: updateProgress,
    );

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (result.success) {
      SnackBarUtil.showSuccess(context, result.message);
      _loadFiles();
    } else {
      SnackBarUtil.showError(context, result.message);
    }
  }

  Future<void> _importArchive() async {
    // 显示动态进度对话框
    final updateProgress = _showProgressDialog('正在准备解压...');

    final result = await SubtitleLibraryService.importArchive(
      onProgress: updateProgress,
    );

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (result.success) {
      SnackBarUtil.showSuccess(context, result.message);
      _loadFiles();
    } else {
      SnackBarUtil.showError(context, result.message);
    }
  }

  void Function(String)? _showProgressDialog(String initialMessage) {
    final ValueNotifier<String> progressNotifier =
        ValueNotifier(initialMessage);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<String>(
            valueListenable: progressNotifier,
            builder: (context, message, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return (String message) {
      if (mounted) {
        progressNotifier.value = message;
      }
    };
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
            // iOS 不支持文件夹选择器
            if (!Platform.isIOS)
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

  void _showLibraryInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        title: const Text(
          '字幕库使用说明',
          style: TextStyle(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 功能说明
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '字幕库功能',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '用于存放主动导入或保存的文本文件',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 支持的文件类型
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '支持导入的文件类型',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '字幕文件，文件夹，压缩包',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 自动加载标准
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '字幕自动加载',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '播放音频时，系统会自动在字幕库中查找匹配的字幕文件：',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '在"已解析"文件夹下查找对应作品\n支持格式：RJ123456、RJ01003058、BJ123456、VJ123456',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '在"已保存"文件夹下查找单个字幕文件',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '匹配规则：字幕文件名与音频文件名相同\n（去除或保留音频扩展名均可）',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 智能分类
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '4',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '智能分类与标记',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '导入时自动识别 RJ/BJ/VJ 格式文件夹，归类到"已解析"',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '纯数字文件夹自动添加 RJ 前缀（如 123456 → RJ123456）',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '作品详情页音频文件显示 📘 标记表示有字幕库匹配',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 高级功能
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '5',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '高级功能',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '同名文件夹自动合并，同名文件自动替换',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '支持导入嵌套压缩包，自动解压并分类',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '向前兼容：自动迁移根目录旧格式文件夹',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
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
            if (item['type'] == 'text' &&
                FileIconUtils.isLyricFile(item['title'] ?? ''))
              ListTile(
                leading: const Icon(Icons.subtitles, color: Colors.orange),
                title: const Text('载入为字幕'),
                onTap: () {
                  Navigator.pop(context);
                  _loadLyricManually(item);
                },
              ),
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
            onSavedToLibrary: _loadFiles,
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

  // 手动加载字幕
  Future<void> _loadLyricManually(Map<String, dynamic> item) async {
    final title = item['title'] ?? '未知文件';
    final path = item['path'] as String;

    // 检查当前是否有播放中的音频
    final currentTrackAsync = ref.read(currentTrackProvider);
    final currentTrack = currentTrackAsync.value;

    if (currentTrack == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('当前没有播放的音频，无法加载字幕'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 二次确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        title: const Text('加载字幕'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('确定要将以下文件加载为当前音频的字幕吗？'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '字幕文件：',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前音频：',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      currentTrack.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '注意：切换到其他音频时，字幕将自动恢复为默认匹配方式。',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定加载'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 显示加载中提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('正在加载字幕...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // 从本地文件路径加载字幕
      await ref
          .read(lyricControllerProvider.notifier)
          .loadLyricFromLocalFile(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('字幕已加载：$title'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载字幕失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _moveItem(Map<String, dynamic> item) async {
    final libraryDir =
        await SubtitleLibraryService.getSubtitleLibraryDirectory();
    final itemPath = item['path'] as String;

    if (!mounted) return;

    final selectedFolder = await showDialog<String>(
      context: context,
      builder: (context) => _FolderBrowserDialog(
        rootPath: libraryDir.path,
        excludePath: item['type'] == 'folder' ? itemPath : null,
      ),
    );

    if (selectedFolder == null) return;

    final success = await SubtitleLibraryService.move(itemPath, selectedFolder);

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
                // 字幕文件操作按钮
                if (!isFolder && FileIconUtils.isLyricFile(item['title'] ?? ''))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _loadLyricManually(item),
                        icon: const Icon(Icons.subtitles),
                        color: Colors.orange,
                        tooltip: '加载为字幕',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: () => _previewFile(path),
                        icon: const Icon(Icons.visibility),
                        color: Colors.blue,
                        tooltip: '预览',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  )
                else if (isFolder)
                  Text(
                    '${(item['children'] as List?)?.length ?? 0} 项',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                // 更多选项按钮
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onPressed: () => _showFileOptions(item, path),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
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
                            onRefresh: () => _loadFiles(forceRefresh: true),
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
                        onPressed: () => _loadFiles(forceRefresh: true),
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
                      tooltip: '字幕库使用说明',
                      onPressed: _showLibraryInfoDialog,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// 树形文件夹浏览器对话框（懒加载）
class _FolderBrowserDialog extends StatefulWidget {
  final String rootPath;
  final String? excludePath; // 排除的路径（用于移动文件夹时）

  const _FolderBrowserDialog({
    required this.rootPath,
    this.excludePath,
  });

  @override
  State<_FolderBrowserDialog> createState() => _FolderBrowserDialogState();
}

class _FolderBrowserDialogState extends State<_FolderBrowserDialog> {
  final List<String> _pathStack = []; // 当前路径栈
  List<Map<String, dynamic>> _currentFolders = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  String get _currentPath {
    if (_pathStack.isEmpty) {
      return widget.rootPath;
    }
    return _pathStack.last;
  }

  String get _currentDisplayName {
    if (_pathStack.isEmpty) {
      return '根目录';
    }
    final name = _pathStack.last.split(Platform.pathSeparator).last;
    // 限制最多10个字符
    if (name.length > 10) {
      return '${name.substring(0, 10)}...';
    }
    return name;
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);

    try {
      final folders = await SubtitleLibraryService.getSubFolders(_currentPath);

      // 过滤排除的路径
      final filteredFolders = widget.excludePath != null
          ? folders.where((folder) {
              final folderPath = folder['path'] as String;
              return folderPath != widget.excludePath &&
                  !folderPath.startsWith(
                      '${widget.excludePath}${Platform.pathSeparator}');
            }).toList()
          : folders;

      setState(() {
        _currentFolders = filteredFolders;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _navigateToFolder(String folderPath) {
    setState(() {
      _pathStack.add(folderPath);
    });
    _loadFolders();
  }

  void _navigateBack() {
    if (_pathStack.isNotEmpty) {
      setState(() {
        _pathStack.removeLast();
      });
      _loadFolders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (_pathStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _navigateBack,
              tooltip: '返回上级',
            ),
          Expanded(
            child: Text(
              '移动到: $_currentDisplayName',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 子文件夹列表
                  Expanded(
                    child: _currentFolders.isEmpty
                        ? const Center(
                            child: Text(
                              '此目录下没有子文件夹',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _currentFolders.length,
                            itemBuilder: (context, index) {
                              final folder = _currentFolders[index];
                              final name = folder['name'] as String;
                              final path = folder['path'] as String;

                              return ListTile(
                                leading: const Icon(Icons.folder,
                                    color: Colors.amber),
                                title: Text(name),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _navigateToFolder(path),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        Flexible(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: Text(
              _currentDisplayName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => Navigator.pop(context, _currentPath),
          ),
        ),
      ],
    );
  }
}
