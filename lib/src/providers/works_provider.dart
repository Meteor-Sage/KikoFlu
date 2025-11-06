import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/work.dart';
import '../services/kikoeru_api_service.dart' hide kikoeruApiServiceProvider;
import 'auth_provider.dart';

// Display mode - 展示模式
enum DisplayMode {
  all('all', '全部作品'),
  popular('popular', '热门推荐');

  const DisplayMode(this.value, this.label);
  final String value;
  final String label;
}

// Layout types - 参考原始代码的三种布局
enum LayoutType {
  list, // 列表布局
  smallGrid, // 小网格布局 (3列)
  bigGrid // 大网格布局 (2列)
}

// Sort options - 参考原始代码的简化排序选项
enum SortOption {
  release('release', '发布日期'),
  id('id', 'ID'),
  price('price', '价格'),
  create_date('create_date', '创建日期');

  const SortOption(this.value, this.label);
  final String value;
  final String label;
}

// Sort direction
enum SortDirection {
  asc('asc', '升序'),
  desc('desc', '降序');

  const SortDirection(this.value, this.label);
  final String value;
  final String label;
}

// Works state
class WorksState extends Equatable {
  final List<Work> works;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final LayoutType layoutType;
  final SortOption sortOption;
  final SortDirection sortDirection;
  final DisplayMode displayMode;
  final int subtitleFilter; // 0: 全部, 1: 仅带字幕

  const WorksState({
    this.works = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.layoutType = LayoutType.bigGrid, // 默认大网格布局
    this.sortOption = SortOption.create_date,
    this.sortDirection = SortDirection.desc,
    this.displayMode = DisplayMode.all, // 默认显示全部作品
    this.subtitleFilter = 0, // 默认显示全部
  });

  WorksState copyWith({
    List<Work>? works,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    LayoutType? layoutType,
    SortOption? sortOption,
    SortDirection? sortDirection,
    DisplayMode? displayMode,
    int? subtitleFilter,
  }) {
    return WorksState(
      works: works ?? this.works,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      layoutType: layoutType ?? this.layoutType,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      displayMode: displayMode ?? this.displayMode,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
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
        displayMode,
        subtitleFilter,
      ];
}

// Works notifier
class WorksNotifier extends StateNotifier<WorksState> {
  final KikoeruApiService _apiService;

  WorksNotifier(this._apiService) : super(const WorksState());

  Future<void> loadWorks({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      Map<String, dynamic> response;

      // 根据显示模式选择不同的API
      if (state.displayMode == DisplayMode.popular) {
        response = await _apiService.getPopularWorks(
          page: page,
          pageSize: 20,
          subtitle: state.subtitleFilter, // 热门推荐也支持字幕筛选
        );
      } else {
        response = await _apiService.getWorks(
          page: page,
          order: state.sortOption.value,
          sort: state.sortDirection.value,
          subtitle: state.subtitleFilter, // 使用字幕筛选
        );
      }

      final worksData = response['works'] as List<dynamic>?;
      final pagination = response['pagination'] as Map<String, dynamic>?;

      if (worksData == null) {
        throw Exception('No works data in response');
      }

      final works = worksData
          .map((workJson) => Work.fromJson(workJson as Map<String, dynamic>))
          .toList();

      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? 1;

      // 热门推荐最多100个，需要特殊处理hasMore
      bool hasMore;
      if (state.displayMode == DisplayMode.popular) {
        hasMore =
            works.length >= 20 && totalCount > (page * 20) && totalCount <= 100;
      } else {
        hasMore = works.length >= 20 && (page * 20) < totalCount;
      }

      if (refresh) {
        state = state.copyWith(
          works: works,
          isLoading: false,
          currentPage: currentPage + 1,
          totalCount: totalCount,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          works: [...state.works, ...works],
          isLoading: false,
          currentPage: currentPage + 1,
          totalCount: totalCount,
          hasMore: hasMore,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load works: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadWorks(refresh: true);
  }

  void setSortOption(SortOption option) {
    if (state.sortOption != option) {
      state = state.copyWith(sortOption: option);
      refresh();
    }
  }

  void setSortDirection(SortDirection direction) {
    if (state.sortDirection != direction) {
      state = state.copyWith(sortDirection: direction);
      refresh();
    }
  }

  void toggleSortDirection() {
    final newDirection = state.sortDirection == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
    setSortDirection(newDirection);
  }

  void setLayoutType(LayoutType layoutType) {
    state = state.copyWith(layoutType: layoutType);
  }

  void toggleLayoutType() {
    late LayoutType newLayoutType;
    switch (state.layoutType) {
      case LayoutType.bigGrid:
        newLayoutType = LayoutType.smallGrid;
        break;
      case LayoutType.smallGrid:
        newLayoutType = LayoutType.list;
        break;
      case LayoutType.list:
        newLayoutType = LayoutType.bigGrid;
        break;
    }
    setLayoutType(newLayoutType);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Switch between all works and popular works
  void setDisplayMode(DisplayMode mode) {
    if (state.displayMode != mode) {
      state = state.copyWith(displayMode: mode);
      refresh();
    }
  }

  // Toggle subtitle filter
  void toggleSubtitleFilter() {
    final newFilter = state.subtitleFilter == 0 ? 1 : 0;
    state = state.copyWith(subtitleFilter: newFilter);
    refresh();
  }
}

// Providers
final worksProvider = StateNotifierProvider<WorksNotifier, WorksState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  return WorksNotifier(apiService);
});
