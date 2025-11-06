enum SearchType {
  keyword('keyword', '关键词搜索', '输入作品名称或关键词...'),
  rjNumber('rj_number', 'RJ号搜索', '输入RJ号（6位数字）...'),
  va('va', '声优搜索', '选择声优...'),
  tag('tag', '标签搜索', '选择标签...'),
  ;

  const SearchType(this.value, this.label, this.hint);

  final String value;
  final String label;
  final String hint;

  static SearchType fromValue(String value) {
    return SearchType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SearchType.keyword,
    );
  }
}
