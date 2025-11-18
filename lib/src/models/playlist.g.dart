// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
      id: json['id'] as String,
      userName: json['user_name'] as String,
      privacy: (json['privacy'] as num).toInt(),
      locale: json['locale'] as String,
      playbackCount: (json['playback_count'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      worksCount: (json['works_count'] as num).toInt(),
      latestWorkID: (json['latestWorkID'] as num?)?.toInt(),
      mainCoverUrl: json['mainCoverUrl'] as String,
    );

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
      'id': instance.id,
      'user_name': instance.userName,
      'privacy': instance.privacy,
      'locale': instance.locale,
      'playback_count': instance.playbackCount,
      'name': instance.name,
      'description': instance.description,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'works_count': instance.worksCount,
      'latestWorkID': instance.latestWorkID,
      'mainCoverUrl': instance.mainCoverUrl,
    };

PlaylistPagination _$PlaylistPaginationFromJson(Map<String, dynamic> json) =>
    PlaylistPagination(
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      totalCount: (json['totalCount'] as num).toInt(),
    );

Map<String, dynamic> _$PlaylistPaginationToJson(PlaylistPagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'pageSize': instance.pageSize,
      'totalCount': instance.totalCount,
    };

PlaylistResponse _$PlaylistResponseFromJson(Map<String, dynamic> json) =>
    PlaylistResponse(
      playlists: (json['playlists'] as List<dynamic>)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PlaylistPagination.fromJson(
          json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlaylistResponseToJson(PlaylistResponse instance) =>
    <String, dynamic>{
      'playlists': instance.playlists,
      'pagination': instance.pagination,
    };
