import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subtitle_library_service.dart';

final subtitleLibraryProvider = StateNotifierProvider<SubtitleLibraryNotifier, Set<int>>((ref) {
  return SubtitleLibraryNotifier();
});

class SubtitleLibraryNotifier extends StateNotifier<Set<int>> {
  StreamSubscription? _subscription;

  SubtitleLibraryNotifier() : super({}) {
    _init();
  }

  void _init() {
    refresh();
    _subscription = SubtitleLibraryService.onCacheUpdated.listen((_) {
      refresh();
    });
  }

  Future<void> refresh() async {
    final parsedFolders = await SubtitleLibraryService.getParsedSubtitleFolders();
    
    final ids = <int>{};
    final regex = RegExp(r'RJ(\d+)', caseSensitive: false);

    for (final folder in parsedFolders) {
      final match = regex.firstMatch(folder);
      if (match != null) {
        final idStr = match.group(1);
        if (idStr != null) {
          final id = int.tryParse(idStr);
          if (id != null) {
            ids.add(id);
          }
        }
      }
    }

    if (mounted) {
      state = ids;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
