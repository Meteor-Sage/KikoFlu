import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('work detail refresh bypasses both metadata and track caches', () {
    final source = File(
      'lib/src/screens/work_detail_screen.dart',
    ).readAsStringSync();

    expect(source, contains('getWork(widget.work.id, forceRefresh: true)'));
    expect(
      source,
      contains('_fileExplorerController.refresh(forceRefresh: true)'),
    );
    expect(source, contains('controller: _fileExplorerController'));
  });
}
