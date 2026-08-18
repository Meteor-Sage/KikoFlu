import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/work.dart';
import '../services/kikoeru_api_service.dart' hide kikoeruApiServiceProvider;
import '../services/log_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';
import '../models/sort_options.dart';
import 'subtitle_library_provider.dart';
import '../utils/subtitle_filter.dart';
import '../utils/paged_collection.dart';

final _log = LogService.instance;

// Display mode - 展示模式
enum DisplayMode {
  all('all', '全部作品'),
  popular('popular', '热门推荐'),
  recommended('recommended', '推荐');

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

class WorksModeSnapshot extends Equatable {
  static const _noValue = Object();

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
  final bool isLastPage;

  const WorksModeSnapshot({
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
    this.isLastPage = false,
  });

  WorksModeSnapshot copyWith({
    List<Work>? works,
    List<Work>? rawWorks,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    Object? error = _noValue,
    Object? loadMoreError = _noValue,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    bool? isLastPage,
  }) {
    return WorksModeSnapshot(
      works: works ?? this.works,
      rawWorks: rawWorks ?? this.rawWorks,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error == _noValue ? this.error : error as String?,
      loadMoreError: loadMoreError == _noValue
          ? this.loadMoreError
          : loadMoreError as String?,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLastPage: isLastPage ?? this.isLastPage,
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
        isLastPage,
      ];
}

// Works state
class WorksState extends Equatable {
  final LayoutType layoutType;
  final SortOrder sortOption;
  final SortDirection sortDirection;
  final DisplayMode displayMode;
  final int subtitleFilter; // 0: 全部, 1: 有字幕
  final int basePageSize; // 用户设置的基础分页大小
  final Map<DisplayMode, WorksModeSnapshot> modeStates;

  // 实际使用的分页大小（字幕筛选时翻倍）
  int get pageSize => SubtitleFilterMode.fromValue(subtitleFilter).isActive
      ? basePageSize * 2
      : basePageSize;

  WorksState({
    this.layoutType = LayoutType.bigGrid, // 默认大网格布局
    this.sortOption = SortOrder.release,
    this.sortDirection = SortDirection.desc,
    this.displayMode = DisplayMode.all, // 默认显示全部作品
    this.subtitleFilter = 0, // 默认显示全部
    this.basePageSize = 40, // 全部模式每页40条
    Map<DisplayMode, WorksModeSnapshot>? modeStates,
  }) : modeStates = modeStates ?? _createInitialModeStates();

  WorksState copyWith({
    LayoutType? layoutType,
    SortOrder? sortOption,
    SortDirection? sortDirection,
    DisplayMode? displayMode,
    int? subtitleFilter,
    int? basePageSize,
    Map<DisplayMode, WorksModeSnapshot>? modeStates,
  }) {
    return WorksState(
      layoutType: layoutType ?? this.layoutType,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      displayMode: displayMode ?? this.displayMode,
      subtitleFilter: subtitleFilter ?? this.subtitleFilter,
      basePageSize: basePageSize ?? this.basePageSize,
      modeStates: modeStates ?? this.modeStates,
    );
  }

  WorksModeSnapshot get _currentModeState =>
      modeStates[displayMode] ?? const WorksModeSnapshot();

  List<Work> get works => _currentModeState.works;
  List<Work> get rawWorks => _currentModeState.rawWorks;
  bool get isLoading => _currentModeState.isLoading;
  bool get isRefreshing => _currentModeState.isRefreshing;
  bool get isLoadingMore => _currentModeState.isLoadingMore;
  String? get error => _currentModeState.error;
  String? get loadMoreError => _currentModeState.loadMoreError;
  int get currentPage => _currentModeState.currentPage;
  int get totalCount => _currentModeState.totalCount;
  bool get hasMore => _currentModeState.hasMore;
  bool get isLastPage => _currentModeState.isLastPage;

  static Map<DisplayMode, WorksModeSnapshot> _createInitialModeStates() {
    return {
      for (final mode in DisplayMode.values) mode: const WorksModeSnapshot(),
    };
  }

  @override
  List<Object?> get props => [
        layoutType,
        sortOption,
        sortDirection,
        displayMode,
        subtitleFilter,
        basePageSize,
        modeStates,
      ];
}

// Works notifier
class WorksNotifier extends StateNotifier<WorksState> {
  final KikoeruApiService _apiService;
  final Ref _ref;
  final Map<DisplayMode, PagedRequestGate> _requestGates = {
    for (final mode in DisplayMode.values) mode: PagedRequestGate(),
  };

