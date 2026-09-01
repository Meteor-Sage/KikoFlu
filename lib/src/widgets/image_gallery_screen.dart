import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/snackbar_util.dart';
import '../utils/local_file_url.dart';
import '../services/storage_service.dart';
import '../../l10n/app_localizations.dart';
import 'cached_image_widget.dart';
import 'confirmation_dialog.dart';

/// 图片画廊屏幕，支持查看、缩放、保存图片
class ImageGalleryScreen extends StatefulWidget {
  final List<Map<String, String>> images;
  final int initialIndex;
  final int? workId;

  const ImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.workId,
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
  bool _isSaving = false;

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

  void _handleDoubleTap(int index) {
    final controller = _getTransformController(index);
    final currentScale = controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      controller.value = Matrix4.identity();
      setState(() => _isScaled = false);
    } else {
      const newScale = 2.0;
      controller.value = Matrix4.identity()
        ..scaleByDouble(newScale, newScale, newScale, 1);
      setState(() => _isScaled = true);
    }
  }

  void _handleTapNavigation(TapDownDetails details) {
    if (_isScaled || _pointerCount > 0) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (tapPosition > screenWidth * 2 / 3) {
      if (_currentIndex < widget.images.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    final l10n = S.of(context);
    setState(() => _isSaving = true);

    try {
      final currentImage = widget.images[_currentIndex];
      final imageUrl = currentImage['url'] ?? '';
      final imageName = currentImage['title'] ?? 'image_${_currentIndex + 1}';

      List<int> imageBytes;

      // 检查是否是本地文件
      final localPath = LocalFileUrl.pathFromUrl(imageUrl);
      if (localPath != null) {
        final localFile = File(localPath);
        imageBytes = await localFile.readAsBytes();
      } else {
        // 网络图片，使用 Dio 下载
        final response = await Dio().get(
          imageUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: StorageService.serverCookieHeaders,
          ),
        );
        imageBytes = response.data as List<int>;
      }

      if (Platform.isAndroid) {
        await _saveToGallery(imageBytes, imageName, l10n);
      } else {
        await _saveToFile(imageBytes, imageName, l10n);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, l10n.saveFailedWithError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveToGallery(
      List<int> imageBytes, String imageName, S l10n) async {
    PermissionStatus status = await Permission.photos.request();

    if (status.isPermanentlyDenied || status == PermissionStatus.restricted) {
      status = await Permission.storage.request();
    }

    if (!mounted) return;

    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        final shouldOpenSettings = await showCommonConfirmationDialog(
          context: context,
          title: l10n.storagePermissionRequired,
          content: Text(l10n.storagePermissionForGalleryDesc),
          confirmLabel: l10n.goToSettings,
          variant: ConfirmationDialogVariant.warning,
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      } else {
        SnackBarUtil.showWarning(
            context, l10n.storagePermissionRequiredForImage);
      }
      return;
    }

    final result = await SaverGallery.saveImage(
      Uint8List.fromList(imageBytes),
      fileName: imageName,
      skipIfExists: false,
      androidRelativePath: "Pictures/KikoFlu",
    );

    if (!mounted) return;

    if (result.isSuccess) {
      SnackBarUtil.showSuccess(context, l10n.imageSavedToGallery);
    } else {
      SnackBarUtil.showError(
          context,
          l10n.saveFailedWithError(
              result.errorMessage ?? l10n.saveImageFailed));
    }
  }

  Future<void> _saveToFile(
      List<int> imageBytes, String imageName, S l10n) async {
    String fileName = imageName;
    if (!fileName.toLowerCase().endsWith('.jpg') &&
        !fileName.toLowerCase().endsWith('.jpeg') &&
        !fileName.toLowerCase().endsWith('.png') &&
        !fileName.toLowerCase().endsWith('.gif')) {
      fileName += '.jpg';
    }

    if (Platform.isIOS) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(path.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(imageBytes);
        if (!mounted) {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          return;
        }

        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: l10n.saveImage,
          fileName: fileName,
          type: FileType.image,
          bytes: Uint8List.fromList(imageBytes),
        );

        if (outputFile != null && mounted) {
          SnackBarUtil.showSuccess(context, l10n.imageSavedToGallery);
        }

        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtil.showError(
              context, l10n.saveFailedWithError(e.toString()));
        }
      }
    } else {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: l10n.saveImage,
        fileName: fileName,
        type: FileType.image,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(imageBytes);

        if (mounted) {
          SnackBarUtil.showSuccess(context, l10n.imageSavedToPath(outputFile));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currentImage = widget.images[_currentIndex];
    final title = currentImage['title'] ?? '';
    final pageLabel = '${_currentIndex + 1}/${widget.images.length}';
    final isSingleImage = widget.images.length == 1;

    final imageArea = _buildImagePageView(isLandscape);

    if (isLandscape) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          elevation: 0,
          foregroundColor: Colors.white,
          title: isSingleImage
              ? (title.isNotEmpty ? Text(title) : null)
              : Text(pageLabel),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _saveImage,
                tooltip: S.of(context).saveImage,
              ),
            if (isLandscape)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: imageArea),
              if (title.isNotEmpty && !isSingleImage)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _buildTitleBadge(title),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: isSingleImage
            ? (title.isNotEmpty
                ? Text(title, style: const TextStyle(fontSize: 16))
                : null)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pageLabel, style: const TextStyle(fontSize: 16)),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _saveImage,
              tooltip: S.of(context).saveImage,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: imageArea),
                if (title.isNotEmpty && !isSingleImage)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: _buildTitleBadge(title),
                  ),
              ],
            ),
          ),
          if (!isSingleImage) _buildThumbnailStrip(),
        ],
      ),
    );
  }

  Widget _buildImagePageView(bool isLandscape) {
    return Listener(
      onPointerDown: (_) => _updatePointerCount(increment: true),
      onPointerUp: (_) => _updatePointerCount(increment: false),
      onPointerCancel: (_) => _resetPointerCount(),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _isScaled = false;
            _pointerCount = 0;
          });
          _resetAllTransformations();
        },
        physics: _isScaled || _pointerCount > 1
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemBuilder: (context, index) {
          final image = widget.images[index];
          final controller = _getTransformController(index);

          return GestureDetector(
            onTapDown: _handleTapNavigation,
            onDoubleTap: () => _handleDoubleTap(index),
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              transformationController: controller,
              minScale: 1.0,
              maxScale: 4.0,
              onInteractionEnd: (_) {
                final maxScale = controller.value.getMaxScaleOnAxis();
                setState(() => _isScaled = maxScale > 1.01);
              },
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: CachedImageWidget(
                  imageUrl: image['url'] ?? '',
                  hash: image['hash'] ?? '',
                  workId: widget.workId,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentIndex;

          return GestureDetector(
            onTap: () => _jumpToImage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedImageWidget(
                  imageUrl: widget.images[index]['url'] ?? '',
                  hash: widget.images[index]['hash'] ?? '',
                  workId: widget.workId,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _jumpToImage(int index) {
    if (index == _currentIndex) return;
    _resetAllTransformations();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _resetAllTransformations() {
    for (final controller in _transformControllers.values) {
      controller.value = Matrix4.identity();
    }
  }

  void _updatePointerCount({required bool increment}) {
    setState(() {
      if (increment) {
        _pointerCount += 1;
      } else {
        _pointerCount = _pointerCount > 0 ? _pointerCount - 1 : 0;
      }
    });
  }

  void _resetPointerCount() {
    if (_pointerCount == 0) return;
    setState(() => _pointerCount = 0);
  }
}
