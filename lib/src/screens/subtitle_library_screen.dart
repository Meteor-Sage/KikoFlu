import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subtitle_library_service.dart';
import '../services/subtitle_library_tree.dart';
import '../providers/settings_provider.dart';
import '../widgets/text_preview_screen.dart';
import '../widgets/subtitle_library_content_view.dart';
import '../widgets/subtitle_library_file_list.dart';
import '../widgets/subtitle_library_folder_browser_dialog.dart';
import '../widgets/manual_subtitle_load_flow.dart';
import '../widgets/subtitle_library_guide_dialog.dart';
import '../widgets/subtitle_library_top_bar.dart';
import '../providers/audio_provider.dart';
import '../providers/lyric_provider.dart';
import '../utils/file_icon_utils.dart';
import '../utils/snackbar_util.dart';
import '../utils/subtitle_library_display.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/responsive_dialog.dart';
import '../widgets/floating_feed_toolbar.dart';

/// 字幕库界面
class SubtitleLibraryScreen extends ConsumerStatefulWidget {
  const SubtitleLibraryScreen({
    super.key,
    this.toolbarTop = 8,
    this.collapsedToolbarTop,
    this.primaryToolbarVisible,
  });

  final double toolbarTop;
  final double? collapsedToolbarTop;
  final ValueListenable<bool>? primaryToolbarVisible;

  @override
  ConsumerState<SubtitleLibraryScreen> createState() =>
      _SubtitleLibraryScreenState();
}

