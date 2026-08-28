import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/snackbar_util.dart';
import '../../l10n/app_localizations.dart';

import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../widgets/scrollable_appbar.dart';
import '../services/work_track_file_builder.dart';
import '../utils/system_ui_style.dart';
import '../widgets/file_explorer_widget.dart';
import '../widgets/file_selection_dialog.dart';
import '../widgets/global_audio_player_wrapper.dart';
import '../widgets/responsive_dialog.dart';
import '../widgets/work_bookmark_manager.dart';
import '../widgets/rating_detail_popup.dart';
import '../services/translation_service.dart';
import '../widgets/download_fab.dart';
import '../providers/work_detail_display_provider.dart';
import '../widgets/work_detail/tag_vote_dialog.dart';
import '../widgets/work_detail/add_tag_dialog.dart';
import '../widgets/work_detail/recommendation_section.dart';
import '../widgets/work_detail/work_title_header.dart';
import '../widgets/work_detail/work_metadata_sections.dart';
import '../widgets/work_detail/work_stats_section.dart';
import '../widgets/work_detail/work_extra_sections.dart';
import '../widgets/work_detail/work_cover_frame.dart';
import '../widgets/work_detail/work_detail_responsive_layout.dart';
import '../widgets/work_detail/work_detail_error_banner.dart';
import '../widgets/work_detail/work_progress_action_button.dart';

import '../widgets/image_gallery_screen.dart';

class WorkDetailScreen extends ConsumerStatefulWidget {
  final Work work;
  final String? heroTag;
  final ImageProvider<Object>? initialCoverImageProvider;

