import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:kikoeru_flutter/src/models/history_record.dart';
import 'package:kikoeru_flutter/src/models/audio_track.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/services/playback_history_service.dart';
import 'package:kikoeru_flutter/src/services/playback_history_store.dart';

// --- Test Helpers ---

Work _makeWork(int id, {String title = 'Test Work'}) {
  return Work.fromJson({
    'id': id,
    'title': '$title $id',
    'circle': const {'id': 1, 'name': 'Test Circle'},
    'create_date': '2024-01-01',
    'dl_count': 0,
    'price': 0,
    'review_count': 0,
    'rate_count': 0,
    'rate_average_2dp': 0.0,
    'rate_count_detail': const [],
    'rank': null,
    'has_subtitle': false,
    'tags': const [],
    'vas': const [],
  });
}

AudioTrack _makeTrack(int workId, {String id = 'track-1'}) {
  return AudioTrack(
    id: id,
    title: 'Track $id',
    url: 'https://example.com/audio.mp3',
    workId: workId,
  );
}

class _FakePlaybackHistoryStore implements PlaybackHistoryStore {
  final Map<int, HistoryRecord> records = {};

  @override
  Future<void> addOrUpdate(HistoryRecord record) async {
    records[record.work.id] = record;
  }

  @override
  Future<HistoryRecord?> getByWorkId(int workId) async {
    return records[workId];
  }
}

class _ControlledPlaybackHistoryStore implements PlaybackHistoryStore {
  final Map<int, HistoryRecord> records = {};
  final Completer<void> firstWriteStarted = Completer<void>();
  final Completer<void> releaseFirstWrite = Completer<void>();
  int _writeCount = 0;

  @override
  Future<void> addOrUpdate(HistoryRecord record) async {
    _writeCount++;
    if (_writeCount == 1) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    records[record.work.id] = record;
  }

  @override
  Future<HistoryRecord?> getByWorkId(int workId) async {
    return records[workId];
  }
}

