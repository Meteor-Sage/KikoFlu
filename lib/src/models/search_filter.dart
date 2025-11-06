enum SearchFilter {
  all('all', '全部'),
  marked('marked', '已标记'),
  listening('listening', '正在听'),
  listened('listened', '已听完'),
  replay('replay', '重听'),
  postponed('postponed', '延后'),
  ;

  const SearchFilter(this.value, this.label);

  final String value;
  final String label;

  static SearchFilter fromValue(String value) {
    return SearchFilter.values.firstWhere(
      (filter) => filter.value == value,
      orElse: () => SearchFilter.all,
    );
  }
}
