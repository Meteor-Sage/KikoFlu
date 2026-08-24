import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/providers/audio_provider.dart';
import 'package:kikoeru_flutter/src/providers/lyric_provider.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';

class _SubtitlePriorityNotifier extends SubtitleLibraryPriorityNotifier {
  _SubtitlePriorityNotifier() : super() {
    state = SubtitleLibraryPriority.lowest;
  }
}

Future<void> _waitForLyricText(
  ProviderContainer container,
  String expected,
) async {
  for (var i = 0; i < 100; i++) {
    final lyrics = container.read(lyricControllerProvider).lyrics;
    if (lyrics.isNotEmpty && lyrics.single.text == expected) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  final lyrics = container.read(lyricControllerProvider).lyrics;
  expect(lyrics, isNotEmpty);
  expect(lyrics.single.text, expected);
}

AudioTrack _track(String hash, String title) {
  return AudioTrack(
    id: hash,
    url: 'file:///$title',
    title: title,
    workId: 123,
    hash: hash,
  );
}

void main() {
  test('auto loader refreshes local subtitles when offline track changes',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'lyric_auto_loader_',
    );
    final track1Subtitle = File('${tempDir.path}/track01.lrc');
    final track2Subtitle = File('${tempDir.path}/track02.lrc');
    await track1Subtitle.writeAsString('[00:01.00]first line');
    await track2Subtitle.writeAsString('[00:01.00]second line');

    final trackChanges = StreamController<AudioTrack?>();
    final container = ProviderContainer(
      overrides: [
        currentTrackProvider.overrideWith((ref) => trackChanges.stream),
        subtitleLibraryPriorityProvider.overrideWith(
          (ref) => _SubtitlePriorityNotifier(),
        ),
      ],
    );

    addTearDown(() async {
      container.dispose();
      await trackChanges.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    container.read(fileListControllerProvider.notifier).updateFiles(
      [
        {
          'type': 'folder',
          'title': 'Disc',
          'children': [
            {
              'type': 'audio',
              'title': 'track01.mp3',
              'hash': 'track-1',
            },
            {
              'type': 'text',
              'title': 'track01.lrc',
              'hash': 'local:Disc/track01.lrc',
              'localPath': track1Subtitle.path,
            },
            {
              'type': 'audio',
              'title': 'track02.mp3',
              'hash': 'track-2',
            },
            {
              'type': 'text',
              'title': 'track02.lrc',
              'hash': 'local:Disc/track02.lrc',
              'localPath': track2Subtitle.path,
            },
          ],
        },
      ],
      workId: 123,
    );
    final autoLoaderSubscription =
        container.listen<void>(lyricAutoLoaderProvider, (_, __) {});

    trackChanges.add(_track('track-1', 'track01.mp3'));
    await _waitForLyricText(container, 'first line');

    trackChanges.add(_track('track-2', 'track02.mp3'));
    await _waitForLyricText(container, 'second line');

    autoLoaderSubscription.close();
  });

  test('auto loader restores file tree for current and later queue tracks',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'lyric_session_restore_',
    );
    final track1Subtitle = File('${tempDir.path}/track01.lrc');
    final track2Subtitle = File('${tempDir.path}/track02.lrc');
    await track1Subtitle.writeAsString('[00:01.00]restored first');
    await track2Subtitle.writeAsString('[00:01.00]restored second');

    var loaderCalls = 0;
    final trackChanges = StreamController<AudioTrack?>();
    final container = ProviderContainer(
      overrides: [
        currentTrackProvider.overrideWith((ref) => trackChanges.stream),
        subtitleLibraryPriorityProvider.overrideWith(
          (ref) => _SubtitlePriorityNotifier(),
        ),
        playbackLyricFileTreeLoaderProvider.overrideWithValue((track) async {
          loaderCalls++;
          return [
            {
              'type': 'folder',
              'title': 'Disc',
              'children': [
                {
                  'type': 'audio',
                  'title': 'track01.mp3',
                  'hash': 'track-1',
                },
                {
                  'type': 'text',
                  'title': 'track01.lrc',
                  'hash': 'local:Disc/track01.lrc',
                  'localPath': track1Subtitle.path,
                },
                {
                  'type': 'audio',
                  'title': 'track02.mp3',
                  'hash': 'track-2',
                },
                {
                  'type': 'text',
                  'title': 'track02.lrc',
                  'hash': 'local:Disc/track02.lrc',
                  'localPath': track2Subtitle.path,
                },
              ],
            },
          ];
        }),
      ],
    );

    addTearDown(() async {
      container.dispose();
      await trackChanges.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final autoLoaderSubscription =
        container.listen<void>(lyricAutoLoaderProvider, (_, __) {});

    trackChanges.add(_track('track-1', 'track01.mp3'));
    await _waitForLyricText(container, 'restored first');
    expect(loaderCalls, 1);

    trackChanges.add(_track('track-2', 'track02.mp3'));
    await _waitForLyricText(container, 'restored second');
    expect(loaderCalls, 1);

    autoLoaderSubscription.close();
  });

  test('auto loader rebuilds an offline subtitle tree after restart', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'lyric_offline_session_restore_',
    );
    final discDir = Directory('${tempDir.path}/Disc');
    await discDir.create();
    final audioFile = File('${discDir.path}/track01.mp3');
    final subtitleFile = File('${discDir.path}/track01.lrc');
    await audioFile.writeAsBytes([0]);
    await subtitleFile.writeAsString('[00:01.00]offline restored');
    await File('${tempDir.path}/work_metadata.json').writeAsString(jsonEncode({
      'id': 123,
      'children': [
        {
          'type': 'folder',
          'title': 'Disc',
          'children': [
            {
              'type': 'audio',
              'title': 'track01.mp3',
              'hash': 'remote-audio-hash',
            },
            {
              'type': 'text',
              'title': 'track01.lrc',
              'hash': 'remote-subtitle-hash',
            },
          ],
        },
      ],
    }));

    final trackChanges = StreamController<AudioTrack?>();
    final container = ProviderContainer(
      overrides: [
        currentTrackProvider.overrideWith((ref) => trackChanges.stream),
        subtitleLibraryPriorityProvider.overrideWith(
          (ref) => _SubtitlePriorityNotifier(),
        ),
      ],
    );

    addTearDown(() async {
      container.dispose();
      await trackChanges.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final autoLoaderSubscription =
        container.listen<void>(lyricAutoLoaderProvider, (_, __) {});
    trackChanges.add(AudioTrack(
      id: 'remote-audio-hash',
      url: audioFile.uri.toString(),
      title: 'track01.mp3',
      workId: 123,
      hash: 'remote-audio-hash',
      sourcePath: audioFile.path,
      subtitleWorkDirPath: tempDir.path,
    ));

    await _waitForLyricText(container, 'offline restored');
    final restoredContext = container.read(fileListControllerProvider);
    expect(restoredContext.workId, 123);
    expect(restoredContext.subtitleWorkDirPath, tempDir.path);

    autoLoaderSubscription.close();
  });
}
