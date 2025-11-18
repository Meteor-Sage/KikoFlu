import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/playlist.dart';
import '../services/kikoeru_api_service.dart' hide kikoeruApiServiceProvider;
import 'auth_provider.dart';

class PlaylistsState extends Equatable {
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;
  final int pageSize;

  const PlaylistsState({
    this.playlists = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.pageSize = 20,
  });

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
    int? pageSize,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        playlists,
        isLoading,
        error,
        currentPage,
        totalCount,
        hasMore,
        pageSize,
      ];
}

class PlaylistsNotifier extends StateNotifier<PlaylistsState> {
  final KikoeruApiService _apiService;

  PlaylistsNotifier(this._apiService) : super(const PlaylistsState());

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.currentPage;

    state = state.copyWith(isLoading: true, error: null, currentPage: page);

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

      // 获取分页信息
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final totalCount = pagination?['totalCount'] ?? 0;
      final pageSize = pagination?['pageSize'] ?? state.pageSize;

      // 计算是否有更多页
      final totalPages = totalCount > 0 ? (totalCount / pageSize).ceil() : 1;
      final hasMore = page < totalPages;

      state = state.copyWith(
        playlists: playlists,
        totalCount: totalCount,
        hasMore: hasMore,
        isLoading: false,
        currentPage: page,
        pageSize: pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 跳转到指定页
  Future<void> goToPage(int page) async {
    if (page < 1 || state.isLoading) return;
    state = state.copyWith(currentPage: page);
    await load(refresh: false);
  }

  // 上一页
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      final prevPage = state.currentPage - 1;
      state = state.copyWith(currentPage: prevPage);
      await load(refresh: false);
    }
  }

  // 下一页
  Future<void> nextPage() async {
    if (state.hasMore) {
      final nextPage = state.currentPage + 1;
      state = state.copyWith(currentPage: nextPage);
      await load(refresh: false);
    }
  }

  void refresh() => load(refresh: true);
}

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, PlaylistsState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  return PlaylistsNotifier(apiService);
});
