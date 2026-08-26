import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS 15+ floating lyrics use immediate sample-buffer frames', () {
    final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(
      source,
      contains('if #available(iOS 15.0, *)'),
      reason: 'Modern iOS should use the public custom-content PiP API.',
    );
    expect(
      source,
      contains('sampleBufferDisplayLayer: displayLayer'),
      reason: 'Dynamic lyrics should bypass AVPlayer video pre-rendering.',
    );
    expect(
      source,
      contains('screen.nativeScale'),
      reason: 'PiP render density should follow the active display.',
    );
    expect(
      source,
      contains('CMSampleBufferGetSampleAttachmentsArray'),
      reason: 'Sample attachments must use the Core Media sample array.',
    );
    expect(
      source,
      contains('kCMSampleAttachmentKey_DisplayImmediately'),
      reason: 'Each changed lyric should replace the displayed frame at once.',
    );
    expect(
      source,
      contains('sampleBufferHeartbeatInterval: TimeInterval = 0.25'),
      reason: 'Static lyrics still need a live sample-buffer cadence for PiP.',
    );
    expect(
      source,
      contains('startSampleBufferHeartbeat()'),
      reason: 'The cadence must start with the PiP lifecycle.',
    );
    expect(
      source,
      contains('sampleBufferFrameGeneration == generation'),
      reason: 'Heartbeat frames should reuse pixels until the lyric changes.',
    );
    expect(
      source,
      contains('sampleBufferRenderer.enqueue(sampleBuffer)'),
      reason:
          'iOS 17+ must use the renderer API instead of the deprecated layer queue.',
    );
    expect(
      source,
      contains('CMSampleBufferCreateForImageBuffer'),
      reason: 'Image-backed sample buffers should explicitly mark data ready.',
    );
    expect(
      source,
      contains('removingDisplayedImage: true'),
      reason: 'Interrupted renderers must remove stale decoded images before resuming.',
    );
    expect(
      source,
      contains('stopSampleBufferHeartbeat()'),
      reason: 'The cadence must stop when PiP closes.',
    );
    expect(
      source,
      contains('displayLayer.opacity = 1'),
      reason:
          'The PiP source must not inherit the old near-transparent output.',
    );
    expect(
      source,
      contains(
        'displayLayer.bounds = CGRect(origin: .zero, size: logicalFrameSize)',
      ),
      reason:
          'The PiP source needs nondegenerate point bounds with the frame aspect ratio.',
    );
    expect(source, contains('displayLayer.contentsScale = renderScale'));
    expect(
      source,
      contains('parentLayer.insertSublayer(displayLayer, below: view.layer)'),
      reason:
          'The full-size source must stay behind Flutter instead of covering it.',
    );
    expect(
      source,
      isNot(contains('displayLayer.frame = CGRect(x: 0, y: 0, width: 1')),
      reason:
          'A 1x1 source can produce a black PiP mirror on stricter iOS versions.',
    );
    expect(
      source,
      contains('kCVImageBufferCGColorSpaceKey'),
      reason:
          'Device rendering needs an explicit color space on the IOSurface.',
    );
    expect(
      source,
      contains('kCVImageBufferAlphaChannelIsOpaque'),
      reason: 'The opaque lyric frame should publish matching alpha metadata.',
    );
    expect(
      source,
      isNot(contains('CMSetAttachment(')),
      reason: 'DisplayImmediately is a sample attachment, not a buffer one.',
    );
    expect(
      source,
      contains('AVPictureInPictureController(playerLayer: layer)'),
      reason: 'iOS 13 and 14 still need the existing player-backed fallback.',
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
    expect(nativeSource, contains('sample_buffer_frame_enqueued'));
    expect(nativeSource, contains('sample_buffer_frame_content'));
    expect(nativeSource, contains('sampleBufferLastCreationFailureStage'));
    expect(nativeSource, contains('sampleBufferNonMonotonicTimestampCount'));
    expect(nativeSource, contains('sample_buffer_failed_to_decode'));
    expect(nativeSource, contains('sample_buffer_cadence_stalled'));
    expect(nativeSource, contains('sampleBufferMaximumEnqueueGapMilliseconds'));
    expect(nativeSource, contains('stopRequestedByApp'));
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
