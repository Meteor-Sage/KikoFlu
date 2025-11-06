enum SortOrder {
  id('id', 'ID'),
  release('release', '发布日期'),
  dlCount('dl_count', '下载量'),
  price('price', '价格'),
  rateCount('rate_count', '评分数'),
  rating('rating', '评分'),
  reviewCount('review_count', '评论数'),
  title('title', '标题'),
  randomSeed('random', '随机'),
  ;

  const SortOrder(this.value, this.label);

  final String value;
  final String label;

  static SortOrder fromValue(String value) {
    return SortOrder.values.firstWhere(
      (order) => order.value == value,
      orElse: () => SortOrder.id,
    );
  }
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
