import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/lyric.dart';
import '../models/audio_track.dart';
import '../services/cache_service.dart';
import '../services/subtitle_library_service.dart';
import 'auth_provider.dart';
import 'audio_provider.dart';
import 'settings_provider.dart';

// 字幕状态
class LyricState {
  final List<LyricLine> lyrics;
  final bool isLoading;
  final String? error;
  final String? lyricUrl;
  final Duration timelineOffset; // 时间轴偏移（毫秒）

  LyricState({
    this.lyrics = const [],
    this.isLoading = false,
    this.error,
    this.lyricUrl,
    this.timelineOffset = Duration.zero,
  });

  LyricState copyWith({
    List<LyricLine>? lyrics,
    bool? isLoading,
    String? error,
    String? lyricUrl,
    Duration? timelineOffset,
  }) {
    return LyricState(
      lyrics: lyrics ?? this.lyrics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lyricUrl: lyricUrl ?? this.lyricUrl,
      timelineOffset: timelineOffset ?? this.timelineOffset,
    );
  }

  /// 获取应用了时间轴偏移后的字幕列表
  List<LyricLine> get adjustedLyrics {
    if (timelineOffset == Duration.zero) {
      return lyrics;
    }
    return lyrics.map((lyric) => lyric.applyOffset(timelineOffset)).toList();
  }
}

// 字幕控制器
class LyricController extends StateNotifier<LyricState> {
  final Ref ref;

  LyricController(this.ref) : super(LyricState());

