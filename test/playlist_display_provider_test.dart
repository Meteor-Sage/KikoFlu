import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/playlist_display_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAsyncPreferenceLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to masonry and accepts the legacy grid value', () async {
    SharedPreferences.setMockInitialValues({
      PlaylistDisplayNotifier.preferenceKey: 'grid',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(playlistDisplayProvider), PlaylistLayoutType.masonry);
    await _pumpAsyncPreferenceLoad();
    expect(container.read(playlistDisplayProvider), PlaylistLayoutType.masonry);
  });

  test('loads and persists the selected playlist layout', () async {
    SharedPreferences.setMockInitialValues({
      PlaylistDisplayNotifier.preferenceKey: PlaylistLayoutType.list.value,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(playlistDisplayProvider), PlaylistLayoutType.masonry);
    await _pumpAsyncPreferenceLoad();
    expect(container.read(playlistDisplayProvider), PlaylistLayoutType.list);

    await container
        .read(playlistDisplayProvider.notifier)
        .updateLayout(PlaylistLayoutType.masonry);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PlaylistDisplayNotifier.preferenceKey),
      PlaylistLayoutType.masonry.value,
    );
  });

  test(
    'an immediate local selection is not overwritten by async loading',
    () async {
      SharedPreferences.setMockInitialValues({
        PlaylistDisplayNotifier.preferenceKey: PlaylistLayoutType.masonry.value,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(playlistDisplayProvider.notifier)
          .updateLayout(PlaylistLayoutType.list);
      await _pumpAsyncPreferenceLoad();

      expect(container.read(playlistDisplayProvider), PlaylistLayoutType.list);
    },
  );
}
