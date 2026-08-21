import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_track.dart';
import 'log_service.dart';

class PlaybackSessionSnapshot {
  const PlaybackSessionSnapshot({
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.ownerKey,
  });

  static const int version = 1;

  final List<AudioTrack> queue;
  final int currentIndex;
  final Duration position;
  final String ownerKey;

  Map<String, dynamic> toJson() => {
    'version': version,
    'queue': queue.map((track) => track.toJson()).toList(),
    'currentIndex': currentIndex,
    'positionMs': position.inMilliseconds,
    'ownerKey': ownerKey,
  };

  factory PlaybackSessionSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != version) {
      throw const FormatException('Unsupported playback session version');
    }

    final rawQueue = json['queue'];
    if (rawQueue is! List || rawQueue.isEmpty) {
      throw const FormatException('Playback session queue is empty');
    }

    final queue = rawQueue
        .map(
          (item) => AudioTrack.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final currentIndex = json['currentIndex'];
    if (currentIndex is! int ||
        currentIndex < 0 ||
        currentIndex >= queue.length) {
      throw const FormatException('Invalid playback session index');
    }

    final rawPosition = json['positionMs'];
    final positionMs = rawPosition is num ? rawPosition.toInt() : 0;
    final ownerKey = json['ownerKey'];
    if (ownerKey is! String || ownerKey.isEmpty) {
      throw const FormatException('Playback session owner is missing');
    }
    return PlaybackSessionSnapshot(
      queue: queue,
      currentIndex: currentIndex,
      position: Duration(milliseconds: positionMs.clamp(0, 1 << 53)),
      ownerKey: ownerKey,
    );
  }
}

abstract interface class PlaybackSessionStore {
  Future<PlaybackSessionSnapshot?> load();

  Future<void> save(PlaybackSessionSnapshot snapshot);

  Future<void> savePosition(Duration position);

  Future<void> clear();
}

class SharedPreferencesPlaybackSessionStore implements PlaybackSessionStore {
  const SharedPreferencesPlaybackSessionStore();

  static const String storageKey = 'playback_session_v1';
  static const String positionKey = 'playback_session_position_v1';

  @override
  Future<PlaybackSessionSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final json = jsonDecode(encoded);
      if (json is! Map) throw const FormatException('Invalid session JSON');
      final snapshot =
          PlaybackSessionSnapshot.fromJson(Map<String, dynamic>.from(json));
      final positionMs = prefs.getInt(positionKey);
      if (positionMs == null) return snapshot;
      return PlaybackSessionSnapshot(
        queue: snapshot.queue,
        currentIndex: snapshot.currentIndex,
        position: Duration(milliseconds: positionMs.clamp(0, 1 << 53)),
        ownerKey: snapshot.ownerKey,
      );
    } catch (error) {
      LogService.instance.captureOutput(
        '[AudioSession] Ignoring invalid saved session: $error',
      );
      await prefs.remove(storageKey);
      await prefs.remove(positionKey);
      return null;
    }
  }

  @override
  Future<void> save(PlaybackSessionSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
    await prefs.setInt(positionKey, snapshot.position.inMilliseconds);
  }

  @override
  Future<void> savePosition(Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(positionKey, position.inMilliseconds);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    await prefs.remove(positionKey);
  }
}
