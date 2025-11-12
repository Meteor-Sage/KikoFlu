// 歌词行模型
class LyricLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
  });
}

// 歌词解析器
class LyricParser {
  // 自动检测格式并解析
  static List<LyricLine> parse(String content) {
    List<LyricLine> result = [];

    // 检测是否是 LRC 格式（包含 [mm:ss.xx] 格式的时间戳）
    if (content.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'))) {
      result = parseLRC(content);
    } else {
      // 尝试 WebVTT 格式
      result = parseWebVTT(content);
    }

    // 如果解析结果为空，提示失败
    if (result.isEmpty) {
      throw const FormatException("解析失败，格式不支持");
    }

    return result;
  }

  // 解析 LRC 格式
  static List<LyricLine> parseLRC(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 跳过元数据标签
      if (RegExp(r'^\[[a-z]{2}:').hasMatch(trimmedLine)) {
        continue;
      }

      // 匹配时间戳
      final timeMatches =
          RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]').allMatches(trimmedLine);

      if (timeMatches.isEmpty) continue;

      // 提取所有时间戳
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

      // 提取歌词文本
      String text =
          trimmedLine.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'), '').trim();

      // 每个时间戳创建一行
      for (final timestamp in timestamps) {
        lyrics.add(LyricLine(
          startTime: timestamp,
          endTime: timestamp, // 后面计算
          text: text,
        ));
      }
    }

    return _finalizeLyrics(lyrics);
  }

  // 解析 WebVTT 格式（不依赖序号行）
  static List<LyricLine> parseWebVTT(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      // 跳过 WEBVTT 标记、NOTE 和空行
      if (line.isEmpty || line.startsWith('WEBVTT') || line == 'NOTE') {
        i++;
        continue;
      }

      // 匹配时间戳行（支持 hh:mm:ss.mmm 或 mm:ss.mmm）
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

        // 读取歌词文本（可能多行）
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

  // 公共的后处理逻辑（排序 + 结束时间计算，让歌词时间无缝衔接）
  static List<LyricLine> _finalizeLyrics(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];

    // 按时间排序
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<LyricLine> finalLyrics = [];

    // 处理每一行歌词，让它们无缝衔接
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

  // 根据当前播放时间获取当前歌词
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