class _SubtitleLibraryScreenState extends ConsumerState<SubtitleLibraryScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  String? _errorMessage;
  LibraryStats? _stats;
  bool _isSelectionMode = false;
  final Set<String> _selectedPaths = {}; // 选中的文件/文件夹路径
  StreamSubscription<void>? _cacheUpdateSubscription;

  // 搜索相关
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _currentPath = '';
  String? _rootPath;

  @override
  void initState() {
    super.initState();
    _cacheUpdateSubscription =
        SubtitleLibraryService.onCacheUpdated.listen((_) {
      if (mounted) {
        _loadFiles();
      }
    });
    _initRootPath();
  }

  Future<void> _initRootPath() async {
    final dir = await SubtitleLibraryService.getSubtitleLibraryDirectory();
    if (!mounted) return;
    setState(() {
      _rootPath = dir.path;
      _currentPath = dir.path;
    });
    _loadFiles();
  }

  @override
  void dispose() {
    _cacheUpdateSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
      _selectedPaths.addAll(SubtitleLibraryTree.collectPaths(_files));
    });
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

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final uri = Uri.file(path);
        await launchUrl(uri);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).openFolderFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedPaths.isEmpty) return;

    final selectedPaths = _selectedPaths.toList();
    final totalCount = selectedPaths.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmDelete),
        content: Text(S.of(context).deleteSelectedConfirm(totalCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int successCount = 0;
    for (final path in selectedPaths) {
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
        content:
            Text(S.of(context).deletedNOfTotalItems(successCount, totalCount)),
        backgroundColor: successCount > 0 ? Colors.green : Colors.red,
      ),
    );

    _loadFiles();
  }

  Future<void> _loadFiles({bool forceRefresh = false}) async {
    if (!mounted) return;

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

      if (!mounted) return;

      setState(() {
        _files = files;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = S.of(context).loadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _importFile() async {
    // 显示简单的加载对话框（单文件导入通常很快）
    _showSimpleLoadingDialog(S.of(context).importingSubtitleFile);

    final result = await SubtitleLibraryService.importSubtitleFile();

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (result.success) {
      // 先刷新界面
      await _loadFiles();

      // 等待界面更新完成后再显示提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showSuccess(context, result.message);
          }
        });
      }
    } else {
      if (mounted) {
        SnackBarUtil.showError(context, result.message);
      }
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
    final updateProgress = _showProgressDialog(S.of(context).preparingImport);

    final result = await SubtitleLibraryService.importFolder(
      onProgress: updateProgress,
    );

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (result.success) {
      // 先刷新界面
      await _loadFiles();

      // 等待界面更新完成后再显示提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showSuccess(context, result.message);
          }
        });
      }
    } else {
      if (mounted) {
        SnackBarUtil.showError(context, result.message);
      }
    }
  }

  Future<void> _importArchive() async {
    // 显示动态进度对话框
    final updateProgress = _showProgressDialog(S.of(context).preparingExtract);

    final result = await SubtitleLibraryService.importArchive(
      onProgress: updateProgress,
    );

    if (!mounted) return;

    // 关闭加载对话框
    Navigator.of(context).pop();

    if (result.success) {
      // 先刷新界面
      await _loadFiles();

      // 等待界面更新完成后再显示提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showSuccess(context, result.message);
          }
        });
      }
    } else {
      if (mounted) {
        SnackBarUtil.showError(context, result.message);
      }
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
    showBottomSheetMenu(
      context: context,
      children: [
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(S.of(context).importSubtitleFile),
          subtitle: Text(S.of(context).supportedSubtitleFormats),
          onTap: () {
            Navigator.pop(context);
            _importFile();
          },
        ),
        // iOS 不支持文件夹选择器
        if (!Platform.isIOS)
          ListTile(
            leading: const Icon(Icons.folder),
            title: Text(S.of(context).importFolder),
            subtitle: Text(S.of(context).importFolderDesc),
            onTap: () {
              Navigator.pop(context);
              _importFolder();
            },
          ),
        ListTile(
          leading: const Icon(Icons.archive),
          title: Text(S.of(context).importArchive),
          subtitle: Text(S.of(context).importArchiveDesc),
          onTap: () {
            Navigator.pop(context);
            _importArchive();
          },
        ),
      ],
    );
  }

  void _showLibraryInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => const SubtitleLibraryGuideDialog(),
    );
  }

  void _showFileOptions(Map<String, dynamic> item, String path) {
    showBottomSheetMenu(
      context: context,
      children: [
        if (item['type'] == 'text' &&
            FileIconUtils.isLyricFile(item['title'] ?? ''))
          ListTile(
            leading: const Icon(Icons.subtitles, color: Colors.orange),
            title: Text(S.of(context).loadAsSubtitle),
            onTap: () {
              Navigator.pop(context);
              _loadLyricManually(item);
            },
          ),
        if (item['type'] == 'text')
          ListTile(
            leading: const Icon(Icons.visibility),
            title: Text(S.of(context).preview),
            onTap: () {
              Navigator.pop(context);
              _previewFile(path);
            },
          ),
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: Text(S.of(context).open),
          onTap: () {
            Navigator.pop(context);
            _openFile(path);
          },
        ),
        ListTile(
          leading: const Icon(Icons.drive_file_move),
          title: Text(S.of(context).moveTo),
          onTap: () {
            Navigator.pop(context);
            _moveItem(item);
          },
        ),
        ListTile(
          leading: const Icon(Icons.edit),
          title: Text(S.of(context).rename),
          onTap: () {
            Navigator.pop(context);
            _renameItem(item);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: Text(S.of(context).delete,
              style: const TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            _deleteItem(item);
          },
        ),
      ],
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
          content: Text(S.of(context).previewFailed(e.toString())),
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
          content: Text(S.of(context).openFailed(e.toString())),
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
        title: Text(S.of(context).rename),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: S.of(context).newName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(S.of(context).confirm),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == item['title']) {
      return;
    }

    final success = await SubtitleLibraryService.rename(item['path'], newName);

    if (!mounted) return;

    if (success) {
      // 先刷新界面
      await _loadFiles();

      // 等待界面更新完成后再显示提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).renameSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).renameFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final isFolder = item['type'] == 'folder';
    final title = isFolder
        ? localizedSubtitleFolderTitle(context, item['title'])
        : item['title'];
    final content = isFolder
        ? '${S.of(context).deleteItemConfirm(title)}\n\n${S.of(context).deleteFolderContentsWarning}'
        : S.of(context).deleteItemConfirm(title);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmDelete),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await SubtitleLibraryService.delete(item['path']);

    if (!mounted) return;

    if (success) {
      // 先刷新界面
      await _loadFiles();

      // 等待界面更新完成后再显示提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).deleteSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).deleteFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 手动加载字幕
  Future<void> _loadLyricManually(Map<String, dynamic> item) async {
    final title = (item['title'] ?? S.of(context).unknownFile).toString();
    final path = item['path'] as String;

    // 检查当前是否有播放中的音频
    final currentTrackAsync = ref.read(currentTrackProvider);
    final currentTrack = currentTrackAsync.value;

    await runManualSubtitleLoadFlow(
      context,
      file: path,
      workId: 0,
      subtitleTitle: title,
      currentAudioTitle: currentTrack?.title,
      loadSubtitle: (file, {required workId}) {
        return ref
            .read(lyricControllerProvider.notifier)
            .loadLyricFromLocalFile(file as String);
      },
      isMounted: () => mounted,
      errorDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _moveItem(Map<String, dynamic> item) async {
    final libraryDir =
        await SubtitleLibraryService.getSubtitleLibraryDirectory();
    final itemPath = item['path'] as String;

    if (!mounted) return;

    final selectedFolder = await showDialog<String>(
      context: context,
      builder: (context) => SubtitleLibraryFolderBrowserDialog(
        rootPath: libraryDir.path,
        excludePath: item['type'] == 'folder' ? itemPath : null,
      ),
    );

    if (selectedFolder == null) return;

    final success = await SubtitleLibraryService.move(itemPath, selectedFolder);

    if (!mounted) return;

    if (success) {
      // 先刷新界面
      await _loadFiles();

      // 等待界面更新完成后再显示提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).moveSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).moveFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterFiles(
      List<Map<String, dynamic>> files, String query) {
    return SubtitleLibraryTree.filterFiles(files, query);
  }

  @override
  Widget build(BuildContext context) {
    // 监听刷新触发器（例如下载路径更改时）
    ref.listen<int>(subtitleLibraryRefreshTriggerProvider, (previous, next) {
      if (previous != next) {
        _loadFiles();
      }
    });

    return PopScope(
      canPop: _currentPath == _rootPath || _currentPath.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateUp();
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showImportOptions,
          tooltip: S.of(context).importSubtitle,
          child: const Icon(Icons.add),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: SubtitleLibraryContentView(
                isLoading: _isLoading,
                empty: _files.isEmpty,
                errorMessage: _errorMessage,
                onRetry: _loadFiles,
                child: SubtitleLibraryFileList(
                  items: _isSearching
                      ? _filterFiles(_files, _searchQuery)
                      : _getCurrentFiles(),
                  selectedPaths: _selectedPaths,
                  selectionMode: _isSelectionMode,
                  recursive: _isSearching,
                  header: Padding(
                    padding: EdgeInsets.only(top: widget.toolbarTop + 60),
                    child: _buildBreadcrumbs(),
                  ),
                  onRefresh: () => _loadFiles(forceRefresh: true),
                  onSelectionToggle: _toggleItemSelection,
                  onFolderTap: _navigateTo,
                  onPreviewFile: _previewFile,
                  onLoadSubtitle: _loadLyricManually,
                  onShowOptions: _showFileOptions,
                ),
              ),
            ),
            if (widget.primaryToolbarVisible == null)
              Positioned(
                top: widget.toolbarTop,
                left: FloatingToolbarLayout.horizontalPadding(context),
                right: FloatingToolbarLayout.horizontalPadding(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPrimaryToolbar(),
                      ),
                    ),
                    _buildSecondaryToolbar(),
                  ],
                ),
              )
            else
              FloatingToolbarPositionFollower(
                primaryToolbarVisible: widget.primaryToolbarVisible!,
                visibleTop: widget.toolbarTop,
                hiddenTop: widget.collapsedToolbarTop ?? widget.toolbarTop,
                left: FloatingToolbarLayout.horizontalPadding(context),
                right: FloatingToolbarLayout.horizontalPadding(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPrimaryToolbar(),
                      ),
                    ),
                    _buildSecondaryToolbar(),
                  ],
                ),
              ),
            if (_rootPath != null && _currentPath == _rootPath)
              Positioned(
                left: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 12,
                child: IgnorePointer(
                  child: Text(
                    _stats == null
                        ? ''
                        : S.of(context).nFilesWithSize(
                              _stats!.totalFiles,
                              _stats!.sizeFormatted,
                            ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.8),
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleItemSelection(
      String path, bool isFolder, Map<String, dynamic> item) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (isFolder) {
          _removeChildrenFromSelection(item);
        }
      } else {
        _selectedPaths.add(path);
        if (isFolder) {
          _addChildrenToSelection(item);
        }
      }
    });
  }

  void _addChildrenToSelection(Map<String, dynamic> folder) {
    _selectedPaths.addAll(SubtitleLibraryTree.collectChildPaths(folder));
  }

  void _removeChildrenFromSelection(Map<String, dynamic> folder) {
    _selectedPaths.removeAll(SubtitleLibraryTree.collectChildPaths(folder));
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _selectedPaths.clear();
      _isSelectionMode = false;
    });
  }

  void _navigateUp() {
    if (_rootPath == null || _currentPath == _rootPath) return;
    final parent = Directory(_currentPath).parent;
    // Ensure we don't go above root
    if (parent.path.length < _rootPath!.length) return;

    setState(() {
      _currentPath = parent.path;
      _selectedPaths.clear();
      _isSelectionMode = false;
    });
  }

  List<Map<String, dynamic>> _getCurrentFiles() {
    return SubtitleLibraryTree.currentFiles(
      files: _files,
      currentPath: _currentPath,
      rootPath: _rootPath,
    );
  }

  SubtitleLibraryTopBar _buildTopBar() {
    return SubtitleLibraryTopBar(
      isSelectionMode: _isSelectionMode,
      isSearching: _isSearching,
      selectedCount: _selectedPaths.length,
      searchQuery: _searchQuery,
      searchController: _searchController,
      currentPath: _currentPath,
      rootPath: _rootPath,
      showOpenFolderButton:
          Platform.isWindows || Platform.isMacOS || Platform.isLinux,
      stats: _stats,
      pathSeparator: Platform.pathSeparator,
      onExitSelection: _toggleSelectionMode,
      onSelectAll: _selectAll,
      onDeselectAll: _deselectAll,
      onDeleteSelected: _deleteSelectedItems,
      onRefresh: () => _loadFiles(forceRefresh: true),
      onOpenFolder: _openSubtitleLibraryFolder,
      onStartSearch: () {
        setState(() {
          _isSearching = true;
        });
      },
      onCloseSearch: () {
        setState(() {
          _isSearching = false;
          _searchQuery = '';
          _searchController.clear();
        });
      },
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onClearSearch: () {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
      },
      onStartSelection: _toggleSelectionMode,
      onShowGuide: _showLibraryInfoDialog,
      onNavigateTo: _navigateTo,
    );
  }

  Widget _buildBreadcrumbs() {
    final topBar = _buildTopBar();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.folder_open, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: topBar.buildBreadcrumbs(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryToolbar() {
    if (_isSelectionMode) {
      return FloatingToolbarSurface(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingToolbarIconButton(
              icon: Icons.close,
              tooltip: S.of(context).exitSelection,
              onPressed: _toggleSelectionMode,
            ),
            FloatingToolbarIconButton(
              icon: _selectedPaths.isEmpty ? Icons.select_all : Icons.deselect,
              tooltip: _selectedPaths.isEmpty
                  ? S.of(context).selectAll
                  : S.of(context).deselectAll,
              onPressed: _selectedPaths.isEmpty ? _selectAll : _deselectAll,
            ),
            if (_selectedPaths.isNotEmpty)
              FloatingToolbarIconButton(
                icon: Icons.delete,
                tooltip: S.of(context).delete,
                onPressed: _deleteSelectedItems,
              ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return FloatingToolbarSurface(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingToolbarIconButton(
              icon: Icons.arrow_back,
              tooltip: S.of(context).close,
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: S.of(context).searchSubtitles,
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final canNavigateUp = _rootPath != null && _currentPath != _rootPath;
    return FloatingToolbarSurface(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingToolbarIconButton(
            icon: Icons.arrow_back,
            tooltip: S.of(context).back,
            onPressed: canNavigateUp ? _navigateUp : null,
          ),
          FloatingToolbarIconButton(
            icon: Icons.checklist,
            tooltip: S.of(context).select,
            onPressed: _toggleSelectionMode,
          ),
          FloatingToolbarIconButton(
            icon: Icons.search,
            tooltip: S.of(context).search,
            onPressed: () => setState(() => _isSearching = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryToolbar() {
    return FloatingToolbarSurface(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingToolbarIconButton(
            icon: Icons.refresh,
            tooltip: S.of(context).reload,
            onPressed: () => _loadFiles(forceRefresh: true),
          ),
          FloatingToolbarIconButton(
            icon: Icons.info_outline,
            tooltip: S.of(context).subtitleLibraryGuide,
            onPressed: _showLibraryInfoDialog,
          ),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            FloatingToolbarIconButton(
              icon: Icons.folder_open,
              tooltip: S.of(context).openFolder,
              onPressed: _openSubtitleLibraryFolder,
            ),
        ],
      ),
    );
  }
}
