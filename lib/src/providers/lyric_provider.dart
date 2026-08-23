import 'dart:io';
import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../models/lyric.dart';
import '../models/audio_track.dart';
import '../services/cache_service.dart';
import '../services/subtitle_library_service.dart';
import '../services/subtitle_database.dart';
import '../services/log_service.dart';
import '../utils/encoding_utils.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'audio_provider.dart';
import 'settings_provider.dart';

final _log = LogService.instance;

// 字幕状态
class LyricState {
  final List<LyricLine> lyrics;
  final bool isLoading;
  final String? error;
  final String? lyricUrl;
  final Duration timelineOffset; // 时间轴偏移（毫秒）
  final List<LyricLine>? translatedLyrics; // 翻译后的歌词
  final bool isTranslating; // 是否正在翻译
  final bool showTranslated; // 是否显示翻译
  final int translatedCount;
  final int translationTotal;
  final String? translatedSubtitlePath;

  LyricState({
    this.lyrics = const [],
    this.isLoading = false,
    this.error,
    this.lyricUrl,
    this.timelineOffset = Duration.zero,
    this.translatedLyrics,
    this.isTranslating = false,
    this.showTranslated = false,
    this.translatedCount = 0,
    this.translationTotal = 0,
    this.translatedSubtitlePath,
  });

  LyricState copyWith({
    List<LyricLine>? lyrics,
    bool? isLoading,
    String? error,
    String? lyricUrl,
    Duration? timelineOffset,
    List<LyricLine>? translatedLyrics,
    bool? isTranslating,
    bool? showTranslated,
    int? translatedCount,
    int? translationTotal,
    String? translatedSubtitlePath,
  }) {
    return LyricState(
      lyrics: lyrics ?? this.lyrics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lyricUrl: lyricUrl ?? this.lyricUrl,
      timelineOffset: timelineOffset ?? this.timelineOffset,
      translatedLyrics: translatedLyrics ?? this.translatedLyrics,
      isTranslating: isTranslating ?? this.isTranslating,
      showTranslated: showTranslated ?? this.showTranslated,
      translatedCount: translatedCount ?? this.translatedCount,
      translationTotal: translationTotal ?? this.translationTotal,
      translatedSubtitlePath:
          translatedSubtitlePath ?? this.translatedSubtitlePath,
    );
  }

  /// 获取应用了时间轴偏移后的字幕列表
  List<LyricLine> get adjustedLyrics {
    if (timelineOffset == Duration.zero) {
      return lyrics;
    }
    return lyrics.map((lyric) => lyric.applyOffset(timelineOffset)).toList();
  }

  /// 是否已翻译
  bool get isTranslated => translatedLyrics != null;

  /// 用于显示的歌词列表（翻译后 > 原文，均应用时间轴偏移）
  List<LyricLine> get displayLyrics {
    final source = (showTranslated && translatedLyrics != null)
        ? translatedLyrics!
        : lyrics;
    if (timelineOffset == Duration.zero) return source;
    return source.map((lyric) => lyric.applyOffset(timelineOffset)).toList();
  }

  /// 判断歌词是否需要翻译（大部分字符已经是当前语言则不需要）
  bool needsTranslation(Locale appLocale) {
    final allText = lyrics
        .where((l) => l.text.isNotEmpty && l.text != '♪ - ♪')
        .map((l) => l.text)
        .join();
    if (allText.length < 5) return false;

    int cjk = 0, hiragana = 0, katakana = 0, latin = 0, cyrillic = 0;
    for (final code in allText.runes) {
      if (code >= 0x4E00 && code <= 0x9FFF) {
        cjk++;
      } else if (code >= 0x3040 && code <= 0x309F) {
        hiragana++;
      } else if (code >= 0x30A0 && code <= 0x30FF) {
        katakana++;
      } else if ((code >= 0x0041 && code <= 0x005A) ||
          (code >= 0x0061 && code <= 0x007A)) {
        latin++;
      } else if (code >= 0x0400 && code <= 0x04FF) {
        cyrillic++;
      }
    }

    final total = cjk + hiragana + katakana + latin + cyrillic;
    if (total == 0) return false;

    switch (appLocale.languageCode) {
      case 'ja':
        // 日文：包含平/片假名+汉字
        return (hiragana + katakana + cjk) / total < 0.5;
      case 'zh':
        // 中文：纯汉字；有假名则可能是日语
        if (hiragana + katakana > 0) return true;
        return cjk / total < 0.5;
      case 'en':
        return latin / total < 0.5;
      case 'ru':
        return cyrillic / total < 0.5;
      default:
        return true;
    }
  }
}

