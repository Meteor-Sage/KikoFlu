import 'package:flutter/services.dart';

class AndroidSubtitleDirectorySelection {
  const AndroidSubtitleDirectorySelection({
    required this.path,
    required this.token,
    required this.skippedCount,
    required this.errorCount,
  });

  final String path;
  final String token;
  final int skippedCount;
  final int errorCount;
}

class AndroidSubtitleDirectoryPicker {
  const AndroidSubtitleDirectoryPicker([
    this._channel = const MethodChannel(channelName),
  ]);

  static const channelName =
      'com.meteor.kikoeruflutter/subtitle_directory_picker';

  final MethodChannel _channel;

  Future<AndroidSubtitleDirectorySelection?> pick({
    required List<String> allowedExtensions,
  }) async {
    final response = await _channel.invokeMapMethod<String, Object?>(
      'pickDirectory',
      {'allowedExtensions': allowedExtensions},
    );
    if (response == null) return null;

    final path = response['path'];
    final token = response['token'];
    if (path is! String || path.isEmpty || token is! String || token.isEmpty) {
      throw PlatformException(
        code: 'invalid_response',
        message: 'Android subtitle directory picker returned invalid data.',
      );
    }

    return AndroidSubtitleDirectorySelection(
      path: path,
      token: token,
      skippedCount: response['skippedCount'] as int? ?? 0,
      errorCount: response['errorCount'] as int? ?? 0,
    );
  }

  Future<void> release(String token) async {
    await _channel.invokeMethod<void>('releaseDirectory', {'token': token});
  }
}
