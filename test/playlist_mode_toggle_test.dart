import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/audio_tap_playlist_mode.dart';
import 'package:kikoeru_flutter/src/providers/settings_provider.dart';
import 'package:kikoeru_flutter/src/widgets/player/playlist_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('playlist mode menu selects and persists all modes', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: PlaylistModeToggle()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.playlist_play), findsOneWidget);
    expect(find.byType(PopupMenuButton<AudioTapPlaylistMode>), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<AudioTapPlaylistMode>));
    await tester.pumpAndSettle();
    expect(find.text('Replace Mode'), findsOneWidget);
    expect(find.text('Append Mode'), findsOneWidget);
    expect(find.text('Single-Audio Append Mode'), findsOneWidget);

    await tester.tap(
      find.ancestor(
        of: find.text('Append Mode'),
        matching: find.byType(CheckedPopupMenuItem<AudioTapPlaylistMode>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    expect(
      container.read(audioTapPlaylistModeProvider),
      AudioTapPlaylistMode.appendDirectory,
    );

    await tester.tap(find.byType(PopupMenuButton<AudioTapPlaylistMode>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Single-Audio Append Mode'),
        matching: find.byType(CheckedPopupMenuItem<AudioTapPlaylistMode>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.queue_music), findsOneWidget);
    expect(
      container.read(audioTapPlaylistModeProvider),
      AudioTapPlaylistMode.appendSingle,
    );
  });
}
