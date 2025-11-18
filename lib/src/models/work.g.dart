// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Work _$WorkFromJson(Map<String, dynamic> json) => Work(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      circleId: (json['circle_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      vas: (json['vas'] as List<dynamic>?)
          ?.map((e) => Va.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      age: json['age'] as String?,
      release: json['release'] as String?,
      dlCount: (json['dl_count'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      rateCount: (json['rate_count'] as num?)?.toInt(),
      rateAverage: (json['rate_average_2dp'] as num?)?.toDouble(),
      hasSubtitle: json['has_subtitle'] as bool?,
      duration: (json['duration'] as num?)?.toInt(),
      progress: json['progress'] as String?,
      userRating: (json['userRating'] as num?)?.toInt(),
      rateCountDetail: (json['rate_count_detail'] as List<dynamic>?)
          ?.map((e) => RatingDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      description: json['description'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => AudioFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      sourceUrl: json['source_url'] as String?,
      otherLanguageEditions: (json['other_language_editions_in_db']
              as List<dynamic>?)
          ?.map((e) => OtherLanguageEdition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkToJson(Work instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'circle_id': instance.circleId,
      'name': instance.name,
      'vas': instance.vas,
      'tags': instance.tags,
      'age': instance.age,
      'release': instance.release,
      'dl_count': instance.dlCount,
      'price': instance.price,
      'review_count': instance.reviewCount,
      'rate_count': instance.rateCount,
      'rate_average_2dp': instance.rateAverage,
      'has_subtitle': instance.hasSubtitle,
      'duration': instance.duration,
      'progress': instance.progress,
      'userRating': instance.userRating,
      'rate_count_detail': instance.rateCountDetail,
      'images': instance.images,
      'description': instance.description,
      'children': instance.children,
      'source_url': instance.sourceUrl,
      'other_language_editions_in_db': instance.otherLanguageEditions,
    };

OtherLanguageEdition _$OtherLanguageEditionFromJson(
        Map<String, dynamic> json) =>
    OtherLanguageEdition(
      id: (json['id'] as num).toInt(),
      lang: json['lang'] as String,
      title: json['title'] as String,
      sourceId: json['source_id'] as String,
      isOriginal: json['is_original'] as bool,
      sourceType: json['source_type'] as String,
    );

Map<String, dynamic> _$OtherLanguageEditionToJson(
        OtherLanguageEdition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lang': instance.lang,
      'title': instance.title,
      'source_id': instance.sourceId,
      'is_original': instance.isOriginal,
      'source_type': instance.sourceType,
    };

RatingDetail _$RatingDetailFromJson(Map<String, dynamic> json) => RatingDetail(
      reviewPoint: (json['review_point'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      ratio: (json['ratio'] as num).toInt(),
    );

Map<String, dynamic> _$RatingDetailToJson(RatingDetail instance) =>
    <String, dynamic>{
      'review_point': instance.reviewPoint,
      'count': instance.count,
      'ratio': instance.ratio,
    };

Circle _$CircleFromJson(Map<String, dynamic> json) => Circle(
      id: (json['id'] as num).toInt(),
      title: json['name'] as String,
    );

Map<String, dynamic> _$CircleToJson(Circle instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.title,
    };

Va _$VaFromJson(Map<String, dynamic> json) => Va(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$VaToJson(Va instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      upvote: (json['upvote'] as num?)?.toInt(),
      downvote: (json['downvote'] as num?)?.toInt(),
      myVote: (json['myVote'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'upvote': instance.upvote,
      'downvote': instance.downvote,
      'myVote': instance.myVote,
    };

AudioFile _$AudioFileFromJson(Map<String, dynamic> json) => AudioFile(
      title: json['title'] as String,
      type: json['type'] as String?,
      hash: json['hash'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => AudioFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaDownloadUrl: json['mediaDownloadUrl'] as String?,
      size: (json['size'] as num?)?.toInt(),
      duration: json['duration'],
    );

Map<String, dynamic> _$AudioFileToJson(AudioFile instance) => <String, dynamic>{
      'title': instance.title,
      'type': instance.type,
      'hash': instance.hash,
      'children': instance.children,
      'mediaDownloadUrl': instance.mediaDownloadUrl,
      'size': instance.size,
      'duration': instance.duration,
    };