  // 根据音频轨道查找并加载字幕
  Future<void> loadLyricForTrack(
      AudioTrack track, List<dynamic> allFiles) async {
    print(
        '[Lyric] 尝试加载: track="${track.title}", workId=${track.workId}, 文件数=${allFiles.length}');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 获取字幕库优先级设置
      final libraryPriority = ref.read(subtitleLibraryPriorityProvider);
      final isLibraryFirst = libraryPriority == SubtitleLibraryPriority.highest;

      print('[Lyric] 字幕库优先级: ${libraryPriority.displayName}');

      // 根据设置决定查找顺序
      if (isLibraryFirst) {
        // 优先级1：从字幕库查找匹配的字幕文件
        final libraryLyricPath = await _findLyricInLibrary(track);
        if (libraryLyricPath != null) {
          print('[Lyric] 从字幕库加载: $libraryLyricPath');
          await loadLyricFromLocalFile(libraryLyricPath);
          return;
        }
      }

      // 从完整文件树查找字幕文件
      final lyricFile = _findLyricFile(track, allFiles);

      if (lyricFile == null) {
        // 如果文件树未找到且优先级为最后，尝试字幕库
        if (!isLibraryFirst) {
          print('[Lyric] 文件树未找到，尝试字幕库');
          final libraryLyricPath = await _findLyricInLibrary(track);
          if (libraryLyricPath != null) {
            print('[Lyric] 从字幕库加载: $libraryLyricPath');
            await loadLyricFromLocalFile(libraryLyricPath);
            return;
          }
        }

        print('[Lyric] 未找到匹配字幕: track="${track.title}"');
        state = LyricState(lyrics: [], isLoading: false);
        return;
      }

      print(
          '[Lyric] 找到匹配字幕: title="${lyricFile['title']}", type="${lyricFile['type']}", hash=${lyricFile['hash']}');

      // 获取认证信息
      final authState = ref.read(authProvider);
      final host = authState.host ?? '';
      final token = authState.token ?? '';
      final hash = lyricFile['hash'];
      final fileName = lyricFile['title'] ?? lyricFile['name'];
      final workId = track.workId;

      if (hash == null || host.isEmpty || workId == null) {
        state = LyricState(lyrics: [], isLoading: false);
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

      if (cachedContent != null) {
        print('[Lyric] 从缓存加载字幕: $hash');
        content = cachedContent;
      } else {
        // 2. 缓存未命中，从网络下载
        print('[Lyric] 从网络下载字幕: $hash');
        final dio = Dio();
        final response = await dio.get(
          lyricUrl,
          options: Options(
            responseType: ResponseType.plain,
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        if (response.statusCode == 200) {
          content = response.data as String;

          // 3. 缓存字幕内容
          await CacheService.cacheTextContent(
            workId: workId,
            hash: hash,
            content: content,
          );
        } else {
          state = LyricState(
            lyrics: [],
            isLoading: false,
            error: 'HTTP ${response.statusCode}',
          );
          return;
        }
      }

      // 4. 解析字幕
      final lyrics = LyricParser.parse(content); // 自动检测格式
      print('[Lyric] 解析完成: ${lyrics.length} 行字幕');
      state = LyricState(
        lyrics: lyrics,
        isLoading: false,
        lyricUrl: lyricUrl,
      );
    } catch (e) {
      print('[Lyric] 加载失败: $e');
      state = LyricState(
        lyrics: [],
        isLoading: false,
        error: '加载字幕失败: $e',
      );
    }
  }

  // 从字幕库查找匹配的字幕文件
  Future<String?> _findLyricInLibrary(AudioTrack track) async {
    try {
      final libraryDir =
          await SubtitleLibraryService.getSubtitleLibraryDirectory();
      if (!await libraryDir.exists()) {
        return null;
      }

      final trackTitle = track.title;
      final workId = track.workId;

      print('[Lyric] 在字幕库中查找: track="$trackTitle", workId=$workId');

      // 优先级1: 查找作品ID文件夹（在"已解析"文件夹下）
      if (workId != null) {
        final parsedFolderPath = '${libraryDir.path}/已解析';
        final parsedFolder = Directory(parsedFolderPath);

        if (await parsedFolder.exists()) {
          // 生成可能的文件夹名称列表（支持带前导零的格式）
          final possibleFolderNames = [
            'RJ$workId', // RJ1003058
            'RJ0$workId', // RJ01003058
            'BJ$workId', // BJ1003058
            'BJ0$workId', // BJ01003058
            'VJ$workId', // VJ1003058
            'VJ0$workId', // VJ01003058
          ];

          // 尝试查找所有可能的文件夹
          for (final folderName in possibleFolderNames) {
            final folderPath = '$parsedFolderPath/$folderName';
            final folder = Directory(folderPath);
            if (await folder.exists()) {
              final match = await _searchLyricInFolder(
                folder,
                trackTitle,
              );
              if (match != null) {
                print('[Lyric] 在已解析/$folderName文件夹找到匹配: $match');
                return match;
              }
            }
          }
        }
      }

      // 优先级2: 查找"已保存"文件夹
      final savedFolderPath = '${libraryDir.path}/已保存';
      final savedFolder = Directory(savedFolderPath);
      if (await savedFolder.exists()) {
        final match = await _searchLyricInFolder(
          savedFolder,
          trackTitle,
        );
        if (match != null) {
          print('[Lyric] 在"已保存"文件夹找到匹配: $match');
          return match;
        }
      }

      print('[Lyric] 字幕库中未找到匹配的字幕');
      return null;
    } catch (e) {
      print('[Lyric] 字幕库查找出错: $e');
      return null;
    }
  }

  // 在指定文件夹中递归搜索匹配的字幕文件
  Future<String?> _searchLyricInFolder(
    Directory folder,
    String trackTitle,
  ) async {
    String? bestMatchPath;
    double bestScore = 0.0;

    try {
      await for (final entity in folder.list(recursive: true)) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final (isMatch, score) =
              SubtitleLibraryService.checkMatch(fileName, trackTitle);

          if (isMatch) {
            if (score > bestScore) {
              bestScore = score;
              bestMatchPath = entity.path;
              // 如果是完美匹配，直接返回
              if (score == 1.0) return entity.path;
            }
          }
        }
      }
    } catch (e) {
      // 忽略权限错误等
    }
    return bestMatchPath;
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
    // print('[Lyric] 音频文件路径: $audioParentPath');

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
            print('[Lyric] 找到真完美匹配(同目录): $fileName');
            return;
          }

