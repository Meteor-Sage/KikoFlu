import '../models/audio_track.dart';
import '../utils/local_file_url.dart';
import '../utils/file_tree_utils.dart';

typedef AudioUrlResolver = Future<String?> Function(dynamic file);

class AudioTrackQueueResult {
  const AudioTrackQueueResult({
    required this.tracks,
    required this.startIndex,
  });

  final List<AudioTrack> tracks;
  final int startIndex;

  bool get isEmpty => tracks.isEmpty;
}

class AudioTrackQueueBuilder {
  const AudioTrackQueueBuilder();

  Future<AudioTrackQueueResult> build({
    required List<dynamic> audioFiles,
    required dynamic selectedFile,
    required AudioUrlResolver resolveUrl,
    required int workId,
    required String albumTitle,
    required String unknownTitle,
    String? artist,
    String? artworkUrl,
    String? subtitleWorkDirPath,
    bool requireHash = false,
  }) async {
    final tracks = <AudioTrack>[];

    for (final file in audioFiles) {
      final hash = FileTreeUtils.property(file, 'hash')?.toString();
      if (requireHash && (hash == null || hash.isEmpty)) {
        continue;
      }

      final title = FileTreeUtils.titleOf(file, defaultValue: unknownTitle);
      final url = await resolveUrl(file);
      if (url == null || url.isEmpty) {
        continue;
      }

      tracks.add(AudioTrack(
        id: hash ?? title,
        url: url,
        title: title,
        artist: artist,
        album: albumTitle,
        artworkUrl: artworkUrl,
        duration: _parseDuration(FileTreeUtils.property(file, 'duration')),
        workId: workId,
        hash: hash,
        sourcePath: _sourcePathFromUrl(url),
        subtitleWorkDirPath: subtitleWorkDirPath,
      ));
    }

    final selectedHash =
        FileTreeUtils.property(selectedFile, 'hash')?.toString();
    final selectedTitle =
        FileTreeUtils.titleOf(selectedFile, defaultValue: unknownTitle);
    final selectedId = selectedHash ?? selectedTitle;
    final matchedIndex = tracks.indexWhere((track) => track.id == selectedId);

    return AudioTrackQueueResult(
      tracks: tracks,
      startIndex: matchedIndex != -1 ? matchedIndex : 0,
    );
  }

  static Duration? _parseDuration(dynamic durationValue) {
    if (durationValue is num) {
      return Duration(milliseconds: (durationValue * 1000).round());
    }
    return null;
  }

  static String? _sourcePathFromUrl(String url) {
    return LocalFileUrl.pathFromUrl(url);
  }
}
