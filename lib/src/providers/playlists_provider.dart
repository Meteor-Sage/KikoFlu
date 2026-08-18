import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/playlist.dart';
import '../services/kikoeru_api_service.dart' hide kikoeruApiServiceProvider;
import '../services/log_service.dart';
import '../utils/paged_collection.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

class PlaylistsState extends Equatable {
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final String? loadMoreError;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final int pageSize;
  final bool isRefreshing;
  final bool isLoadingMore;

  const PlaylistsState({
    this.playlists = const [],
    this.isLoading = false,
    this.error,
    this.loadMoreError,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.pageSize = 20,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    bool? isLoading,
    String? error,
    String? loadMoreError,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    int? pageSize,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      loadMoreError: loadMoreError,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        playlists,
        isLoading,
        error,
        loadMoreError,
        currentPage,
        totalCount,
        hasMore,
        pageSize,
        isRefreshing,
        isLoadingMore,
      ];
}

class PlaylistsNotifier extends StateNotifier<PlaylistsState> {
  final KikoeruApiService _apiService;
  final PagedRequestGate _requestGate = PagedRequestGate();

  PlaylistsNotifier(this._apiService, {int initialPageSize = 20})
      : super(PlaylistsState(pageSize: initialPageSize));

  void updatePageSize(int newSize) {
    if (state.pageSize == newSize) return;
    state = state.copyWith(pageSize: newSize);
    refresh();
  }

  Future<void> load({
    bool refresh = false,
    int? targetPage,
    bool append = false,
    bool supersede = false,
  }) async {
    final token = _requestGate.begin(supersede: supersede || refresh);
    if (token == null) return;
    final page = refresh ? 1 : (targetPage ?? state.currentPage);

    state = state.copyWith(
      isLoading: state.playlists.isEmpty,
      isRefreshing: refresh && state.playlists.isNotEmpty,
      isLoadingMore: append,
      error: null,
      loadMoreError: null,
      currentPage: page,
    );

    try {
      final result = await _apiService.getUserPlaylists(
        page: page,
        pageSize: state.pageSize,
        filterBy: 'all',
      );

      // 解析播放列表
      final List<dynamic> rawList = result['playlists'] as List? ?? [];
      final playlists = rawList
          .map((item) => Playlist.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!_requestGate.isCurrent(token)) return;

      // 获取分页信息
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] ?? 0;
      final pageSize = pagination?['pageSize'] ?? state.pageSize;

      // 计算是否有更多页
      final totalPages = totalCount > 0 ? (totalCount / pageSize).ceil() : 1;
      final hasMore = page < totalPages;
      final merged = mergePagedItems(
        existing: state.playlists,
        incoming: playlists,
        idOf: (playlist) => playlist.id,
        replace: !append,
      );

      state = state.copyWith(
        playlists: merged,
        totalCount: totalCount,
        hasMore: hasMore,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        currentPage: page,
        pageSize: pageSize,
        error: null,
        loadMoreError: null,
      );
    } catch (e) {
      if (!_requestGate.isCurrent(token)) return;
      final message = e.toString();
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: append ? null : message,
        loadMoreError: append ? message : null,
      );
    } finally {
      _requestGate.complete(token);
    }
  }

  // 跳转到指定页
  Future<void> goToPage(int page) async {
    if (page < 1 || state.isLoading) return;
    await load(targetPage: page);
  }

  // 上一页
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      final prevPage = state.currentPage - 1;
      await load(targetPage: prevPage);
    }
  }

  // 下一页
  Future<void> nextPage() async {
    await loadMore();
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isRefreshing) return;
    await load(targetPage: state.currentPage + 1, append: true);
  }

  /// 删除播放列表
  /// 根据播放列表的所有者和类型自动选择合适的删除API
  Future<void> deletePlaylist(
    Playlist playlist,
    String currentUserName,
  ) async {
    try {
      // 判断是否为当前用户创建的播放列表
      final isOwner = playlist.userName == currentUserName;

      if (isOwner) {
        // 如果是系统播放列表，不允许删除
        if (playlist.isSystemPlaylist) {
          throw Exception('系统播放列表不能删除');
        }
        // 使用删除API删除自己创建的播放列表
        await _apiService.deletePlaylist(playlist.id);
      } else {
        // 使用取消收藏API删除别人的播放列表
        await _apiService.removeLikePlaylist(playlist.id);
      }

      // 删除成功后刷新列表
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() => load(refresh: true, supersede: true);
}

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, PlaylistsState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  final pageSize = ref.read(pageSizeProvider);
  final notifier = PlaylistsNotifier(apiService, initialPageSize: pageSize);

  ref.listen(pageSizeProvider, (previous, next) {
    if (previous != next) {
      notifier.updatePageSize(next);
    }
  });

  // 监听用户切换，自动刷新播放列表
  ref.listen(currentUserProvider, (previous, next) {
    final prevUser = previous;
    final nextUser = next;
    if (prevUser?.name != nextUser?.name || prevUser?.host != nextUser?.host) {
      logOutput('[PlaylistsProvider] User changed, refreshing playlists');
      notifier.refresh();
    }
  });

  return notifier;
});
