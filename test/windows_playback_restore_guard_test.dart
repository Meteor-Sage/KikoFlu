import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows session restore defers native audio loading until play', () {
    final source = File(
      'lib/src/services/audio_player_service.dart',
    ).readAsStringSync();

    final restoreStart = source.indexOf(
      'Future<void> restorePlaybackSession()',
    );
    final deferredBranch = source.indexOf(
      'if (Platform.isWindows)',
      restoreStart,
    );
    final eagerLoad = source.indexOf(
      'await _loadTrack(_queue[_currentIndex], emitCurrentTrack: false);',
      restoreStart,
    );

    expect(restoreStart, greaterThanOrEqualTo(0));
    expect(deferredBranch, greaterThan(restoreStart));
    expect(eagerLoad, greaterThan(deferredBranch));
    expect(
      source.substring(deferredBranch, eagerLoad),
      contains('Windows native source loading deferred until playback'),
    );
    expect(source, contains('await _loadDeferredRestoredSourceIfNeeded();'));
    expect(
      source,
      contains('_deferredRestorePosition != null ||'),
      reason:
          'Native zero-position events must not checkpoint while the '
          'restored source is still deferred.',
    );
    expect(
      source,
      contains('position: position,'),
      reason:
          'Lifecycle checkpoints must preserve the deferred position instead '
          'of replacing it with the unloaded native player position.',
    );
  });
}
