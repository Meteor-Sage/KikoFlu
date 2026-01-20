import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../utils/snackbar_util.dart';

/// 封面预览对话框，支持放大查看和保存图片
class CoverPreviewDialog extends StatefulWidget {
  /// 网络图片URL
  final String? imageUrl;

  /// 本地图片路径
  final String? localPath;

  /// 用于生成保存文件名的标识
  final String? identifier;

  /// Hero标签（用于动画过渡）
  final String? heroTag;

  const CoverPreviewDialog({
    super.key,
    this.imageUrl,
    this.localPath,
    this.identifier,
    this.heroTag,
  }) : assert(imageUrl != null || localPath != null,
            'Either imageUrl or localPath must be provided');

  /// 显示封面预览对话框
  static Future<void> show(
    BuildContext context, {
    String? imageUrl,
    String? localPath,
    String? identifier,
    String? heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return CoverPreviewDialog(
            imageUrl: imageUrl,
            localPath: localPath,
            identifier: identifier,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<CoverPreviewDialog> createState() => _CoverPreviewDialogState();
}

class _CoverPreviewDialogState extends State<CoverPreviewDialog> {
  final TransformationController _transformController =
      TransformationController();
  bool _isSaving = false;
  bool _showControls = true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      _transformController.value = Matrix4.identity();
    } else {
      const newScale = 2.5;
      _transformController.value = Matrix4.identity()..scale(newScale);
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      Uint8List? imageBytes;
      String fileName;

      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        // 本地图片
        imageBytes = await File(widget.localPath!).readAsBytes();
        fileName =
            'cover_${widget.identifier ?? DateTime.now().millisecondsSinceEpoch}.jpg';
      } else if (widget.imageUrl != null) {
        // 网络图片
        final response = await Dio().get<List<int>>(
          widget.imageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        imageBytes = Uint8List.fromList(response.data!);
        fileName =
            'cover_${widget.identifier ?? DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        throw Exception('没有可用的图片');
      }

      // 根据平台选择保存方式
      if (Platform.isAndroid || Platform.isIOS) {
        await _saveToGallery(imageBytes, fileName);
      } else {
        await _saveToFile(imageBytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveToGallery(Uint8List bytes, String fileName) async {
    // 请求权限
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (mounted) {
            SnackBarUtil.showError(context, '需要存储权限才能保存图片');
          }
          return;
        }
      }
    }

    final result = await SaverGallery.saveImage(
      bytes,
      fileName: fileName,
      androidRelativePath: 'Pictures/KikoFlu',
      skipIfExists: false,
    );

    if (mounted) {
      if (result.isSuccess) {
        SnackBarUtil.showSuccess(context, '已保存到相册');
      } else {
        SnackBarUtil.showError(context, '保存失败');
      }
    }
  }

  Future<void> _saveToFile(Uint8List bytes, String fileName) async {
    // 桌面端：让用户选择保存位置
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '保存封面图片',
      fileName: fileName,
      type: FileType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(bytes);
      if (mounted) {
        SnackBarUtil.showSuccess(context, '已保存到: $result');
      }
    }
  }

  Widget _buildImage() {
    Widget imageWidget;

    if (widget.localPath != null && File(widget.localPath!).existsSync()) {
      imageWidget = Image.file(
        File(widget.localPath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          if (widget.imageUrl != null) {
            return CachedNetworkImage(
              imageUrl: widget.imageUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.error,
                color: Colors.white,
                size: 48,
              ),
            );
          }
          return const Icon(
            Icons.error,
            color: Colors.white,
            size: 48,
          );
        },
      );
    } else if (widget.imageUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.error,
          color: Colors.white,
          size: 48,
        ),
      );
    } else {
      imageWidget = const Icon(
        Icons.image_not_supported,
        color: Colors.white,
        size: 48,
      );
    }

    if (widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 图片区域
            Center(
              child: GestureDetector(
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: _buildImage(),
                ),
              ),
            ),

            // 顶部工具栏
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 关闭按钮
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        // 保存按钮
                        IconButton(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_alt, color: Colors.white),
                          onPressed: _isSaving ? null : _saveImage,
                          tooltip: '保存图片',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 底部提示
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      '双击放大 · 双指缩放',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
