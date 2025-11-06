import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/work.dart';
import '../models/audio_track.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/lyric_provider.dart';

class FileExplorerWidget extends ConsumerStatefulWidget {
  final Work work;

  const FileExplorerWidget({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<FileExplorerWidget> createState() => _FileExplorerWidgetState();
}

class _FileExplorerWidgetState extends ConsumerState<FileExplorerWidget> {
  List<dynamic> _currentFiles = [];
  List<List<dynamic>> _navigationHistory = [];
  List<String> _pathHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWorkTree();
  }

  Future<void> _loadWorkTree() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      final files = await apiService.getWorkTracks(widget.work.id);

      // 保存文件列表到全局状态，供歌词查找使用
      ref.read(fileListControllerProvider.notifier).updateFiles(files);

      setState(() {
        _currentFiles = files;
        _navigationHistory.clear(); // 清空导航历史
        _pathHistory.clear(); // 清空路径历史
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载文件失败: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToFolder(dynamic folder) {
    if (folder['children'] != null) {
      setState(() {
        _navigationHistory.add(List.from(_currentFiles));
        _pathHistory.add(folder['title'] ?? folder['name'] ?? '未知');
        _currentFiles = List<dynamic>.from(folder['children']);
      });
    }
  }

  void _navigateBack() {
    if (_navigationHistory.isNotEmpty) {
      setState(() {
        _currentFiles = _navigationHistory.removeLast();
        _pathHistory.removeLast();
      });
    }
  }

  String get _currentPath {
    if (_pathHistory.isEmpty) {
      return '/';
    }
    return '/' + _pathHistory.join('/');
  }

  void _playAudioFile(dynamic audioFile) {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    // Current work cover URL (used as track artwork)
    String? coverUrl;
    if (host.isNotEmpty) {
      String normalizedUrl = host;
      if (!host.startsWith('http://') && !host.startsWith('https://')) {
        normalizedUrl = 'https://$host';
      }
      coverUrl = token.isNotEmpty
          ? '$normalizedUrl/api/cover/${widget.work.id}?token=$token'
          : '$normalizedUrl/api/cover/${widget.work.id}';
    }

    // 获取音频文件信息
    final hash = audioFile['hash'];
    final title = audioFile['title'] ?? audioFile['name'] ?? '未知';

    // 获取当前目录下所有音频文件
    final audioFiles = _getAudioFilesFromCurrentDirectory();
    final currentIndex = audioFiles.indexWhere((file) => file['hash'] == hash);

    if (currentIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法找到音频文件: $title'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 构建播放队列
    final List<AudioTrack> audioTracks = audioFiles
        .map((file) {
          final fileHash = file['hash'];
          final fileTitle = file['title'] ?? file['name'] ?? '未知';

          // 优先使用API返回的mediaStreamUrl，如果没有则构建URL
          String audioUrl = '';
          if (file['mediaStreamUrl'] != null &&
              file['mediaStreamUrl'].toString().isNotEmpty) {
            audioUrl = file['mediaStreamUrl'];
          } else if (host.isNotEmpty && fileHash != null) {
            String normalizedUrl = host;
            if (!host.startsWith('http://') && !host.startsWith('https://')) {
              normalizedUrl = 'https://$host';
            }
            audioUrl = '$normalizedUrl/api/media/stream/$fileHash?token=$token';
          }

          // 获取声优信息
          final vaNames = widget.work.vas?.map((va) => va.name).toList() ?? [];
          final artistInfo = vaNames.isNotEmpty ? vaNames.join(', ') : null;

          return AudioTrack(
            id: fileHash ?? fileTitle,
            url: audioUrl,
            title: fileTitle,
            artist: artistInfo,
            album: widget.work.title,
            artworkUrl: coverUrl,
            duration: file['duration'] != null
                ? Duration(milliseconds: (file['duration'] * 1000).round())
                : null,
            workId: widget.work.id,
            hash: fileHash,
          );
        })
        .where((track) => track.url.isNotEmpty)
        .toList();

    if (audioTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('没有找到可播放的音频文件'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('播放音频: $title');
    print('播放队列包含 ${audioTracks.length} 个文件');

    // 播放音频队列，从当前选择的文件开始
    final adjustedIndex =
        audioTracks.indexWhere((track) => track.id == (hash ?? title));
    final startIndex = adjustedIndex != -1 ? adjustedIndex : 0;

    ref.read(audioPlayerControllerProvider.notifier).playTracks(
          audioTracks,
          startIndex: startIndex,
        );

    // 注意：歌词会通过 lyricAutoLoaderProvider 自动加载
    // 不需要手动调用 loadLyricForTrack

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在播放: $title (${startIndex + 1}/${audioTracks.length})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 获取当前目录下所有音频文件
  List<dynamic> _getAudioFilesFromCurrentDirectory() {
    final List<dynamic> audioFiles = [];

    void extractAudioFiles(List<dynamic> items) {
      for (final item in items) {
        if (item['type'] == 'audio') {
          audioFiles.add(item);
        } else if (item['type'] == 'folder' && item['children'] != null) {
          extractAudioFiles(item['children']);
        }
      }
    }

    if (_currentFiles.isNotEmpty) {
      extractAudioFiles(_currentFiles);
    }

    return audioFiles;
  }

  IconData _getFileIcon(dynamic file) {
    final type = file['type'] ?? '';
    final title = file['title'] ?? file['name'] ?? '';

    if (type == 'folder') {
      return Icons.folder;
    } else if (type == 'audio') {
      if (title.toLowerCase().endsWith('.mp4')) {
        return Icons.video_library;
      }
      return Icons.audiotrack;
    } else if (type == 'image' || _isImageFile(file)) {
      return Icons.image;
    } else if (type == 'text' || _isTextFile(file)) {
      return Icons.text_snippet;
    } else if (type == 'pdf' || _isPdfFile(file)) {
      return Icons.picture_as_pdf;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(dynamic file) {
    final type = file['type'] ?? '';

    if (type == 'folder') {
      return Colors.amber;
    } else if (type == 'audio') {
      return Colors.green;
    } else if (type == 'image' || _isImageFile(file)) {
      return Colors.blue;
    } else if (type == 'text' || _isTextFile(file)) {
      return Colors.grey;
    } else if (type == 'pdf' || _isPdfFile(file)) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  String _getFileTypeText(dynamic file) {
    final type = file['type'] ?? '';
    final children = file['children'];

    if (type == 'folder' && children != null) {
      return '${(children as List).length} 项';
    } else if (_isImageFile(file)) {
      return '图片';
    } else if (_isTextFile(file)) {
      return '文本';
    } else if (_isPdfFile(file)) {
      return 'PDF文档';
    } else if (type.isNotEmpty) {
      return type.toUpperCase();
    }
    return '';
  }

  bool _isImageFile(dynamic file) {
    final type = file['type'] ?? '';
    final title = (file['title'] ?? file['name'] ?? '').toLowerCase();
    return type == 'image' ||
        title.endsWith('.jpg') ||
        title.endsWith('.jpeg') ||
        title.endsWith('.png') ||
        title.endsWith('.gif') ||
        title.endsWith('.bmp') ||
        title.endsWith('.webp');
  }

  bool _isTextFile(dynamic file) {
    final type = file['type'] ?? '';
    final title = (file['title'] ?? file['name'] ?? '').toLowerCase();
    return type == 'text' ||
        title.endsWith('.txt') ||
        title.endsWith('.vtt') ||
        title.endsWith('.srt') ||
        title.endsWith('.md') ||
        title.endsWith('.log') ||
        title.endsWith('.json') ||
        title.endsWith('.xml');
  }

  bool _isPdfFile(dynamic file) {
    final type = file['type'] ?? '';
    final title = (file['title'] ?? file['name'] ?? '').toLowerCase();
    return type == 'pdf' || title.endsWith('.pdf');
  }

  // 判断是否是字幕文件
  bool _isLyricFile(dynamic file) {
    final title = (file['title'] ?? file['name'] ?? '').toLowerCase();
    return title.endsWith('.vtt') ||
        title.endsWith('.srt') ||
        title.endsWith('.lrc') ||
        title.endsWith('.txt');
  }

  // 手动加载字幕
  Future<void> _loadLyricManually(dynamic file) async {
    final title = file['title'] ?? file['name'] ?? '未知文件';

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
      builder: (context) => AlertDialog(
        title: const Text('加载字幕'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要将以下文件加载为当前音频的字幕吗？'),
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

    // 显示加载中
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
      // 调用手动加载字幕方法
      await ref.read(lyricControllerProvider.notifier).loadLyricManually(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('字幕加载成功：$title'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('字幕加载失败：$e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _previewImageFile(dynamic file) {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';

    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法预览图片：缺少必要信息'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String normalizedUrl = host;
    if (!host.startsWith('http://') && !host.startsWith('https://')) {
      normalizedUrl = 'https://$host';
    }

    // 获取当前目录下所有图片文件
    final imageFiles = _getImageFilesFromCurrentDirectory();
    final currentIndex =
        imageFiles.indexWhere((f) => f['hash'] == file['hash']);

    if (currentIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法找到图片文件'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 构建图片URL列表
    final imageItems = imageFiles.map((f) {
      final hash = f['hash'];
      final title = f['title'] ?? f['name'] ?? '未知图片';
      final url = '$normalizedUrl/api/media/stream/$hash?token=$token';
      return <String, String>{'url': url, 'title': title};
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          images: imageItems,
          initialIndex: currentIndex,
        ),
      ),
    );
  }

  // 获取当前目录下所有图片文件
  List<dynamic> _getImageFilesFromCurrentDirectory() {
    final List<dynamic> imageFiles = [];

    void extractImageFiles(List<dynamic> items) {
      for (final item in items) {
        if (_isImageFile(item)) {
          imageFiles.add(item);
        } else if (item['type'] == 'folder' && item['children'] != null) {
          extractImageFiles(item['children']);
        }
      }
    }

    if (_currentFiles.isNotEmpty) {
      extractImageFiles(_currentFiles);
    }

    return imageFiles;
  }

  void _previewTextFile(dynamic file) {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final hash = file['hash'];
    final title = file['title'] ?? file['name'] ?? '未知文本';

    if (hash == null || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法预览文本：缺少必要信息'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String normalizedUrl = host;
    if (!host.startsWith('http://') && !host.startsWith('https://')) {
      normalizedUrl = 'https://$host';
    }
    final textUrl = '$normalizedUrl/api/media/stream/$hash?token=$token';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextPreviewScreen(
          textUrl: textUrl,
          title: title,
        ),
      ),
    );
  }

  void _previewPdfFile(dynamic file) {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final hash = file['hash'];
    final title = file['title'] ?? file['name'] ?? '未知PDF';

    if (hash == null || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法预览PDF：缺少必要信息'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String normalizedUrl = host;
    if (!host.startsWith('http://') && !host.startsWith('https://')) {
      normalizedUrl = 'https://$host';
    }
    final pdfUrl = '$normalizedUrl/api/media/stream/$hash?token=$token';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfUrl: pdfUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 路径导航栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (_navigationHistory.isNotEmpty)
                IconButton(
                  onPressed: _navigateBack,
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 20,
                ),
              Expanded(
                child: Text(
                  _currentPath,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              IconButton(
                onPressed: _loadWorkTree,
                icon: const Icon(Icons.refresh),
                iconSize: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 文件列表
        Expanded(
          child: _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWorkTree,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_currentFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '此文件夹为空',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _currentFiles.length,
      itemBuilder: (context, index) {
        final file = _currentFiles[index];
        final type = file['type'] ?? '';
        final title = file['title'] ?? file['name'] ?? '未知文件';
        final isAudio = type == 'audio';
        final isFolder = type == 'folder';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: ListTile(
            leading: Icon(
              _getFileIcon(file),
              color: _getFileIconColor(file),
              size: 28,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _getFileTypeText(file),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: isAudio
                ? IconButton(
                    onPressed: () => _playAudioFile(file),
                    icon: const Icon(Icons.play_arrow),
                    color: Colors.green,
                  )
                : (_isImageFile(file) || _isTextFile(file) || _isPdfFile(file))
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 如果是字幕文件，显示加载字幕按钮
                          if (_isTextFile(file) && _isLyricFile(file))
                            IconButton(
                              onPressed: () => _loadLyricManually(file),
                              icon: const Icon(Icons.subtitles),
                              color: Colors.orange,
                              tooltip: '加载为字幕',
                            ),
                          // 预览按钮
                          IconButton(
                            onPressed: () {
                              if (_isImageFile(file)) {
                                _previewImageFile(file);
                              } else if (_isPdfFile(file)) {
                                _previewPdfFile(file);
                              } else {
                                _previewTextFile(file);
                              }
                            },
                            icon: const Icon(Icons.visibility),
                            color: Colors.blue,
                            tooltip: '预览',
                          ),
                        ],
                      )
                    : null,
            onTap: () {
              if (isFolder) {
                _navigateToFolder(file);
              } else if (isAudio) {
                _playAudioFile(file);
              } else if (_isImageFile(file)) {
                _previewImageFile(file);
              } else if (_isPdfFile(file)) {
                _previewPdfFile(file);
              } else if (_isTextFile(file)) {
                _previewTextFile(file);
              } else {
                // 其他文件类型的处理
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('暂不支持打开此类型文件: $title'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// Image Gallery Screen with PageView
class ImageGalleryScreen extends StatefulWidget {
  final List<Map<String, String>> images;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformControllers = {};
  bool _isScaled = false;
  int _pointerCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getTransformController(int index) {
    if (!_transformControllers.containsKey(index)) {
      _transformControllers[index] = TransformationController();
    }
    return _transformControllers[index]!;
  }

  // 双击放大/还原
  void _handleDoubleTap(int index) {
    final controller = _getTransformController(index);
    final currentScale = controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      // 已放大，还原到原始大小
      controller.value = Matrix4.identity();
      setState(() {
        _isScaled = false;
      });
    } else {
      // 未放大，放大到2倍
      final newScale = 2.0;
      controller.value = Matrix4.identity()..scale(newScale);
      setState(() {
        _isScaled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_currentIndex + 1}/${widget.images.length} - ${widget.images[_currentIndex]['title']}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('下载功能开发中...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main image viewer
          Expanded(
            child: Listener(
              onPointerDown: (_) {
                setState(() {
                  _pointerCount++;
                });
              },
              onPointerUp: (_) {
                setState(() {
                  _pointerCount--;
                  if (_pointerCount < 0) _pointerCount = 0;
                });
              },
              onPointerCancel: (_) {
                setState(() {
                  _pointerCount--;
                  if (_pointerCount < 0) _pointerCount = 0;
                });
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                // 当有多个手指触摸或图片已放大时，禁用滑动
                physics: _pointerCount > 1 || _isScaled
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final transformController = _getTransformController(index);
                  return GestureDetector(
                    onDoubleTap: () => _handleDoubleTap(index),
                    child: InteractiveViewer(
                      transformationController: transformController,
                      minScale: 0.5,
                      maxScale: 4.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      onInteractionStart: (details) {
                        // 检测是否开始缩放
                        if (details.pointerCount > 1) {
                          setState(() {
                            _isScaled = true;
                          });
                        }
                      },
                      onInteractionUpdate: (details) {
                        // 实时检测缩放状态
                        final scale =
                            transformController.value.getMaxScaleOnAxis();
                        final shouldBeScaled = scale > 1.01;
                        if (_isScaled != shouldBeScaled) {
                          setState(() {
                            _isScaled = shouldBeScaled;
                          });
                        }
                      },
                      onInteractionEnd: (details) {
                        // 交互结束后检查缩放状态
                        final scale =
                            transformController.value.getMaxScaleOnAxis();
                        setState(() {
                          _isScaled = scale > 1.01;
                        });
                      },
                      child: Center(
                        child: Image.network(
                          widget.images[index]['url']!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error,
                                      size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    '加载图片失败\n$error',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Thumbnail strip
          Container(
            height: 100,
            color: Colors.black87,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            widget.images[index]['url']!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                ),
                              );
                            },
                          ),
                        ),
                        // 序号标签
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Text Preview Screen
class TextPreviewScreen extends StatefulWidget {
  final String textUrl;
  final String title;

  const TextPreviewScreen({
    super.key,
    required this.textUrl,
    required this.title,
  });

  @override
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  bool _isLoading = true;
  String? _content;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTextContent();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      setState(() {
        _scrollProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
      });
    }
  }

  Future<void> _loadTextContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        widget.textUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _content = response.data as String;
          _isLoading = false;
        });
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载文本失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('下载功能开发中...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTextContent,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 滚动进度条
        LinearProgressIndicator(
          value: _scrollProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          minHeight: 3,
        ),
        // 文本内容
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _content ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

// PDF 预览屏幕
class PdfPreviewScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _localFilePath;
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    // 删除临时文件
    if (_localFilePath != null) {
      final file = File(_localFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    super.dispose();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      // 下载 PDF 文件到本地
      await dio.download(
        widget.pdfUrl,
        filePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('下载进度: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      setState(() {
        _localFilePath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载PDF失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16),
            ),
            if (_totalPages > 0)
              Text(
                '第 ${_currentPage + 1} 页 / 共 $_totalPages 页',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_localFilePath != null && _totalPages > 1) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage > 0
                  ? () {
                      _pdfViewController?.setPage(_currentPage - 1);
                    }
                  : null,
              tooltip: '上一页',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage < _totalPages - 1
                  ? () {
                      _pdfViewController?.setPage(_currentPage + 1);
                    }
                  : null,
              tooltip: '下一页',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载PDF...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPdf,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localFilePath == null) {
      return const Center(
        child: Text('PDF文件路径无效'),
      );
    }

    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onViewCreated: (PDFViewController controller) {
        _pdfViewController = controller;
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = '渲染PDF失败: $error';
        });
      },
    );
  }
}
