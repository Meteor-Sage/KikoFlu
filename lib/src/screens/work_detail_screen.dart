import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/string_utils.dart';

import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../widgets/scrollable_appbar.dart';
import '../services/storage_service.dart';
import '../widgets/file_explorer_widget.dart';
import '../widgets/file_selection_dialog.dart';
import '../widgets/global_audio_player_wrapper.dart';
import '../widgets/tag_chip.dart';
import '../widgets/va_chip.dart';
import '../widgets/circle_chip.dart';
import '../widgets/responsive_dialog.dart';
import '../widgets/work_bookmark_manager.dart';
import '../widgets/review_progress_dialog.dart';
import '../widgets/rating_detail_popup.dart';
import '../services/translation_service.dart';
import '../widgets/download_fab.dart';
import '../providers/work_detail_display_provider.dart';
import '../widgets/privacy_blur_cover.dart';
import '../widgets/work_detail/tag_vote_dialog.dart';
import '../widgets/work_detail/add_tag_dialog.dart';

import '../widgets/cover_preview_dialog.dart';

class WorkDetailScreen extends ConsumerStatefulWidget {
  final Work work;

  const WorkDetailScreen({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends ConsumerState<WorkDetailScreen> {
  Work? _detailedWork;
  String? _errorMessage;
  bool _showHDImage = false; // 控制是否显示高清图片
  ImageProvider? _hdImageProvider; // 预加载的高清图片
  String? _currentProgress; // 当前收藏状态
  int? _currentRating; // 当前评分
  bool _isUpdatingProgress = false; // 是否正在更新状态
  bool _isOpeningFileSelection = false; // iOS上防止快速重复点击造成对话框立即关闭
  bool _isOpeningProgressDialog = false; // 防止标记状态对话框重复快速打开

  // 翻译相关状态
  String? _translatedTitle; // 翻译后的标题
  bool _showTranslation = false; // 是否显示翻译
  bool _isTranslating = false; // 是否正在翻译

  @override
  void initState() {
    super.initState();
    // 初始化收藏状态（从传入的work中获取）
    _currentProgress = widget.work.progress;
    _currentRating = widget.work.userRating;
    _loadWorkDetail();
    // Hero 动画结束后开始预加载高清图
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _preloadHDImage();
      }
    });
  }

  // 预加载高清图片，完全加载后再切换
  Future<void> _preloadHDImage() async {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';

    if (host.isEmpty) return;

    final imageUrl = widget.work.getCoverImageUrl(host, token: token);
    final imageProvider = NetworkImage(imageUrl);

    try {
      // 预加载图片到内存
      await precacheImage(imageProvider, context);
      // 图片完全加载后才切换显示
      if (mounted) {
        setState(() {
          _hdImageProvider = imageProvider;
          _showHDImage = true;
        });
      }
    } catch (e) {
      // 预加载失败，保持使用缓存图片
      debugPrint('HD image preload failed: $e');
    }
  }

