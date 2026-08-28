import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../providers/work_detail_display_provider.dart';
import '../services/translation_service.dart';
import '../services/download_service.dart';
import '../utils/system_ui_style.dart';
import '../utils/snackbar_util.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/offline_file_explorer_widget.dart';
import '../widgets/global_audio_player_wrapper.dart';
import '../widgets/download_fab.dart';
import '../utils/string_utils.dart';
import '../widgets/image_gallery_screen.dart';
import '../widgets/work_detail/work_title_header.dart';
import '../widgets/work_detail/work_metadata_sections.dart';
import '../widgets/work_detail/work_extra_sections.dart';
import '../widgets/work_detail/work_cover_frame.dart';
import '../widgets/work_detail/work_detail_responsive_layout.dart';

/// 离线作品详情页 - 使用下载时保存的元数据展示作品信息
/// 不依赖网络请求，完全离线可用
class OfflineWorkDetailScreen extends ConsumerStatefulWidget {
  final Work work;
  final bool isOffline; // 标记是否为离线模式
  final String? localCoverPath; // 本地封面图片路径
  final String? localCoverRelativePath; // 本地封面相对作品目录路径
  final String? localWorkDirPath; // 本地作品目录路径
  final List<dynamic>? fileTree; // 原始文件树，保留 localRelativePath 等本地字段

  const OfflineWorkDetailScreen({
    super.key,
    required this.work,
    this.isOffline = true,
    this.localCoverPath,
    this.localCoverRelativePath,
    this.localWorkDirPath,
    this.fileTree,
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
      final translated = await translationService.translate(
        work.title,
        sourceLang: 'ja',
      );

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

        SnackBarUtil.showError(
          context,
          S.of(context).translationFailed(e.toString()),
        );
      }
    }
  }

  // 复制标题到剪贴板
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    SnackBarUtil.showSuccess(
      context,
      S.of(context).copiedToClipboard(label, text),
      duration: const Duration(seconds: 1),
    );
  }

  // 导出作品为ZIP
  Future<void> _exportWork() async {
    final l10n = S.of(context);

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
                Text(l10n.packingWork),
              ],
            ),
          ),
        ),
      );

      // 获取作品下载目录
      final downloadService = DownloadService.instance;
      final workDir = widget.localWorkDirPath != null
          ? Directory(widget.localWorkDirPath!)
          : await downloadService.getWorkDirectory(widget.work.id);

      if (!await workDir.exists()) {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              SnackBarUtil.showError(context, l10n.workDirectoryNotExist);
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
              SnackBarUtil.showError(context, l10n.packingFailed);
            }
          });
        }
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭进度对话框

      // 生成文件名
      final fileName = '${formatRJCode(widget.work.id)}.zip';

      if (Platform.isIOS) {
        // iOS: 通过分享面板导出
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(path.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(zipBytes);
        if (!mounted) return;
        try {
          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(tempFile.path)],
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, 80),
          );
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      } else {
        // 其他平台: 选择目录后写入
        final directoryPath = await FilePicker.platform.getDirectoryPath();
        if (directoryPath == null) return;

        if (!mounted) return;

        final savePath = path.join(directoryPath, fileName);
        final file = File(savePath);
        await file.writeAsBytes(zipBytes);

        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showSuccess(
              context,
              l10n.exportSuccess(savePath),
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    } catch (e) {
      // 在 catch 块中也需要安全处理
      if (!mounted) return;

      // 尝试关闭可能存在的进度对话框
      try {
        Navigator.of(context).pop();
      } catch (_) {
        // 如果对话框已经关闭，忽略错误
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackBarUtil.showError(context, l10n.exportFailed(e.toString()));
        }
      });
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
        final file = ArchiveFile(relativePath, bytes.length, bytes);
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
        child: const Center(child: CircularProgressIndicator()),
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
    final systemOverlayStyle = transparentSystemBarsForBrightness(brightness);

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
                tooltip: S.of(context).exportAsZip,
                onPressed: _exportWork,
              ),
            ],
            title: GestureDetector(
              onLongPress: () => _copyToClipboard(
                widget.work.displayId,
                S.of(context).workIdLabel,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.work.displayId,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isOffline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.offline_bolt,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            S.of(context).offlineBadge,
                            style: const TextStyle(
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

    final work = widget.work;

    // 封面图片组件
    final coverUrl = widget.localCoverPath != null
        ? 'file://${widget.localCoverPath}'
        : '$host/api/cover/${work.id}';
    final hasLocalCover =
        widget.localCoverPath != null &&
        File(widget.localCoverPath!).existsSync();
    final displaySettings = ref.watch(workDetailDisplayProvider);

    // 信息内容组件
    final infoWidget = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题（可长按复制）+ 翻译按钮
          WorkTitleHeader(
            title: work.title,
            translatedTitle: _translatedTitle,
            showTranslation: _showTranslation,
            isTranslating: _isTranslating,
            onTranslate: _translateTitle,
            onCopy: (title) =>
                _copyToClipboard(title, S.of(context).titleLabel),
          ),
          const SizedBox(height: 16),

          WorkCreatorChipsSection(work: work, onCopy: _copyToClipboard),

          WorkTagChipsSection(
            tags: work.tags,
            onTagLongPress: (tag) =>
                _copyToClipboard(tag.name, S.of(context).tagLabel),
          ),

          WorkReleaseDateSection(release: work.release),

          // 文件浏览器
          OfflineFileExplorerWidget(
            work: work,
            localWorkDirPath: widget.localWorkDirPath,
            localCoverRelativePath: widget.localCoverRelativePath,
            fileTree:
                widget.fileTree ??
                work.children?.map((e) {
                  if (e is Map<String, dynamic>) {
                    return e;
                  }
                  // 如果是 AudioFile 对象，转换为 Map
                  return e.toJson();
                }).toList(),
          ),
        ],
      ),
    );

    return WorkDetailResponsiveLayout(
      coverBuilder: (context, isLandscape) {
        return WorkCoverFrame(
          heroTag: 'offline_work_cover_${widget.work.id}',
          isLandscape: isLandscape,
          showAgeRating: displaySettings.showAgeRating,
          age: work.age,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageGalleryScreen(
                  images: [
                    {'url': coverUrl, 'title': work.title, 'hash': ''},
                  ],
                  initialIndex: 0,
                ),
              ),
            );
          },
          layers: [
            if (hasLocalCover)
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
        );
      },
      info: infoWidget,
    );
  }
}
