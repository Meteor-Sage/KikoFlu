import 'dart:math' as math;

/// User-controlled gain applied globally to every audio track.
///
/// A value of [defaultDecibels] leaves the decoded audio unchanged.
class AudioGainSettings {
  static const double minDecibels = -12;
  static const double maxDecibels = 12;
  static const double defaultDecibels = 0;
  static const double stepDecibels = 0.5;

  const AudioGainSettings({this.decibels = defaultDecibels});

  final double decibels;

  AudioGainSettings copyWith({double? decibels}) {
    return AudioGainSettings(
      decibels: normalize(decibels ?? this.decibels),
    );
  }

  static double normalize(double value) {
    if (!value.isFinite) return defaultDecibels;
    final clamped = value.clamp(minDecibels, maxDecibels).toDouble();
    return (clamped / stepDecibels).round() * stepDecibels;
  }

  static double linearMultiplier(double decibels) {
    return math.pow(10, normalize(decibels) / 20).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioGainSettings && other.decibels == decibels;

  @override
  int get hashCode => decibels.hashCode;
}
