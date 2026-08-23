import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/download_task.dart';

void main() {
  test('download task identity scopes the same hash to its work', () {
    expect(
      DownloadTask.createId(workId: 1, hash: 'same', fileName: 'a.mp3'),
      '1:hash:same',
    );
    expect(
      DownloadTask.createId(workId: 2, hash: 'same', fileName: 'a.mp3'),
      '2:hash:same',
    );
  });

  test('hash-less task identity includes its relative path', () {
    expect(
      DownloadTask.createId(
        workId: 7,
        hash: null,
        fileName: 'disc1/track.mp3',
      ),
      '7:path:disc1/track.mp3',
    );
  });

  test('persisted legacy ids are migrated when decoded', () {
    final task = DownloadTask.fromJson(const {
      'id': 'shared-hash',
      'workId': 42,
      'workTitle': 'Work',
      'fileName': 'track.mp3',
      'downloadUrl': 'https://example.invalid/track.mp3',
      'hash': 'shared-hash',
      'downloadedBytes': 0,
      'status': 'paused',
      'createdAt': '2026-01-01T00:00:00.000',
    });

    expect(task.id, '42:hash:shared-hash');
    expect(task.status, DownloadStatus.paused);
  });
}
