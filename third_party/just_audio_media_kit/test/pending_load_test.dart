import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/src/pending_load.dart';

void main() {
  test('media open errors fail the pending just_audio load', () async {
    final pendingLoad = MediaKitPendingLoad();
    final expectation = expectLater(
      pendingLoad.future,
      throwsA(
        isA<PlatformException>()
            .having((error) => error.code, 'code', '1')
            .having(
              (error) => error.message,
              'message',
              'Failed to open media',
            ),
      ),
    );

    pendingLoad.fail('Failed to open media');

    await expectation;
  });

  test('late media errors do not replace a completed load', () async {
    final pendingLoad = MediaKitPendingLoad();
    pendingLoad.complete(const Duration(seconds: 12));
    pendingLoad.fail('late error');

    expect(await pendingLoad.future, const Duration(seconds: 12));
  });
}
