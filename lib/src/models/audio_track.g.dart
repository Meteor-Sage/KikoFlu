// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioTrack _$AudioTrackFromJson(Map<String, dynamic> json) => AudioTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      artworkUrl: json['artworkUrl'] as String?,
      duration: json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
      lyricUrl: json['lyricUrl'] as String?,
      workId: (json['workId'] as num?)?.toInt(),
      hash: json['hash'] as String?,
    );

Map<String, dynamic> _$AudioTrackToJson(AudioTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'artist': instance.artist,
      'album': instance.album,
      'artworkUrl': instance.artworkUrl,
      'duration': instance.duration?.inMicroseconds,
      'lyricUrl': instance.lyricUrl,
      'workId': instance.workId,
      'hash': instance.hash,
    };

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => AudioTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tracks': instance.tracks,
      'currentIndex': instance.currentIndex,
    };
