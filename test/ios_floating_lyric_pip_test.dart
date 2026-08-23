import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS floating lyrics render into AVPlayerLayer video frames', () {
    final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(
      source,
      contains('AVPictureInPictureController(playerLayer: layer)'),
      reason: 'PiP should use the existing player-backed media pipeline.',
    );
    expect(
      source,
      contains('applyingCIFiltersWithHandler'),
      reason: 'Lyrics should be composited into every PiP video frame.',
    );
    expect(
      source,
      isNot(contains('AVSampleBufferDisplayLayer')),
      reason:
          'The unverified sample-buffer pipeline produced black PiP output.',
    );
    expect(
      source,
      isNot(contains('UIApplication.shared.windows')),
      reason:
          'The app window list cannot reliably identify the system PiP window.',
    );
    expect(
      source,
      isNot(contains('window.addSubview')),
      reason: 'A full-window lyric view can cover the main Flutter interface.',
    );
  });

  test('iOS PiP diagnostics are forwarded to exportable app logs', () {
    final nativeSource = File(
      'ios/Runner/AppDelegate.swift',
    ).readAsStringSync();
    final dartSource = File(
      'lib/src/services/floating_lyric_service.dart',
    ).readAsStringSync();

    expect(nativeSource, contains('invokeMethod("onDiagnostic"'));
    expect(nativeSource, contains('pip_health_check'));
    expect(nativeSource, contains('video_compositor_first_frame'));
    expect(dartSource, contains("case 'onDiagnostic':"));
    expect(dartSource, contains("tag: 'FloatingLyric.iOS'"));
  });
}
