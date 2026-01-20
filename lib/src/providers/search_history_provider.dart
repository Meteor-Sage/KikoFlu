import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史记录项
class SearchHistoryItem {
  /// 唯一标识符
  final String id;

  /// 搜索关键词（用于 API 请求）
  final String keyword;

  /// 搜索条件的可读描述
  final String displayText;

  /// 搜索时间
  final DateTime timestamp;

  /// 搜索参数（包含条件详情）
  final Map<String, dynamic>? searchParams;

  const SearchHistoryItem({
    required this.id,
    required this.keyword,
    required this.displayText,
    required this.timestamp,
    this.searchParams,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'keyword': keyword,
        'displayText': displayText,
        'timestamp': timestamp.toIso8601String(),
        'searchParams': searchParams,
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      displayText: json['displayText'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      searchParams: json['searchParams'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistoryItem &&
          runtimeType == other.runtimeType &&
          keyword == other.keyword;

  @override
  int get hashCode => keyword.hashCode;
}

/// 搜索历史状态
class SearchHistoryState {
  final List<SearchHistoryItem> items;
  final bool isLoading;

  const SearchHistoryState({
    this.items = const [],
    this.isLoading = false,
  });

  SearchHistoryState copyWith({
    List<SearchHistoryItem>? items,
    bool? isLoading,
  }) {
    return SearchHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 搜索历史 Notifier
class SearchHistoryNotifier extends StateNotifier<SearchHistoryState> {
  static const String _preferenceKey = 'search_history';
  static const int _maxHistoryItems = 20; // 最多保存20条记录

  SearchHistoryNotifier() : super(const SearchHistoryState(isLoading: true)) {
    _loadHistory();
  }

  /// 从本地存储加载历史记录
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_preferenceKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final items = jsonList
            .map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();

        state = SearchHistoryState(items: items, isLoading: false);
      } else {
        state = const SearchHistoryState(isLoading: false);
      }
    } catch (e) {
      state = const SearchHistoryState(isLoading: false);
    }
  }

  /// 保存历史记录到本地存储
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.items.map((e) => e.toJson()).toList();
      await prefs.setString(_preferenceKey, json.encode(jsonList));
    } catch (e) {
      // 保存失败静默处理
    }
  }

  /// 添加搜索记录
  Future<void> addHistory({
    required String keyword,
    required String displayText,
    Map<String, dynamic>? searchParams,
  }) async {
    // 创建新记录
    final newItem = SearchHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      keyword: keyword,
      displayText: displayText,
      timestamp: DateTime.now(),
      searchParams: searchParams,
    );

    // 移除相同关键词的旧记录
    final updatedItems =
        state.items.where((item) => item.keyword != keyword).toList();

    // 添加新记录到开头
    updatedItems.insert(0, newItem);

    // 限制历史记录数量
    if (updatedItems.length > _maxHistoryItems) {
      updatedItems.removeRange(_maxHistoryItems, updatedItems.length);
    }

    state = state.copyWith(items: updatedItems);
    await _saveHistory();
  }

  /// 移除单条记录
  Future<void> removeHistory(String id) async {
    final updatedItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: updatedItems);
    await _saveHistory();
  }

  /// 清空所有历史记录
  Future<void> clearHistory() async {
    state = state.copyWith(items: []);
    await _saveHistory();
  }
}

/// 搜索历史 Provider
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, SearchHistoryState>((ref) {
  return SearchHistoryNotifier();
});
