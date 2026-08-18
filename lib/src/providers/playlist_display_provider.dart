import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlaylistLayoutType {
  masonry('masonry'),
  list('list');

  const PlaylistLayoutType(this.value);

  final String value;

  static PlaylistLayoutType fromValue(String? value) {
    if (value == 'grid') return PlaylistLayoutType.masonry;
    return PlaylistLayoutType.values.firstWhere(
      (layout) => layout.value == value,
      orElse: () => PlaylistLayoutType.masonry,
    );
  }
}

class PlaylistDisplayNotifier extends StateNotifier<PlaylistLayoutType> {
  static const String preferenceKey = 'playlist_display_layout';

  PlaylistDisplayNotifier() : super(PlaylistLayoutType.masonry) {
    _loadPreference();
  }

  bool _changedLocally = false;

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _changedLocally) return;
      state = PlaylistLayoutType.fromValue(prefs.getString(preferenceKey));
    } catch (_) {
      // Keep the default layout when preferences are unavailable.
    }
  }

  Future<void> updateLayout(PlaylistLayoutType type) async {
    _changedLocally = true;
    state = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preferenceKey, type.value);
    } catch (_) {
      // The in-memory selection remains valid for this session.
    }
  }

  Future<void> toggleLayout() {
    return updateLayout(
      state == PlaylistLayoutType.masonry
          ? PlaylistLayoutType.list
          : PlaylistLayoutType.masonry,
    );
  }
}

final playlistDisplayProvider =
    StateNotifierProvider<PlaylistDisplayNotifier, PlaylistLayoutType>(
  (ref) => PlaylistDisplayNotifier(),
);
