import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS floating lyrics render inside the PiP media content', () {
    final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(
      source,
      contains('AVSampleBufferDisplayLayer'),
      reason: 'iOS 15+ should use the public custom-media PiP content source.',
    );
    expect(
      source,
      contains('applyingCIFiltersWithHandler'),
      reason:
          'Older iOS versions should composite lyrics into the video frame.',
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
}