// 字幕控制器
class LyricController extends StateNotifier<LyricState> {
  final Ref ref;
  int _loadRequestId = 0;
  int _translationRequestId = 0;

  LyricController(this.ref) : super(LyricState());

  int _beginLoadRequest() {
    _translationRequestId++;
    return ++_loadRequestId;
  }

  bool _isCurrentLoadRequest(int requestId) {
    return mounted && requestId == _loadRequestId;
  }

  void _setStateForLoadRequest(int requestId, LyricState nextState) {
    if (_isCurrentLoadRequest(requestId)) {
      state = nextState;
    }
  }

  LyricState _loadingStatePreservingCurrentLyrics() {
    return LyricState(
      lyrics: state.lyrics,
      isLoading: true,
      lyricUrl: state.lyricUrl,
      timelineOffset: state.timelineOffset,
    );
  }

  int _beginTranslationRequest() => ++_translationRequestId;

  bool _isCurrentTranslationRequest(int requestId) {
    return mounted && requestId == _translationRequestId;
  }

  bool _isSameTrack(AudioTrack? a, AudioTrack? b) {
    if (a == null || b == null) return identical(a, b);
    return a.id == b.id &&
        a.url == b.url &&
        a.title == b.title &&
        a.workId == b.workId &&
        a.hash == b.hash &&
        a.sourcePath == b.sourcePath;
  }

  // 根据音频轨道查找并加载字幕
  Future<void> loadLyricForTrack(
      AudioTrack track, List<dynamic> allFiles) async {
    final requestId = _beginLoadRequest();
    _log.captureOutput(
        '[Lyric] 尝试加载: track="${track.title}", workId=${track.workId}, 文件数=${allFiles.length}');
    _setStateForLoadRequest(
      requestId,
      _loadingStatePreservingCurrentLyrics(),
    );

    try {
      // 获取字幕库优先级设置
      final libraryPriority = ref.read(subtitleLibraryPriorityProvider);
      final isLibraryFirst = libraryPriority == SubtitleLibraryPriority.highest;

      _log.captureOutput('[Lyric] 字幕库优先级: ${libraryPriority.displayName}');

      // 根据设置决定查找顺序
      if (isLibraryFirst) {
        // 优先级1：从字幕库查找匹配的字幕文件
        final libraryLyricPath = await _findLyricInLibrary(track);
        if (!_isCurrentLoadRequest(requestId)) return;
        if (libraryLyricPath != null) {
          _log.captureOutput('[Lyric] 从字幕库加载: $libraryLyricPath');
          await _loadLyricFromLocalFile(libraryLyricPath, requestId);
          return;
        }
      }

      // 从完整文件树查找字幕文件
      final lyricFile = _findLyricFile(track, allFiles);

      if (lyricFile == null) {
        // 如果文件树未找到且优先级为最后，尝试字幕库
        if (!isLibraryFirst) {
          _log.captureOutput('[Lyric] 文件树未找到，尝试字幕库');
          final libraryLyricPath = await _findLyricInLibrary(track);
          if (!_isCurrentLoadRequest(requestId)) return;
          if (libraryLyricPath != null) {
            _log.captureOutput('[Lyric] 从字幕库加载: $libraryLyricPath');
            await _loadLyricFromLocalFile(libraryLyricPath, requestId);
            return;
          }
        }

        _log.captureOutput('[Lyric] 未找到匹配字幕: track="${track.title}"');
        _setStateForLoadRequest(
          requestId,
          LyricState(lyrics: [], isLoading: false),
        );
        return;
      }

      _log.captureOutput(
          '[Lyric] 找到匹配字幕: title="${lyricFile['title']}", type="${lyricFile['type']}", hash=${lyricFile['hash']}');

      final localPath = _localPathOf(lyricFile);
      if (localPath != null) {
        await _loadLyricFromLocalFile(localPath, requestId);
        return;
      }

      // 获取认证信息
      final authState = ref.read(authProvider);
      final host = authState.host ?? '';
      final token = authState.token ?? '';
      final hash = lyricFile['hash'];
      final fileName = lyricFile['title'] ?? lyricFile['name'];
      final workId = track.workId;

      if (hash == null || host.isEmpty || workId == null) {
        _setStateForLoadRequest(
          requestId,
          LyricState(lyrics: [], isLoading: false),
        );
        return;
      }

      // 构建字幕 URL
      String normalizedUrl = host;
      if (!host.startsWith('http://') && !host.startsWith('https://')) {
        normalizedUrl = 'https://$host';
      }
      final lyricUrl = '$normalizedUrl/api/media/stream/$hash?token=$token';

      String? content;

      // 1. 先尝试从缓存加载（包括下载文件和缓存文件）
      final cachedContent = await CacheService.getCachedTextContent(
        workId: workId,
        hash: hash,
        fileName: fileName,
      );
      if (!_isCurrentLoadRequest(requestId)) return;

      if (cachedContent != null) {
        _log.captureOutput('[Lyric] 从缓存加载字幕: $hash');
        content = cachedContent;
      } else {
        // 2. 缓存未命中，从网络下载
        _log.captureOutput('[Lyric] 从网络下载字幕: $hash');
        final dio = Dio();
        final response = await dio.get<List<int>>(
          lyricUrl,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 30),
            headers: StorageService.serverCookieHeaders,
          ),
        );
        if (!_isCurrentLoadRequest(requestId)) return;

        if (response.statusCode == 200) {
          // 使用智能编码检测解码字节
          final (decodedContent, encoding) =
              EncodingUtils.decodeBytes(response.data!);
          _log.captureOutput('[Lyric] 网络字幕编码: $encoding');
          content = decodedContent;

          // 3. 缓存字幕内容
          await CacheService.cacheTextContent(
            workId: workId,
            hash: hash,
            content: content,
          );
          if (!_isCurrentLoadRequest(requestId)) return;
        } else {
          _setStateForLoadRequest(
            requestId,
            LyricState(
              lyrics: [],
              isLoading: false,
              error: 'HTTP ${response.statusCode}',
            ),
          );
          return;
        }
      }

