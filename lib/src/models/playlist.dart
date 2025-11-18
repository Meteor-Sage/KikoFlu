import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'playlist.g.dart';

/// 播放列表隐私设置
enum PlaylistPrivacy {
  /// 私享 - 只有您可以观看
  private(0, '私享', '只有您可以观看'),

  /// 不公开 - 知道链接的人才能观看
  unlisted(1, '不公开', '知道链接的人才能观看'),

  /// 公开 - 任何人都可以观看
  public(2, '公开', '任何人都可以观看');

  final int value;
  final String label;
  final String description;

  const PlaylistPrivacy(this.value, this.label, this.description);

  static PlaylistPrivacy fromValue(int value) {
    return PlaylistPrivacy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlaylistPrivacy.private,
    );
  }
}

/// 播放列表模型
@JsonSerializable()
class Playlist extends Equatable {
  /// 播放列表ID
  final String id;

  /// 用户名
  @JsonKey(name: 'user_name')
  final String userName;

  /// 隐私设置 (0: 公开, 1: 私密等)
  final int privacy;

  /// 语言区域
  final String locale;

  /// 播放次数
  @JsonKey(name: 'playback_count')
  final int playbackCount;

  /// 播放列表名称
  final String name;

  /// 描述
  final String description;

  /// 创建时间
  @JsonKey(name: 'created_at')
  final String createdAt;

  /// 更新时间
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  /// 作品数量
  @JsonKey(name: 'works_count')
  final int worksCount;

  /// 最新作品ID
  @JsonKey(name: 'latestWorkID')
  final int? latestWorkID;

  /// 主封面URL
  @JsonKey(name: 'mainCoverUrl')
  final String mainCoverUrl;

  const Playlist({
    required this.id,
    required this.userName,
    required this.privacy,
    required this.locale,
    required this.playbackCount,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.worksCount,
    this.latestWorkID,
    required this.mainCoverUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistToJson(this);

  /// 获取完整的封面URL
  String getFullCoverUrl(String baseUrl, {String? token}) {
    // 如果已经是完整URL，直接返回
    if (mainCoverUrl.startsWith('http://') ||
        mainCoverUrl.startsWith('https://')) {
      return mainCoverUrl;
    }

    // 处理相对路径
    String normalizedUrl = baseUrl;
    if (baseUrl.isNotEmpty &&
        !baseUrl.startsWith('http://') &&
        !baseUrl.startsWith('https://')) {
      normalizedUrl = 'https://$baseUrl';
    }

    // 如果是默认图片，直接拼接
    if (mainCoverUrl.startsWith('/statics/')) {
      return '$normalizedUrl$mainCoverUrl';
    }

    // 带token的封面请求
    if (token != null && token.isNotEmpty) {
      return '$normalizedUrl$mainCoverUrl?token=$token';
    }

    return '$normalizedUrl$mainCoverUrl';
  }

  /// 是否为系统播放列表
  bool get isSystemPlaylist {
    return name.startsWith('__SYS_PLAYLIST_');
  }

  /// 获取系统播放列表的显示名称
  String get displayName {
    if (name == '__SYS_PLAYLIST_MARKED') {
      return '我标记的';
    } else if (name == '__SYS_PLAYLIST_LIKED') {
      return '我喜欢的';
    }
    return name;
  }

  @override
  List<Object?> get props => [
        id,
        userName,
        privacy,
        locale,
        playbackCount,
        name,
        description,
        createdAt,
        updatedAt,
        worksCount,
        latestWorkID,
        mainCoverUrl,
      ];
}

/// 播放列表分页信息
@JsonSerializable()
class PlaylistPagination extends Equatable {
  final int page;
  final int pageSize;
  final int totalCount;

  const PlaylistPagination({
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory PlaylistPagination.fromJson(Map<String, dynamic> json) =>
      _$PlaylistPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistPaginationToJson(this);

  @override
  List<Object?> get props => [page, pageSize, totalCount];
}

/// 播放列表响应模型
@JsonSerializable()
class PlaylistResponse extends Equatable {
  final List<Playlist> playlists;
  final PlaylistPagination pagination;

  const PlaylistResponse({
    required this.playlists,
    required this.pagination,
  });

  factory PlaylistResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaylistResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistResponseToJson(this);

  @override
  List<Object?> get props => [playlists, pagination];
}
