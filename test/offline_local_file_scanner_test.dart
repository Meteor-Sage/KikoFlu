import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/services/offline_local_file_scanner.dart';
import 'package:path/path.dart' as p;

Map<String, dynamic> fileItem(
  String title, {
  String? type,
  String? hash,
}) {
  return {
    'type': type ?? 'file',
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

class _ObjectFile {
  const _ObjectFile({
    required this.type,
    required this.title,
    this.hash,
    this.children,
    this.duration,
    this.size,
  });

  final String type;
  final String title;
  final String? hash;
  final List<dynamic>? children;
  final int? duration;
  final int? size;
}

void main() {
  group('OfflineLocalFileScanner', () {
    test('keeps only existing completed files and prunes empty folders',
        () async {
      final existingPaths = {
        '/downloads/123/Disc 1/track01.mp3',
        '/downloads/123/Disc 1/hashless.mp3',
        '/downloads/123/Disc 1/cover.jpg',
        '/downloads/123/Disc 1/cover.jpg.downloading',
      };
      final track = fileItem('track01.mp3', hash: 'track');
      final tree = [
        folderItem('Disc 1', [
          track,
          fileItem('cover.jpg', hash: 'cover'),
          fileItem('notes.txt', hash: 'notes'),
          fileItem('hashless.mp3'),
        ]),
        folderItem('Empty', [
          fileItem('missing.mp3', hash: 'missing'),
        ]),
      ];
      final scanner = OfflineLocalFileScanner(
        fileExists: (path) async => existingPaths.contains(path),
      );

      final result = await scanner.scan(
        fileTree: tree,
        workDirPath: '/downloads/123',
      );

      expect(result.fileExists, {
        'track': true,
        'local:Disc 1/hashless.mp3': true,
      });
      expect(result.files, hasLength(1));

      final folder = result.files.single as Map<String, dynamic>;
      expect(folder['title'], 'Disc 1');

      final children = folder['children'] as List<dynamic>;
      expect(children, hasLength(2));
      final trackChild = children
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['title'] == 'track01.mp3');
      expect(trackChild, containsPair('hash', 'track'));
      expect(
        trackChild,
        containsPair('localPath', '/downloads/123/Disc 1/track01.mp3'),
      );

      final hashlessChild = children
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['title'] == 'hashless.mp3');
      expect(hashlessChild, containsPair('type', 'audio'));
      expect(
        hashlessChild,
        containsPair('hash', 'local:Disc 1/hashless.mp3'),
      );
      expect(trackChild, containsPair('relativePath', 'Disc 1/track01.mp3'));
      expect(track['type'], 'file');
    });

    test('preserves specific metadata type when extension is generic',
        () async {
      final scanner = OfflineLocalFileScanner(
        fileExists: (path) async => path == '/downloads/123/video.bin',
      );

      final result = await scanner.scan(
        fileTree: [
          fileItem('video.bin', type: 'video', hash: 'video'),
        ],
        workDirPath: '/downloads/123',
      );

      expect(result.files.single, {
        'type': 'video',
        'title': 'video.bin',
        'hash': 'video',
        'localPath': '/downloads/123/video.bin',
        'relativePath': 'video.bin',
      });
    });

    test('converts object-backed file tree items to maps', () async {
      final scanner = OfflineLocalFileScanner(
        fileExists: (path) async => path == '/downloads/123/Disc/script.pdf',
      );

      final result = await scanner.scan(
        fileTree: const [
          _ObjectFile(
            type: 'folder',
            title: 'Disc',
            children: [
              _ObjectFile(
                type: 'file',
                title: 'script.pdf',
                hash: 'pdf',
                duration: 12,
                size: 2048,
              ),
            ],
          ),
        ],
        workDirPath: '/downloads/123',
      );

      expect(result.files, [
        {
          'type': 'folder',
          'title': 'Disc',
          'children': [
            {
              'type': 'pdf',
              'title': 'script.pdf',
              'hash': 'pdf',
              'localPath': '/downloads/123/Disc/script.pdf',
              'relativePath': 'Disc/script.pdf',
              'duration': 12,
              'size': 2048,
            },
          ],
        },
      ]);
    });

    test('merges completed files discovered on disk but missing from metadata',
        () async {
      final workDir = await Directory.systemTemp.createTemp(
        'offline_local_file_scanner_',
      );
      addTearDown(() async {
        if (await workDir.exists()) {
          await workDir.delete(recursive: true);
        }
      });

      await File(p.join(workDir.path, 'Disc 1', 'track01.mp3'))
          .create(recursive: true);
      await File(p.join(workDir.path, 'Disc 1', 'bonus.wav'))
          .writeAsString('audio');
      await File(p.join(workDir.path, 'Disc 1', 'bonus.srt'))
          .writeAsString('1\n00:00:01,000 --> 00:00:02,000\nhello');

      final result = await const OfflineLocalFileScanner().scan(
        fileTree: [
          folderItem('Disc 1', [
            fileItem('track01.mp3', hash: 'track'),
          ]),
        ],
        workDirPath: workDir.path,
      );

      final folder = result.files.single as Map<String, dynamic>;
      final children = folder['children'] as List<dynamic>;
      expect(
        children
            .cast<Map<String, dynamic>>()
            .map((item) => item['title']),
        ['bonus.srt', 'bonus.wav', 'track01.mp3'],
      );
      final titles = children
          .map((item) => (item as Map<String, dynamic>)['title'])
          .toSet();

      expect(titles, {'track01.mp3', 'bonus.wav', 'bonus.srt'});

      final bonusAudio = children
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['title'] == 'bonus.wav');
      expect(bonusAudio['type'], 'audio');
      expect(bonusAudio['hash'], 'local:Disc 1/bonus.wav');
      expect(
          bonusAudio['localPath'], p.join(workDir.path, 'Disc 1', 'bonus.wav'));

      final bonusSubtitle = children
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['title'] == 'bonus.srt');
      expect(bonusSubtitle['type'], 'text');
      expect(bonusSubtitle['hash'], 'local:Disc 1/bonus.srt');
      expect(
        bonusSubtitle['localPath'],
        p.join(workDir.path, 'Disc 1', 'bonus.srt'),
      );
    });

    test('merges discovered files into folders with sanitized local paths',
        () async {
      final workDir = await Directory.systemTemp.createTemp(
        'offline_local_file_scanner_',
      );
      addTearDown(() async {
        if (await workDir.exists()) {
          await workDir.delete(recursive: true);
        }
      });

      await File(p.join(workDir.path, 'Disc_1', 'track_.mp3'))
          .create(recursive: true);
      await File(p.join(workDir.path, 'Disc_1', 'bonus.wav'))
          .writeAsString('audio');

      final result = await const OfflineLocalFileScanner().scan(
        fileTree: [
          {
            'type': 'folder',
            'title': 'Disc:1',
            'localRelativePath': 'Disc_1',
            'children': [
              {
                'type': 'audio',
                'title': 'track?.mp3',
                'hash': 'track',
                'localRelativePath': 'Disc_1/track_.mp3',
              },
            ],
          },
        ],
        workDirPath: workDir.path,
      );

      expect(result.files, hasLength(1));
      final folder = result.files.single as Map<String, dynamic>;
      expect(folder['title'], 'Disc:1');

      final children = folder['children'] as List<dynamic>;
      expect(
        children
            .cast<Map<String, dynamic>>()
            .map((item) => item['title'])
            .toSet(),
        {'track?.mp3', 'bonus.wav'},
      );
      expect(
        result.files
            .cast<Map<String, dynamic>>()
            .where((item) => item['title'] == 'Disc_1'),
        isEmpty,
      );
    });

    test('sorts existing metadata and newly discovered files together',
        () async {
      final workDir = await Directory.systemTemp.createTemp(
        'offline_local_file_scanner_',
      );
      addTearDown(() async {
        if (await workDir.exists()) {
          await workDir.delete(recursive: true);
        }
      });

      await File(p.join(workDir.path, 'Track02.vtt')).writeAsString('subtitle');
      await File(p.join(workDir.path, 'Track00.mp3')).writeAsString('audio');
      await File(p.join(workDir.path, 'Track01.mp3')).writeAsString('audio');

      final result = await const OfflineLocalFileScanner().scan(
        fileTree: [
          fileItem('Track02.vtt', hash: 'subtitle'),
          fileItem('Track01.mp3', hash: 'audio-1'),
        ],
        workDirPath: workDir.path,
      );

      expect(
        result.files
            .cast<Map<String, dynamic>>()
            .map((item) => item['title']),
        ['Track00.mp3', 'Track01.mp3', 'Track02.vtt'],
      );
    });

    test('skips app metadata, hidden files, and partial downloads', () async {
      final workDir = await Directory.systemTemp.createTemp(
        'offline_local_file_scanner_',
      );
      addTearDown(() async {
        if (await workDir.exists()) {
          await workDir.delete(recursive: true);
        }
      });

      await File(p.join(workDir.path, 'work_metadata.json'))
          .writeAsString('{}');
      await File(p.join(workDir.path, 'cover.jpg')).writeAsString('cover');
      await File(p.join(workDir.path, 'folder.webp')).writeAsString('cover');
      await File(p.join(workDir.path, 'poster.png')).writeAsString('cover');
      await File(p.join(workDir.path, '.DS_Store')).writeAsString('hidden');
      await File(p.join(workDir.path, 'track.mp3.downloading'))
          .writeAsString('partial');
      await File(p.join(workDir.path, 'partial.mp3')).writeAsString('partial');
      await File(p.join(workDir.path, 'partial.mp3.downloading'))
          .writeAsString('partial marker');
      await File(p.join(workDir.path, 'extra.mp3')).writeAsString('audio');

      final result = await const OfflineLocalFileScanner().scan(
        fileTree: const [],
        workDirPath: workDir.path,
      );

      expect(result.files, hasLength(1));
      expect(
          (result.files.single as Map<String, dynamic>)['title'], 'extra.mp3');
    });
  });
}
