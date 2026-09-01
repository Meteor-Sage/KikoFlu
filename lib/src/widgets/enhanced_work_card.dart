import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../providers/work_card_display_provider.dart';
import '../providers/subtitle_library_provider.dart';
import '../services/storage_service.dart';
import '../screens/work_detail_screen.dart';
import '../utils/snackbar_util.dart';
import '../utils/string_utils.dart';
import '../utils/age_rating.dart';
import '../utils/work_cover_prefetch.dart';
import '../../l10n/app_localizations.dart';
import 'tag_chip.dart';
import 'va_chip.dart';
import 'age_rating_chip.dart';
import 'work_bookmark_manager.dart';
import 'privacy_blur_cover.dart';

class EnhancedWorkCard extends ConsumerStatefulWidget {
  final Work work;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final int crossAxisCount;
  final bool? isListLayout;

  const EnhancedWorkCard({
    super.key,
    required this.work,
    this.onTap,
    this.trailingAction,
    this.crossAxisCount = 2,
    this.isListLayout,
  });

  @override
  ConsumerState<EnhancedWorkCard> createState() => _EnhancedWorkCardState();
}

class _EnhancedWorkCardState extends ConsumerState<EnhancedWorkCard> {
  bool get _isListLayout =>
      widget.isListLayout ?? widget.crossAxisCount <= 1;

  String? _progress; // 当前收藏状态
  int? _rating; // 当前评分
  bool _loadingProgress = false; // 是否在获取状态
  bool _updating = false; // 是否在更新状态

  @override
  void initState() {
    super.initState();
    _progress = widget.work.progress; // 初始来自传入的work
    _rating = widget.work.userRating; // 初始评分
  }

  // 长按逻辑：获取最新详情(含 progress)，然后弹出编辑菜单
  Future<void> _onLongPress() async {
    if (_loadingProgress || _updating) return;
    setState(() => _loadingProgress = true);
    try {
      final api = ref.read(kikoeruApiServiceProvider);
      final json = await api.getWork(widget.work.id);
      final detailed = Work.fromJson(json);
      setState(() {
        _progress = detailed.progress; // 更新最新状态
        _rating = detailed.userRating; // 更新评分
        _loadingProgress = false;
      });
      _showEditSheet();
    } catch (e) {
      setState(() => _loadingProgress = false);
      if (mounted) {
        SnackBarUtil.showError(
            context, S.of(context).getStatusFailed(e.toString()));
      }
    }
  }

