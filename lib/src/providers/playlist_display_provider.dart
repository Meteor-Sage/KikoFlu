import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放列表显示布局类型
enum PlaylistLayoutType {
  masonry('masonry'),
  list('list');

  const PlaylistLayoutType(this.value);

  final String value;

  static PlaylistLayoutType fromValue(String? value) {
    return PlaylistLayoutType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlaylistLayoutType.masonry,
    );
  }
}

/// 播放列表显示布局设置
class PlaylistDisplayNotifier extends StateNotifier<PlaylistLayoutType> {
  static const String preferenceKey = 'playlist_display_layout';

  PlaylistDisplayNotifier() : super(PlaylistLayoutType.masonry) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = PlaylistLayoutType.fromValue(prefs.getString(preferenceKey));
    } catch (e) {
      state = PlaylistLayoutType.masonry;
    }
  }

  Future<void> updateLayout(PlaylistLayoutType type) async {
    state = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preferenceKey, type.value);
    } catch (e) {
      // ignore
    }
  }
}

/// 播放列表显示布局提供者
final playlistDisplayProvider =
    StateNotifierProvider<PlaylistDisplayNotifier, PlaylistLayoutType>((ref) {
  return PlaylistDisplayNotifier();
});
