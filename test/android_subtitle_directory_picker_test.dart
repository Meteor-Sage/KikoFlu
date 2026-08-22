import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/android_subtitle_directory_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AndroidSubtitleDirectoryPicker.channelName);
  const picker = AndroidSubtitleDirectoryPicker(channel);
  final binding = TestDefaultBinaryMessengerBinding.instance;

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('returns the staged SAF directory and releases it by token', () async {
    final calls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'pickDirectory') {
        return <String, Object?>{
          'path': '/cache/subtitle_import_1/RJ123456',
          'token': 'temporary-token',
          'skippedCount': 4,
          'errorCount': 1,
        };
      }
      return null;
    });

    final selection = await picker.pick(
      allowedExtensions: const ['lrc', 'srt'],
    );
    await picker.release(selection!.token);

    expect(selection.path, '/cache/subtitle_import_1/RJ123456');
    expect(selection.skippedCount, 4);
    expect(selection.errorCount, 1);
    expect(calls, hasLength(2));
    expect(calls.first.method, 'pickDirectory');
    expect(calls.first.arguments, {
      'allowedExtensions': ['lrc', 'srt'],
    });
    expect(calls.last.method, 'releaseDirectory');
    expect(calls.last.arguments, {'token': 'temporary-token'});
  });

  test('returns null when the Android directory picker is cancelled', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => null,
    );

    final selection = await picker.pick(allowedExtensions: const ['lrc']);

    expect(selection, isNull);
  });

  test('rejects malformed platform responses', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => <String, Object?>{'path': '/cache/missing-token'},
    );

    expect(
      () => picker.pick(allowedExtensions: const ['lrc']),
      throwsA(isA<PlatformException>()),
    );
  });
}
