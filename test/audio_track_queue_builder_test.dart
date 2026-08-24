import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/audio_track_queue_builder.dart';

Map<String, dynamic> audioItem(
  String title, {
  String? hash,
  num? duration,
}) {
  return {
    'type': 'audio',
    'title': title,
    if (hash != null) 'hash': hash,
    if (duration != null) 'duration': duration,
  };
}

void main() {
  group('AudioTrackQueueBuilder', () {
    test('builds tracks and selects start index by hash', () async {
      final files = [
        audioItem('track01.mp3', hash: 'h1', duration: 1.5),
        audioItem('track02.mp3', hash: 'h2', duration: 2),
      ];

      final result = await const AudioTrackQueueBuilder().build(
        audioFiles: files,
        selectedFile: files[1],
        resolveUrl: (file) async => 'file://${file['title']}',
        workId: 123456,
        albumTitle: 'Album',
        unknownTitle: 'Unknown',
        artist: 'Artist',
        artworkUrl: 'cover.jpg',
        subtitleWorkDirPath: '/downloads/123456',
      );

      expect(result.tracks, hasLength(2));
      expect(result.startIndex, 1);
      expect(result.tracks.first.id, 'h1');
      expect(result.tracks.first.title, 'track01.mp3');
      expect(result.tracks.first.url, 'file://track01.mp3');
      expect(result.tracks.first.artist, 'Artist');
      expect(result.tracks.first.album, 'Album');
      expect(result.tracks.first.artworkUrl, 'cover.jpg');
      expect(result.tracks.first.duration, const Duration(milliseconds: 1500));
      expect(result.tracks.first.workId, 123456);
      expect(result.tracks.first.hash, 'h1');
      expect(result.tracks.first.sourcePath, 'track01.mp3');
      expect(
        result.tracks.first.subtitleWorkDirPath,
        '/downloads/123456',
      );
    });

    test('falls back to title as id when hash is optional', () async {
      final files = [audioItem('track01.mp3')];

      final result = await const AudioTrackQueueBuilder().build(
        audioFiles: files,
        selectedFile: files.first,
        resolveUrl: (_) async => 'https://example.test/track01.mp3',
        workId: 1,
        albumTitle: 'Album',
        unknownTitle: 'Unknown',
      );

      expect(result.tracks.single.id, 'track01.mp3');
      expect(result.startIndex, 0);
    });

    test('keeps raw local source path when file URL is not percent-encoded',
        () async {
      final files = [audioItem('100% pure.mp3')];

      final result = await const AudioTrackQueueBuilder().build(
        audioFiles: files,
        selectedFile: files.first,
        resolveUrl: (_) async => 'file:///downloads/100% pure.mp3',
        workId: 1,
        albumTitle: 'Album',
        unknownTitle: 'Unknown',
      );

      expect(result.tracks.single.sourcePath, '/downloads/100% pure.mp3');
      expect(result.startIndex, 0);
    });

    test('skips files without hash when requireHash is true', () async {
      final files = [
        audioItem('missing_hash.mp3'),
        audioItem('track01.mp3', hash: 'h1'),
      ];

      final result = await const AudioTrackQueueBuilder().build(
        audioFiles: files,
        selectedFile: files.first,
        resolveUrl: (file) async => 'file://${file['title']}',
        workId: 1,
        albumTitle: 'Album',
        unknownTitle: 'Unknown',
        requireHash: true,
      );

      expect(result.tracks, hasLength(1));
      expect(result.tracks.single.hash, 'h1');
      expect(result.startIndex, 0);
    });

    test('skips files when resolver returns no playable url', () async {
      final files = [
        audioItem('track01.mp3', hash: 'h1'),
        audioItem('track02.mp3', hash: 'h2'),
      ];

      final result = await const AudioTrackQueueBuilder().build(
        audioFiles: files,
        selectedFile: files[1],
        resolveUrl: (file) async => file['hash'] == 'h1' ? null : 'file://ok',
        workId: 1,
        albumTitle: 'Album',
        unknownTitle: 'Unknown',
      );

      expect(result.tracks, hasLength(1));
      expect(result.tracks.single.hash, 'h2');
      expect(result.startIndex, 0);
    });

    test('falls back to first track when selected file is missing', () async {
      final files = [
        audioItem('track01.mp3', hash: 'h1'),
        audioItem('track02.mp3', hash: 'h2'),
      ];

      final result = await const AudioTrackQueueBuilder().build(
        audioFiles: files,
        selectedFile: null,
        resolveUrl: (file) async => 'file://${file['title']}',
        workId: 1,
        albumTitle: 'Album',
        unknownTitle: 'Unknown',
      );

      expect(result.tracks, hasLength(2));
      expect(result.startIndex, 0);
    });
  });
}
