import 'dart:async';

import 'package:flutter/services.dart';

/// Bridges media_kit's asynchronous state/error streams to just_audio's
/// awaited platform load operation.
class MediaKitPendingLoad {
  static const String errorCode = '1';

  final Completer<Duration?> _completer = Completer<Duration?>();

  Future<Duration?> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void complete(Duration? duration) {
    if (!_completer.isCompleted) {
      _completer.complete(duration);
    }
  }

  void fail(String message) {
    if (!_completer.isCompleted) {
      _completer.completeError(
        PlatformException(code: errorCode, message: message),
      );
    }
  }
}