  const WorkDetailScreen({
    super.key,
    required this.work,
    this.heroTag,
    this.initialCoverImageProvider,
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
  final FileExplorerController _fileExplorerController =
      FileExplorerController();

  // 翻译相关状态
  String? _translatedTitle; // 翻译后的标题
  bool _showTranslation = false; // 是否显示翻译
  bool _isTranslating = false; // 是否正在翻译

  Future<void> _restoreMiniPlayerAfterModalExit(VoidCallback clearFlag) async {
    // A pushed route's Future completes when pop starts, before its reverse
    // transition leaves the overlay. Keep native glass suppressed until then.
    await Future<void>.delayed(kThemeAnimationDuration);
    if (mounted) {
      setState(clearFlag);
    } else {
      clearFlag();
    }
  }

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

        SnackBarUtil.showError(
          context,
          S.of(context).translationFailed(e.toString()),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  // 复制文本到剪贴板并显示提示
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      SnackBarUtil.showSuccess(
        context,
        S.of(context).copiedToClipboard(label, text),
        duration: const Duration(seconds: 2),
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
        onCopyTag: () => _copyToClipboard(tag.name, S.of(context).tagLabel),
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
          SnackBarUtil.showWarning(
            context,
            S.of(context).cannotOpenLink,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(
          context,
          S.of(context).openLinkFailed(e.toString()),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  // 显示文件选择对话框
  Future<void> _showFileSelectionDialog() async {
    // 防抖: 避免 iOS 上快速双击导致同一路由被重复创建又立即被关闭
    if (_isOpeningFileSelection) return;
    setState(() => _isOpeningFileSelection = true);

    final preparedWorkFuture = _prepareWorkForFileSelection();

    try {
      await showResponsiveBottomSheet<void>(
        context: context,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        builder: (dialogContext) {
          return FutureBuilder<Work>(
            future: preparedWorkFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(S.of(context).loadingFileList),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BottomSheetHeader(
                      title: S.of(context).loadFailed,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(S
                          .of(context)
                          .loadFileListFailed(snapshot.error.toString())),
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
      await _restoreMiniPlayerAfterModalExit(
        () => _isOpeningFileSelection = false,
      );
    }
  }

  Future<Work> _prepareWorkForFileSelection() async {
    final apiService = ref.read(kikoeruApiServiceProvider);
    final files = await apiService.getWorkTracks(widget.work.id);
    final authState = ref.read(authProvider);
    final trackFileBuilder = WorkTrackFileBuilder(
      host: authState.host ?? '',
      token: authState.token ?? '',
    );
    final baseWork = _detailedWork ?? widget.work;
    return trackFileBuilder.withTracks(work: baseWork, files: files);
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
          _errorMessage = S.of(context).loadFailedWithError(e.toString());
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

      // 元数据和文件树都必须绕过缓存，并等待两者完成后再报告刷新成功。
      final refreshResults = await Future.wait<dynamic>([
        apiService.getWork(widget.work.id, forceRefresh: true),
        _fileExplorerController.refresh(forceRefresh: true),
      ]);
      final response = refreshResults.first as Map<String, dynamic>;
      final detailedWork = Work.fromJson(response);

      if (mounted) {
        setState(() {
          _detailedWork = detailedWork;
          _currentProgress = detailedWork.progress;
          _currentRating = detailedWork.userRating;
        });

        // 显示刷新成功提示
        SnackBarUtil.showSuccess(
          context,
          S.of(context).refreshComplete,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = S.of(context).refreshFailed(e.toString());
        });

        SnackBarUtil.showError(
          context,
          S.of(context).refreshFailed(e.toString()),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  // 显示收藏状态选择对话框
  Future<void> _showProgressDialog() async {
    if (_isOpeningProgressDialog) return; // 防抖避免 iOS 双击导致立即关闭
    setState(() => _isOpeningProgressDialog = true);

    final manager = WorkBookmarkManager(ref: ref, context: context);

    try {
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
    } finally {
      await _restoreMiniPlayerAfterModalExit(
        () => _isOpeningProgressDialog = false,
      );
    }
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
    final systemOverlayStyle = transparentSystemBarsForBrightness(brightness);

    return GlobalAudioPlayerWrapper(
      suppressLiquidGlassMiniPlayer:
          _isOpeningFileSelection || _isOpeningProgressDialog,
      child: Scaffold(
        floatingActionButton: const DownloadFab(),
        appBar: ScrollableAppBar(
          systemOverlayStyle: systemOverlayStyle,
          // 作品编号作为标题,支持长按复制
          title: GestureDetector(
            onLongPress: () => _copyToClipboard(
                widget.work.displayId, S.of(context).workIdLabel),
            child: Text(
              widget.work.displayId,
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
              tooltip: S.of(context).download,
            ),
            WorkProgressActionButton(
              progress: _currentProgress,
              isLoading: _isUpdatingProgress,
              onPressed: _showProgressDialog,
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

    // 使用已有的work信息（来自列表），详细信息加载后再更新
    final work = _detailedWork ?? widget.work;

    // 封面图片组件
    final effectiveHeroTag = widget.heroTag ?? 'work_cover_${widget.work.id}';
    final coverUrl = work.getCoverImageUrl(host, token: token);
    final displaySettings = ref.watch(workDetailDisplayProvider);
    final showSubtitleBadge =
        displaySettings.showSubtitleTag && work.hasSubtitle == true;

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
              return WorkTitleHeader(
                title: work.title,
                translatedTitle: _translatedTitle,
                showTranslation: _showTranslation,
                showTranslateButton: displaySettings.showTranslateButton,
                isTranslating: _isTranslating,
                showExternalLink:
                    displaySettings.showExternalLinks && work.sourceUrl != null,
                onTranslate: _translateTitle,
                onOpenExternalLink: work.sourceUrl == null
                    ? null
                    : () => _openSourceUrl(work.sourceUrl!),
                onCopy: (title) => _copyToClipboard(
                  title,
                  S.of(context).titleLabel,
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          WorkDetailErrorBanner(
            message: _errorMessage,
            onRetry: _loadWorkDetail,
          ),

          // 评分信息、价格、时长和销量
          Consumer(
            builder: (context, ref, _) {
              final displaySettings = ref.watch(workDetailDisplayProvider);
              return WorkStatsSection(
                work: work,
                currentRating: _currentRating,
                showRating: displaySettings.showRating,
                showPrice: displaySettings.showPrice,
                showDuration: displaySettings.showDuration,
                showSales: displaySettings.showSales,
                onShowRatingDetails: () => _showRatingDetailDialog(work),
                onShowProgress: _showProgressDialog,
              );
            },
          ),

          const SizedBox(height: 16),

          WorkCreatorChipsSection(
            work: work,
            onCopy: _copyToClipboard,
          ),

          WorkTagChipsSection(
            tags: work.tags,
            onTagLongPress: _showTagInfo,
            onTagSecondaryTap: _showTagInfo,
            onAddTag: _showAddTagDialog,
          ),

          Consumer(
            builder: (context, ref, _) {
              final displaySettings = ref.watch(workDetailDisplayProvider);
              return WorkReleaseDateSection(
                release: work.release,
                visible: displaySettings.showReleaseDate,
              );
            },
          ),

          OtherLanguageEditionsSection(
            editions: work.otherLanguageEditions,
            onEditionSelected: (edition) {
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
          ),

          // 文件浏览器组件 - 移除固定高度，让它自由展开
          FileExplorerWidget(
            work: work,
            controller: _fileExplorerController,
          ),

          // 相关推荐
          RecommendationSection(work: work),
        ],
      ),
    );

    return WorkDetailResponsiveLayout(
      onRefresh: _refreshWorkDetail,
      coverBuilder: (context, isLandscape) {
        return WorkCoverFrame(
          heroTag: effectiveHeroTag,
          isLandscape: isLandscape,
          showSubtitleBadge: showSubtitleBadge,
          showAgeRating: displaySettings.showAgeRating,
          age: work.age,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImageGalleryScreen(
                  images: [
                    {
                      'url': coverUrl,
                      'title': work.title,
                      'hash': '',
                    },
                  ],
                  initialIndex: 0,
                ),
              ),
            );
          },
          layers: [
            CachedNetworkImage(
              imageUrl: coverUrl,
              cacheKey: 'work_cover_${widget.work.id}',
              fit: BoxFit.contain,
              placeholder: (context, url) => _buildCoverPlaceholder(),
              errorWidget: (context, url, error) => _buildCoverPlaceholder(),
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
            ),
            if (_showHDImage && _hdImageProvider != null)
              Image(
                image: _hdImageProvider!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
          ],
        );
      },
      info: infoWidget,
    );
  }

  Widget _buildCoverPlaceholder() {
    final initialCover = widget.initialCoverImageProvider;
    if (initialCover != null) {
      return Image(
        image: initialCover,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildMissingCoverPlaceholder(),
      );
    }
    return _buildMissingCoverPlaceholder();
  }

  Widget _buildMissingCoverPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 300,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        size: 64,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
