import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/work.dart';
import '../services/kikoeru_api_service.dart' hide kikoeruApiServiceProvider;
import '../providers/works_provider.dart';
import '../models/sort_options.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';
import 'subtitle_library_provider.dart';
import '../utils/subtitle_filter.dart';
import '../utils/paged_collection.dart';
import '../utils/persistent_enum_preference.dart';

// Layout types for search results
enum SearchLayoutType {
  list,
  smallGrid,
  bigGrid,
}

// Extension to convert SearchLayoutType to LayoutType
extension SearchLayoutTypeExtension on SearchLayoutType {
  LayoutType toWorksLayoutType() {
    switch (this) {
      case SearchLayoutType.list:
        return LayoutType.list;
      case SearchLayoutType.smallGrid:
        return LayoutType.smallGrid;
      case SearchLayoutType.bigGrid:
        return LayoutType.bigGrid;
    }
  }
}

// Search result state
class SearchResultState extends Equatable {
  final List<Work> works;
  final List<Work> rawWorks;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final String? loadMoreError;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final SearchLayoutType layoutType;
  final SortOrder sortOption;
  final SortDirection sortDirection;
  final int subtitleFilter;
  final int basePageSize; // 用户设置的基础分页大小
  final String keyword;
  final Map<String, dynamic>? searchParams;

  // 实际使用的分页大小（字幕筛选时翻倍）
  int get pageSize => SubtitleFilterMode.fromValue(subtitleFilter).isActive
      ? basePageSize * 2
      : basePageSize;

  const SearchResultState({
    this.works = const [],
    this.rawWorks = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.layoutType = SearchLayoutType.bigGrid,
    this.sortOption = SortOrder.release,
    this.sortDirection = SortDirection.desc,
    this.subtitleFilter = 0,
    this.basePageSize = 40,
    this.keyword = '',
    this.searchParams,
  });

  SearchResultState copyWith({
    List<Work>? works,
    List<Work>? rawWorks,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? error,
    String? loadMoreError,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    SearchLayoutType? layoutType,
    SortOrder? sortOption,
    SortDirection? sortDirection,
    int? subtitleFilter,
    int? basePageSize,
    String? keyword,
    Map<String, dynamic>? searchParams,
  }) {
    return SearchResultState(
      works: works ?? this.works,
      rawWorks: rawWorks ?? this.rawWorks,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      loadMoreError: loadMoreError,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      layoutType: layoutType ?? this.layoutType,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
      basePageSize: basePageSize ?? this.basePageSize,
      keyword: keyword ?? this.keyword,
      searchParams: searchParams ?? this.searchParams,
    );
  }

  @override
  List<Object?> get props => [
        works,
        rawWorks,
        isLoading,
        isRefreshing,
        isLoadingMore,
        error,
        loadMoreError,
        currentPage,
        totalCount,
        hasMore,
        layoutType,
        sortOption,
        sortDirection,
        subtitleFilter,
        basePageSize,
        keyword,
        searchParams,
      ];
}

// Search result notifier
class SearchResultNotifier extends StateNotifier<SearchResultState> {
  static const String layoutPreferenceKey = 'search_result_layout_type';

  final KikoeruApiService _apiService;
  final Ref _ref;
  final PagedRequestGate _requestGate = PagedRequestGate();
  final _layoutPreference = PersistentEnumPreference<SearchLayoutType>(
    key: layoutPreferenceKey,
    values: SearchLayoutType.values,
    fallback: SearchLayoutType.bigGrid,
  );

  SearchResultNotifier(this._apiService, this._ref, {int initialPageSize = 20})
      : super(SearchResultState(basePageSize: initialPageSize)) {
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final layoutType = await _layoutPreference.load();
    if (!mounted || layoutType == null || layoutType == state.layoutType) {
      return;
    }
    state = state.copyWith(
      layoutType: layoutType,
      error: state.error,
      loadMoreError: state.loadMoreError,
    );
  }

  Future<void> initializeSearch({
    required String keyword,
    Map<String, dynamic>? searchParams,
  }) async {
    state = state.copyWith(
      keyword: keyword,
      searchParams: searchParams,
      currentPage: 1,
      works: [],
      rawWorks: [],
    );
    await loadResults(targetPage: 1, supersede: true);
  }

  void updatePageSize(int newSize) {
    if (state.basePageSize == newSize) return;
    state = state.copyWith(basePageSize: newSize);
    // 如果当前有搜索内容，刷新列表
    if (state.keyword.isNotEmpty || state.searchParams != null) {
      refresh();
    }
  }

