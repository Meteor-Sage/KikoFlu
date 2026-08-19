import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/sort_options.dart';
import '../providers/search_result_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../widgets/works_grid_view.dart';
import '../widgets/virtualized_sliver_collection.dart';
import '../widgets/sort_dialog.dart';
import '../widgets/global_audio_player_wrapper.dart';
import '../widgets/download_fab.dart';
import '../utils/l10n_extensions.dart';
import '../utils/subtitle_filter.dart';
import '../widgets/floating_feed_toolbar.dart';
import '../utils/system_ui_style.dart';

class SearchResultScreen extends StatelessWidget {
  final String keyword;
  final String? searchTypeLabel;
  final Map<String, dynamic>? searchParams;

  const SearchResultScreen({
    super.key,
    required this.keyword,
    this.searchTypeLabel,
    this.searchParams,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        searchResultProvider.overrideWith((ref) {
          final apiService = ref.watch(kikoeruApiServiceProvider);
          final pageSize = ref.read(pageSizeProvider);
          final notifier =
              SearchResultNotifier(apiService, ref, initialPageSize: pageSize);

          ref.listen(pageSizeProvider, (previous, next) {
            if (previous != next) {
              notifier.updatePageSize(next);
            }
          });

          return notifier;
        }),
      ],
      child: _SearchResultContent(
        keyword: keyword,
        searchTypeLabel: searchTypeLabel,
        searchParams: searchParams,
      ),
    );
  }
}

class _SearchResultContent extends ConsumerStatefulWidget {
  final String keyword;
  final String? searchTypeLabel;
  final Map<String, dynamic>? searchParams;

  const _SearchResultContent({
    required this.keyword,
    this.searchTypeLabel,
    this.searchParams,
  });

  @override
  ConsumerState<_SearchResultContent> createState() =>
      _SearchResultContentState();
}

