// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoTrack _$VideoTrackFromJson(Map<String, dynamic> json) => VideoTrack(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
      workId: json['workId'] as String?,
      hash: json['hash'] as String?,
      quality: (json['quality'] as num?)?.toInt(),
      format: json['format'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VideoTrackToJson(VideoTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'thumbnailUrl': instance.thumbnailUrl,
      'duration': instance.duration?.inMicroseconds,
      'workId': instance.workId,
      'hash': instance.hash,
      'quality': instance.quality,
      'format': instance.format,
      'size': instance.size,
    };

VideoPlaylist _$VideoPlaylistFromJson(Map<String, dynamic> json) =>
    VideoPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      videos: (json['videos'] as List<dynamic>)
          .map((e) => VideoTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$VideoPlaylistToJson(VideoPlaylist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'videos': instance.videos,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