  // 显示编辑收藏状态对话框
  Future<void> _showEditSheet() async {
    if (_updating) return; // 防止重复操作

    final manager = WorkBookmarkManager(ref: ref, context: context);

    await manager.showMarkDialog(
      workId: widget.work.id,
      currentProgress: _progress,
      currentRating: _rating,
      workTitle: widget.work.title,
      onChanged: (newProgress, newRating) {
        // 更新本地状态
        if (mounted) {
          setState(() {
            _progress = newProgress;
            _rating = newRating;
          });
        }
      },
    );

    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(
      authProvider.select(
        (state) => (host: state.host ?? '', token: state.token ?? ''),
      ),
    );
    final displaySettings = ref.watch(workCardDisplayProvider);
    final hasLocalSubtitle = ref.watch(
      subtitleLibraryProvider.select((ids) => ids.contains(widget.work.id)),
    );
    final coverCacheWidth = resolveWorkCoverCacheWidth(
      context,
      crossAxisCount: widget.crossAxisCount,
      isListCard: _isListLayout,
    );
    final initialCoverImageProvider = auth.host.isEmpty
        ? null
        : createWorkCoverImageProvider(
            work: widget.work,
            host: auth.host,
            token: auth.token,
            cacheWidth: coverCacheWidth,
          );

    final cardOnTap = widget.onTap ??
        () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkDetailScreen(
                work: widget.work,
                initialCoverImageProvider: initialCoverImageProvider,
              ),
            ),
          );
        };

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        // A very narrow grid cell should use the compact content variant even
        // when a responsive fallback reduced a nominal grid to two columns.
        final isNarrowGridCell =
            !_isListLayout && constraints.maxWidth < 160;
        final isCompact = !_isListLayout &&
            (widget.crossAxisCount >= 5 ||
                (widget.crossAxisCount == 3 && !isLandscape) ||
                isNarrowGridCell);

        if (_isListLayout) {
          return _buildFullCard(
            context,
            auth.host,
            auth.token,
            cardOnTap,
            displaySettings,
            hasLocalSubtitle,
            trailingAction: widget.trailingAction,
          );
        }
        if (isCompact) {
          return _buildCompactCard(
            context,
            auth.host,
            auth.token,
            cardOnTap,
            displaySettings,
            hasLocalSubtitle,
            trailingAction: widget.trailingAction,
          );
        }
        return _buildMediumCard(
          context,
          auth.host,
          auth.token,
          cardOnTap,
          displaySettings,
          hasLocalSubtitle,
          trailingAction: widget.trailingAction,
        );
      },
    );
  }

  // 紧凑卡片 (3列布局)
  Widget _buildCompactCard(
    BuildContext context,
    String host,
    String token,
    VoidCallback cardOnTap,
    WorkCardDisplaySettings displaySettings,
    bool hasLocalSubtitle, {
    Widget? trailingAction,
  }) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final titleFontSize =
        displaySettings.scaleFontSize(isLandscape ? 13.5 : 11.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0),
      elevation: 8,
      child: InkWell(
        onTap: cardOnTap,
        onLongPress: _onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 让 Column 高度自适应
          children: [
            // 封面图片区域
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  _buildCoverImage(context, host, token),
                  // 作品编号标签 (左上角)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: _buildRjTag(),
                  ),
                  if (displaySettings.showAgeRating &&
                      AgeRatingFormatter.hasValue(widget.work.age))
                    Positioned(
                      top: 4,
                      right: 4,
                      child: AgeRatingChip(age: widget.work.age, compact: true),
                    ),
                  // 字幕标签 (左下角)
                  if (displaySettings.showSubtitleTag &&
                      (widget.work.hasSubtitle == true || hasLocalSubtitle))
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: _buildSubtitleTag(
                        context,
                        isLocal: hasLocalSubtitle,
                      ),
                    ),
                  // 日期标签 (右下角)
                  if (displaySettings.showReleaseDate &&
                      widget.work.release != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: _buildDateTag(),
                    ),
                ],
              ),
            ),
            // 信息区域 - 自适应高度
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.work.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                fontSize: titleFontSize,
                              ),
                        ),
                      ),
                      if (trailingAction != null) ...[
                        const SizedBox(width: 4),
                        trailingAction,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 中等卡片 (2列布局)
  Widget _buildMediumCard(
    BuildContext context,
    String host,
    String token,
    VoidCallback cardOnTap,
    WorkCardDisplaySettings displaySettings,
    bool hasLocalSubtitle, {
    Widget? trailingAction,
  }) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final titleFontSize =
        displaySettings.scaleFontSize(isLandscape ? 14.5 : 12.0);
    final bodyFontSize =
        displaySettings.scaleFontSize(isLandscape ? 13.5 : 10.0);
    final priceFontSize =
        displaySettings.scaleFontSize(isLandscape ? 13.5 : 10.0);
    final ratingFontSize =
        displaySettings.scaleFontSize(isLandscape ? 13.0 : 9.0);
    final iconSize = isLandscape ? 14.0 : 12.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0),
      elevation: 8,
      child: InkWell(
        onTap: cardOnTap,
        onLongPress: _onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 封面区域
            AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                children: [
                  _buildCoverImage(context, host, token),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _buildRjTag(),
                  ),
                  if (displaySettings.showAgeRating &&
                      AgeRatingFormatter.hasValue(widget.work.age))
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AgeRatingChip(age: widget.work.age, compact: true),
                    ),
                  // 字幕标签 (左下角)
                  if (displaySettings.showSubtitleTag &&
                      (widget.work.hasSubtitle == true || hasLocalSubtitle))
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: _buildSubtitleTag(
                        context,
                        isLocal: hasLocalSubtitle,
                      ),
                    ),
                  if (displaySettings.showReleaseDate &&
                      widget.work.release != null)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _buildDateTag(),
                    ),
                ],
              ),
            ),
            // 信息区域 - 自适应高度
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.work.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                fontSize: titleFontSize,
                              ),
                        ),
                      ),
                      if (trailingAction != null) ...[
                        const SizedBox(width: 4),
                        trailingAction,
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // 社团名称
                  if (displaySettings.showCircle)
                    Text(
                      widget.work.name ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: bodyFontSize,
                          ),
                    ),
                  if (displaySettings.showCircle) const SizedBox(height: 3),
                  // 价格
                  if (displaySettings.showPrice && widget.work.price != null)
                    Text(
                      S.of(context).priceInYen(widget.work.price!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                            fontSize: priceFontSize,
                          ),
                    ),
                  // 评分信息
                  if (displaySettings.showRating &&
                      widget.work.rateAverage != null &&
                      widget.work.rateCount != null &&
                      (widget.work.rateCount! > 0 ||
                          widget.work.rateAverage! != 0)) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber[700],
                          size: iconSize,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.work.rateAverage!.toStringAsFixed(1)} (${widget.work.rateCount})',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.amber[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: ratingFontSize,
                                  ),
                        ),
                      ],
                    ),
                  ],
                  // 时长信息
                  if (displaySettings.showDuration &&
                      widget.work.duration != null &&
                      widget.work.duration! > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blue,
                          size: iconSize,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          formatDuration(
                              Duration(seconds: widget.work.duration!)),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (widget.work.vas != null && widget.work.vas!.isNotEmpty)
                    _buildVoiceActorsRow(context),
                  const SizedBox(height: 2),
                  if (widget.work.tags != null && widget.work.tags!.isNotEmpty)
                    _buildTagsRow(context),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 完整卡片 (列表布局)
  Widget _buildFullCard(
    BuildContext context,
    String host,
    String token,
    VoidCallback cardOnTap,
    WorkCardDisplaySettings displaySettings,
    bool hasLocalSubtitle, {
    Widget? trailingAction,
  }) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final rjFontSize = displaySettings.scaleFontSize(isLandscape ? 12.0 : 11.0);
    final titleFontSize =
        displaySettings.scaleFontSize(isLandscape ? 18.0 : 16.0);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final coverWidth = (availableWidth * 0.24).clamp(120.0, 260.0).toDouble();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          child: InkWell(
            onTap: cardOnTap,
            onLongPress: _onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 列表封面使用横向比例，降低卡片高度并提升信息密度。
                      SizedBox(
                        width: coverWidth,
                        child: AspectRatio(
                          aspectRatio: isLandscape ? 1.55 : 1.4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildCoverImage(context, host, token),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 顶部标签与标题和封面保持同一行。
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.work.displayId,
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                      fontSize: rjFontSize,
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (displaySettings.showAgeRating &&
                                    AgeRatingFormatter.hasValue(widget.work.age))
                                  AgeRatingChip(
                                    age: widget.work.age,
                                    fontSize: rjFontSize,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                  ),
                                if (displaySettings.showSubtitleTag &&
                                    (widget.work.hasSubtitle == true ||
                                        hasLocalSubtitle))
                                  _buildSubtitleTag(
                                    context,
                                    isLocal: hasLocalSubtitle,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.work.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          height: 1.25,
                                          fontSize: titleFontSize,
                                        ),
                                  ),
                                ),
                                if (trailingAction != null) ...[
                                  const SizedBox(width: 4),
                                  trailingAction,
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFullCardDetails(
                    context,
                    displaySettings,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullCardDetails(
    BuildContext context,
    WorkCardDisplaySettings displaySettings,
  ) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final bodyFontSize =
        displaySettings.scaleFontSize(isLandscape ? 14.0 : 13.0);
    final metaFontSize =
        displaySettings.scaleFontSize(isLandscape ? 13.0 : 12.0);
    final tagFontSize =
        displaySettings.scaleFontSize(isLandscape ? 13.0 : 12.0);
    final colorScheme = Theme.of(context).colorScheme;
    final hasCircle = displaySettings.showCircle &&
        widget.work.name != null &&
        widget.work.name!.trim().isNotEmpty;
    final hasPrice = displaySettings.showPrice && widget.work.price != null;
    final hasRelease = displaySettings.showReleaseDate &&
        widget.work.release != null;
    final hasRating = displaySettings.showRating &&
        widget.work.rateAverage != null &&
        widget.work.rateCount != null &&
        widget.work.rateCount! > 0;
    final hasDuration = displaySettings.showDuration &&
        widget.work.duration != null &&
        widget.work.duration! > 0;
    final hasSales = displaySettings.showSales && widget.work.dlCount != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCircle || hasPrice) ...[
          Row(
            children: [
              if (hasCircle)
                Expanded(
                  child: Text(
                    widget.work.name!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: bodyFontSize,
                        ),
                  ),
                ),
              if (!hasCircle) const Spacer(),
              if (hasPrice)
                Text(
                  S.of(context).priceInYen(widget.work.price!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: bodyFontSize,
                      ),
                ),
            ],
          ),
        ],
        if (hasRelease || hasRating || hasDuration || hasSales) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasRelease)
                Text(
                  widget.work.release!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: metaFontSize,
                      ),
                ),
              if (hasRating)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[700],
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.work.rateAverage!.toStringAsFixed(1)} (${widget.work.rateCount})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                            fontSize: metaFontSize,
                          ),
                    ),
                  ],
                ),
              if (hasDuration)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      formatDuration(
                        Duration(seconds: widget.work.duration!),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: metaFontSize,
                          ),
                    ),
                  ],
                ),
              if (hasSales)
                Text(
                  S.of(context).soldCount('${widget.work.dlCount}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontSize: metaFontSize,
                      ),
                ),
            ],
          ),
        ],
        if (widget.work.vas != null && widget.work.vas!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildVoiceActorsWrap(
            context,
            fontSize: tagFontSize,
          ),
        ],
        if (widget.work.tags != null && widget.work.tags!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTagsWrap(context, fontSize: tagFontSize),
        ],
      ],
    );
  }

  Widget _buildCoverImage(BuildContext context, String host, String token) {
    // 使用缓存网络图片，减少滚动时的解码与网络开销，提升流畅度
    if (host.isEmpty) {
      return _buildPlaceholder(context);
    }

    final url = widget.work.getCoverImageUrl(host, token: token);
    final targetWidth = resolveWorkCoverCacheWidth(
      context,
      crossAxisCount: widget.crossAxisCount,
      isListCard: _isListLayout,
    );

    final httpHeaders = StorageService.serverCookieHeaders;

    return Hero(
      tag: 'work_cover_${widget.work.id}',
      child: PrivacyBlurCover(
        borderRadius: BorderRadius.circular(4),
        child: RepaintBoundary(
          child: CachedNetworkImage(
            imageUrl: url,
            httpHeaders: httpHeaders,
            cacheKey: 'work_cover_${widget.work.id}',
            memCacheWidth: targetWidth, // 降低解码分辨率，减少 GPU / CPU 压力
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            fadeInDuration: const Duration(milliseconds: 120),
            fadeOutDuration: const Duration(milliseconds: 90),
            placeholderFadeInDuration: const Duration(milliseconds: 80),
            placeholder: (context, _) => _buildPlaceholder(context),
            errorWidget: (context, _, __) => _buildPlaceholder(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.audiotrack,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildRjTag() {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final displaySettings = ref.watch(workCardDisplayProvider);
    final fontSize = displaySettings.scaleFontSize(isLandscape ? 13.0 : 11.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.work.displayId,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateTag() {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final displaySettings = ref.watch(workCardDisplayProvider);
    final fontSize = displaySettings.scaleFontSize(isLandscape ? 13.0 : 10.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.work.release!,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubtitleTag(BuildContext context, {bool isLocal = false}) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final displaySettings = ref.watch(workCardDisplayProvider);
    final iconSize = displaySettings.scaleFontSize(isLandscape ? 16.0 : 14.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLocal
            ? Colors.green.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.closed_caption,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final displaySettings = ref.watch(workCardDisplayProvider);
    final fontSize = displaySettings.scaleFontSize(isLandscape ? 13.0 : 10.0);

    return Container(
      constraints: const BoxConstraints(minHeight: 14),
      child: Wrap(
        spacing: 3,
        runSpacing: 2,
        children: widget.work.tags!.map((tag) {
          return TagChip(
            tag: tag,
            fontSize: fontSize,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            borderRadius: 6,
            fontWeight: FontWeight.w500,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVoiceActorsRow(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final displaySettings = ref.watch(workCardDisplayProvider);
    final fontSize = displaySettings.scaleFontSize(isLandscape ? 13.0 : 10.0);

    return Container(
      constraints: const BoxConstraints(minHeight: 14),
      child: Wrap(
        spacing: 3,
        runSpacing: 2,
        children: widget.work.vas!.map((va) {
          return VaChip(
            va: va,
            fontSize: fontSize,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            borderRadius: 6,
            fontWeight: FontWeight.w500,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagsWrap(BuildContext context, {required double fontSize}) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: widget.work.tags!.map((tag) {
        return TagChip(
          tag: tag,
          fontSize: fontSize,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          borderRadius: 12,
          fontWeight: FontWeight.w500,
        );
      }).toList(),
    );
  }

  Widget _buildVoiceActorsWrap(BuildContext context,
      {required double fontSize}) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: widget.work.vas!.map((va) {
        return VaChip(
          va: va,
          fontSize: fontSize,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          borderRadius: 12,
          fontWeight: FontWeight.w500,
        );
      }).toList(),
    );
  }
}