  WorksNotifier(
    this._apiService,
    this._ref, {
    int initialPageSize = 40,
    SortOrder initialSortOption = SortOrder.release,
    SortDirection initialSortDirection = SortDirection.desc,
  }) : super(WorksState(
          basePageSize: initialPageSize,
          sortOption: initialSortOption,
          sortDirection: initialSortDirection,
        ));

  WorksModeSnapshot _getModeState(DisplayMode mode) {
    return state.modeStates[mode] ?? const WorksModeSnapshot();
  }

  void _updateModeState(
    DisplayMode mode,
    WorksModeSnapshot Function(WorksModeSnapshot current) updater,
  ) {
    final updatedStates =
        Map<DisplayMode, WorksModeSnapshot>.from(state.modeStates);
    final currentSnapshot = _getModeState(mode);
    updatedStates[mode] = updater(currentSnapshot);
    state = state.copyWith(modeStates: updatedStates);
  }

  void _updateActiveModeState(
    WorksModeSnapshot Function(WorksModeSnapshot current) updater,
  ) {
    _updateModeState(state.displayMode, updater);
  }

  void updatePageSize(int newSize) {
    if (state.basePageSize == newSize) return;
    state = state.copyWith(basePageSize: newSize);
    refresh();
  }

  Future<void> loadWorks({
    bool refresh = false,
    int? targetPage,
    bool append = false,
    bool supersede = false,
  }) async {
    final mode = state.displayMode;
    final modeState = _getModeState(mode);
    final requestGate = _requestGates[mode]!;
    final requestToken = requestGate.begin(supersede: supersede);

    if (requestToken == null) {
      _log.captureOutput('[WorksProvider] Already loading, skipping');
      return;
    }

    final previousPage = modeState.currentPage;
    final page = targetPage ?? (refresh ? 1 : (append ? previousPage + 1 : 1));

    _log.captureOutput(
        '[WorksProvider] Loading works - mode: $mode, page: $page, refresh: $refresh, currentPage: $previousPage, targetPage: $targetPage');

    _updateModeState(
      mode,
      (snapshot) => snapshot.copyWith(
        isLoading: true,
        isRefreshing: !append,
        isLoadingMore: append,
        error: null,
        loadMoreError: null,
      ),
    );

    try {
      Map<String, dynamic> response;

      final pageSize = state.pageSize;
      final sortOption = state.sortOption;
      final sortDirection = state.sortDirection;

      // 当字幕筛选开启时，不发送 subtitle 参数给服务器，而是在前端过滤
      // 这样可以同时显示服务器有字幕 和 本地字幕库有字幕的作品
      const serverSubtitleParam = 0; // 始终请求所有作品，前端过滤

      if (mode == DisplayMode.popular) {
        response = await _apiService.getPopularWorks(
          page: page,
          pageSize: pageSize,
          subtitle: serverSubtitleParam,
        );
      } else if (mode == DisplayMode.recommended) {
        final currentUser = _ref.read(authProvider).currentUser;
        final recommenderUuid = currentUser?.recommenderUuid ??
            '766cc58d-7f1e-4958-9a93-913400f378dc';

        response = await _apiService.getRecommendedWorks(
          recommenderUuid: recommenderUuid,
          page: page,
          pageSize: pageSize,
          subtitle: serverSubtitleParam,
        );
      } else {
        response = await _apiService.getWorks(
          page: page,
          order: sortOption.value,
          sort: sortOption == SortOrder.nsfw ? 'asc' : sortDirection.value,
          subtitle: serverSubtitleParam,
          pageSize: pageSize,
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

      if (!requestGate.isCurrent(requestToken)) return;

      final latestModeState = _getModeState(mode);
      final newRawWorks = mergePagedItems<Work, int>(
        existing: latestModeState.rawWorks,
        incoming: works,
        idOf: (work) => work.id,
        replace: !append || page == 1,
      );

      final blockedItems = _ref.read(blockedItemsProvider);
      final filteredWorks = _filterWorks(newRawWorks, blockedItems);

      final totalCount = pagination?['totalCount'] as int? ?? 0;
      final currentPage = pagination?['currentPage'] as int? ?? page;

      bool hasMore;
      bool isLastPage = false;

      if (mode == DisplayMode.popular || mode == DisplayMode.recommended) {
        final currentTotal = newRawWorks.length;
        hasMore = works.length >= pageSize &&
            currentTotal < 100 &&
            currentTotal < totalCount;
        isLastPage = !hasMore && filteredWorks.isNotEmpty;
      } else {
        hasMore = (currentPage * pageSize) < totalCount;
        isLastPage = !hasMore && filteredWorks.isNotEmpty;
      }

      _log.captureOutput(
          '[WorksProvider] Loaded ${filteredWorks.length} works (filtered from ${newRawWorks.length}), total: ${filteredWorks.length}, hasMore: $hasMore, currentPage: $currentPage');

      _updateModeState(
        mode,
        (snapshot) => snapshot.copyWith(
          works: filteredWorks,
          rawWorks: newRawWorks,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          currentPage: currentPage,
          totalCount: totalCount,
          hasMore: hasMore,
          isLastPage: isLastPage,
          error: null,
          loadMoreError: null,
        ),
      );
    } catch (e) {
      if (!requestGate.isCurrent(requestToken)) return;
      _log.captureOutput('Failed to load works: $e');

      final message = '加载失败: ${e.toString()}';
      _updateModeState(
        mode,
        (snapshot) => snapshot.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: append ? null : message,
          loadMoreError: append ? message : null,
        ),
      );
    } finally {
      requestGate.complete(requestToken);
    }
  }

  Future<void> refresh({bool resetPage = true}) async {
    await loadWorks(
      refresh: true,
      targetPage: 1,
      supersede: true,
    );
  }

  Future<void> loadMore() async {
    final modeState = _getModeState(state.displayMode);
    if (modeState.isLoading || !modeState.hasMore) return;
    await loadWorks(
      targetPage: modeState.currentPage + 1,
      append: true,
    );
  }

  // 跳转到指定页(仅全部模式)
  Future<void> goToPage(int page) async {
    if (state.displayMode != DisplayMode.all) return;
    if (page < 1) return;

    // 检查页码是否超出范围
    final maxPage = (state.totalCount / state.pageSize).ceil();
    if (page > maxPage && maxPage > 0) return;

    await loadWorks(targetPage: page);
  }

  // 下一页(仅全部模式)
  Future<void> nextPage() async {
    if (state.displayMode != DisplayMode.all) return;
    if (!state.hasMore || state.isLoading) return;
    await loadMore();
  }

  // 上一页(仅全部模式)
  Future<void> previousPage() async {
    if (state.displayMode != DisplayMode.all) return;
    if (state.currentPage <= 1 || state.isLoading) return;
    await loadWorks(targetPage: state.currentPage - 1);
  }

  void setSortOption(SortOrder option) {
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
    _updateActiveModeState((modeState) => modeState.copyWith(error: null));
  }

  // Switch between all works and popular works
  void setDisplayMode(DisplayMode mode) {
    if (state.displayMode == mode) return;

    state = state.copyWith(displayMode: mode);

    final targetState = _getModeState(mode);
    final shouldLoadInitial =
        targetState.works.isEmpty && !targetState.isLoading;

    if (shouldLoadInitial) {
      refresh();
    }
  }

  bool get isSubtitleFilterActive =>
      SubtitleFilterMode.fromValue(state.subtitleFilter).isActive;

  // Cycle subtitle filter: all -> with subtitles -> all
  void toggleSubtitleFilter() {
    final oldFilterMode = SubtitleFilterMode.fromValue(state.subtitleFilter);
    final newFilterMode = oldFilterMode.next;
    final newFilter = newFilterMode.value;

    state = state.copyWith(subtitleFilter: newFilter);
    refresh();
  }

  void reapplyFilters() {
    final blockedItems = _ref.read(blockedItemsProvider);
    final updatedStates = state.modeStates.map((mode, snapshot) {
      final filteredWorks = _filterWorks(snapshot.rawWorks, blockedItems);
      return MapEntry(mode, snapshot.copyWith(works: filteredWorks));
    });
    state = state.copyWith(modeStates: updatedStates);
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
}

// Provider
final worksProvider = StateNotifierProvider<WorksNotifier, WorksState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  final pageSize = ref.read(pageSizeProvider);
  final defaultSort = ref.read(defaultSortProvider);

  final notifier = WorksNotifier(
    apiService,
    ref,
    initialPageSize: pageSize,
    initialSortOption: defaultSort.order,
    initialSortDirection: defaultSort.direction,
  );

  ref.listen(pageSizeProvider, (previous, next) {
    if (previous != next) {
      notifier.updatePageSize(next);
    }
  });

  ref.listen(defaultSortProvider, (previous, next) {
    if (previous != next) {
      notifier.setSortOption(next.order);
      notifier.setSortDirection(next.direction);
    }
  });

  // 监听用户切换，自动刷新作品列表
  ref.listen(currentUserProvider, (previous, next) {
    // 只有当用户真正变化时才刷新（用户名或服务器地址不同）
    final prevUser = previous;
    final nextUser = next;
    if (prevUser?.name != nextUser?.name || prevUser?.host != nextUser?.host) {
      _log.captureOutput('[WorksProvider] User changed, refreshing works list');
      notifier.refresh();
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
