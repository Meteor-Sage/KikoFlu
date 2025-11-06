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
    // 检测是否是 LRC 格式（包含 [mm:ss.xx] 格式的时间戳）
    if (content.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'))) {
      return parseLRC(content);
    }
    // 否则尝试 WebVTT 格式
    return parseWebVTT(content);
  }

  // 解析 LRC 格式
  static List<LyricLine> parseLRC(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 跳过元数据标签 [ti:], [ar:], [al:], [by:], [re:], [ve:] 等
      if (RegExp(r'^\[[a-z]{2}:').hasMatch(trimmedLine)) {
        continue;
      }

      // 匹配时间戳和歌词文本：[mm:ss.xx]歌词文本
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

      // 提取歌词文本（移除所有时间戳标签）
      String text =
          trimmedLine.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'), '').trim();

      // 如果文本为空，保留为空行（用于显示间隔）
      // 每个时间戳都创建一个歌词行
      for (final timestamp in timestamps) {
        lyrics.add(LyricLine(
          startTime: timestamp,
          endTime: timestamp, // LRC 格式没有结束时间，后续会计算
          text: text,
        ));
      }
    }

    // 按时间排序
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 计算每行的结束时间（下一行的开始时间）
    // 并在间隙 > 1秒的地方插入占位符
    final List<LyricLine> finalLyrics = [];
    for (int i = 0; i < lyrics.length - 1; i++) {
      final currentLyric = LyricLine(
        startTime: lyrics[i].startTime,
        endTime: lyrics[i + 1].startTime,
        text: lyrics[i].text,
      );
      finalLyrics.add(currentLyric);

      // 检查与下一句的间隙
      final gap = lyrics[i + 1].startTime - currentLyric.endTime;
      if (gap >= const Duration(seconds: 1)) {
        // 插入占位符行（空文本表示显示 ♪）
        finalLyrics.add(LyricLine(
          startTime: currentLyric.endTime,
          endTime: lyrics[i + 1].startTime,
          text: '', // 空文本用于显示音符占位符
        ));
      }
    }

    // 最后一行的结束时间设置为开始时间 + 5秒
    if (lyrics.isNotEmpty) {
      final lastIndex = lyrics.length - 1;
      finalLyrics.add(LyricLine(
        startTime: lyrics[lastIndex].startTime,
        endTime: lyrics[lastIndex].startTime + const Duration(seconds: 5),
        text: lyrics[lastIndex].text,
      ));
    }

    return finalLyrics;
  }

  // 解析 WebVTT 格式
  static List<LyricLine> parseWebVTT(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      // 跳过 WEBVTT 标记和空行
      if (line.isEmpty || line.startsWith('WEBVTT') || line == 'NOTE') {
        i++;
        continue;
      }

      // 检查是否是序号行（纯数字）
      if (RegExp(r'^\d+$').hasMatch(line)) {
        i++;
        if (i >= lines.length) break;

        // 解析时间戳行
        final timeLine = lines[i].trim();
        final timeMatch = RegExp(
                r'(\d{2}):(\d{2}):(\d{2}\.\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}\.\d{3})')
            .firstMatch(timeLine);

        if (timeMatch != null) {
          final startTime = _parseTime(
            int.parse(timeMatch.group(1)!),
            int.parse(timeMatch.group(2)!),
            double.parse(timeMatch.group(3)!),
          );

          final endTime = _parseTime(
            int.parse(timeMatch.group(4)!),
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
      } else {
        i++;
      }
    }

    // 按时间排序
    lyrics.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 在间隙 > 1秒的地方插入占位符
    final List<LyricLine> finalLyrics = [];
    for (int i = 0; i < lyrics.length; i++) {
      finalLyrics.add(lyrics[i]);

      // 检查与下一句的间隙
      if (i < lyrics.length - 1) {
        final gap = lyrics[i + 1].startTime - lyrics[i].endTime;
        if (gap >= const Duration(seconds: 1)) {
          // 插入占位符行（空文本表示显示 ♪）
          finalLyrics.add(LyricLine(
            startTime: lyrics[i].endTime,
            endTime: lyrics[i + 1].startTime,
            text: '', // 空文本用于显示音符占位符
          ));
        }
      }
    }

    return finalLyrics;
  }

  static Duration _parseTime(int hours, int minutes, double seconds) {
    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
    return Duration(milliseconds: (totalSeconds * 1000).round());
  }

  // 根据当前播放时间获取当前歌词
  // 如果当前时间在歌词之间的间隙中，且间隙 < 1秒，则显示上一句歌词
  static String? getCurrentLyric(List<LyricLine> lyrics, Duration position) {
    for (int i = 0; i < lyrics.length; i++) {
      final lyric = lyrics[i];
      if (position >= lyric.startTime && position < lyric.endTime) {
        return lyric.text;
      }

      // 检查是否在当前歌词结束后、下一句歌词开始前的间隙中
      if (i < lyrics.length - 1) {
        final nextLyric = lyrics[i + 1];
        if (position >= lyric.endTime && position < nextLyric.startTime) {
          final gap = nextLyric.startTime - lyric.endTime;
          // 如果间隙 < 1秒，显示上一句歌词
          if (gap < const Duration(seconds: 1)) {
            return lyric.text;
          }
          // 如果间隙 >= 1秒，返回 null（显示占位符）
          return null;
        }
      }
    }
    return null;
  }
}
