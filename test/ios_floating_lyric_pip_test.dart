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
      contains('screen.nativeScale'),
      reason: 'PiP render density should follow the active display.',
    );
    expect(
      source,
      contains('composition.renderSize = renderSize'),
      reason: 'The video compositor should output the adaptive frame size.',
    );
    expect(
      source,
      contains('CGRect(origin: .zero, size: request.renderSize)'),
      reason: 'Each lyric frame should render at the requested output size.',
    );
    expect(
      source,
      contains('composition.frameDuration = CMTime'),
      reason: 'Lyric updates should not be limited by the 1 fps source video.',
    );
    expect(
      source,
      contains('outputFrameRate: Int32 = 30'),
      reason: 'Active PiP rendering should not add visible subtitle latency.',
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

  test('floating lyrics use a low-latency playback position timer', () {
    final providerSource = File(
      'lib/src/providers/floating_lyric_provider.dart',
    ).readAsStringSync();

    expect(providerSource, contains('Timer.periodic('));
    expect(
      providerSource,
      contains('Timer.periodic(const Duration(milliseconds: 50)'),
    );
    expect(providerSource, contains('_positionTimer?.cancel()'));
  });
}
