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

  testWidgets('playlist mode toggle cycles through all modes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const Scaffold(body: PlaylistModeToggle()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.playlist_play), findsOneWidget);
    expect(find.byType(Chip), findsNothing);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    expect(find.text('Append Mode'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.byIcon(Icons.queue_music), findsOneWidget);
    expect(find.text('Single-Track Append'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.byIcon(Icons.playlist_play), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
    expect(
      container.read(audioTapPlaylistModeProvider),
      AudioTapPlaylistMode.replaceQueue,
    );
  });
}