      // 4. 解析字幕
      final lyrics = LyricParser.parse(content); // 自动检测格式
      _log.captureOutput('[Lyric] 解析完成: ${lyrics.length} 行字幕');
      _setStateForLoadRequest(
        requestId,
        LyricState(
          lyrics: lyrics,
          isLoading: false,
          lyricUrl: lyricUrl,
        ),
      );
    } catch (e) {
      _log.captureOutput('[Lyric] 加载失败: $e');
      _setStateForLoadRequest(
        requestId,
        LyricState(
          lyrics: [],
          isLoading: false,
          error: '加载字幕失败: $e',
        ),
      );
    }
  }

  // 从字幕库查找匹配的字幕文件（使用数据库查询）
  Future<String?> _findLyricInLibrary(AudioTrack track) async {
    try {
      final trackTitle = track.title;
      final workId = track.workId;

      _log.captureOutput(
          '[Lyric] 在字幕库中查找: track="$trackTitle", workId=$workId');

      // 确保数据库已初始化
      await SubtitleLibraryService.ensureInitialized();

      // 获取字幕库根目录，用于将相对路径拼接为绝对路径
      final libraryDir =
          await SubtitleLibraryService.getSubtitleLibraryDirectory();
      final libraryRoot = libraryDir.path;

      // 优先级1: 通过 workId 查询数据库
      if (workId != null) {
        final records =
            await SubtitleDatabase.instance.getFilesByWorkId(workId);
        if (records.isNotEmpty) {
          String? bestMatchPath;
          double bestScore = 0.0;

          for (final record in records) {
            final (isMatch, score) =
                SubtitleLibraryService.checkMatch(record.fileName, trackTitle);
            if (isMatch && score > bestScore) {
              final absolutePath = record.absolutePath(libraryRoot);
              // 验证文件是否仍存在（DB 可能过期）
              if (!await File(absolutePath).exists()) continue;
              bestScore = score;
              bestMatchPath = absolutePath;
              if (score == 1.0) {
                _log.captureOutput(
                    '[Lyric] 在数据库中找到完美匹配 (workId=$workId): ${record.fileName}');
                return absolutePath;
              }
            }
          }

          if (bestMatchPath != null) {
            _log.captureOutput(
                '[Lyric] 在数据库中找到最佳匹配 (workId=$workId, score=$bestScore)');
            return bestMatchPath;
          }
        }
      }

      // 优先级2: 在"已保存"分类中查找
      final savedRecords = await SubtitleDatabase.instance
          .getFilesByCategory(SubtitleLibraryService.savedFolderName);
      if (savedRecords.isNotEmpty) {
        String? bestMatchPath;
        double bestScore = 0.0;

        for (final record in savedRecords) {
          final (isMatch, score) =
              SubtitleLibraryService.checkMatch(record.fileName, trackTitle);
          if (isMatch && score > bestScore) {
            final absolutePath = record.absolutePath(libraryRoot);
            if (!await File(absolutePath).exists()) continue;
            bestScore = score;
            bestMatchPath = absolutePath;
            if (score == 1.0) {
              _log.captureOutput('[Lyric] 在"已保存"中找到完美匹配: ${record.fileName}');
              return absolutePath;
            }
          }
        }

        if (bestMatchPath != null) {
          _log.captureOutput('[Lyric] 在"已保存"中找到最佳匹配 (score=$bestScore)');
          return bestMatchPath;
        }
      }

      _log.captureOutput('[Lyric] 字幕库中未找到匹配的字幕');
      return null;
    } catch (e) {
      _log.captureOutput('[Lyric] 字幕库查找出错: $e');
      return null;
    }
  }

  // 查找字幕文件
  dynamic _findLyricFile(AudioTrack track, List<dynamic> allFiles) {
    // 获取音频文件名
    final trackTitle = track.title;
    // 尝试获取音频文件的相对路径（如果AudioTrack中有保存的话，目前AudioTrack结构里可能没有直接保存相对路径，
    // 但我们可以尝试通过遍历allFiles找到track对应的文件对象来获取其父路径，或者简化处理：
    // 由于AudioTrack通常是从allFiles构建的，我们可以在遍历时比较层级结构。
    // 但为了简化，我们这里定义"真完美匹配"为：文件名完全匹配(score=1.0) 且 位于同一目录下。
    // 由于我们是在递归遍历allFiles，我们可以记录当前遍历的文件夹路径。

    // 实际上，AudioTrack对象中并没有保存其在文件树中的位置信息，只保存了url/hash等。
    // 如果要实现"相对文件树路径也一致"，我们需要知道AudioTrack的原始路径。
    // 现有的AudioTrack结构：id, url, title, artist, album, artworkUrl, duration, workId, hash.
    // 我们可以尝试通过hash在allFiles中找到原始音频文件对象，从而确定其路径。

    // 1. 先找到音频文件在文件树中的位置（父文件夹路径）
    String? audioParentPath;

    String? findAudioPath(List<dynamic> files, String currentPath) {
      for (final file in files) {
        final fileType = file['type'] ?? '';
        final fileName = file['title'] ?? file['name'] ?? '';

        if (fileType == 'folder' && file['children'] != null) {
          final path =
              currentPath.isEmpty ? fileName : '$currentPath/$fileName';
          final result = findAudioPath(file['children'], path);
          if (result != null) return result;
        } else {
          // 通过hash匹配（如果track有hash）或者title匹配
          if ((track.hash != null && file['hash'] == track.hash) ||
              (track.hash == null && fileName == trackTitle)) {
            return currentPath;
          }
        }
      }
      return null;
    }

    audioParentPath = findAudioPath(allFiles, '');
    // _log.captureOutput('[Lyric] 音频文件路径: $audioParentPath');

    dynamic bestMatchFile;
    double bestScore = 0.0;
    bool foundTruePerfectMatch = false;

    // 递归搜索字幕文件
    void searchInFiles(List<dynamic> files, String currentPath) {
      for (final file in files) {
        // 如果已经找到真完美匹配，停止搜索
        if (foundTruePerfectMatch) return;

        final fileType = file['type'] ?? '';
        final fileName = file['title'] ?? file['name'] ?? '';

        // 如果是文件夹，递归搜索
        if (fileType == 'folder' && file['children'] != null) {
          final path =
              currentPath.isEmpty ? fileName : '$currentPath/$fileName';
          searchInFiles(file['children'], path);
          continue;
        }

        final (isMatch, score) =
            SubtitleLibraryService.checkMatch(fileName, trackTitle);

        if (isMatch) {
          // 检查是否是"真完美匹配"：分数1.0 且 路径相同
          final isSamePath =
              audioParentPath != null && currentPath == audioParentPath;
          final isTruePerfect = score == 1.0 && isSamePath;

          if (isTruePerfect) {
            bestScore = 1.0;
            bestMatchFile = file;
            foundTruePerfectMatch = true;
            _log.captureOutput('[Lyric] 找到真完美匹配(同目录): $fileName');
            return;
          }

          // 如果不是真完美匹配，但分数更高，或者分数相同但之前没有找到过1.0的匹配
          // 注意：如果之前已经找到了一个score=1.0的（非同目录），我们不应该被低分的覆盖
          // 但如果找到了另一个score=1.0的（非同目录），我们可以保留任意一个，或者保留第一个
          if (score > bestScore) {
            bestScore = score;
            bestMatchFile = file;
            _log.captureOutput(
                '[Lyric] 找到更佳匹配: lyric="$fileName", score=$score');
          } else if (score == 1.0 && bestScore == 1.0) {
            // 已经有一个完美匹配了，但不是同目录的（否则上面就return了）
            // 当前这个也是完美匹配，也不是同目录的（否则上面就return了）
            // 保持原样，或者根据其他规则（如文件名长度？）
          }
        }
      }
    }

    searchInFiles(allFiles, '');

    if (bestMatchFile != null) {
      _log.captureOutput(
          '[Lyric] 最终匹配: track="${track.title}", lyric="${bestMatchFile['title'] ?? bestMatchFile['name']}", score=$bestScore, isTruePerfect=$foundTruePerfectMatch');
    }

    return bestMatchFile;
  }

  // 清空字幕
  void clearLyrics() {
    _beginLoadRequest();
    state = LyricState();
  }

  /// 调整字幕轴偏移
  void adjustTimelineOffset(Duration offset) {
    state = state.copyWith(timelineOffset: offset);
  }

  /// 重置字幕轴偏移
  void resetTimelineOffset() {
    state = state.copyWith(timelineOffset: Duration.zero);
  }

  /// 切换歌词翻译（已有翻译时在原文/翻译间切换）。
  Future<void> toggleTranslation() async {
    if (state.lyrics.isEmpty || state.isTranslating) return;

    if (state.isTranslated) {
      state = state.copyWith(showTranslated: !state.showTranslated);
      return;
    }

    await translateAndSaveCurrentLyrics();
  }

  /// 翻译当前播放字幕，完成后立即显示翻译，并按偏好设置保存到字幕库。
  Future<String?> translateAndSaveCurrentLyrics() async {
    if (state.lyrics.isEmpty || state.isTranslating) return null;

    if (state.isTranslated) {
      state = state.copyWith(showTranslated: true);
      return state.translatedSubtitlePath;
    }

    final requestId = _beginTranslationRequest();
    final sourceLyrics = List<LyricLine>.from(state.lyrics);
    final sourceOffset = state.timelineOffset;
    final currentTrack = ref.read(currentTrackProvider).value;

    state = state.copyWith(
      isTranslating: true,
      translatedCount: 0,
      translationTotal: 0,
    );

    try {
      final translationService = TranslationService();

      // 收集需要翻译的文本（跳过空行和音符占位）
      final textsToTranslate = <String>[];
      final indexMap = <int>[];

      for (int i = 0; i < sourceLyrics.length; i++) {
        final text = sourceLyrics[i].text;
        if (text.isNotEmpty && text != '♪ - ♪') {
          textsToTranslate.add(text);
          indexMap.add(i);
        }
      }

      if (textsToTranslate.isEmpty) {
        if (_isCurrentTranslationRequest(requestId)) {
          state = state.copyWith(isTranslating: false);
        }
        return null;
      }

      // 将歌词行用换行符拼接后复用文本浏览的分块翻译机制。
      const separator = '\n';
      final joinedText = textsToTranslate.join(separator);
      final translatedText = await translationService.translateLongText(
        joinedText,
        onProgress: (current, total) {
          if (_isCurrentTranslationRequest(requestId)) {
            state = state.copyWith(
              translatedCount: current,
              translationTotal: total,
            );
          }
        },
      );
      if (!_isCurrentTranslationRequest(requestId)) return null;

      final latestTrack = ref.read(currentTrackProvider).value;
      if (!_isSameTrack(currentTrack, latestTrack)) {
        if (_isCurrentTranslationRequest(requestId)) {
          state = state.copyWith(isTranslating: false);
        }
        return null;
      }

      // 将翻译结果按换行符拆回逐行，映射回原歌词
      final translatedTexts = translatedText.split(separator);
      if (translatedTexts.length > textsToTranslate.length) {
        final overflow = translatedTexts.skip(textsToTranslate.length - 1);
        translatedTexts
          ..removeRange(textsToTranslate.length - 1, translatedTexts.length)
          ..add(overflow.join(' '));
      } else if (translatedTexts.length < textsToTranslate.length) {
        for (var i = translatedTexts.length; i < textsToTranslate.length; i++) {
          translatedTexts.add(textsToTranslate[i]);
        }
      }

      // 构建翻译后的歌词列表（保留原时间戳）
      final translated = List<LyricLine>.from(sourceLyrics);
      for (int i = 0; i < indexMap.length; i++) {
        final idx = indexMap[i];
        translated[idx] = sourceLyrics[idx].copyWith(text: translatedTexts[i]);
      }

      final shouldAutoSave = await ref
          .read(autoSaveTranslatedLyricsProvider.notifier)
          .resolvedEnabled();
      if (!_isCurrentTranslationRequest(requestId) ||
          !_isSameTrack(currentTrack, ref.read(currentTrackProvider).value)) {
        return null;
      }

      final savedPath = shouldAutoSave
          ? await _saveTranslatedLyricsToLibrary(
              translated,
              requestId: requestId,
              currentTrack: currentTrack,
              timelineOffset: sourceOffset,
            )
          : null;
      if (!_isCurrentTranslationRequest(requestId)) return null;

      state = state.copyWith(
        translatedLyrics: translated,
        showTranslated: true,
        isTranslating: false,
        translatedCount: state.translationTotal,
        translationTotal: state.translationTotal,
        translatedSubtitlePath: savedPath,
      );
      return savedPath;
    } catch (e) {
      _log.captureOutput('[Lyric] 翻译失败: $e');
      if (_isCurrentTranslationRequest(requestId)) {
        state = state.copyWith(isTranslating: false);
      }
      rethrow;
    }
  }

  Future<String?> _saveTranslatedLyricsToLibrary(
    List<LyricLine> lyrics, {
    required int requestId,
    required AudioTrack? currentTrack,
    required Duration timelineOffset,
  }) async {
    bool isCurrentRequest() =>
        _isCurrentTranslationRequest(requestId) &&
        _isSameTrack(currentTrack, ref.read(currentTrackProvider).value);

    if (currentTrack == null || lyrics.isEmpty || !isCurrentRequest()) {
      return null;
    }

    final libraryDir =
        await SubtitleLibraryService.getSubtitleLibraryDirectory();
    if (!isCurrentRequest()) return null;
    final savedDir = Directory(
      path.join(libraryDir.path, SubtitleLibraryService.savedFolderName),
    );
    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }
    if (!isCurrentRequest()) return null;

    final audioNameWithoutExt =
        SubtitleLibraryService.removeAudioExtension(currentTrack.title);
    final filePath = path.join(savedDir.path, '$audioNameWithoutExt.lrc');
    final content = _exportLyricLines(
      lyrics,
      format: 'lrc',
      timelineOffset: timelineOffset,
    );
    if (content.isEmpty) return null;

    final tempFile = File('$filePath.translation-$requestId.tmp');
    try {
      await tempFile.writeAsString(content, flush: true);
      if (!isCurrentRequest()) return null;

      // Commit synchronously after the last identity check so a track-change
      // event cannot interleave between validation and the atomic rename.
      try {
        tempFile.renameSync(filePath);
      } on FileSystemException {
        final destination = File(filePath);
        if (destination.existsSync()) destination.deleteSync();
        tempFile.renameSync(filePath);
      }
    } finally {
      if (tempFile.existsSync()) tempFile.deleteSync();
    }
    await SubtitleLibraryService.refreshDirectoryCache(savedDir.path);
    return filePath;
  }

  /// 清除翻译结果
  void clearTranslation() {
    state = LyricState(
      lyrics: state.lyrics,
      isLoading: state.isLoading,
      error: state.error,
      lyricUrl: state.lyricUrl,
      timelineOffset: state.timelineOffset,
    );
  }

  /// 获取导出格式的字幕内容（应用了时间轴偏移）
  String exportLyrics({String format = 'lrc'}) {
    return _exportLyricLines(
      state.adjustedLyrics,
      format: format,
      timelineOffset: Duration.zero,
    );
  }

  String exportTranslatedLyrics({String format = 'lrc'}) {
    final lyrics = state.translatedLyrics;
    if (lyrics == null) return '';
    return _exportLyricLines(
      lyrics,
      format: format,
      timelineOffset: state.timelineOffset,
    );
  }

  String _exportLyricLines(
    List<LyricLine> sourceLyrics, {
    String format = 'lrc',
    Duration timelineOffset = Duration.zero,
  }) {
    final adjustedLyrics = timelineOffset == Duration.zero
        ? sourceLyrics
        : sourceLyrics
            .map((lyric) => lyric.applyOffset(timelineOffset))
            .toList();
    if (adjustedLyrics.isEmpty) return '';

    final buffer = StringBuffer();

    if (format == 'lrc') {
      // LRC 格式
      for (final lyric in adjustedLyrics) {
        if (lyric.text.isEmpty) continue; // 跳过占位符
        final minutes = lyric.startTime.inMinutes;
        final seconds = lyric.startTime.inSeconds % 60;
        final centiseconds = (lyric.startTime.inMilliseconds % 1000) ~/ 10;
        buffer.writeln(
            '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]${lyric.text}');
      }
    } else if (format == 'vtt') {
      // WebVTT 格式
      buffer.writeln('WEBVTT\n');
      for (final lyric in adjustedLyrics) {
        if (lyric.text.isEmpty) continue; // 跳过占位符
        buffer.writeln(
            '${_formatWebVTTTime(lyric.startTime)} --> ${_formatWebVTTTime(lyric.endTime)}');
        buffer.writeln(lyric.text);
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _formatWebVTTTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  }

  // 手动加载字幕文件
  /// 从本地文件路径加载字幕（用于字幕库）
  Future<void> loadLyricFromLocalFile(String filePath) async {
    final requestId = _beginLoadRequest();
    await _loadLyricFromLocalFile(filePath, requestId);
  }

  Future<void> _loadLyricFromLocalFile(
    String filePath,
    int requestId,
  ) async {
    _setStateForLoadRequest(
      requestId,
      _loadingStatePreservingCurrentLyrics(),
    );

    try {
      _log.captureOutput('[Lyric] 从本地文件加载字幕: $filePath');

      // 读取文件内容
      final file = File(filePath);
      if (!await file.exists()) {
        _setStateForLoadRequest(
          requestId,
          LyricState(
            lyrics: [],
            isLoading: false,
            error: '文件不存在',
          ),
        );
        return;
      }
      if (!_isCurrentLoadRequest(requestId)) return;

      // 使用智能编码检测读取文件
      final (content, encoding) =
          await EncodingUtils.readFileWithEncoding(file);
      if (!_isCurrentLoadRequest(requestId)) return;
      _log.captureOutput('[Lyric] 检测到文件编码: $encoding');

      // 解析字幕
      final lyrics = LyricParser.parse(content);
      _setStateForLoadRequest(
        requestId,
        LyricState(
          lyrics: lyrics,
          isLoading: false,
          lyricUrl: 'file://$filePath',
        ),
      );

      _log.captureOutput('[Lyric] 成功从本地文件加载字幕，共 ${lyrics.length} 行');
    } catch (e) {
      _log.captureOutput('[Lyric] 从本地文件加载字幕失败: $e');
      if (!_isCurrentLoadRequest(requestId)) return;
      _setStateForLoadRequest(
        requestId,
        LyricState(
          lyrics: [],
          isLoading: false,
          error: '加载字幕失败: $e',
        ),
      );
      rethrow;
    }
  }

  Future<void> loadLyricManually(dynamic lyricFile, {int? workId}) async {
    final requestId = _beginLoadRequest();
    _setStateForLoadRequest(
      requestId,
      _loadingStatePreservingCurrentLyrics(),
    );

    try {
      final localPath = _localPathOf(lyricFile);
      if (localPath != null) {
        await _loadLyricFromLocalFile(localPath, requestId);
        return;
      }

      // 获取认证信息
      final authState = ref.read(authProvider);
      final host = authState.host ?? '';
      final token = authState.token ?? '';
      final hash = lyricFile['hash'];

      if (hash == null || host.isEmpty) {
        _setStateForLoadRequest(
          requestId,
          LyricState(
            lyrics: [],
            isLoading: false,
            error: '缺少必要信息',
          ),
        );
        return;
      }

      // 构建字幕 URL
      String normalizedUrl = host;
      if (!host.startsWith('http://') && !host.startsWith('https://')) {
        if (host.contains('localhost') ||
            host.startsWith('127.0.0.1') ||
            host.startsWith('192.168.')) {
          normalizedUrl = 'http://$host';
        } else {
          normalizedUrl = 'https://$host';
        }
      }
      final lyricUrl = '$normalizedUrl/api/media/stream/$hash?token=$token';

      String content;

      // 1. 先尝试从缓存加载（包括下载文件和缓存文件）
      // 优先级：传入的 workId > lyricFile 中的 workId > 当前播放音轨的 workId
      int? effectiveWorkId = workId ?? lyricFile['workId'] as int?;
      if (effectiveWorkId == null) {
        final currentTrackAsync = ref.read(currentTrackProvider);
        final currentTrack = currentTrackAsync.value;
        effectiveWorkId = currentTrack?.workId;
      }

      final fileName = lyricFile['title'] ?? lyricFile['name'];
      final cachedContent = effectiveWorkId != null
          ? await CacheService.getCachedTextContent(
              workId: effectiveWorkId,
              hash: hash,
              fileName: fileName,
            )
          : null;
      if (!_isCurrentLoadRequest(requestId)) return;

      if (cachedContent != null) {
        _log.captureOutput('[Lyric] 手动加载 - 从缓存加载字幕: $hash');
        content = cachedContent;
      } else {
        // 2. 缓存未命中，从网络下载
        _log.captureOutput('[Lyric] 手动加载 - 从网络下载字幕: $hash');
        final dio = Dio();
        final response = await dio.get<List<int>>(
          lyricUrl,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 30),
            headers: StorageService.serverCookieHeaders,
          ),
        );
        if (!_isCurrentLoadRequest(requestId)) return;

        if (response.statusCode == 200) {
          // 使用智能编码检测解码字节
          final (decodedContent, encoding) =
              EncodingUtils.decodeBytes(response.data!);
          _log.captureOutput('[Lyric] 手动加载 - 网络字幕编码: $encoding');
          content = decodedContent;

          // 3. 缓存字幕内容
          if (effectiveWorkId != null) {
            await CacheService.cacheTextContent(
              workId: effectiveWorkId,
              hash: hash,
              content: content,
            );
            if (!_isCurrentLoadRequest(requestId)) return;
          }
        } else {
          _setStateForLoadRequest(
            requestId,
            LyricState(
              lyrics: [],
              isLoading: false,
              error: 'HTTP ${response.statusCode}',
            ),
          );
          return;
        }
      }

      // 4. 解析字幕
      final lyrics = LyricParser.parse(content);
      _setStateForLoadRequest(
        requestId,
        LyricState(
          lyrics: lyrics,
          isLoading: false,
          lyricUrl: lyricUrl,
        ),
      );
    } catch (e) {
      if (!_isCurrentLoadRequest(requestId)) return;
      _setStateForLoadRequest(
        requestId,
        LyricState(
          lyrics: [],
          isLoading: false,
          error: '加载字幕失败: $e',
        ),
      );
      rethrow;
    }
  }

  String? _localPathOf(dynamic file) {
    if (file is! Map) return null;
    final localPath = file['localPath'];
    if (localPath is String && localPath.isNotEmpty) {
      return localPath;
    }
    return null;
  }
}