class _SearchResultContentState extends ConsumerState<_SearchResultContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    logOutput(
        '[SearchResult] Screen initialized with keyword: ${widget.keyword}, type: ${widget.searchTypeLabel}');
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logOutput(
          '[SearchResult] Starting search with params: ${widget.searchParams}');
      ref.read(searchResultProvider.notifier).initializeSearch(
            keyword: widget.keyword,
            searchParams: widget.searchParams,
          );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSortDialog(BuildContext context) {
    final state = ref.read(searchResultProvider);
    showDialog(
      context: context,
      builder: (context) => CommonSortDialog(
        currentOption: state.sortOption,
        currentDirection: state.sortDirection,
        availableOptions: SortOrder.values
            .where((option) =>
                option != SortOrder.nsfw && option != SortOrder.updatedAt)
            .toList(),
        onSort: (option, direction) {
          ref.read(searchResultProvider.notifier).updateSort(option, direction);
        },
        autoClose: true,
      ),
    );
  }

  IconData _getLayoutIcon(SearchLayoutType layoutType) {
    switch (layoutType) {
      case SearchLayoutType.bigGrid:
        return Icons.grid_3x3;
      case SearchLayoutType.smallGrid:
        return Icons.view_list;
      case SearchLayoutType.list:
        return Icons.view_agenda;
    }
  }

  String _getLayoutTooltip(SearchLayoutType layoutType) {
    switch (layoutType) {
      case SearchLayoutType.bigGrid:
        return S.of(context).switchToSmallGrid;
      case SearchLayoutType.smallGrid:
        return S.of(context).switchToList;
      case SearchLayoutType.list:
        return S.of(context).switchToLargeGrid;
    }
  }

  IconData _getSubtitleFilterIcon(int subtitleFilter) {
    final mode = SubtitleFilterMode.fromValue(subtitleFilter);
    return mode == SubtitleFilterMode.withSubtitles
        ? Icons.closed_caption
        : Icons.closed_caption_disabled;
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchResultProvider);

    final horizontalPadding = FloatingToolbarLayout.horizontalPadding(context);

    final topPadding = MediaQuery.paddingOf(context).top;
    final systemOverlayStyle =
        transparentSystemBarsForBrightness(Theme.of(context).brightness);

    return GlobalAudioPlayerWrapper(
      child: AnnotatedRegion(
        value: systemOverlayStyle,
        child: Scaffold(
          floatingActionButton: const DownloadFab(),
          body: Stack(
            children: [
              Positioned.fill(child: _buildBody(searchState)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ProgressiveTopBlur(height: topPadding + 72),
              ),
              Positioned(
                top: topPadding + 8,
                left: horizontalPadding,
                right: horizontalPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingToolbarSurface(
                      child: FloatingToolbarIconButton(
                        icon: Icons.arrow_back,
                        tooltip: S.of(context).back,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    FloatingToolbarSurface(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingToolbarIconButton(
                            icon: _getLayoutIcon(searchState.layoutType),
                            tooltip: _getLayoutTooltip(searchState.layoutType),
                            onPressed: () => ref
                                .read(searchResultProvider.notifier)
                                .toggleLayoutType(),
                          ),
                          FloatingToolbarIconButton(
                            icon: _getSubtitleFilterIcon(
                                searchState.subtitleFilter),
                            tooltip: SubtitleFilterMode.fromValue(
                              searchState.subtitleFilter,
                            ).localizedTooltip(context),
                            isSelected: SubtitleFilterMode.fromValue(
                              searchState.subtitleFilter,
                            ).isActive,
                            onPressed: () => ref
                                .read(searchResultProvider.notifier)
                                .toggleSubtitleFilter(),
                          ),
                          FloatingToolbarIconButton(
                            icon: Icons.sort,
                            tooltip: S.of(context).sort,
                            onPressed: () => _showSortDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInfo(BuildContext context, SearchResultState searchState) {
    // 检查是否有详细的搜索条件
    final conditions = widget.searchParams?['conditions'] as List?;
    final minRate = widget.searchParams?['minRate'] as num?;
    final ageRating = widget.searchParams?['ageRating'] as String?;
    final salesRange = widget.searchParams?['salesRange'] as String?;

    // 如果有详细条件，显示为芯片
    if (conditions != null && conditions.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 搜索条件芯片
          ...conditions.map((condition) {
            final type = condition['type'] as String;
            final value = condition['value'] as String;
            final isExclude = condition['isExclude'] as bool? ?? false;
            // RJ号需要添加RJ前缀显示
            final isRjNumber = RegExp(r'^\d+$').hasMatch(value);
            final displayValue = isRjNumber ? 'RJ$value' : value;

            return Chip(
              avatar: Icon(
                isExclude
                    ? Icons.remove_circle_outline
                    : _getConditionIcon(type),
                size: 16,
              ),
              label: Text(
                '$type: $displayValue',
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: isExclude
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            );
          }),

          // 高级筛选条件芯片
          if (minRate != null && minRate > 0)
            Chip(
              avatar: const Icon(Icons.star, size: 16),
              label: Text(
                '${S.of(context).ratingLabel} ≥ ${minRate.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
          if (ageRating != null)
            Chip(
              avatar: const Icon(Icons.shield, size: 16),
              label: Text(
                ageRating,
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
          if (salesRange != null)
            Chip(
              avatar: const Icon(Icons.trending_up, size: 16),
              label: Text(
                salesRange,
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),

          // 结果统计
          if (searchState.totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                S.of(context).totalNWorks(searchState.totalCount),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      );
    }

    // 原有的简单显示方式（兼容旧逻辑）
    String searchInfo = widget.keyword;
    if (widget.searchTypeLabel != null) {
      searchInfo = '${widget.searchTypeLabel}: $searchInfo';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                searchInfo,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (searchState.totalCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.numbers,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  S.of(context).totalNWorks(searchState.totalCount),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(SearchResultState searchState) {
    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).loadFailed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              searchState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(searchResultProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (searchState.works.isEmpty && searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('...'),
          ],
        ),
      );
    }

    if (searchState.works.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              S.of(context).noResults,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return WorksGridView(
      works: searchState.works,
      layoutType: searchState.layoutType.toWorksLayoutType(),
      scrollController: _scrollController,
      isLoading: searchState.isLoading,
      isRefreshing: false,
      isLoadingMore: searchState.isLoadingMore,
      hasMore: searchState.hasMore,
      error: searchState.error,
      loadMoreError: searchState.loadMoreError,
      onRetry: () => ref.read(searchResultProvider.notifier).refresh(),
      showInlineLoadingIndicator: searchState.isLoading,
      pagination: VirtualizedPagination(
        currentPage: searchState.currentPage,
        pageSize: searchState.pageSize,
        totalCount: searchState.totalCount,
        hasMore: searchState.hasMore,
        isLoading: searchState.isLoading || searchState.isRefreshing,
        onPreviousPage: () => ref
            .read(searchResultProvider.notifier)
            .goToPage(searchState.currentPage - 1),
        onNextPage: () => ref
            .read(searchResultProvider.notifier)
            .goToPage(searchState.currentPage + 1),
        onGoToPage: ref.read(searchResultProvider.notifier).goToPage,
        nextPageOnOverscroll: true,
        scrollDuration: const Duration(milliseconds: 300),
        scrollCurve: Curves.easeOut,
        endMessage: S.of(context).reachedEnd,
        extraBuilder: searchState.rawWorks.length > searchState.works.length
            ? (context) => Text(
                  '${searchState.rawWorks.length - searchState.works.length} filtered',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                )
            : null,
      ),
      sliversBefore: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 64,
              left: MediaQuery.orientationOf(context) == Orientation.landscape
                  ? 24
                  : 8,
              right: MediaQuery.orientationOf(context) == Orientation.landscape
                  ? 24
                  : 8,
              bottom: 8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildSearchInfo(context, searchState),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getConditionIcon(String type) {
    // type is a localized label, so we match by checking common patterns
    // This is a best-effort fallback; the main UI uses SearchType enum directly
    return Icons.search;
  }
}
