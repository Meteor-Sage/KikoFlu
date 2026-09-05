import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/providers/audio_provider.dart';
import 'package:kikoeru_flutter/src/services/audio_player_service.dart';

const _first = AudioTrack(
  id: '1',
  title: 'First',
  url: 'https://example.test/1',
);
const _second = AudioTrack(
  id: '2',
  title: 'Second',
  url: 'https://example.test/2',
);

class _Player extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  int plays = 0;
  int seeks = 0;
  int loads = 0;
  Completer<Duration?>? loading;
  Completer<void>? seeking;

  @override
  bool playing = true;
  @override
  ProcessingState processingState = ProcessingState.ready;
  @override
  PlayerState get playerState => PlayerState(playing, processingState);
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  void complete() {
    processingState = ProcessingState.completed;
    states.add(playerState);
  }

  @override
  Future<void> play() async {
    plays++;
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
    states.add(playerState); // Pausing at EOF emits another completed state.
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seeks++;
    await seeking?.future;
    processingState = ProcessingState.ready;
  }

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    loads++;
    await loading?.future;
    processingState = ProcessingState.ready;
    return const Duration(minutes: 10);
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  @override
  Future<void> dispose() => states.close();
}

// Keep persistence out of these tests while exercising the real playback logic.
class _Service extends AudioPlayerService {
  _Service(super.player, {required super.queue}) : super.forTesting();

  @override
  Future<void> persistPlaybackPosition() async {}
  @override
  Future<void> persistPlaybackSession() async {}
}

void main() {
  for (final mode in LoopMode.values) {
    testWidgets('normal playback still advances or repeats in $mode', (
      tester,
    ) async {
      final player = _Player();
      final service = _Service(player, queue: [_first, _second]);
      await service.setRepeatMode(mode);
      player.complete();
      await tester.pump();
      expect(player.plays, 1);
      expect(player.seeks, mode == LoopMode.one ? 1 : 0);
      expect(player.loads, mode == LoopMode.one ? 0 : 1);
      await service.dispose();
    });

    testWidgets('sleep completion prevents advance/repeat in $mode', (
      tester,
    ) async {
      final player = _Player();
      final service = _Service(player, queue: [_first, _second]);
      final timer = SleepTimerController(
        service,
        pause: service.pause,
        now: tester.binding.clock.now,
      );
      await service.setRepeatMode(mode);
      timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
      await tester.pump(const Duration(seconds: 5));
      player.complete();
      await tester.pump();
      // Flush the second completed notification caused by pause as well.
      await tester.pump();
      expect(player.playing, isFalse);
      expect(player.plays, 0);
      expect(player.loads, 0);
      expect(player.seeks, 0);
      expect(timer.state.isActive, isFalse);
      timer.dispose();
      await service.dispose();
    });
  }

  testWidgets(
    'timer pause during next-track loading is not undone by autoplay',
    (tester) async {
      final player = _Player()..loading = Completer<Duration?>();
      final service = _Service(player, queue: [_first, _second]);
      final timer = SleepTimerController(
        service,
        pause: service.pause,
        now: tester.binding.clock.now,
      );
      timer.setTimer(const Duration(seconds: 5));
      final switching = service.skipToNext();
      await tester.pump();
      expect(player.loads, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(player.playing, isFalse);
      player.loading!.complete(const Duration(minutes: 10));
      await switching;
      expect(player.plays, 0);
      timer.dispose();
      await service.dispose();
    },
  );

  testWidgets('timer pause during repeat seek is not undone by autoplay', (
    tester,
  ) async {
    final player = _Player()..seeking = Completer<void>();
    final service = _Service(player, queue: [_first]);
    final timer = SleepTimerController(
      service,
      pause: service.pause,
      now: tester.binding.clock.now,
    );
    await service.setRepeatMode(LoopMode.one);
    timer.setTimer(const Duration(seconds: 5));
    player.complete();
    await tester.pump();
    expect(player.seeks, 1);
    await tester.pump(const Duration(seconds: 5));
    player.seeking!.complete();
    await tester.pump();
    expect(player.playing, isFalse);
    expect(player.plays, 0);
    timer.dispose();
    await service.dispose();
  });
}
