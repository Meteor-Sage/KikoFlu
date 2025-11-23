enum SortOrder {
  release('release', '发布日期'),
  createDate('create_date', '收录日期'),
  rating('rate_average_2dp', '评分'),
  review('review_count', '评论数'),
  randomSeed('random', '随机'),
  dlCount('dl_count', '销量'),
  price('price', '价格'),
  nsfw('nsfw', '全年龄'),
  updatedAt('updated_at', '标记时间'),
  ;

  const SortOrder(this.value, this.label);

  final String value;
  final String label;
}

enum SortDirection {
  asc('asc', '升序'),
  desc('desc', '降序'),
  ;

  const SortDirection(this.value, this.label);

  final String value;
  final String label;

  static SortDirection fromValue(String value) {
    return SortDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => SortDirection.desc,
    );
  }
}
