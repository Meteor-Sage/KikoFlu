class SubtitleMatchResult {
  const SubtitleMatchResult({
    required this.isMatch,
    required this.score,
  });

  final bool isMatch;
  final double score;

  (bool, double) toRecord() => (isMatch, score);
}

class SubtitleMatcher {
  static const _subtitleExtensions = ['.vtt', '.srt', '.txt', '.lrc'];
  static const _audioExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.m4a',
    '.aac',
    '.ogg',
    '.opus',
    '.wma',
    '.mp4',
    '.m4b',
  ];

  static SubtitleMatchResult check(
    String subtitleFileName,
    String audioFileName,
  ) {
    final lowerSubtitle = subtitleFileName.toLowerCase();
    final lowerAudio = audioFileName.toLowerCase();

    String? subtitleContentName;
    for (final ext in _subtitleExtensions) {
      if (lowerSubtitle.endsWith(ext)) {
        subtitleContentName =
            lowerSubtitle.substring(0, lowerSubtitle.length - ext.length);
        break;
      }
    }

    if (subtitleContentName == null) {
      return const SubtitleMatchResult(isMatch: false, score: 0.0);
    }

    final audioBaseName = removeAudioExtension(lowerAudio);
    final subtitleBaseName = removeAudioExtension(subtitleContentName);

    if (audioBaseName == subtitleBaseName) {
      return const SubtitleMatchResult(isMatch: true, score: 1.0);
    }

    final normalizedAudio = normalizeForMatching(audioBaseName);
    final normalizedSubtitle = normalizeForMatching(subtitleBaseName);

    if (normalizedAudio.isEmpty || normalizedSubtitle.isEmpty) {
      return const SubtitleMatchResult(isMatch: false, score: 0.0);
    }

    if (normalizedAudio == normalizedSubtitle) {
      return const SubtitleMatchResult(isMatch: true, score: 1.0);
    }

    final similarity =
        _calculateSimilarity(normalizedAudio, normalizedSubtitle);
    final threshold = normalizedAudio.length < 10 ? 0.9 : 0.85;

    return SubtitleMatchResult(
      isMatch: similarity >= threshold,
      score: similarity,
    );
  }

  static bool isSubtitleForAudio(
    String subtitleFileName,
    String audioFileName,
  ) {
    return check(subtitleFileName, audioFileName).isMatch;
  }

  static String removeAudioExtension(String fileName) {
    final lowerName = fileName.toLowerCase();
    for (final ext in _audioExtensions) {
      if (lowerName.endsWith(ext)) {
        return fileName.substring(0, fileName.length - ext.length);
      }
    }
    return fileName;
  }

  static String normalizeForMatching(String fileName) {
    var result = _foldFullWidthAscii(fileName);

    result = result.replaceAll(RegExp(r'\（.*?\）'), '');
    result = result.replaceAll(RegExp(r'\(.*?\)'), '');
    result = result.replaceAll(RegExp(r'\[.*?\]'), '');
    result = result.replaceAll(RegExp(r'【.*?】'), '');

    const suffixesToRemove = [
      '_se无',
      '_se',
      '_se有',
      '_seなし',
      '_nose',
      '_se無し',
      '_se有り',
      '_seあり',
      '_se_off',
      'se无',
      'se有',
      'seなし',
      'nose',
      'se無し',
      'se有り',
      'seあり',
      'se_off',
    ];

    for (final suffix in suffixesToRemove) {
      if (result.toLowerCase().endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length);
      }
    }

    result = result.replaceAll(
      RegExp(r'[^\w\u4e00-\u9fa5\u3040-\u309f\u30a0-\u30ff]'),
      '',
    );

    return result.trim();
  }

  static String _foldFullWidthAscii(String value) {
    return String.fromCharCodes(
      value.runes.map((codePoint) {
        if (codePoint == 0x3000) return 0x20;
        if (codePoint >= 0xFF01 && codePoint <= 0xFF5E) {
          return codePoint - 0xFEE0;
        }
        return codePoint;
      }),
    );
  }

  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final v0 = List<int>.filled(s2.length + 1, 0);
    final v1 = List<int>.filled(s2.length + 1, 0);

    for (var i = 0; i <= s2.length; i++) {
      v0[i] = i;
    }

    for (var i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (var j = 0; j < s2.length; j++) {
        final cost = s1.codeUnitAt(i) == s2.codeUnitAt(j) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((curr, next) => curr < next ? curr : next);
      }

      for (var j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }
}
