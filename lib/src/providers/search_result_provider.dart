import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/work.dart';
import '../services/kikoeru_api_service.dart' hide kikoeruApiServiceProvider;
import '../providers/works_provider.dart';
import '../models/sort_options.dart';
import 'auth_provider.dart';

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
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final SearchLayoutType layoutType;
  final SortOrder sortOption;
  final SortDirection sortDirection;
  final int subtitleFilter;
  final int pageSize;
  final String keyword;
  final Map<String, dynamic>? searchParams;

  const SearchResultState({
    this.works = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.layoutType = SearchLayoutType.bigGrid,
    this.sortOption = SortOrder.createDate,
    this.sortDirection = SortDirection.desc,
    this.subtitleFilter = 0,
    this.pageSize = 30,
    this.keyword = '',
    this.searchParams,
  });

  SearchResultState copyWith({
    List<Work>? works,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    SearchLayoutType? layoutType,
    SortOrder? sortOption,
    SortDirection? sortDirection,
    int? subtitleFilter,
    int? pageSize,
    String? keyword,
    Map<String, dynamic>? searchParams,
  }) {
    return SearchResultState(
      works: works ?? this.works,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      layoutType: layoutType ?? this.layoutType,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
      pageSize: pageSize ?? this.pageSize,
      keyword: keyword ?? this.keyword,
      searchParams: searchParams ?? this.searchParams,
    );
  }

  @override
  List<Object?> get props => [
        works,
        isLoading,
        error,
        currentPage,
        totalCount,
        hasMore,
        layoutType,
        sortOption,
        sortDirection,
        subtitleFilter,
        pageSize,
        keyword,
        searchParams,
      ];
}

// Search result notifier
class SearchResultNotifier extends StateNotifier<SearchResultState> {
  final KikoeruApiService _apiService;

  SearchResultNotifier(this._apiService) : super(const SearchResultState());

  Future<void> initializeSearch({
    required String keyword,
    Map<String, dynamic>? searchParams,
  }) async {
    state = state.copyWith(
      keyword: keyword,
      searchParams: searchParams,
      currentPage: 1,
      works: [],
    );
    await loadResults();
  }

  Future<void> loadResults({int? targetPage}) async {
    if (state.isLoading) return;

    final page = targetPage ?? state.currentPage;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      Map<String, dynamic> result;

      // 根据 searchParams 判断搜索类型
      if (state.searchParams?.containsKey('vaId') == true) {
        // 声优搜索 - 支持完整的排序和过滤参数
        result = await _apiService.getWorksByVa(
          vaId: state.searchParams!['vaId'],
          page: page,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: state.subtitleFilter,
        );
      } else if (state.searchParams?.containsKey('tagId') == true) {
        // 标签搜索 - 支持完整的排序和过滤参数
        result = await _apiService.getWorksByTag(
          tagId: state.searchParams!['tagId'],
          page: page,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: state.subtitleFilter,
        );
      } else {
        // 关键词搜索 - 支持完整的排序和过滤参数
        result = await _apiService.searchWorks(
          keyword: state.keyword,
          page: page,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: state.subtitleFilter,
        );
      }

      final works =
          (result['works'] as List).map((json) => Work.fromJson(json)).toList();

      final pagination = result['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] ?? works.length;

      // 计算是否还有更多页
      final totalPages =
          totalCount > 0 ? (totalCount / state.pageSize).ceil() : 1;
      final hasMorePages = page < totalPages;

      state = state.copyWith(
        works: works,
        currentPage: page,
        totalCount: totalCount,
        hasMore: hasMorePages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> goToPage(int page) async {
    await loadResults(targetPage: page);
  }

  Future<void> refresh() async {
    await loadResults(targetPage: 1);
  }

  void toggleLayoutType() {
    final nextLayout = switch (state.layoutType) {
      SearchLayoutType.bigGrid => SearchLayoutType.smallGrid,
      SearchLayoutType.smallGrid => SearchLayoutType.list,
      SearchLayoutType.list => SearchLayoutType.bigGrid,
    };
    state = state.copyWith(layoutType: nextLayout);
  }

  void toggleSubtitleFilter() {
    final newFilter = state.subtitleFilter == 0 ? 1 : 0;
    state = state.copyWith(
      subtitleFilter: newFilter,
      currentPage: 1,
      works: [],
    );
    loadResults();
  }

  void updateSort(SortOrder option, SortDirection direction) {
    state = state.copyWith(
      sortOption: option,
      sortDirection: direction,
      currentPage: 1,
      works: [],
    );
    loadResults();
  }
}

// Provider
final searchResultProvider =
    StateNotifierProvider<SearchResultNotifier, SearchResultState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  return SearchResultNotifier(apiService);
});
