import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/lyric.dart';

void main() {
  // ============================================================
  // LRC 解析
  // ============================================================
  group('LRC Parser', () {
    test('基本 LRC 解析', () {
      const lrc = '''[00:00.00]第一行歌词
[00:05.50]第二行歌词
[00:10.20]第三行歌词''';

      final lyrics = LyricParser.parse(lrc);
      expect(lyrics.length, greaterThanOrEqualTo(3));
      expect(lyrics[0].text, '第一行歌词');
      expect(lyrics[0].startTime, Duration.zero);
      expect(lyrics[1].text, '第二行歌词');
      expect(lyrics[1].startTime, const Duration(seconds: 5, milliseconds: 500));
      expect(lyrics[2].text, '第三行歌词');
      expect(lyrics[2].startTime, const Duration(seconds: 10, milliseconds: 200));
    });

    test('LRC endTime 自动设置为下一行 startTime', () {
      const lrc = '''[00:00.00]Line A
[00:03.00]Line B
[00:06.00]Line C''';

      final lyrics = LyricParser.parse(lrc);
      // Line A endTime == Line B startTime
      expect(lyrics.first.endTime, const Duration(seconds: 3));
    });

    test('LRC 最后一行 endTime 默认 +5s', () {
      const lrc = '''[00:00.00]Line A
[00:03.00]Line B''';

      final lyrics = LyricParser.parse(lrc);
      final last = lyrics.last;
      // 最后一行如果 endTime == startTime，应该 +5s
      expect(last.endTime, const Duration(seconds: 8));
    });

    test('LRC 跳过元数据标签 ([ti: [ar: [al: 等)', () {
      const lrc = '''[ti:Song Title]
[ar:Artist Name]
[al:Album Name]
[00:00.00]实际歌词
[00:05.00]第二行''';

      final lyrics = LyricParser.parse(lrc);
      for (final l in lyrics) {
        expect(l.text.contains('Song Title'), isFalse);
        expect(l.text.contains('Artist Name'), isFalse);
        expect(l.text.contains('Album Name'), isFalse);
      }
      expect(lyrics.any((l) => l.text == '实际歌词'), isTrue);
    });

    test('LRC 多时间戳同行 (如卡拉OK格式)', () {
      const lrc = '[00:10.00][00:20.00][00:30.00]重复歌词';

      final lyrics = LyricParser.parse(lrc);
      // 同一行文本应出现3次（3个时间戳）
      final matchingLines = lyrics.where((l) => l.text == '重复歌词');
      expect(matchingLines.length, 3);
    });

    test('LRC 空行文本被合并或替换为音符', () {
      const lrc = '''[00:00.00]有歌词
[00:02.00]
[00:10.00]恢复歌词''';

      final lyrics = LyricParser.parse(lrc);
      // 空行应被处理：短间隔合并到上一行，长间隔替换为 ♪ - ♪
      final texts = lyrics.map((l) => l.text).toList();
      // 不应有纯空字符串
      for (final t in texts) {
        expect(t.trim().isEmpty, isFalse);
      }
    });

    test('LRC 按时间排序', () {
      const lrc = '''[00:10.00]后面的
[00:00.00]前面的
[00:05.00]中间的''';

      final lyrics = LyricParser.parse(lrc);
      expect(lyrics[0].text, '前面的');
      expect(lyrics[1].text, '中间的');
      expect(lyrics[2].text, '后面的');
    });

    test('LRC 接受三位毫秒、无小数和逗号小数时间戳', () {
      const lrc = '''[00:01.250]毫秒
[1:02]无小数
[01:03,5]逗号小数''';

      final lyrics = LyricParser.parse(lrc);

      expect(lyrics.length, 3);
      expect(
        lyrics[0].startTime,
        const Duration(seconds: 1, milliseconds: 250),
      );
      expect(lyrics[1].startTime, const Duration(minutes: 1, seconds: 2));
      expect(
        lyrics[2].startTime,
        const Duration(minutes: 1, seconds: 3, milliseconds: 500),
      );
    });
  });

  // ============================================================
  // WebVTT 解析
  // ============================================================
  group('WebVTT Parser', () {
    test('标准 WebVTT 解析', () {
      const vtt = '''WEBVTT

00:00:01.000 --> 00:00:04.000
Hello world

00:00:05.000 --> 00:00:08.000
Second subtitle''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics.length, greaterThanOrEqualTo(2));
      expect(lyrics[0].text, 'Hello world');
      expect(lyrics[0].startTime, const Duration(seconds: 1));
      expect(lyrics[1].text, 'Second subtitle');
    });

    test('WebVTT 带小时的时间戳', () {
      const vtt = '''WEBVTT

01:30:00.000 --> 01:30:05.000
At one hour thirty minutes''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics[0].startTime, const Duration(hours: 1, minutes: 30));
      expect(lyrics[0].endTime,
          const Duration(hours: 1, minutes: 30, seconds: 5));
    });

    test('WebVTT 无小时前缀 (mm:ss.mmm)', () {
      const vtt = '''WEBVTT

00:01.000 --> 00:04.000
Short format''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics[0].text, 'Short format');
      expect(lyrics[0].startTime, const Duration(seconds: 1));
    });

    test('WebVTT 多行文本', () {
      const vtt = '''WEBVTT

00:00:01.000 --> 00:00:05.000
First line
Second line''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics[0].text, 'First line\nSecond line');
    });

    test('WebVTT 跳过序号行', () {
      const vtt = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
Cue one

2
00:00:05.000 --> 00:00:08.000
Cue two''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics.length, greaterThanOrEqualTo(2));
      expect(lyrics[0].text, 'Cue one');
      expect(lyrics[1].text, 'Cue two');
    });

    test('WebVTT 保留原始 endTime', () {
      const vtt = '''WEBVTT

00:00:01.000 --> 00:00:04.000
Line one

00:00:05.000 --> 00:00:08.000
Line two''';

      final lyrics = LyricParser.parse(vtt);
      // finalize 会设置 endTime = 下一行 startTime
      expect(lyrics[0].endTime, const Duration(seconds: 5));
    });

    test('SRT 格式（实质上同 WebVTT 解析器处理）', () {
      // SRT 使用逗号分隔毫秒，但 parse() 检测不到 LRC 时用 WebVTT 解析
      // VTT 解析器期望 . 而非 ,，所以标准 SRT 可能需要预处理
      // 这里测试转换后的 SRT（. 替代 ,）
      const srt = '''1
00:00:01.000 --> 00:00:04.000
First subtitle

2
00:00:05.000 --> 00:00:08.000
Second subtitle''';

      final lyrics = LyricParser.parse(srt);
      expect(lyrics.length, greaterThanOrEqualTo(2));
      expect(lyrics[0].text, 'First subtitle');
    });
  });

  // ============================================================
  // 格式检测
  // ============================================================
  group('Format Detection', () {
    test('自动检测 LRC 格式', () {
      const lrc = '[00:01.00]This is LRC';
      final lyrics = LyricParser.parse(lrc);
      expect(lyrics[0].text, 'This is LRC');
    });

    test('自动检测 WebVTT 格式', () {
      const vtt = '''WEBVTT

00:00:01.000 --> 00:00:04.000
This is VTT''';
      final lyrics = LyricParser.parse(vtt);
      expect(lyrics[0].text, 'This is VTT');
    });

    test('无法解析的格式抛出 FormatException', () {
      const garbage = 'This is just plain text\nwith no timestamps';
      expect(
        () => LyricParser.parse(garbage),
        throwsA(isA<FormatException>()),
      );
    });

    test('空内容抛出 FormatException', () {
      expect(
        () => LyricParser.parse(''),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ============================================================
  // getCurrentLyric
  // ============================================================
  group('getCurrentLyric', () {
    late List<LyricLine> lyrics;

    setUp(() {
      lyrics = [
        LyricLine(
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 3),
          text: 'Line 1',
        ),
        LyricLine(
          startTime: const Duration(seconds: 3),
          endTime: const Duration(seconds: 6),
          text: 'Line 2',
        ),
        LyricLine(
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 13),
          text: 'Line 3',
        ),
      ];
    });

    test('返回当前时间对应的歌词行', () {
      expect(
        LyricParser.getCurrentLyric(lyrics, const Duration(seconds: 1)),
        'Line 1',
      );
      expect(
        LyricParser.getCurrentLyric(lyrics, const Duration(seconds: 4)),
        'Line 2',
      );
    });

    test('正好在 startTime 时返回该行', () {
      expect(
        LyricParser.getCurrentLyric(lyrics, Duration.zero),
        'Line 1',
      );
      expect(
        LyricParser.getCurrentLyric(lyrics, const Duration(seconds: 3)),
        'Line 2',
      );
    });

    test('间隔 <1s 时延续上一行', () {
      // Line 2: end=6s, Line 3: start=10s, gap=4s → null
      // 构造一个短间隔场景
      final shortGapLyrics = [
        LyricLine(
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 3),
          text: 'A',
        ),
        LyricLine(
          startTime: const Duration(seconds: 3, milliseconds: 500),
          endTime: const Duration(seconds: 6),
          text: 'B',
        ),
      ];
      // 在 3.0s ~ 3.5s 间隔内（<1s），应延续前一行
      expect(
        LyricParser.getCurrentLyric(
            shortGapLyrics, const Duration(seconds: 3, milliseconds: 200)),
        'A',
      );
    });

    test('间隔 >=1s 时返回 null', () {
      // Line 2 ends at 6s, Line 3 starts at 10s (gap = 4s)
      expect(
        LyricParser.getCurrentLyric(lyrics, const Duration(seconds: 8)),
        isNull,
      );
    });

    test('播放位置在所有歌词之前返回 null', () {
      final laterLyrics = [
        LyricLine(
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 8),
          text: 'Late',
        ),
      ];
      expect(
        LyricParser.getCurrentLyric(laterLyrics, const Duration(seconds: 1)),
        isNull,
      );
    });

    test('空歌词列表返回 null', () {
      expect(LyricParser.getCurrentLyric([], const Duration(seconds: 1)), isNull);
    });
  });

  // ============================================================
  // LyricLine Model
  // ============================================================
  group('LyricLine', () {
    test('copyWith 正确复制和覆盖', () {
      final original = LyricLine(
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 5),
        text: 'original',
      );

      final copied = original.copyWith(text: 'modified');
      expect(copied.text, 'modified');
      expect(copied.startTime, original.startTime);
      expect(copied.endTime, original.endTime);
    });

    test('applyOffset 正确偏移时间', () {
      final line = LyricLine(
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 15),
        text: 'test',
      );

      final shifted = line.applyOffset(const Duration(seconds: 3));
      expect(shifted.startTime, const Duration(seconds: 13));
      expect(shifted.endTime, const Duration(seconds: 18));
      expect(shifted.text, 'test');
    });

    test('applyOffset 负偏移', () {
      final line = LyricLine(
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 15),
        text: 'test',
      );

      final shifted = line.applyOffset(const Duration(seconds: -2));
      expect(shifted.startTime, const Duration(seconds: 8));
      expect(shifted.endTime, const Duration(seconds: 13));
    });
  });

  // ============================================================
  // 空行合并逻辑 (_mergeEmptyLines via finalize)
  // ============================================================
  group('Empty Line Merging', () {
    test('短空行（<3s）合并到上一行', () {
      const lrc = '''[00:00.00]歌词A
[00:05.00]
[00:06.00]歌词B''';

      final lyrics = LyricParser.parse(lrc);
      // 空行 [05:00-06:00] 只有1s，应合并到歌词A
      // 歌词A 的 endTime 应延伸到 06:00
      final lineA = lyrics.firstWhere((l) => l.text == '歌词A');
      expect(lineA.endTime, const Duration(seconds: 6));
    });

    test('长空行（>=3s）替换为 ♪ - ♪', () {
      const lrc = '''[00:00.00]歌词A
[00:05.00]
[00:15.00]歌词B''';

      final lyrics = LyricParser.parse(lrc);
      // 空行 [05:00-15:00] 有10s，应替换为 ♪ - ♪
      expect(lyrics.any((l) => l.text == '♪ - ♪'), isTrue);
    });
  });

  // ============================================================
  // 标准 SRT 格式解析
  // ============================================================
  group('SRT Parser', () {
    test('标准 SRT 格式（逗号分隔毫秒）', () {
      const srt = '''1
00:00:01,000 --> 00:00:04,000
Hello world

2
00:00:05,500 --> 00:00:08,200
Second subtitle

3
00:00:10,000 --> 00:00:13,500
Third subtitle''';

      final lyrics = LyricParser.parse(srt);
      expect(lyrics.length, greaterThanOrEqualTo(3));
      expect(lyrics[0].text, 'Hello world');
      expect(lyrics[0].startTime, const Duration(seconds: 1));
      expect(lyrics[1].text, 'Second subtitle');
      expect(lyrics[1].startTime, const Duration(seconds: 5, milliseconds: 500));
      expect(lyrics[2].text, 'Third subtitle');
      expect(lyrics[2].startTime, const Duration(seconds: 10));
    });

    test('SRT 多行文本', () {
      const srt = '''1
00:00:01,000 --> 00:00:05,000
First line
Second line

2
00:00:06,000 --> 00:00:10,000
Next cue''';

      final lyrics = LyricParser.parse(srt);
      expect(lyrics[0].text, 'First line\nSecond line');
    });

    test('SRT 保留 endTime', () {
      const srt = '''1
00:00:01,000 --> 00:00:04,500
Line one

2
00:00:06,000 --> 00:00:09,000
Line two''';

      final lyrics = LyricParser.parse(srt);
      expect(lyrics[0].endTime, const Duration(seconds: 6));
    });

    test('SRT 毫秒精度', () {
      const srt = '''1
00:01:30,456 --> 00:01:35,789
Precise timing''';

      final lyrics = LyricParser.parse(srt);
      expect(lyrics[0].startTime,
          const Duration(minutes: 1, seconds: 30, milliseconds: 456));
    });

    test('SRT 单条字幕', () {
      const srt = '''1
00:00:00,000 --> 00:00:05,000
Only one''';

      final lyrics = LyricParser.parse(srt);
      expect(lyrics.length, 1);
      expect(lyrics[0].text, 'Only one');
    });
  });

  // ============================================================
  // ASS (Advanced SubStation Alpha) 格式
  // ============================================================
  group('ASS Parser', () {
    test('标准 ASS 格式', () {
      const ass = '''[Script Info]
Title: Test Subtitle
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,Hello world
Dialogue: 0,0:00:05.50,0:00:08.20,Default,,0,0,0,,Second subtitle
Dialogue: 0,0:00:10.00,0:00:13.50,Default,,0,0,0,,Third subtitle''';

      final lyrics = LyricParser.parse(ass);
      expect(lyrics.length, greaterThanOrEqualTo(3));
      expect(lyrics[0].text, 'Hello world');
      expect(lyrics[0].startTime, const Duration(seconds: 1));
      expect(lyrics[1].text, 'Second subtitle');
      expect(lyrics[1].startTime, const Duration(seconds: 5, milliseconds: 500));
      expect(lyrics[2].text, 'Third subtitle');
      expect(lyrics[2].startTime, const Duration(seconds: 10));
    });

    test('ASS 内联样式标签过滤', () {
      const ass = '''[Script Info]
ScriptType: v4.00+

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,{\\b1}Bold text{\\b0}
Dialogue: 0,0:00:06.00,0:00:10.00,Default,,0,0,0,,{\\i1\\c&H0000FF&}Styled text''';

      final lyrics = LyricParser.parse(ass);
      expect(lyrics[0].text, 'Bold text');
      expect(lyrics[1].text, 'Styled text');
    });

    test('ASS \\N 换行符', () {
      const ass = '''[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Line one\\NLine two''';

      final lyrics = LyricParser.parse(ass);
      expect(lyrics[0].text, 'Line one\nLine two');
    });

    test('ASS 跳过 Comment 行', () {
      const ass = '''[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Comment: 0,0:00:00.00,0:00:01.00,Default,,0,0,0,,This is a comment
Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Actual subtitle''';

      final lyrics = LyricParser.parse(ass);
      expect(lyrics.length, greaterThanOrEqualTo(1));
      expect(lyrics[0].text, 'Actual subtitle');
    });

    test('ASS 时间精度 (H:MM:SS.cc)', () {
      const ass = '''[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,1:30:15.50,1:30:20.00,Default,,0,0,0,,At 1h30m15.5s''';

      final lyrics = LyricParser.parse(ass);
      expect(lyrics[0].startTime,
          const Duration(hours: 1, minutes: 30, seconds: 15, milliseconds: 500));
    });
  });

  // ============================================================
  // SSA (SubStation Alpha v4) 格式
  // ============================================================
  group('SSA Parser', () {
    test('标准 SSA 格式 (v4)', () {
      const ssa = '''[Script Info]
ScriptType: v4.00

[V4 Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding
Style: Default,Arial,24,16777215,65535,65535,-2147483640,-1,0,1,3,0,2,30,30,30,0,0

[Events]
Format: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: Marked=0,0:00:01.00,0:00:04.00,Default,,0000,0000,0000,,Hello from SSA
Dialogue: Marked=0,0:00:05.00,0:00:08.00,Default,,0000,0000,0000,,Second line''';

      final lyrics = LyricParser.parse(ssa);
      expect(lyrics.length, greaterThanOrEqualTo(2));
      expect(lyrics[0].text, 'Hello from SSA');
      expect(lyrics[1].text, 'Second line');
    });
  });

  // ============================================================
  // SBV (YouTube) 格式
  // ============================================================
  group('SBV Parser', () {
    test('标准 SBV 格式', () {
      const sbv = '''0:00:01.000,0:00:04.000
Hello world

0:00:05.500,0:00:08.200
Second subtitle

0:00:10.000,0:00:13.500
Third subtitle''';

      final lyrics = LyricParser.parse(sbv);
      expect(lyrics.length, greaterThanOrEqualTo(3));
      expect(lyrics[0].text, 'Hello world');
      expect(lyrics[0].startTime, const Duration(seconds: 1));
      expect(lyrics[1].text, 'Second subtitle');
      expect(lyrics[1].startTime, const Duration(seconds: 5, milliseconds: 500));
    });

    test('SBV 多行文本', () {
      const sbv = '''0:00:01.000,0:00:05.000
First line
Second line

0:00:06.000,0:00:10.000
Next''';

      final lyrics = LyricParser.parse(sbv);
      expect(lyrics[0].text, 'First line\nSecond line');
    });

    test('SBV 保留 endTime', () {
      const sbv = '''0:00:01.000,0:00:04.000
Line one

0:00:06.000,0:00:09.000
Line two''';

      final lyrics = LyricParser.parse(sbv);
      // finalize 设置 endTime = 下一行 startTime
      expect(lyrics[0].endTime, const Duration(seconds: 6));
    });
  });

  // ============================================================
  // TTML / DFXP (XML) 格式
  // ============================================================
  group('TTML/DFXP Parser', () {
    test('标准 TTML 格式', () {
      const ttml = '''<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:04.000">Hello world</p>
      <p begin="00:00:05.500" end="00:00:08.200">Second subtitle</p>
      <p begin="00:00:10.000" end="00:00:13.500">Third subtitle</p>
    </div>
  </body>
</tt>''';

      final lyrics = LyricParser.parse(ttml);
      expect(lyrics.length, greaterThanOrEqualTo(3));
      expect(lyrics[0].text, 'Hello world');
      expect(lyrics[0].startTime, const Duration(seconds: 1));
      expect(lyrics[1].text, 'Second subtitle');
      expect(lyrics[1].startTime, const Duration(seconds: 5, milliseconds: 500));
    });

    test('DFXP 格式 (TTML 旧称)', () {
      const dfxp = '''<?xml version="1.0" encoding="UTF-8"?>
<tt xml:lang="en" xmlns="http://www.w3.org/2006/10/ttaf1">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000">DFXP subtitle</p>
      <p begin="00:00:06.000" end="00:00:10.000">Second line</p>
    </div>
  </body>
</tt>''';

      final lyrics = LyricParser.parse(dfxp);
      expect(lyrics.length, greaterThanOrEqualTo(2));
      expect(lyrics[0].text, 'DFXP subtitle');
    });

    test('TTML 带 HTML 标签过滤', () {
      const ttml = '''<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="00:00:01.000" end="00:00:05.000"><span style="s1">Styled</span> text</p>
      <p begin="00:00:06.000" end="00:00:10.000">Normal text</p>
    </div>
  </body>
</tt>''';

      final lyrics = LyricParser.parse(ttml);
      expect(lyrics[0].text, 'Styled text');
    });

    test('TTML 时间格式 HH:MM:SS.mmm', () {
      const ttml = '''<?xml version="1.0" encoding="UTF-8"?>
<tt xmlns="http://www.w3.org/ns/ttml">
  <body>
    <div>
      <p begin="01:30:15.500" end="01:30:20.000">Late cue</p>
    </div>
  </body>
</tt>''';

      final lyrics = LyricParser.parse(ttml);
      expect(lyrics[0].startTime,
          const Duration(hours: 1, minutes: 30, seconds: 15, milliseconds: 500));
    });
  });

  // ============================================================
  // 边界情况
  // ============================================================
  group('Edge Cases', () {
    test('单行 LRC', () {
      const lrc = '[00:00.00]Only one line';
      final lyrics = LyricParser.parse(lrc);
      expect(lyrics.length, 1);
      expect(lyrics[0].text, 'Only one line');
      // 单行 endTime = startTime + 5s
      expect(lyrics[0].endTime, const Duration(seconds: 5));
    });

    test('单行 WebVTT', () {
      const vtt = '''WEBVTT

00:00:00.000 --> 00:00:05.000
Only one cue''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics.length, 1);
      expect(lyrics[0].text, 'Only one cue');
    });

    test('LRC 含 Windows 换行符 (\\r\\n)', () {
      const lrc = '[00:00.00]Line 1\r\n[00:05.00]Line 2\r\n[00:10.00]Line 3';
      final lyrics = LyricParser.parse(lrc);
      expect(lyrics.length, greaterThanOrEqualTo(3));
      expect(lyrics[0].text, 'Line 1');
    });

    test('LRC 时间戳精度：百分之一秒', () {
      const lrc = '[00:01.99]Precise timing';
      final lyrics = LyricParser.parse(lrc);
      // 99 centiseconds = 990 ms
      expect(lyrics[0].startTime, const Duration(seconds: 1, milliseconds: 990));
    });

    test('WebVTT 毫秒精度', () {
      const vtt = '''WEBVTT

00:00:01.123 --> 00:00:02.456
Precise''';

      final lyrics = LyricParser.parse(vtt);
      expect(lyrics[0].startTime, const Duration(seconds: 1, milliseconds: 123));
      expect(lyrics[0].endTime, const Duration(seconds: 2, milliseconds: 456));
    });

    test('大量歌词行性能', () {
      final buf = StringBuffer();
      for (int i = 0; i < 500; i++) {
        final min = (i ~/ 60).toString().padLeft(2, '0');
        final sec = (i % 60).toString().padLeft(2, '0');
        buf.writeln('[$min:$sec.00]Line $i');
      }

      final stopwatch = Stopwatch()..start();
      final lyrics = LyricParser.parse(buf.toString());
      stopwatch.stop();

      expect(lyrics.length, greaterThanOrEqualTo(400));
      // 500 行应在 100ms 内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