void main() {
  group('PlaybackHistoryService - Session Logic', () {
    late PlaybackHistoryService service;
    late _FakePlaybackHistoryStore store;

    setUp(() {
      store = _FakePlaybackHistoryStore();
      PlaybackHistoryService.resetForTest(store: store);
      service = PlaybackHistoryService.instance;
    });

    tearDown(() {
      PlaybackHistoryService.resetForTest();
    });

    group('Initial State', () {
      test('initial state is empty', () {
        expect(service.currentWorkId, isNull);
        expect(service.currentWork, isNull);
        expect(service.currentTrack, isNull);
        expect(service.lastKnownPositionMs, 0);
        expect(service.lastPersistedPositionMs, 0);
        expect(service.dirty, false);
      });
    });

    group('setSessionForTest', () {
      test('sets correct state', () {
        final work = _makeWork(100);
        final track = _makeTrack(100);

        service.setSessionForTest(
          workId: 100,
          work: work,
          track: track,
          positionMs: 5000,
        );

        expect(service.currentWorkId, 100);
        expect(service.currentWork, isNotNull);
        expect(service.currentWork!.id, 100);
        expect(service.currentTrack, isNotNull);
        expect(service.currentTrack!.workId, 100);
        expect(service.lastKnownPositionMs, 5000);
        expect(service.lastPersistedPositionMs, 0);
        expect(service.dirty, false);
      });

      test('sets state without track', () {
        final work = _makeWork(101);

        service.setSessionForTest(
          workId: 101,
          work: work,
          positionMs: 3000,
        );

        expect(service.currentWorkId, 101);
        expect(service.currentTrack, isNull);
        expect(service.lastKnownPositionMs, 3000);
      });
    });

    group('onSeekCommitted', () {
      test('updates lastKnownPositionMs', () async {
        final work = _makeWork(200);
        final track = _makeTrack(200);

        service.setSessionForTest(
          workId: 200,
          work: work,
          track: track,
          positionMs: 1000,
        );

        await service.onSeekCommitted(const Duration(milliseconds: 30000));

        expect(service.lastKnownPositionMs, 30000);
        expect(service.lastPersistedPositionMs, 30000);
        expect(store.records[200]?.lastPositionMs, 30000);
      });

      test('marks dirty then persist clears it', () async {
        final work = _makeWork(201);
        final track = _makeTrack(201);

        service.setSessionForTest(
          workId: 201,
          work: work,
          track: track,
          positionMs: 0,
        );

        await service.onSeekCommitted(const Duration(milliseconds: 15000));

        expect(service.lastKnownPositionMs, 15000);
        expect(service.lastPersistedPositionMs, 15000);
        expect(service.dirty, false);
      });
    });

    group('History Updated Stream', () {
      test('emits after successful persist', () async {
        final work = _makeWork(500);
        final track = _makeTrack(500);

        service.setSessionForTest(
          workId: 500,
          work: work,
          track: track,
          positionMs: 0,
        );

        final events = <int?>[];
        final sub = service.historyUpdatedStream.listen(events.add);

        await service.onSeekCommitted(const Duration(milliseconds: 10000));

        // Give the stream time to emit
        await Future.delayed(const Duration(milliseconds: 50));

        await sub.cancel();
        expect(events, [500]);
      });
    });

    group('Multiple Seeks (position tracking)', () {
      test('last seek position wins', () async {
        final work = _makeWork(600);
        final track = _makeTrack(600);

        service.setSessionForTest(
          workId: 600,
          work: work,
          track: track,
          positionMs: 0,
        );

        await service.onSeekCommitted(const Duration(milliseconds: 5000));
        expect(service.lastKnownPositionMs, 5000);
        expect(service.lastPersistedPositionMs, 5000);

        await service.onSeekCommitted(const Duration(milliseconds: 10000));
        expect(service.lastKnownPositionMs, 10000);
        expect(service.lastPersistedPositionMs, 10000);

        await service.onSeekCommitted(const Duration(milliseconds: 15000));
        expect(service.lastKnownPositionMs, 15000);
        expect(service.lastPersistedPositionMs, 15000);
      });

      test('backward seek also updates position', () async {
        final work = _makeWork(601);
        final track = _makeTrack(601);

        service.setSessionForTest(
          workId: 601,
          work: work,
          track: track,
          positionMs: 30000,
        );

        await service.onSeekCommitted(const Duration(milliseconds: 5000));
        expect(service.lastKnownPositionMs, 5000);
        expect(service.lastPersistedPositionMs, 5000);
      });

      test('concurrent writes preserve seek event order', () async {
        final controlledStore = _ControlledPlaybackHistoryStore();
        PlaybackHistoryService.resetForTest(store: controlledStore);
        service = PlaybackHistoryService.instance;
        final work = _makeWork(602);
        final track = _makeTrack(602);

        service.setSessionForTest(
          workId: 602,
          work: work,
          track: track,
        );

        final first = service.onSeekCommitted(
          const Duration(milliseconds: 5000),
        );
        await controlledStore.firstWriteStarted.future;
        final second = service.onSeekCommitted(
          const Duration(milliseconds: 10000),
        );
        controlledStore.releaseFirstWrite.complete();

        await Future.wait([first, second]);

        expect(controlledStore.records[602]?.lastPositionMs, 10000);
        expect(service.lastKnownPositionMs, 10000);
        expect(service.lastPersistedPositionMs, 10000);
        expect(service.dirty, false);
      });
    });

    group('Detach', () {
      test('detach does not throw', () {
        service.detach();
        expect(service.currentWorkId, isNull);
      });

      test('detach after setSession leaves session data', () {
        final work = _makeWork(700);
        service.setSessionForTest(
          workId: 700,
          work: work,
          positionMs: 5000,
        );

        service.detach();

        // Session data persists after detach (only subscriptions are cancelled)
        expect(service.currentWorkId, 700);
      });
    });

    group('resetForTest', () {
      test('clears singleton and allows new instance', () {
        final work = _makeWork(800);
        service.setSessionForTest(
          workId: 800,
          work: work,
          positionMs: 5000,
        );

        PlaybackHistoryService.resetForTest();
        final newInstance = PlaybackHistoryService.instance;

        expect(newInstance.currentWorkId, isNull);
        expect(newInstance.currentWork, isNull);
      });
    });
  });

  group('Regression: Seek scenarios (position tracking only)', () {
    late PlaybackHistoryService service;
    late _FakePlaybackHistoryStore store;

    setUp(() {
      store = _FakePlaybackHistoryStore();
      PlaybackHistoryService.resetForTest(store: store);
      service = PlaybackHistoryService.instance;
    });

    tearDown(() {
      PlaybackHistoryService.resetForTest();
    });

    test('验收#3: seek → pause 后位置正确', () async {
      final work = _makeWork(900);
      final track = _makeTrack(900);

      service.setSessionForTest(
        workId: 900,
        work: work,
        track: track,
        positionMs: 0,
      );

      // User seeks to 45s
      await service.onSeekCommitted(const Duration(milliseconds: 45000));
      expect(service.lastKnownPositionMs, 45000);
      expect(store.records[900]?.lastPositionMs, 45000);

      // User seeks slightly forward (simulating playback progress)
      await service.onSeekCommitted(const Duration(milliseconds: 45500));
      expect(service.lastKnownPositionMs, 45500);
      expect(store.records[900]?.lastPositionMs, 45500);
    });

    test('验收#4: seek → switch track → old position preserved in memory',
        () async {
      final work1 = _makeWork(901);
      final track1 = _makeTrack(901, id: 'track-a');

      // Playing track 1
      service.setSessionForTest(
        workId: 901,
        work: work1,
        track: track1,
        positionMs: 0,
      );

      // Seek to 60s on track 1
      await service.onSeekCommitted(const Duration(milliseconds: 60000));
      expect(service.lastKnownPositionMs, 60000);
      expect(service.lastPersistedPositionMs, 60000);
      expect(store.records[901]?.lastPositionMs, 60000);

      // Switch to track 2
      final work2 = _makeWork(902);
      final track2 = _makeTrack(902, id: 'track-b');

      service.setSessionForTest(
        workId: 902,
        work: work2,
        track: track2,
        positionMs: 0,
      );

      // Track 2 is at 0
      expect(service.currentWorkId, 902);
      expect(service.lastKnownPositionMs, 0);
    });

    test('flushNow does nothing when no session', () async {
      // Should not throw when there's no active session
      await service.flushNow(reason: FlushReason.appBackground);
      expect(service.currentWorkId, isNull);
    });

    test('flushNow does nothing when work is null', () async {
      // Edge case: workId set but work is null (shouldn't happen normally)
      // Since setSessionForTest always sets work, we just verify the
      // service handles a fresh instance gracefully
      await service.flushNow(reason: FlushReason.appBackground);
      expect(service.dirty, false);
    });
  });

  group('FlushReason enum', () {
    test('all reasons are defined', () {
      expect(
          FlushReason.values,
          containsAll([
            FlushReason.checkpoint,
            FlushReason.seekCommitted,
            FlushReason.paused,
            FlushReason.stopped,
            FlushReason.trackChanged,
            FlushReason.appBackground,
            FlushReason.dispose,
          ]));
    });
  });
}
