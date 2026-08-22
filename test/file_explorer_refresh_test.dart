import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
import 'package:kikoeru_flutter/src/providers/auth_provider.dart';
import 'package:kikoeru_flutter/src/services/kikoeru_api_service.dart'
    show KikoeruApiService;
import 'package:kikoeru_flutter/src/widgets/file_explorer_widget.dart';

class _FailingApiService extends KikoeruApiService {
  final List<bool> forceRefreshCalls = [];

  @override
  Future<List<dynamic>> getWorkTracks(
    int workId, {
    bool forceRefresh = false,
  }) async {
    forceRefreshCalls.add(forceRefresh);
    throw StateError('network unavailable');
  }
}

void main() {
  testWidgets('controller reloads mounted file tree with cache bypass', (
    tester,
  ) async {
    final apiService = _FailingApiService();
    final controller = FileExplorerController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [kikoeruApiServiceProvider.overrideWithValue(apiService)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: FileExplorerWidget(
              work: const Work(id: 39, title: 'Work'),
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(apiService.forceRefreshCalls, [false]);

    await expectLater(
      controller.refresh(forceRefresh: true),
      throwsA(isA<StateError>()),
    );
    await tester.pump();

    expect(apiService.forceRefreshCalls, [false, true]);
  });
}
