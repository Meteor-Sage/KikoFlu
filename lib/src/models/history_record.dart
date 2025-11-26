import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'work.dart';
import 'audio_track.dart';

class HistoryRecord extends Equatable {
  final Work work;
  final DateTime lastPlayedTime;
  final AudioTrack? lastTrack;
  final int lastPositionMs;

  const HistoryRecord({
    required this.work,
    required this.lastPlayedTime,
    this.lastTrack,
    this.lastPositionMs = 0,
  });

  HistoryRecord copyWith({
    Work? work,
    DateTime? lastPlayedTime,
    AudioTrack? lastTrack,
    int? lastPositionMs,
  }) {
    return HistoryRecord(
      work: work ?? this.work,
      lastPlayedTime: lastPlayedTime ?? this.lastPlayedTime,
      lastTrack: lastTrack ?? this.lastTrack,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'work_id': work.id,
      'work_json': jsonEncode(work.toJson()),
      'last_played_time': lastPlayedTime.millisecondsSinceEpoch,
      'last_track_json':
          lastTrack != null ? jsonEncode(lastTrack!.toJson()) : null,
      'last_position_ms': lastPositionMs,
    };
  }

  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    return HistoryRecord(
      work: Work.fromJson(jsonDecode(map['work_json'])),
      lastPlayedTime:
          DateTime.fromMillisecondsSinceEpoch(map['last_played_time']),
      lastTrack: map['last_track_json'] != null
          ? AudioTrack.fromJson(jsonDecode(map['last_track_json']))
          : null,
      lastPositionMs: map['last_position_ms'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        work,
        lastPlayedTime,
        lastTrack,
        lastPositionMs,
      ];
}