  Future<void> loadResults({
    int? targetPage,
    bool append = false,
    bool supersede = false,
  }) async {
    final requestToken = _requestGate.begin(supersede: supersede);
    if (requestToken == null) return;

    final page = targetPage ?? state.currentPage;
    state = state.copyWith(
      isLoading: true,
      isRefreshing: !append,
      isLoadingMore: append,
      error: null,
      loadMoreError: null,
    );

    try {
      Map<String, dynamic> result;
      const serverSubtitleParam = 0;

      if (state.searchParams?.containsKey('vaId') == true) {
        result = await _apiService.getWorksByVa(
          vaId: state.searchParams!['vaId'],
          page: page,
          pageSize: state.pageSize,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: serverSubtitleParam,
        );
      } else if (state.searchParams?.containsKey('tagId') == true) {
        result = await _apiService.getWorksByTag(
          tagId: state.searchParams!['tagId'],
          page: page,
          pageSize: state.pageSize,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: serverSubtitleParam,
        );
      } else {
        result = await _apiService.searchWorks(
          keyword: state.keyword,
          page: page,
          pageSize: state.pageSize,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: serverSubtitleParam,
        );
      }

      if (!_requestGate.isCurrent(requestToken)) return;

      final pageWorks =
          (result['works'] as List).map((json) => Work.fromJson(json)).toList();
      final rawWorks = mergePagedItems<Work, int>(
        existing: const [],
        incoming: pageWorks,
        idOf: (work) => work.id,
        replace: true,
      );
      final blockedItems = _ref.read(blockedItemsProvider);
      final filteredWorks = _filterWorks(rawWorks, blockedItems);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] ?? pageWorks.length;
      final totalPages =
          totalCount > 0 ? (totalCount / state.pageSize).ceil() : 1;

      state = state.copyWith(
        works: filteredWorks,
        rawWorks: rawWorks,
        currentPage: page,
        totalCount: totalCount,
        hasMore: page < totalPages,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: null,
        loadMoreError: null,
      );
    } catch (e) {
      if (!_requestGate.isCurrent(requestToken)) return;
      final message = e.toString();
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: append ? null : message,
        loadMoreError: append ? message : null,
      );
    } finally {
      _requestGate.complete(requestToken);
    }
  }

  void reapplyFilters() {
    final blockedItems = _ref.read(blockedItemsProvider);
    final filteredWorks = _filterWorks(state.rawWorks, blockedItems);
    state = state.copyWith(works: filteredWorks);
  }

  List<Work> _filterWorks(List<Work> works, BlockedItemsState blockedItems) {
    // 获取本地字幕库的作品ID
    final localSubtitleIds = _ref.read(subtitleLibraryProvider);
    final subtitleFilter = state.subtitleFilter;

    final subtitleFilteredWorks = filterWorksBySubtitleMode(
      works,
      localSubtitleIds,
      subtitleFilter,
    );

    return subtitleFilteredWorks.where((work) {
      // Check tags
      if (work.tags != null) {
        for (final tag in work.tags!) {
          if (blockedItems.tags.contains(tag.name)) return false;
        }
      }
      // Check CVs
      if (work.vas != null) {
        for (final va in work.vas!) {
          if (blockedItems.cvs.contains(va.name)) return false;
        }
      }
      // Check Circle
      if (work.name != null && blockedItems.circles.contains(work.name)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> goToPage(int page) async {
    await loadResults(targetPage: page);
  }

  Future<void> refresh() async {
    await loadResults(targetPage: state.currentPage, supersede: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await loadResults(targetPage: state.currentPage + 1);
  }

  void toggleLayoutType() {
    final nextLayout = switch (state.layoutType) {
      SearchLayoutType.bigGrid => SearchLayoutType.smallGrid,
      SearchLayoutType.smallGrid => SearchLayoutType.list,
      SearchLayoutType.list => SearchLayoutType.bigGrid,
    };
    state = state.copyWith(layoutType: nextLayout);
    unawaited(_layoutPreference.save(nextLayout));
  }

  bool get isSubtitleFilterActive =>
      SubtitleFilterMode.fromValue(state.subtitleFilter).isActive;

  void toggleSubtitleFilter() {
    final currentPage = state.currentPage;
    final oldFilterMode = SubtitleFilterMode.fromValue(state.subtitleFilter);
    final newFilterMode = oldFilterMode.next;
    final newFilter = newFilterMode.value;

    int newPage;
    if (oldFilterMode == SubtitleFilterMode.all && newFilterMode.isActive) {
      newPage = ((currentPage + 1) / 2).ceil();
    } else if (oldFilterMode.isActive &&
        newFilterMode == SubtitleFilterMode.all) {
      newPage = (currentPage * 2) - 1;
    } else {
      newPage = currentPage;
    }
    newPage = newPage.clamp(1, 9999);

    state = state.copyWith(
      subtitleFilter: newFilter,
      currentPage: newPage,
      works: [],
      rawWorks: [],
    );
    loadResults(targetPage: newPage, supersede: true);
  }

  void updateSort(SortOrder option, SortDirection direction) {
    state = state.copyWith(
      sortOption: option,
      sortDirection: direction,
      currentPage: 1,
      works: [],
      rawWorks: [],
    );
    refresh();
  }
}

// Provider
final searchResultProvider =
    StateNotifierProvider<SearchResultNotifier, SearchResultState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  final pageSize = ref.read(pageSizeProvider);
  final notifier =
      SearchResultNotifier(apiService, ref, initialPageSize: pageSize);

  ref.listen(pageSizeProvider, (previous, next) {
    if (previous != next) {
      notifier.updatePageSize(next);
    }
  });

  // 监听屏蔽列表变化，重新过滤
  ref.listen(blockedItemsProvider, (previous, next) {
    if (previous != next) {
      notifier.reapplyFilters();
    }
  });

  // 监听本地字幕库变化，当字幕筛选开启时重新过滤
  ref.listen(subtitleLibraryProvider, (previous, next) {
    if (previous != next && notifier.isSubtitleFilterActive) {
      notifier.reapplyFilters();
    }
  });

  return notifier;
});
