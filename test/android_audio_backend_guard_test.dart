import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android keeps just_audio native backend and patched Media3', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final androidBuild =
        File('android/app/build.gradle.kts').readAsStringSync();

    expect(
      mainSource,
      isNot(matches(RegExp(
        r'JustAudioMediaKit\.ensureInitialized\(\s*android\s*:\s*true',
      ))),
      reason: 'Registering just_audio_media_kit for Android globally replaces '
          'the native Media3/AudioTrack backend for every audio format.',
    );
    expect(pubspec, isNot(contains('media_kit_libs_android_audio:')));
    expect(androidBuild, contains('val media3Version = "1.6.1"'));
  });
}
