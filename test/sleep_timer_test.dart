import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/providers/audio_provider.dart';
import 'package:kikoeru_flutter/src/services/audio_player_service.dart';

const _track = AudioTrack(id: 'one', title: 'One', url: 'file:///one.mp3');

class _FakeAudioService implements AudioPlayerService {
  final tracks = StreamController<AudioTrack?>.broadcast(sync: true);
  final ends = StreamController<void>.broadcast(sync: true);
  int pauseCount = 0;

  @override
  AudioTrack? currentTrack = _track;

  @override
  bool playing = true;

  @override
  PlayerState get playerState => PlayerState(playing, processingState);
  ProcessingState processingState = ProcessingState.ready;

  @override
  Stream<AudioTrack?> get currentTrackStream => tracks.stream;

  @override
  Stream<void> get trackEndStream => ends.stream;

  @override
  Future<void> pause() async {
    pauseCount++;
    playing = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAudioService audio;
  late SleepTimerController timer;

  void initialize(WidgetTester tester, {DateTime Function()? now}) {
    audio = _FakeAudioService();
    timer = SleepTimerController(
      audio,
      pause: audio.pause,
      now: now ?? tester.binding.clock.now,
    );
    addTearDown(() async {
      timer.dispose();
      await audio.tracks.close();
      await audio.ends.close();
    });
  }

  testWidgets('deadline pauses once without finishing the track', (
    tester,
  ) async {
    initialize(tester);
    timer.setTimer(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 4));
    expect(audio.pauseCount, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(audio.pauseCount, 1);
    expect(timer.state.isActive, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(audio.pauseCount, 1);
  });

  testWidgets(
    'completion pauses synchronously even when track ID stays the same',
    (tester) async {
      initialize(tester);
      timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
      audio.ends.add(
        null,
      ); // Completion before the deadline must not stop playback.
      expect(audio.pauseCount, 0);
      await tester.pump(const Duration(seconds: 5));
      expect(timer.state.waitingForTrackEnd, isTrue);
      expect(audio.pauseCount, 0);
      audio.ends.add(null); // Single-track repeat / one-item looping queue.
      expect(audio.playing, isFalse);
      expect(audio.pauseCount, 1);
      expect(timer.state.isActive, isFalse);
      audio.ends.add(null);
      expect(audio.pauseCount, 1);
    },
  );

  testWidgets('last-track completion clears the waiting state', (tester) async {
    initialize(tester);
    timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
    await tester.pump(const Duration(seconds: 5));
    audio.processingState = ProcessingState.completed;
    audio.ends.add(null);
    expect(timer.state.isActive, isFalse);
    expect(audio.pauseCount, 1);
  });

  testWidgets('manual track change or queue clearing also stops waiting', (
    tester,
  ) async {
    initialize(tester);
    timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
    await tester.pump(const Duration(seconds: 5));
    audio.tracks.add(_track); // Metadata updates are not a track boundary.
    expect(audio.pauseCount, 0);
    audio.tracks.add(null);
    expect(audio.pauseCount, 1);
    expect(timer.state.isActive, isFalse);
  });

  for (final status in ['paused', 'completed', 'empty']) {
    testWidgets('deadline does not wait forever when player is $status', (
      tester,
    ) async {
      initialize(tester);
      if (status == 'paused') audio.playing = false;
      if (status == 'completed') {
        audio.processingState = ProcessingState.completed;
      }
      if (status == 'empty') audio.currentTrack = null;
      timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
      await tester.pump(const Duration(seconds: 5));
      expect(timer.state.isActive, isFalse);
      expect(audio.pauseCount, 1);
    });
  }

  testWidgets(
    'extension while waiting starts from now and removes old listeners',
    (tester) async {
      initialize(tester);
      timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
      await tester.pump(const Duration(minutes: 10));
      expect(timer.state.waitingForTrackEnd, isTrue);
      timer.addTime(const Duration(minutes: 5));
      expect(timer.state.remainingTime, const Duration(minutes: 5));
      expect(timer.state.waitingForTrackEnd, isFalse);
      expect(timer.state.finishCurrentTrack, isTrue);
      audio.ends.add(null);
      expect(audio.pauseCount, 0);
      await tester.pump(const Duration(minutes: 5));
      audio.ends.add(null);
      expect(audio.pauseCount, 1);
    },
  );

  testWidgets('cancel and replacement prevent stale timer callbacks', (
    tester,
  ) async {
    initialize(tester);
    timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
    await tester.pump(const Duration(seconds: 5));
    timer.cancelTimer();
    audio.ends.add(null);
    audio.tracks.add(null);
    expect(audio.pauseCount, 0);
    timer.setTimer(const Duration(seconds: 5));
    timer.setTimer(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 5));
    expect(audio.pauseCount, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(audio.pauseCount, 1);
  });

  testWidgets(
    'track completion checks deadline before a delayed timer callback',
    (tester) async {
      var now = DateTime(2026, 9, 5);
      initialize(tester, now: () => now);
      timer.setTimer(const Duration(seconds: 5), finishCurrentTrack: true);
      // Simulate wall time advancing while background timer dispatch is delayed.
      now = now.add(const Duration(seconds: 10));
      audio.ends.add(null);
      expect(audio.pauseCount, 1);
      expect(timer.state.isActive, isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(audio.pauseCount, 1);
    },
  );
}