          // 如果不是真完美匹配，但分数更高，或者分数相同但之前没有找到过1.0的匹配
          // 注意：如果之前已经找到了一个score=1.0的（非同目录），我们不应该被低分的覆盖
          // 但如果找到了另一个score=1.0的（非同目录），我们可以保留任意一个，或者保留第一个
          if (score > bestScore) {
            bestScore = score;
            bestMatchFile = file;
            print('[Lyric] 找到更佳匹配: lyric="$fileName", score=$score');
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
      print(
          '[Lyric] 最终匹配: track="${track.title}", lyric="${bestMatchFile['title'] ?? bestMatchFile['name']}", score=$bestScore, isTruePerfect=$foundTruePerfectMatch');
    }

    return bestMatchFile;
  }

  // 清空字幕
  void clearLyrics() {
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

  /// 获取导出格式的字幕内容（应用了时间轴偏移）
  String exportLyrics({String format = 'lrc'}) {
    final adjustedLyrics = state.adjustedLyrics;
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
        buffer.writeln(_formatWebVTTTime(lyric.startTime) +
            ' --> ' +
            _formatWebVTTTime(lyric.endTime));
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[Lyric] 从本地文件加载字幕: $filePath');

      // 读取文件内容
      final file = File(filePath);
      if (!await file.exists()) {
        state = LyricState(
          lyrics: [],
          isLoading: false,
          error: '文件不存在',
        );
        return;
      }

      final content = await file.readAsString();

      // 解析字幕
      final lyrics = LyricParser.parse(content);
      state = LyricState(
        lyrics: lyrics,
        isLoading: false,
        lyricUrl: 'file://$filePath',
      );

      print('[Lyric] 成功从本地文件加载字幕，共 ${lyrics.length} 行');
    } catch (e) {
      print('[Lyric] 从本地文件加载字幕失败: $e');
      state = LyricState(
        lyrics: [],
        isLoading: false,
        error: '加载字幕失败: $e',
      );
      rethrow;
    }
  }

  Future<void> loadLyricManually(dynamic lyricFile, {int? workId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 获取认证信息
      final authState = ref.read(authProvider);
      final host = authState.host ?? '';
      final token = authState.token ?? '';
      final hash = lyricFile['hash'];

      if (hash == null || host.isEmpty) {
        state = LyricState(
          lyrics: [],
          isLoading: false,
          error: '缺少必要信息',
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

      if (cachedContent != null) {
        print('[Lyric] 手动加载 - 从缓存加载字幕: $hash');
        content = cachedContent;
      } else {
        // 2. 缓存未命中，从网络下载
        print('[Lyric] 手动加载 - 从网络下载字幕: $hash');
        final dio = Dio();
        final response = await dio.get(
          lyricUrl,
          options: Options(
            responseType: ResponseType.plain,
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        if (response.statusCode == 200) {
          content = response.data as String;

          // 3. 缓存字幕内容
          if (effectiveWorkId != null) {
            await CacheService.cacheTextContent(
              workId: effectiveWorkId,
              hash: hash,
              content: content,
            );
          }
        } else {
          state = LyricState(
            lyrics: [],
            isLoading: false,
            error: 'HTTP ${response.statusCode}',
          );
          return;
        }
      }

      // 4. 解析字幕
      final lyrics = LyricParser.parse(content);
      state = LyricState(
        lyrics: lyrics,
        isLoading: false,
        lyricUrl: lyricUrl,
      );
    } catch (e) {
      state = LyricState(
        lyrics: [],
        isLoading: false,
        error: '加载字幕失败: $e',
      );
      rethrow;
    }
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

  // 使用调整后的字幕
  final adjustedLyrics = lyricState.adjustedLyrics;

  return position.when(
    data: (pos) => LyricParser.getCurrentLyric(adjustedLyrics, pos),
    loading: () => null,
    error: (_, __) => null,
  );
});
