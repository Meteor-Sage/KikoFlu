import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/auth_provider.dart';
import 'package:kikoeru_flutter/src/providers/my_reviews_provider.dart';
import 'package:kikoeru_flutter/src/providers/search_result_provider.dart';
import 'package:kikoeru_flutter/src/providers/subtitle_library_provider.dart';
import 'package:kikoeru_flutter/src/providers/works_provider.dart';
import 'package:kikoeru_flutter/src/services/kikoeru_api_service.dart'
    hide kikoeruApiServiceProvider;
import 'package:kikoeru_flutter/src/utils/persistent_enum_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _TestLayout { bigGrid, smallGrid, list }

class _TestSubtitleLibraryNotifier extends SubtitleLibraryNotifier {
  @override
  Future<void> refresh() async {}
}

class _TestApiService extends KikoeruApiService {
  String? lastReviewFilter;

  @override
  Future<Map<String, dynamic>> getMyReviews({
    int page = 1,
    int pageSize = 20,
    String? filter,
    String order = 'updated_at',
    String sort = 'desc',
  }) async {
    lastReviewFilter = filter;
    return {
      'works': <dynamic>[],
      'pagination': {'totalCount': 0},
    };
  }
}

Future<void> _pumpAsyncPreferenceLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads a saved enum value', () async {
    SharedPreferences.setMockInitialValues({'layout': 'smallGrid'});
    final preference = PersistentEnumPreference<_TestLayout>(
      key: 'layout',
      values: _TestLayout.values,
      fallback: _TestLayout.bigGrid,
    );

    expect(await preference.load(), _TestLayout.smallGrid);
  });

  test('falls back for a missing or invalid value', () async {
    SharedPreferences.setMockInitialValues({'layout': 'unsupported'});
    final preference = PersistentEnumPreference<_TestLayout>(
      key: 'layout',
      values: _TestLayout.values,
      fallback: _TestLayout.bigGrid,
    );

    expect(await preference.load(), _TestLayout.bigGrid);
  });

  test('persists the selected enum value', () async {
    final preference = PersistentEnumPreference<_TestLayout>(
      key: 'layout',
      values: _TestLayout.values,
      fallback: _TestLayout.bigGrid,
    );

    await preference.save(_TestLayout.list);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('layout'), 'list');
  });

  test('an in-flight load cannot overwrite a local selection', () async {
    SharedPreferences.setMockInitialValues({'layout': 'bigGrid'});
    final preference = PersistentEnumPreference<_TestLayout>(
      key: 'layout',
      values: _TestLayout.values,
      fallback: _TestLayout.bigGrid,
    );

    final pendingLoad = preference.load();
    await preference.save(_TestLayout.smallGrid);

    expect(await pendingLoad, isNull);
  });

  test('feed providers restore and persist their independent layouts',
      () async {
    SharedPreferences.setMockInitialValues({
      WorksNotifier.layoutPreferenceKey: LayoutType.smallGrid.name,
      SearchResultNotifier.layoutPreferenceKey: SearchLayoutType.list.name,
      MyReviewsNotifier.layoutPreferenceKey: MyReviewLayoutType.smallGrid.name,
      MyReviewsNotifier.filterPreferenceKey: MyReviewFilter.listening.name,
    });
    final apiService = _TestApiService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        kikoeruApiServiceProvider.overrideWithValue(apiService),
        subtitleLibraryProvider.overrideWith(
          (ref) => _TestSubtitleLibraryNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(worksProvider).layoutType, LayoutType.bigGrid);
    expect(
      container.read(searchResultProvider).layoutType,
      SearchLayoutType.bigGrid,
    );
    expect(
      container.read(myReviewsProvider).layoutType,
      MyReviewLayoutType.bigGrid,
    );

    await _pumpAsyncPreferenceLoad();

    expect(container.read(worksProvider).layoutType, LayoutType.smallGrid);
    expect(
      container.read(searchResultProvider).layoutType,
      SearchLayoutType.list,
    );
    expect(
      container.read(myReviewsProvider).layoutType,
      MyReviewLayoutType.smallGrid,
    );
    expect(container.read(myReviewsProvider).filter, MyReviewFilter.listening);
    await container.read(myReviewsProvider.notifier).load();
    expect(apiService.lastReviewFilter, MyReviewFilter.listening.value);

    container.read(worksProvider.notifier).toggleLayoutType();
    container.read(searchResultProvider.notifier).toggleLayoutType();
    container.read(myReviewsProvider.notifier).toggleLayoutType();
    container
        .read(myReviewsProvider.notifier)
        .changeFilter(MyReviewFilter.listened);
    await _pumpAsyncPreferenceLoad();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(WorksNotifier.layoutPreferenceKey),
      LayoutType.list.name,
    );
    expect(
      prefs.getString(SearchResultNotifier.layoutPreferenceKey),
      SearchLayoutType.bigGrid.name,
    );
    expect(
      prefs.getString(MyReviewsNotifier.layoutPreferenceKey),
      MyReviewLayoutType.list.name,
    );
    expect(
      prefs.getString(MyReviewsNotifier.filterPreferenceKey),
      MyReviewFilter.listened.name,
    );
  });
}
