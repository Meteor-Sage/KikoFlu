import '../lyric_line.dart';
import '../lyric_parser_support.dart';

class LrcLyricParser {
  const LrcLyricParser._();

  // LRC timestamps commonly use centiseconds, milliseconds, or no fraction.
  // Accept both dot and comma as the fractional separator.
  static final RegExp formatPattern = RegExp(r'\[\d+:\d{1,2}(?:[.,]\d+)?\]');
  static final RegExp metadataPattern = RegExp(r'^\[[a-z]{2}:');
  static final RegExp timestampPattern = RegExp(
    r'\[(\d+):(\d{1,2})(?:[.,](\d+))?\]',
  );

  static bool matches(String content) {
    return content.contains(formatPattern);
  }

  static List<LyricLine> parse(String content) {
    final lines = content.split('\n');
    final List<LyricLine> lyrics = [];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (metadataPattern.hasMatch(trimmedLine)) {
        continue;
      }

      final timeMatches = timestampPattern.allMatches(trimmedLine);

      if (timeMatches.isEmpty) continue;

      final timestamps = <Duration>[];
      for (final match in timeMatches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final fraction = match.group(3);
        final milliseconds = fraction == null
            ? 0
            : int.parse(fraction.padRight(3, '0').substring(0, 3));
        timestamps.add(
          Duration(
            milliseconds: minutes * 60 * 1000 + seconds * 1000 + milliseconds,
          ),
        );
      }

      final text = trimmedLine.replaceAll(timestampPattern, '').trim();

      for (final timestamp in timestamps) {
        lyrics.add(
          LyricLine(startTime: timestamp, endTime: timestamp, text: text),
        );
      }
    }

    return LyricParserSupport.finalizeLyrics(lyrics);
  }
}
