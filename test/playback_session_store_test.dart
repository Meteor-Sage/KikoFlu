import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/services/playback_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('playback session preserves queue, index, and exact position', () async {
    const tracks = [
      AudioTrack(
        id: 'one',
        title: 'Track one',
        url: 'https://example.com/one.mp3',
        artist: 'Artist',
        duration: Duration(minutes: 3),
        workId: 10,
        hash: 'hash-one',
      ),
      AudioTrack(
        id: 'two',
        title: 'Track two',
        url: 'file:///tmp/two.mp3',
        sourcePath: '/tmp/two.mp3',
        subtitleWorkDirPath: '/tmp',
      ),
    ];
    const snapshot = PlaybackSessionSnapshot(
      queue: tracks,
      currentIndex: 1,
      position: Duration(minutes: 1, seconds: 23, milliseconds: 456),
      ownerKey: 'https://example.com\ntester',
    );
    const store = SharedPreferencesPlaybackSessionStore();

    await store.save(snapshot);
    final restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.queue, tracks);
    expect(restored.currentIndex, 1);
    expect(restored.position, snapshot.position);
    expect(restored.ownerKey, snapshot.ownerKey);
  });

  test('position checkpoints do not rewrite queue metadata', () async {
    const store = SharedPreferencesPlaybackSessionStore();
    await store.save(const PlaybackSessionSnapshot(
      queue: [
        AudioTrack(
          id: 'track',
          title: 'Track',
          url: 'https://example.com/audio.mp3',
        ),
      ],
      currentIndex: 0,
      position: Duration(seconds: 10),
      ownerKey: 'https://example.com\ntester',
    ));
    final prefs = await SharedPreferences.getInstance();
    final originalMetadata = prefs.getString(
      SharedPreferencesPlaybackSessionStore.storageKey,
    );

    await store.savePosition(const Duration(seconds: 45));
    final restored = await store.load();

    expect(
      prefs.getString(SharedPreferencesPlaybackSessionStore.storageKey),
      originalMetadata,
    );
    expect(restored?.position, const Duration(seconds: 45));
  });

  test('clearing a completed queue removes the restorable session', () async {
    const store = SharedPreferencesPlaybackSessionStore();
    await store.save(
      const PlaybackSessionSnapshot(
        queue: [
          AudioTrack(
            id: 'track',
            title: 'Track',
            url: 'https://example.com/audio.mp3',
          ),
        ],
      currentIndex: 0,
      position: Duration(seconds: 30),
      ownerKey: 'https://example.com\ntester',
      ),
    );

    await store.clear();

    expect(await store.load(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(SharedPreferencesPlaybackSessionStore.positionKey),
      isFalse,
    );
  });

  test('invalid saved sessions are discarded instead of retried', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesPlaybackSessionStore.storageKey: jsonEncode({
        'version': PlaybackSessionSnapshot.version,
        'queue': <dynamic>[],
        'currentIndex': 0,
        'positionMs': 1000,
        'ownerKey': 'https://example.com\ntester',
      }),
    });
    const store = SharedPreferencesPlaybackSessionStore();

    expect(await store.load(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(SharedPreferencesPlaybackSessionStore.storageKey),
      isFalse,
    );
  });
}
