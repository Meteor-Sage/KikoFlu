import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps Flutter and AppKit on the same effective appearance.
///
/// Flutter normally reports macOS appearance through PlatformDispatcher. On
/// affected macOS/Flutter combinations that value can remain light, while
/// AppKit views continue to update. This bridge uses NSApp's KVO-compliant
/// effectiveAppearance as the source of truth for macOS only.
class PlatformAppearanceService extends ChangeNotifier {
  PlatformAppearanceService._();

  static final instance = PlatformAppearanceService._();

  static const _channel = MethodChannel('com.meteor.kikoeruflutter/appearance');

  Brightness? _effectiveBrightness;
  bool _initialized = false;

  Brightness? get effectiveBrightness => _effectiveBrightness;

  Future<void> initialize() async {
    if (!Platform.isMacOS || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCall);
    try {
      _setBrightness(
        _parseBrightness(
          await _channel.invokeMethod<String>('getEffectiveBrightness'),
        ),
      );
    } on PlatformException {
      // MaterialApp can still fall back to PlatformDispatcher on older builds.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (!Platform.isMacOS) return;
    try {
      final value = await _channel.invokeMethod<String>('setAppearance', {
        'mode': mode.name,
      });
      _setBrightness(_parseBrightness(value));
    } on PlatformException {
      // The Flutter theme remains functional even if the native bridge is
      // unavailable, so appearance sync is intentionally best effort.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'effectiveBrightnessChanged') {
      _setBrightness(_parseBrightness(call.arguments as String?));
    }
  }

  Brightness? _parseBrightness(String? value) => switch (value) {
    'dark' => Brightness.dark,
    'light' => Brightness.light,
    _ => null,
  };

  void _setBrightness(Brightness? value) {
    if (value == null || value == _effectiveBrightness) return;
    _effectiveBrightness = value;
    notifyListeners();
  }

  static ThemeMode resolveMacOSThemeMode(
    ThemeMode requested,
    Brightness? effectiveBrightness,
  ) {
    if (requested != ThemeMode.system || effectiveBrightness == null) {
      return requested;
    }
    return effectiveBrightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