  // 翻译标题
  Future<void> _translateTitle() async {
    if (_isTranslating) return;

    final work = _detailedWork ?? widget.work;

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('翻译失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 复制文本到剪贴板并显示提示
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制$label：$text'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 显示标签投票信息
  void _showTagInfo(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => TagVoteDialog(
        tag: tag,
        workId: widget.work.id,
        onVoteChanged: (updatedTag) {
          // 投票成功后更新本地状态
          if (mounted) {
            setState(() {
              // 更新 _detailedWork 中的 tag
              if (_detailedWork != null && _detailedWork!.tags != null) {
                final tagIndex = _detailedWork!.tags!
                    .indexWhere((t) => t.id == updatedTag.id);
                if (tagIndex != -1) {
                  final updatedTags = List<Tag>.from(_detailedWork!.tags!);
                  updatedTags[tagIndex] = updatedTag;
                  _detailedWork = _detailedWork!.copyWith(tags: updatedTags);
                }
              }
            });
          }
        },
        onCopyTag: () => _copyToClipboard(tag.name, '标签'),
      ),
    );
  }

  // 显示添加标签对话框
  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTagDialog(
        workId: widget.work.id,
        existingTags: _detailedWork?.tags ?? widget.work.tags ?? [],
        onTagsAdded: () {
          // 添加成功后刷新作品详情
          _loadWorkDetail();
        },
      ),
    );
  }

  // 在外部浏览器打开原始链接
  Future<void> _openSourceUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // 直接尝试在外部浏览器打开，不依赖 canLaunchUrl 检查
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        // 如果外部应用模式失败，尝试平台默认方式
        final fallbackLaunched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );

        if (!fallbackLaunched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开链接'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开链接失败: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示文件选择对话框
  Future<void> _showFileSelectionDialog() async {
    // 防抖: 避免 iOS 上快速双击导致同一路由被重复创建又立即被关闭
    if (_isOpeningFileSelection) return;
    _isOpeningFileSelection = true;

    final preparedWorkFuture = _prepareWorkForFileSelection();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return FutureBuilder<Work>(
            future: preparedWorkFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ResponsiveAlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在加载文件列表...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return ResponsiveAlertDialog(
                  title: const Text('加载失败'),
                  content: Text('加载文件列表失败: ${snapshot.error}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
                    ),
                  ],
                );
              }

              final work = snapshot.data!;
              return FileSelectionDialog(work: work);
            },
          );
        },
      );
    } finally {
      _isOpeningFileSelection = false;
    }
  }

  Future<Work> _prepareWorkForFileSelection() async {
    final apiService = ref.read(kikoeruApiServiceProvider);
    final files = await apiService.getWorkTracks(widget.work.id);
    final audioFiles = _convertToAudioFiles(files);
    final baseWork = _detailedWork ?? widget.work;
    return _cloneWorkWithChildren(baseWork, audioFiles);
  }

  Work _cloneWorkWithChildren(Work baseWork, List<AudioFile> audioFiles) {
    return Work(
      id: baseWork.id,
      title: baseWork.title,
      circleId: baseWork.circleId,
      name: baseWork.name,
      vas: baseWork.vas,
      tags: baseWork.tags,
      age: baseWork.age,
      release: baseWork.release,
      dlCount: baseWork.dlCount,
      price: baseWork.price,
      reviewCount: baseWork.reviewCount,
      rateCount: baseWork.rateCount,
      rateAverage: baseWork.rateAverage,
      hasSubtitle: baseWork.hasSubtitle,
      duration: baseWork.duration,
      progress: baseWork.progress,
      images: baseWork.images,
      description: baseWork.description,
      children: audioFiles,
      otherLanguageEditions: baseWork.otherLanguageEditions,
    );
  }

  // 将 API 返回的文件列表转换为 AudioFile 对象
  List<AudioFile> _convertToAudioFiles(List<dynamic> files) {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';

    // 标准化 host URL
    String normalizedHost = host;
    if (host.isNotEmpty &&
        !host.startsWith('http://') &&
        !host.startsWith('https://')) {
      normalizedHost = 'https://$host';
    }

    return files.map((file) {
      final type = file['type'] as String?;
      final title = file['title'] as String? ?? file['name'] as String? ?? '';
      final hash = file['hash'] as String?;
      final size = file['size'] as int?;

      // 构建下载 URL
      String? downloadUrl;
      if (file['mediaStreamUrl'] != null &&
          file['mediaStreamUrl'].toString().isNotEmpty) {
        downloadUrl = file['mediaStreamUrl'];
      } else if (normalizedHost.isNotEmpty &&
          hash != null &&
          type != 'folder') {
        downloadUrl = '$normalizedHost/api/media/stream/$hash?token=$token';
      }

      List<AudioFile>? children;
      if (file['children'] != null && file['children'] is List) {
        children = _convertToAudioFiles(file['children'] as List<dynamic>);
      }

      // API 返回的 type 是 'audio' 而不是 'file'
      return AudioFile(
        title: title,
        hash: hash,
        type: type == 'folder' ? 'folder' : 'file', // 将 'audio' 等类型统一转为 'file'
        children: children,
        size: size,
        mediaDownloadUrl: downloadUrl,
      );
    }).toList();
  }

  Future<void> _loadWorkDetail() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final apiService = ref.read(kikoeruApiServiceProvider);
      final response = await apiService.getWork(widget.work.id);
      final detailedWork = Work.fromJson(response);

      if (mounted) {
        setState(() {
          _detailedWork = detailedWork;
          // 更新收藏状态（从API响应中获取最新状态）
          _currentProgress = detailedWork.progress;
          _currentRating = detailedWork.userRating;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
        });
      }
    }
  }

  // 下拉刷新：强制从网络获取最新数据
  Future<void> _refreshWorkDetail() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final apiService = ref.read(kikoeruApiServiceProvider);

      // 先清除缓存，确保获取最新数据
      final prefs = await StorageService.getPrefs();
      await prefs.remove('work_detail_${widget.work.id}');
      await prefs.remove('work_detail_time_${widget.work.id}');

      // 从网络获取最新数据
      final response = await apiService.getWork(widget.work.id);
      final detailedWork = Work.fromJson(response);

      if (mounted) {
        setState(() {
          _detailedWork = detailedWork;
          _currentProgress = detailedWork.progress;
          _currentRating = detailedWork.userRating;
        });

        // 显示刷新成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('刷新成功'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '刷新失败: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示收藏状态选择对话框
  Future<void> _showProgressDialog() async {
    if (_isOpeningProgressDialog) return; // 防抖避免 iOS 双击导致立即关闭
    _isOpeningProgressDialog = true;

    final manager = WorkBookmarkManager(ref: ref, context: context);

    await manager.showMarkDialog(
      workId: widget.work.id,
      currentProgress: _currentProgress,
      currentRating: _currentRating,
      workTitle: widget.work.title,
      onChanged: (newProgress, newRating) {
        // 更新本地状态
        if (mounted) {
          setState(() {
            _currentProgress = newProgress;
            _currentRating = newRating;
            _isUpdatingProgress = false;
          });
        }
      },
    );

    _isOpeningProgressDialog = false;
  }

  // 显示评分详情弹窗
  Future<void> _showRatingDetailDialog(Work work) async {
    if (work.rateCountDetail == null || work.rateCountDetail!.isEmpty) return;
    if (work.rateAverage == null || work.rateCount == null) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: RatingDetailPopup(
          ratingDetails: work.rateCountDetail!,
          averageRating: work.rateAverage!,
          totalCount: work.rateCount!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根据主题亮度设置状态栏图标颜色
    final brightness = Theme.of(context).brightness;
    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.light
          ? Brightness.dark // 浅色模式用深色图标
          : Brightness.light, // 深色模式用浅色图标
      systemNavigationBarColor: Colors.transparent,
    );

    return GlobalAudioPlayerWrapper(
      child: Scaffold(
        floatingActionButton: const DownloadFab(),
        appBar: ScrollableAppBar(
          systemOverlayStyle: systemOverlayStyle,
          // RJ号作为标题,支持长按复制
          title: GestureDetector(
            onLongPress: () =>
                _copyToClipboard(formatRJCode(widget.work.id), 'RJ号'),
            child: Text(
              formatRJCode(widget.work.id),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // 下载按钮
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _showFileSelectionDialog,
              tooltip: '下载',
            ),
            // 收藏状态按钮 - 带图标和文字
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isUpdatingProgress
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _showProgressDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ReviewProgressDialog.getProgressLabel(
                                _currentProgress),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _currentProgress != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            ReviewProgressDialog.getProgressIcon(
                                _currentProgress),
                            size: 22,
                            color: _currentProgress != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final authState = ref.watch(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // 使用已有的work信息（来自列表），详细信息加载后再更新
    final work = _detailedWork ?? widget.work;

    // 封面图片组件
    final coverWidget = GestureDetector(
      onLongPress: () {
        CoverPreviewDialog.show(
          context,
          imageUrl: work.getCoverImageUrl(host, token: token),
          identifier: widget.work.id.toString(),
          heroTag: 'work_cover_${widget.work.id}',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Hero(
          tag: 'work_cover_${widget.work.id}',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: isLandscape ? null : double.infinity,
              constraints: BoxConstraints(
                maxHeight: isLandscape
                    ? MediaQuery.of(context).size.height * 0.8
                    : 500,
                maxWidth: isLandscape
                    ? MediaQuery.of(context).size.width * 0.45
                    : double.infinity,
              ),
              child: PrivacyBlurCover(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    // 底层：缓存图片，始终显示
                    CachedNetworkImage(
                      imageUrl: work.getCoverImageUrl(host, token: token),
                      cacheKey: 'work_cover_${widget.work.id}',
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // 顶层：高清图，加载完成后覆盖
                    if (_showHDImage && _hdImageProvider != null)
                      Image(
                        image: _hdImageProvider!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink(); // 出错时不显示，保持底层缓存图
                        },
                      ),
                    // 字幕标签 - 浮动在右下角
                    if (ref.watch(workDetailDisplayProvider).showSubtitleTag &&
                        work.hasSubtitle == true)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '字幕',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
          // 标题（可长按复制）+ 内联字幕图标（紧跟标题最后一个字，不换行）
          Consumer(
            builder: (context, ref, _) {
              final displaySettings = ref.watch(workDetailDisplayProvider);
              return GestureDetector(
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
                      if (displaySettings.showExternalLinks &&
                          work.sourceUrl != null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _openSourceUrl(work.sourceUrl!),
                                child: Icon(
                                  Icons.open_in_new,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // 翻译按钮
                      if (displaySettings.showTranslateButton)
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.g_translate,
                                        size: 18,
                                        color: _showTranslation
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
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
              );
            },
          ),
          const SizedBox(height: 8),

          // 显示加载状态或错误信息
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadWorkDetail,
                    child: const Text('重试', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // 评分信息 价格和销售信息
          Consumer(
            builder: (context, ref, _) {
              final displaySettings = ref.watch(workDetailDisplayProvider);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // 评分信息 - 根据设置显示
                  if (displaySettings.showRating)
                    MouseRegion(
                      cursor: work.rateCountDetail != null &&
                              work.rateCountDetail!.isNotEmpty
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: () {
                          if (work.rateCountDetail != null &&
                              work.rateCountDetail!.isNotEmpty) {
                            _showRatingDetailDialog(work);
                          }
                        },
                        child: Tooltip(
                          message: work.rateCountDetail != null &&
                                  work.rateCountDetail!.isNotEmpty
                              ? '点击查看评分详情'
                              : '',
                          preferBelow: false,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                (work.rateAverage != null &&
                                        work.rateCount != null &&
                                        (work.rateCount! > 0 ||
                                            work.rateAverage! != 0))
                                    ? work.rateAverage!.toStringAsFixed(1)
                                    : '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 括号内包含数字和感叹号图标
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '(',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${work.rateCount ?? 0}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  // 如果有详情数据，显示信息图标
                                  if (work.rateCountDetail != null &&
                                      work.rateCountDetail!.isNotEmpty)
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                  Text(
                                    ')',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 我的评分 - 仅当有评分时显示
                  if (_currentRating != null)
                    InkWell(
                      onTap: _showProgressDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$_currentRating',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 价格信息
                  if (displaySettings.showPrice && work.price != null)
                    Text(
                      '${work.price} 日元',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),

                  // 时长信息
                  if (displaySettings.showDuration &&
                      work.duration != null &&
                      work.duration! > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(work.duration!),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),

                  // 销售数量信息
                  if (displaySettings.showSales &&
                      work.dlCount != null &&
                      work.dlCount! > 0)
                    Text(
                      '售出：${_formatNumber(work.dlCount!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                    ),
                ],
              );
            },
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

            // 社团和声优放在同一行
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // 社团名称标签
                if (work.name != null &&
                    work.name!.isNotEmpty &&
                    work.circleId != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: CircleChip(
                      circleId: work.circleId!,
                      circleName: work.name!,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      borderRadius: 6,
                      fontWeight: FontWeight.w500,
                      onLongPress: () => _copyToClipboard(work.name!, '社团'),
                    ),
                  ),

                // 声优列表
                if (work.vas != null && work.vas!.isNotEmpty)
                  ...work.vas!.map((va) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: VaChip(
                        va: va,
                        fontSize: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        borderRadius: 6,
                        fontWeight: FontWeight.w500,
                        onLongPress: () => _copyToClipboard(va.name, '声优'),
                      ),
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
              children: [
                ...work.tags!
                    .map((tag) => MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onSecondaryTapDown: (details) {
                              // 桌面端右键支持
                              _showTagInfo(tag);
                            },
                            child: TagChip(
                              tag: tag,
                              fontSize: 12,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              borderRadius: 6,
                              fontWeight: FontWeight.w500,
                              onLongPress: () => _showTagInfo(tag),
                            ),
                          ),
                        ))
                    .toList(),
                // 添加标签按钮
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showAddTagDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            // 如果没有标签，也显示添加按钮
            GestureDetector(
              onTap: _showAddTagDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '添加标签',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 发布日期
          Consumer(
            builder: (context, ref, _) {
              final displaySettings = ref.watch(workDetailDisplayProvider);
              if (!displaySettings.showReleaseDate || work.release == null) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              );
            },
          ),

          // 其他语言版本
          if (work.otherLanguageEditions != null &&
              work.otherLanguageEditions!.isNotEmpty) ...[
            Text(
              '其他版本',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: work.otherLanguageEditions!.map((edition) {
                return InkWell(
                  onTap: () {
                    // 导航到其他语言版本的作品详情页
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkDetailScreen(
                          work: Work(
                            id: edition.id,
                            title: edition.title,
                          ),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '「${edition.lang}」',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 文件浏览器组件 - 移除固定高度，让它自由展开
          FileExplorerWidget(work: work),
        ],
      ),
    );

    // 根据屏幕方向返回不同布局
    if (isLandscape) {
      // 横屏布局：左右分栏 - 左侧封面固定，右侧信息可滚动
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：封面（固定不滚动）
          Expanded(
            flex: 2,
            child: Center(
              child: coverWidget,
            ),
          ),
          // 右侧：信息（可滚动，带下拉刷新）
          Expanded(
            flex: 3,
            child: RefreshIndicator(
              onRefresh: _refreshWorkDetail,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: infoWidget,
              ),
            ),
          ),
        ],
      );
    } else {
      // 竖屏布局：上下排列
      return RefreshIndicator(
        onRefresh: _refreshWorkDetail,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              coverWidget,
              infoWidget,
            ],
          ),
        ),
      );
    }
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toString();
    }
  }

  // 格式化时长(秒 -> 时:分:秒 或 分:秒)
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }
}
