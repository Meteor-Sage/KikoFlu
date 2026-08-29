import '../models/work.dart';
import '../models/audio_tap_playlist_mode.dart';
import '../utils/file_tree_utils.dart';
import 'audio_track_queue_builder.dart';

enum AudioPlaybackPlanStatus {
  ready,
  selectedFileMissing,
  emptyQueue,
}

class AudioPlaybackPlan {
  const AudioPlaybackPlan._({
    required this.status,
    required this.selectedTitle,
    this.queue,
  });

  factory AudioPlaybackPlan.ready({
    required String selectedTitle,
    required AudioTrackQueueResult queue,
  }) {
    return AudioPlaybackPlan._(
      status: AudioPlaybackPlanStatus.ready,
      selectedTitle: selectedTitle,
      queue: queue,
    );
  }

  factory AudioPlaybackPlan.selectedFileMissing(String selectedTitle) {
    return AudioPlaybackPlan._(
      status: AudioPlaybackPlanStatus.selectedFileMissing,
      selectedTitle: selectedTitle,
    );
  }

  factory AudioPlaybackPlan.emptyQueue(String selectedTitle) {
    return AudioPlaybackPlan._(
      status: AudioPlaybackPlanStatus.emptyQueue,
      selectedTitle: selectedTitle,
    );
  }

  final AudioPlaybackPlanStatus status;
  final String selectedTitle;
  final AudioTrackQueueResult? queue;
}

class AudioPlaybackPlanBuilder {
  const AudioPlaybackPlanBuilder({
    this.queueBuilder = const AudioTrackQueueBuilder(),
  });

  final AudioTrackQueueBuilder queueBuilder;

  Future<AudioPlaybackPlan> build({
    required List<dynamic> fileTree,
    required String parentPath,
    required dynamic selectedFile,
    required AudioUrlResolver resolveUrl,
    required Work work,
    required String unknownTitle,
    String? artworkUrl,
    String? subtitleWorkDirPath,
    bool requireHash = false,
    AudioTapPlaylistMode playlistMode = AudioTapPlaylistMode.replaceQueue,
  }) async {
    final selectedTitle =
        FileTreeUtils.titleOf(selectedFile, defaultValue: unknownTitle);
    final audioFiles = FileTreeUtils.audioFilesInDirectory(
      fileTree,
      parentPath,
    );

    if (!_containsSelectedFile(audioFiles, selectedFile)) {
      return AudioPlaybackPlan.selectedFileMissing(selectedTitle);
    }

    final queueFiles = playlistMode == AudioTapPlaylistMode.appendSingle
        ? <dynamic>[selectedFile]
        : audioFiles;

    final queue = await queueBuilder.build(
      audioFiles: queueFiles,
      selectedFile: selectedFile,
      resolveUrl: resolveUrl,
      workId: work.id,
      albumTitle: work.title,
      unknownTitle: unknownTitle,
      artist: _artistInfo(work),
      artworkUrl: artworkUrl,
      subtitleWorkDirPath: subtitleWorkDirPath,
      requireHash: requireHash,
    );

    if (queue.isEmpty) {
      return AudioPlaybackPlan.emptyQueue(selectedTitle);
    }

    return AudioPlaybackPlan.ready(
      selectedTitle: selectedTitle,
      queue: queue,
    );
  }

  bool _containsSelectedFile(List<dynamic> audioFiles, dynamic selectedFile) {
    final selectedHash = FileTreeUtils.property(selectedFile, 'hash');
    return audioFiles.any(
      (file) => FileTreeUtils.property(file, 'hash') == selectedHash,
    );
  }

  String? _artistInfo(Work work) {
    final vaNames = work.vas?.map((va) => va.name).toList() ?? [];
    return vaNames.isEmpty ? null : vaNames.join(', ');
  }
}
