import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'video_track.g.dart';

@JsonSerializable()
class VideoTrack extends Equatable {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? workId;
  final String? hash;
  final int? quality; // 视频质量 (480p, 720p, 1080p等)
  final String? format; // 视频格式 (mp4, webm等)
  final int? size; // 文件大小（字节）

  const VideoTrack({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.duration,
    this.workId,
    this.hash,
    this.quality,
    this.format,
    this.size,
  });

  factory VideoTrack.fromJson(Map<String, dynamic> json) =>
      _$VideoTrackFromJson(json);

  Map<String, dynamic> toJson() => _$VideoTrackToJson(this);

  VideoTrack copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? thumbnailUrl,
    Duration? duration,
    String? workId,
    String? hash,
    int? quality,
    String? format,
    int? size,
  }) {
    return VideoTrack(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      workId: workId ?? this.workId,
      hash: hash ?? this.hash,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        description,
        thumbnailUrl,
        duration,
        workId,
        hash,
        quality,
        format,
        size,
      ];
}

@JsonSerializable()
class VideoPlaylist extends Equatable {
  final String id;
  final String name;
  final List<VideoTrack> videos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VideoPlaylist({
    required this.id,
    required this.name,
    required this.videos,
    this.createdAt,
    this.updatedAt,
  });

  factory VideoPlaylist.fromJson(Map<String, dynamic> json) =>
      _$VideoPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$VideoPlaylistToJson(this);

  VideoPlaylist copyWith({
    String? id,
    String? name,
    List<VideoTrack>? videos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      videos: videos ?? this.videos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, videos, createdAt, updatedAt];
}
