enum SearchType {
  keyword('keyword', '关键词', '输入作品名称或关键词...'),
  tag('tag', '标签', '输入标签名...'),
  va('va', '声优', '输入声优名...'),
  circle('circle', '社团', '输入社团名...'),
  rjNumber('rj', 'RJ号', '输入数字...'),
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

enum AgeRating {
  all('', '全部'),
  general('general', '全年龄'),
  r15('r15', 'R-15'),
  adult('adult', '成人向'),
  ;

  const AgeRating(this.value, this.label);

  final String value;
  final String label;
}

enum SalesRange {
  all(0, '全部'),
  over100(100, '100+'),
  over300(300, '300+'),
  over500(500, '500+'),
  over700(700, '700+'),
  over1000(1000, '1000+'),
  over2000(2000, '2000+'),
  ;

  const SalesRange(this.value, this.label);

  final int value;
  final String label;
}

class SearchCriteria {
  final String? keyword;
  final String? rjNumber;
  final String? tag;
  final String? circle;
  final String? va;
  final double? minRate;
  final AgeRating? ageRating;
  final SalesRange? salesRange;

  SearchCriteria({
    this.keyword,
    this.rjNumber,
    this.tag,
    this.circle,
    this.va,
    this.minRate,
    this.ageRating,
    this.salesRange,
  });

  String buildSearchKeyword() {
    List<String> parts = [];

    if (keyword != null && keyword!.isNotEmpty) {
      parts.add(keyword!);
    }
    if (rjNumber != null && rjNumber!.isNotEmpty) {
      parts.add(rjNumber!);
    }
    if (tag != null && tag!.isNotEmpty) {
      parts.add('\$tag:$tag\$');
    }
    if (circle != null && circle!.isNotEmpty) {
      parts.add('\$circle:$circle\$');
    }
    if (va != null && va!.isNotEmpty) {
      parts.add('\$va:$va\$');
    }
    if (minRate != null && minRate! > 0) {
      parts.add('\$rate:${minRate!.toInt()}\$');
    }
    if (ageRating != null && ageRating!.value.isNotEmpty) {
      parts.add('\$age:${ageRating!.value}\$');
    }
    if (salesRange != null && salesRange!.value > 0) {
      parts.add('\$sell:${salesRange!.value}\$');
    }

    return parts.isEmpty ? '' : ' ${parts.join(' ')}';
  }

  bool get isEmpty =>
      (keyword == null || keyword!.isEmpty) &&
      (rjNumber == null || rjNumber!.isEmpty) &&
      (tag == null || tag!.isEmpty) &&
      (circle == null || circle!.isEmpty) &&
      (va == null || va!.isEmpty) &&
      (minRate == null || minRate! <= 0) &&
      (ageRating == null || ageRating == AgeRating.all) &&
      (salesRange == null || salesRange == SalesRange.all);

  SearchCriteria copyWith({
    String? keyword,
    String? rjNumber,
    String? tag,
    String? circle,
    String? va,
    double? minRate,
    AgeRating? ageRating,
    SalesRange? salesRange,
  }) {
    return SearchCriteria(
      keyword: keyword ?? this.keyword,
      rjNumber: rjNumber ?? this.rjNumber,
      tag: tag ?? this.tag,
      circle: circle ?? this.circle,
      va: va ?? this.va,
      minRate: minRate ?? this.minRate,
      ageRating: ageRating ?? this.ageRating,
      salesRange: salesRange ?? this.salesRange,
    );
  }
}
