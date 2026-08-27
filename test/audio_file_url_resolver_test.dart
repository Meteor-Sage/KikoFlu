import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/audio_file_url_resolver.dart';

Map<String, dynamic> audioFile({
  String title = 'track01.mp3',
  String? hash = 'hash',
  String? mediaStreamUrl,
}) {
  return {
    'type': 'audio',
    'title': title,
    if (hash != null) 'hash': hash,
    if (mediaStreamUrl != null) 'mediaStreamUrl': mediaStreamUrl,
  };
}

void main() {
  group('AudioFileUrlResolver', () {
    test('online resolver prefers completed downloaded file', () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, hash) async =>
            hash == 'hash' ? '/downloads/123/track01.mp3' : null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
      );

      final url = await resolver.resolveOnline(
        file: audioFile(),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
      );

      expect(url, 'file:///downloads/123/track01.mp3');
    });

    test('online resolver uses manually copied file before cache', () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => '/cache/track01.mp3',
        fileExists: (path) async => path == '/downloads/123/Disc 1/track01.mp3',
      );

      final url = await resolver.resolveOnline(
        file: audioFile(),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {'hash': true},
        fileRelativePaths: const {'hash': 'Disc 1/track01.mp3'},
      );

      expect(url, 'file:///downloads/123/Disc 1/track01.mp3');
    });

    test('online resolver keeps the remote URL when a cache exists', () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => '/cache/track01.mp3',
        fileExists: (_) async => false,
      );

      final url = await resolver.resolveOnline(
        file: audioFile(mediaStreamUrl: '/media/track01'),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {'hash': true},
        fileRelativePaths: const {'hash': 'Disc 1/track01.mp3'},
      );

      expect(url, 'https://example.test/media/track01?token=token');
    });

    test('online resolver handles relative media stream URLs and tokens',
        () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
      );

      final url = await resolver.resolveOnline(
        file: audioFile(mediaStreamUrl: '/media/track01?x=1'),
        workId: 123,
        host: '127.0.0.1:3000',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
      );

      expect(url, 'http://127.0.0.1:3000/media/track01?x=1&token=token');
    });

    test('online resolver falls back to media stream endpoint by hash',
        () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
      );

      final url = await resolver.resolveOnline(
        file: audioFile(),
        workId: 123,
        host: 'example.test',
        token: 'token',
        downloadedFiles: const {},
        fileRelativePaths: const {},
      );

      expect(url, 'https://example.test/api/media/stream/hash?token=token');
    });

    test('offline resolver returns local file URL only when file exists',
        () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
        fileExists: (path) async => path == '/downloads/123/Disc 1/track01.mp3',
      );

      final found = await resolver.resolveOffline(
        file: audioFile(),
        workDir: '/downloads/123',
        parentPath: 'Disc 1',
      );
      final missing = await resolver.resolveOffline(
        file: audioFile(title: 'missing.mp3'),
        workDir: '/downloads/123',
        parentPath: 'Disc 1',
      );

      expect(found, 'file:///downloads/123/Disc 1/track01.mp3');
      expect(missing, isNull);
    });

    test('offline resolver prefers localRelativePath for sanitized downloads',
        () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
        fileExists: (path) async => path == '/downloads/123/Disc_1/track_.mp3',
      );

      final file = audioFile(title: 'track?.mp3')
        ..['localRelativePath'] = 'Disc_1/track_.mp3';

      final found = await resolver.resolveOffline(
        file: file,
        workDir: '/downloads/123',
        parentPath: 'Disc:1',
      );
      final target = await resolver.resolveOfflinePlaybackTarget(
        file: file,
        workId: 123,
        parentPath: 'Disc:1',
        unknownTitle: 'unknown',
      );

      expect(found, 'file:///downloads/123/Disc_1/track_.mp3');
      expect(target.status, OfflineAudioPlaybackTargetStatus.ready);
      expect(
          target.requireTarget.localPath, '/downloads/123/Disc_1/track_.mp3');
      expect(target.requireTarget.selectedTitle, 'track?.mp3');
    });

    test('offline playback target reports missing local file', () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
        fileExists: (_) async => false,
      );

      final missingHashlessFile = await resolver.resolveOfflinePlaybackTarget(
        file: audioFile(hash: null),
        workId: 123,
        parentPath: 'Disc 1',
        unknownTitle: 'unknown',
      );
      final missingFile = await resolver.resolveOfflinePlaybackTarget(
        file: audioFile(),
        workId: 123,
        parentPath: 'Disc 1',
        unknownTitle: 'unknown',
      );

      expect(
        missingHashlessFile.status,
        OfflineAudioPlaybackTargetStatus.missingFile,
      );
      expect(missingHashlessFile.selectedTitle, 'track01.mp3');
      expect(missingFile.status, OfflineAudioPlaybackTargetStatus.missingFile);
      expect(missingFile.selectedTitle, 'track01.mp3');
    });

    test('offline resolver prefers explicit localPath from disk scanner',
        () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
        fileExists: (path) async => path == '/real/downloads/track.mp3',
      );

      final file = audioFile(title: 'track.mp3', hash: null)
        ..['localPath'] = '/real/downloads/track.mp3';

      final url = await resolver.resolveOffline(
        file: file,
        workDir: '/downloads/123',
        parentPath: 'wrong parent',
      );
      final target = await resolver.resolveOfflinePlaybackTarget(
        file: file,
        workId: 123,
        parentPath: 'wrong parent',
        unknownTitle: 'unknown',
      );

      expect(url, 'file:///real/downloads/track.mp3');
      expect(target.status, OfflineAudioPlaybackTargetStatus.ready);
      expect(target.requireTarget.localPath, '/real/downloads/track.mp3');
    });

    test('offline playback target includes paths and local artwork', () async {
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
        fileExists: (path) async =>
            path == '/downloads/123/Disc 1/track01.mp3' ||
            path == '/downloads/123/cover.jpg',
      );

      final result = await resolver.resolveOfflinePlaybackTarget(
        file: audioFile(),
        workId: 123,
        parentPath: 'Disc 1',
        unknownTitle: 'unknown',
      );

      expect(result.status, OfflineAudioPlaybackTargetStatus.ready);
      expect(result.requireTarget.selectedTitle, 'track01.mp3');
      expect(result.requireTarget.workDir, '/downloads/123');
      expect(
          result.requireTarget.localPath, '/downloads/123/Disc 1/track01.mp3');
      expect(
          result.requireTarget.artworkUrl, 'file:///downloads/123/cover.jpg');
    });

    test('offline playback target can use an imported RJ work directory',
        () async {
      const workDir = '/downloads/[circle][RJ123456]Title';
      final resolver = AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async => '/downloads',
        resolveCachedAudioPath: (_) async => null,
        fileExists: (path) async =>
            path == '$workDir/Disc 1/track01.mp3' ||
            path == '$workDir/cover.jpg',
      );

      final result = await resolver.resolveOfflinePlaybackTarget(
        file: audioFile(),
        workId: 123456,
        parentPath: 'Disc 1',
        unknownTitle: 'unknown',
        workDirPath: workDir,
      );

      expect(result.status, OfflineAudioPlaybackTargetStatus.ready);
      expect(result.requireTarget.workDir, workDir);
      expect(result.requireTarget.localPath, '$workDir/Disc 1/track01.mp3');
      expect(result.requireTarget.artworkUrl, 'file://$workDir/cover.jpg');
    });
  });
}
