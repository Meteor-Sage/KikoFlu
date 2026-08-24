import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/services/audio_playback_plan_builder.dart';

Map<String, dynamic> audioItem(
  String title, {
  String? hash,
}) {
  return {
    'type': 'audio',
    'title': title,
    if (hash != null) 'hash': hash,
  };
}

Map<String, dynamic> folderItem(
  String title,
  List<dynamic> children,
) {
  return {
    'type': 'folder',
    'title': title,
    'children': children,
  };
}

const _work = Work(
  id: 123456,
  title: 'Work Title',
  vas: [
    Va(id: '1', name: 'Alice'),
    Va(id: '2', name: 'Bob'),
  ],
);

void main() {
  test('returns missing when selected file is outside the parent directory',
      () async {
    final fileTree = [
      folderItem('Disc 1', [audioItem('track01.mp3', hash: 'h1')]),
      folderItem('Disc 2', [audioItem('track02.mp3', hash: 'h2')]),
    ];

    final plan = await const AudioPlaybackPlanBuilder().build(
      fileTree: fileTree,
      parentPath: 'Disc 1',
      selectedFile: audioItem('track02.mp3', hash: 'h2'),
      resolveUrl: (_) async => 'file://ok',
      work: _work,
      unknownTitle: 'Unknown',
    );

    expect(plan.status, AudioPlaybackPlanStatus.selectedFileMissing);
    expect(plan.selectedTitle, 'track02.mp3');
    expect(plan.queue, isNull);
  });

  test('returns empty when no queue items have playable urls', () async {
    final selectedFile = audioItem('track01.mp3', hash: 'h1');

    final plan = await const AudioPlaybackPlanBuilder().build(
      fileTree: [selectedFile],
      parentPath: '',
      selectedFile: selectedFile,
      resolveUrl: (_) async => null,
      work: _work,
      unknownTitle: 'Unknown',
    );

    expect(plan.status, AudioPlaybackPlanStatus.emptyQueue);
    expect(plan.selectedTitle, 'track01.mp3');
    expect(plan.queue, isNull);
  });

  test('builds a ready queue with work metadata', () async {
    final fileTree = [
      audioItem('track01.mp3', hash: 'h1'),
      audioItem('track02.mp3', hash: 'h2'),
    ];

    final plan = await const AudioPlaybackPlanBuilder().build(
      fileTree: fileTree,
      parentPath: '',
      selectedFile: fileTree.last,
      resolveUrl: (file) async => 'file://${file['title']}',
      work: _work,
      unknownTitle: 'Unknown',
      artworkUrl: 'cover.jpg',
      subtitleWorkDirPath: '/downloads/123456',
    );

    expect(plan.status, AudioPlaybackPlanStatus.ready);
    expect(plan.selectedTitle, 'track02.mp3');
    expect(plan.queue!.tracks, hasLength(2));
    expect(plan.queue!.startIndex, 1);
    expect(plan.queue!.tracks.first.artist, 'Alice, Bob');
    expect(plan.queue!.tracks.first.album, 'Work Title');
    expect(plan.queue!.tracks.first.artworkUrl, 'cover.jpg');
    expect(
      plan.queue!.tracks.first.subtitleWorkDirPath,
      '/downloads/123456',
    );
  });

  test('honors requireHash for local playback queues', () async {
    final fileTree = [
      audioItem('missing_hash.mp3'),
      audioItem('track01.mp3', hash: 'h1'),
    ];

    final plan = await const AudioPlaybackPlanBuilder().build(
      fileTree: fileTree,
      parentPath: '',
      selectedFile: fileTree.first,
      resolveUrl: (file) async => 'file://${file['title']}',
      work: _work,
      unknownTitle: 'Unknown',
      requireHash: true,
    );

    expect(plan.status, AudioPlaybackPlanStatus.ready);
    expect(plan.queue!.tracks, hasLength(1));
    expect(plan.queue!.tracks.single.hash, 'h1');
    expect(plan.queue!.startIndex, 0);
  });
}
