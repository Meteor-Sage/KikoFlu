import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'audio_track.g.dart';

@JsonSerializable()
class AudioTrack extends Equatable {
  final String id;
  final String title;
  final String url;
  final String? artist;
  final String? album;
  final String? artworkUrl;
  final Duration? duration;
  final String? lyricUrl;
  final int? workId;
  final String? hash;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.url,
    this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
    this.lyricUrl,
    this.workId,
    this.hash,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) =>
      _$AudioTrackFromJson(json);

  Map<String, dynamic> toJson() => _$AudioTrackToJson(this);

  AudioTrack copyWith({
    String? id,
    String? title,
    String? url,
    String? artist,
    String? album,
    String? artworkUrl,
    Duration? duration,
    String? lyricUrl,
    int? workId,
    String? hash,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      duration: duration ?? this.duration,
      lyricUrl: lyricUrl ?? this.lyricUrl,
      workId: workId ?? this.workId,
      hash: hash ?? this.hash,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        artist,
        album,
        artworkUrl,
        duration,
        lyricUrl,
        workId,
        hash,
      ];
}

@JsonSerializable()
class Playlist extends Equatable {
  final String id;
  final String name;
  final List<AudioTrack> tracks;
  final int currentIndex;

  const Playlist({
    required this.id,
    required this.name,
    required this.tracks,
    this.currentIndex = 0,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistToJson(this);

  AudioTrack? get currentTrack {
    if (tracks.isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return tracks[currentIndex];
  }

  bool get hasNext => currentIndex < tracks.length - 1;
  bool get hasPrevious => currentIndex > 0;

  Playlist copyWith({
    String? id,
    String? name,
    List<AudioTrack>? tracks,
    int? currentIndex,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [id, name, tracks, currentIndex];
}