// 存储当前工作的文件列表（用于查找字幕）
class FileListState {
  final List<dynamic> files;

  FileListState({this.files = const []});
}

class FileListController extends StateNotifier<FileListState> {
  FileListController() : super(FileListState());

  void updateFiles(List<dynamic> files) {
    state = FileListState(files: files);
  }

  void clear() {
    state = FileListState();
  }
}

final fileListControllerProvider =
    StateNotifierProvider<FileListController, FileListState>((ref) {
  return FileListController();
});

// Provider
final lyricControllerProvider =
    StateNotifierProvider<LyricController, LyricState>((ref) {
  return LyricController(ref);
});

// 监听曲目变化，自动重新加载字幕
final lyricAutoLoaderProvider = Provider<void>((ref) {
  final currentTrack = ref.watch(currentTrackProvider);
  final fileListState = ref.watch(fileListControllerProvider);

  currentTrack.whenData((track) {
    if (track != null && fileListState.files.isNotEmpty) {
      // 延迟加载，避免同步问题
      Future.microtask(() {
        ref.read(lyricControllerProvider.notifier).loadLyricForTrack(
              track,
              fileListState.files,
            );
      });
    } else if (track == null) {
      // 没有播放时清空字幕
      ref.read(lyricControllerProvider.notifier).clearLyrics();
    }
  });
});

// 当前字幕文本 Provider（根据播放位置）
final currentLyricTextProvider = Provider<String?>((ref) {
  final lyricState = ref.watch(lyricControllerProvider);
  final position = ref.watch(positionProvider);

  if (lyricState.lyrics.isEmpty) return null;

  // 使用显示用歌词（翻译后 > 原文）
  final displayLyrics = lyricState.displayLyrics;

  return position.when(
    data: (pos) => LyricParser.getCurrentLyric(displayLyrics, pos),
    loading: () => null,
    error: (_, __) => null,
  );
});
