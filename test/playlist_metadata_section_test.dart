import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/models/playlist.dart';
import 'package:kikoeru_flutter/src/widgets/playlist_metadata_section.dart';

Widget _testApp({
  required Playlist metadata,
  required bool isOwner,
  bool isMasonry = true,
  VoidCallback? onToggleLayout,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: PlaylistMetadataSection(
        metadata: metadata,
        isOwner: isOwner,
        isMasonry: isMasonry,
        onToggleLayout: onToggleLayout ?? () {},
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    ),
  );
}

Playlist _playlist({
  String name = 'Quiet Queue',
  String userName = 'kiko',
  String description = 'A focused listening list',
  int worksCount = 3,
  int playbackCount = 9,
  String createdAt = '2024-01-02T03:04:05',
  String updatedAt = '2024-04-05T06:07:08',
}) {
  return Playlist(
    id: 'playlist-1',
    userName: userName,
    privacy: 1,
    name: name,
    description: description,
    createdAt: createdAt,
    updatedAt: updatedAt,
    worksCount: worksCount,
    playbackCount: playbackCount,
  );
}

void main() {
  testWidgets('renders owner metadata actions and updated timestamp',
      (tester) async {
    var editCount = 0;
    var deleteCount = 0;
    var toggleCount = 0;

    await tester.pumpWidget(
      _testApp(
        metadata: _playlist(),
        isOwner: true,
        onToggleLayout: () => toggleCount++,
        onEdit: () => editCount++,
        onDelete: () => deleteCount++,
      ),
    );

    expect(find.text('Quiet Queue'), findsOneWidget);
    expect(find.text('kiko'), findsOneWidget);
    expect(find.text('A focused listening list'), findsOneWidget);
    expect(find.text('3 works'), findsOneWidget);
    expect(find.text('9 plays'), findsOneWidget);
    expect(find.text('Last updated: 2024-04-05 06:07'), findsOneWidget);
    expect(find.byTooltip('Switch to list view'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.byTooltip('Unfavorite'), findsNothing);

    final layoutButton = find.byTooltip('Switch to list view');
    final editButton = find.byTooltip('Edit');
    expect(tester.getCenter(layoutButton).dx,
        lessThan(tester.getCenter(editButton).dx));

    await tester.tap(layoutButton);
    await tester.tap(editButton);
    await tester.tap(find.byTooltip('Delete'));

    expect(toggleCount, 1);
    expect(editCount, 1);
    expect(deleteCount, 1);
  });

  testWidgets('renders non-owner unfavorite action and created timestamp',
      (tester) async {
    var deleteCount = 0;
    var toggleCount = 0;

    await tester.pumpWidget(
      _testApp(
        metadata: _playlist(
          description: '',
          playbackCount: 0,
          createdAt: '2024-01-02T03:04:05',
          updatedAt: '2024-01-02T03:04:05',
        ),
        isOwner: false,
        isMasonry: false,
        onToggleLayout: () => toggleCount++,
        onEdit: () {},
        onDelete: () => deleteCount++,
      ),
    );

    expect(find.text('A focused listening list'), findsNothing);
    expect(find.text('0 plays'), findsNothing);
    expect(find.text('Created: 2024-01-02 03:04'), findsOneWidget);
    expect(find.byTooltip('Masonry'), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
    expect(find.byTooltip('Unfavorite'), findsOneWidget);

    await tester.tap(find.byTooltip('Masonry'));
    await tester.tap(find.byTooltip('Unfavorite'));

    expect(toggleCount, 1);
    expect(deleteCount, 1);
  });
}
