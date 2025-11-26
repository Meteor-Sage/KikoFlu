import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../services/translation_service.dart';
import '../services/download_service.dart';
import '../utils/snackbar_util.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/tag_chip.dart';
import '../widgets/va_chip.dart';
import '../widgets/circle_chip.dart';
import '../widgets/offline_file_explorer_widget.dart';
import '../widgets/global_audio_player_wrapper.dart';
import '../widgets/download_fab.dart';
import '../utils/string_utils.dart';

/// 离线作品详情页 - 使用下载时保存的元数据展示作品信息
/// 不依赖网络请求，完全离线可用
class OfflineWorkDetailScreen extends ConsumerStatefulWidget {
  final Work work;
  final bool isOffline; // 标记是否为离线模式
  final String? localCoverPath; // 本地封面图片路径

  const OfflineWorkDetailScreen({
    super.key,
    required this.work,
    this.isOffline = true,
    this.localCoverPath,
  });

  @override
  ConsumerState<OfflineWorkDetailScreen> createState() =>
      _OfflineWorkDetailScreenState();
}

class _OfflineWorkDetailScreenState
    extends ConsumerState<OfflineWorkDetailScreen> {
  // 翻译相关状态
  String? _translatedTitle; // 翻译后的标题
  bool _showTranslation = false; // 是否显示翻译
  bool _isTranslating = false; // 是否正在翻译

  // 翻译标题
  Future<void> _translateTitle() async {
    if (_isTranslating) return;

    final work = widget.work;

    // 如果已有翻译，直接切换显示
    if (_translatedTitle != null) {
      setState(() {
        _showTranslation = !_showTranslation;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final translationService = TranslationService();
      final translated =
          await translationService.translate(work.title, sourceLang: 'ja');

      if (mounted) {
        setState(() {
          _translatedTitle = translated;
          _showTranslation = true;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });

        SnackBarUtil.showError(context, '翻译失败: $e');
      }
    }
  }

  // 复制标题到剪贴板
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    SnackBarUtil.showSuccess(
      context,
      '已复制$label: $text',
      duration: const Duration(seconds: 1),
    );
  }

  // 导出作品为ZIP
  Future<void> _exportWork() async {
    try {
      // 显示进度对话框
      if (!mounted) return;
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
                const Text('正在打包作品...'),
              ],
            ),
          ),
        ),
      );

      // 获取作品下载目录
      final downloadService = DownloadService.instance;
      final downloadDir = await downloadService.getDownloadDirectory();
      final workDir = Directory('${downloadDir.path}/${widget.work.id}');

      if (!await workDir.exists()) {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              SnackBarUtil.showError(context, '作品目录不存在');
            }
          });
        }
        return;
      }

      // 创建ZIP压缩包
      final archive = Archive();

      // 递归添加文件到压缩包
      await _addDirectoryToArchive(archive, workDir, workDir.path);

      // 编码为ZIP字节
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        if (mounted) {
          Navigator.of(context).pop();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              SnackBarUtil.showError(context, '打包失败');
            }
          });
        }
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭进度对话框

      // 让用户选择保存位置
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return; // 用户取消

      if (!mounted) return; // 选择目录后再次检查

      // 生成文件名
      final fileName = '${formatRJCode(widget.work.id)}.zip';
      final savePath = path.join(directoryPath, fileName);

      // 写入文件
      final file = File(savePath);
      await file.writeAsBytes(zipBytes);

      if (mounted) {
        // 使用 addPostFrameCallback 确保在正确时机显示提示
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showSuccess(
              context,
              '导出成功：$savePath',
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    } catch (e) {
      // 在 catch 块中也需要安全处理
      if (mounted) {
        // 尝试关闭可能存在的进度对话框
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // 如果对话框已经关闭，忽略错误
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showError(context, '导出失败: $e');
          }
        });
      }
    }
  }

  // 递归添加目录内容到压缩包
  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    await for (final entity in dir.list(recursive: false)) {
      final relativePath = path.relative(entity.path, from: basePath);

      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final file = ArchiveFile(
          relativePath,
          bytes.length,
          bytes,
        );
        archive.addFile(file);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, basePath);
      }
    }
  }

  // 构建网络封面图片（使用缓存）
  Widget _buildNetworkCover(Work work, String host, String token) {
    return CachedNetworkImage(
      imageUrl: '$host/api/cover/${work.id}',
      httpHeaders: {'Authorization': 'Bearer $token'},
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image, size: 64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: GlobalAudioPlayerWrapper(
        child: Scaffold(
          floatingActionButton: const DownloadFab(),
          appBar: ScrollableAppBar(
            systemOverlayStyle: systemOverlayStyle,
            actions: [
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: '导出为ZIP',
                onPressed: _exportWork,
              ),
            ],
            title: GestureDetector(
              onLongPress: () => _copyToClipboard(formatRJCode(widget.work.id), 'RJ号'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatRJCode(widget.work.id),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  if (widget.isOffline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt,
                              size: 12, color: Colors.orange),
                          SizedBox(width: 2),
                          Text(
                            '离线',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final authState = ref.watch(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final work = widget.work;

    // 封面图片组件
    final coverWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Hero(
        tag: 'offline_work_cover_${widget.work.id}',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: isLandscape ? null : double.infinity,
            constraints: BoxConstraints(
              maxHeight:
                  isLandscape ? MediaQuery.of(context).size.height * 0.8 : 500,
              maxWidth: isLandscape
                  ? MediaQuery.of(context).size.width * 0.45
                  : double.infinity,
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // 优先使用本地封面图片
                if (widget.localCoverPath != null &&
                    File(widget.localCoverPath!).existsSync())
                  Image.file(
                    File(widget.localCoverPath!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // 如果本地图片加载失败，回退到网络图片
                      return _buildNetworkCover(work, host, token);
                    },
                  )
                else
                  // 回退到网络图片（缓存）
                  _buildNetworkCover(work, host, token),
              ],
            ),
          ),
        ),
      ),
    );

    // 信息内容组件
    final infoWidget = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题（可长按复制）+ 翻译按钮
          GestureDetector(
            onLongPress: () => _copyToClipboard(
              _showTranslation && _translatedTitle != null
                  ? _translatedTitle!
                  : work.title,
              '标题',
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _showTranslation && _translatedTitle != null
                        ? _translatedTitle
                        : work.title,
                  ),
                  // 翻译按钮
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: MouseRegion(
                        cursor: _isTranslating
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _isTranslating ? null : _translateTitle,
                          child: _isTranslating
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.g_translate,
                                  size: 18,
                                  color: _showTranslation
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
              textAlign: TextAlign.start,
              softWrap: true,
            ),
          ),
          const SizedBox(height: 16),

          // 社团和声优信息
          if ((work.name != null && work.name!.isNotEmpty) ||
              (work.vas != null && work.vas!.isNotEmpty)) ...[
            Text(
              '社团 | 声优',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (work.name != null && work.name!.isNotEmpty)
                  CircleChip(
                    circleId: work.circleId ?? 0,
                    circleName: work.name!,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    borderRadius: 6,
                    fontWeight: FontWeight.w500,
                    onLongPress: () => _copyToClipboard(work.name!, '社团'),
                  ),
                if (work.vas != null)
                  ...work.vas!.map((va) {
                    return VaChip(
                      va: va,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      borderRadius: 6,
                      fontWeight: FontWeight.w500,
                      onLongPress: () => _copyToClipboard(va.name, '声优'),
                    );
                  }).toList(),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 标签信息
          if (work.tags != null && work.tags!.isNotEmpty) ...[
            Text(
              '标签',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: work.tags!
                  .map((tag) => TagChip(
                        tag: tag,
                        fontSize: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        borderRadius: 6,
                        fontWeight: FontWeight.w500,
                        onLongPress: () => _copyToClipboard(tag.name, '标签'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 发布日期
          if (work.release != null) ...[
            Text(
              '发布日期',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              work.release!.split('T')[0],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 16),
          ],

          // 文件浏览器
          OfflineFileExplorerWidget(
            work: work,
            fileTree: work.children != null
                ? work.children!.map((e) {
                    if (e is Map<String, dynamic>) {
                      return e;
                    }
                    // 如果是 AudioFile 对象，转换为 Map
                    return e.toJson();
                  }).toList()
                : null,
          ),
        ],
      ),
    );

    // 根据屏幕方向返回不同布局
    if (isLandscape) {
      // 横屏布局：左右分栏
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：封面
          Expanded(
            flex: 2,
            child: Center(
              child: coverWidget,
            ),
          ),
          // 右侧：信息（可滚动）
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: infoWidget,
            ),
          ),
        ],
      );
    } else {
      // 竖屏布局：上下排列
      return SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            coverWidget,
            infoWidget,
          ],
        ),
      );
    }
  }
}
