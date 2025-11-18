class LyricLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  LyricLine copyWith({
    Duration? startTime,
    Duration? endTime,
    String? text,
  }) {
    return LyricLine(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
    );
  }

  /// 应用时间轴偏移
  LyricLine applyOffset(Duration offset) {
    return LyricLine(
      startTime: startTime + offset,
      endTime: endTime + offset,
      text: text,
    );
  }
}

class LyricParser {
  static List<LyricLine> parse(String content) {
    List<LyricLine> result = [];

    // 检测是否是 LRC 格式（包含 [mm:ss.xx] 格式的时间戳）
    if (content.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'))) {
      result = parseLRC(content);
    } else {
      // 尝试 WebVTT 格式
      result = parseWebVTT(content);
    }

    if (result.isEmpty) {
      throw const FormatException("解析失败，格式不支持");
    }

    return result;
  }

  static List<LyricLine> parseLRC(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (RegExp(r'^\[[a-z]{2}:').hasMatch(trimmedLine)) {
        continue;
      }

      final timeMatches =
          RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]').allMatches(trimmedLine);

      if (timeMatches.isEmpty) continue;

      final timestamps = <Duration>[];
      for (final match in timeMatches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        timestamps.add(Duration(
          milliseconds:
              minutes * 60 * 1000 + seconds * 1000 + centiseconds * 10,
        ));
      }

      String text =
          trimmedLine.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'), '').trim();

      for (final timestamp in timestamps) {
        lyrics.add(LyricLine(
          startTime: timestamp,
          endTime: timestamp,
          text: text,
        ));
      }
    }

    return _finalizeLyrics(lyrics);
  }

  static List<LyricLine> parseWebVTT(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.isEmpty || line.startsWith('WEBVTT') || line == 'NOTE') {
        i++;
        continue;
      }

      final timeMatch = RegExp(
              r'(?:(\d{2}):)?(\d{2}):(\d{2}\.\d{3})\s*-->\s*(?:(\d{2}):)?(\d{2}):(\d{2}\.\d{3})')
          .firstMatch(line);

      if (timeMatch != null) {
        final startTime = _parseTime(
          int.parse(timeMatch.group(1) ?? '0'),
          int.parse(timeMatch.group(2)!),
          double.parse(timeMatch.group(3)!),
        );

        final endTime = _parseTime(
          int.parse(timeMatch.group(4) ?? '0'),
          int.parse(timeMatch.group(5)!),
          double.parse(timeMatch.group(6)!),
        );

        i++;

        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }

        if (textLines.isNotEmpty) {
          lyrics.add(LyricLine(
            startTime: startTime,
            endTime: endTime,
            text: textLines.join('\n'),
          ));
        }
      } else {
        i++;
      }
    }

    return _finalizeLyrics(lyrics);
  }

  static List<LyricLine> _finalizeLyrics(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];

    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<LyricLine> finalLyrics = [];

    for (int i = 0; i < lyrics.length - 1; i++) {
      // 当前歌词的结束时间直接设置为下一行的开始时间
      finalLyrics.add(LyricLine(
        startTime: lyrics[i].startTime,
        endTime: lyrics[i + 1].startTime,
        text: lyrics[i].text,
      ));
    }

    // 最后一行
    final lastIndex = lyrics.length - 1;
    finalLyrics.add(LyricLine(
      startTime: lyrics[lastIndex].startTime,
      endTime: lyrics[lastIndex].endTime == lyrics[lastIndex].startTime
          ? lyrics[lastIndex].startTime + const Duration(seconds: 5)
          : lyrics[lastIndex].endTime,
      text: lyrics[lastIndex].text,
    ));

    return finalLyrics;
  }

  static Duration _parseTime(int hours, int minutes, double seconds) {
    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
    return Duration(milliseconds: (totalSeconds * 1000).round());
  }

  static String? getCurrentLyric(List<LyricLine> lyrics, Duration position) {
    for (int i = 0; i < lyrics.length; i++) {
      final lyric = lyrics[i];
      if (position >= lyric.startTime && position < lyric.endTime) {
        return lyric.text;
      }
      if (i < lyrics.length - 1) {
        final nextLyric = lyrics[i + 1];
        if (position >= lyric.endTime && position < nextLyric.startTime) {
          final gap = nextLyric.startTime - lyric.endTime;
          return gap < const Duration(seconds: 1) ? lyric.text : null;
        }
      }
    }
    return null;
  }
}
