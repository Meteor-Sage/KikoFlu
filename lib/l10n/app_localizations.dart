import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KikoFlu'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navMy.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get navMy;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @offlineModeMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: Network connection failed, only downloaded content is accessible'**
  String get offlineModeMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @searchTypeKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get searchTypeKeyword;

  /// No description provided for @searchTypeTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get searchTypeTag;

  /// No description provided for @searchTypeVa.
  ///
  /// In en, this message translates to:
  /// **'Voice Actor'**
  String get searchTypeVa;

  /// No description provided for @searchTypeCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get searchTypeCircle;

  /// No description provided for @searchTypeRjNumber.
  ///
  /// In en, this message translates to:
  /// **'RJ Number'**
  String get searchTypeRjNumber;

  /// No description provided for @searchHintKeyword.
  ///
  /// In en, this message translates to:
  /// **'Enter work name or keyword...'**
  String get searchHintKeyword;

  /// No description provided for @searchHintTag.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name...'**
  String get searchHintTag;

  /// No description provided for @searchHintVa.
  ///
  /// In en, this message translates to:
  /// **'Enter voice actor name...'**
  String get searchHintVa;

  /// No description provided for @searchHintCircle.
  ///
  /// In en, this message translates to:
  /// **'Enter circle name...'**
  String get searchHintCircle;

  /// No description provided for @searchHintRjNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter number...'**
  String get searchHintRjNumber;

  /// No description provided for @ageRatingAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ageRatingAll;

  /// No description provided for @ageRatingGeneral.
  ///
  /// In en, this message translates to:
  /// **'All Ages'**
  String get ageRatingGeneral;

  /// No description provided for @ageRatingR15.
  ///
  /// In en, this message translates to:
  /// **'R-15'**
  String get ageRatingR15;

  /// No description provided for @ageRatingAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get ageRatingAdult;

  /// No description provided for @salesRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get salesRangeAll;

  /// No description provided for @sortRelease.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get sortRelease;

  /// No description provided for @sortCreateAt.
  ///
  /// In en, this message translates to:
  /// **'Added Date'**
  String get sortCreateAt;

  /// No description provided for @sortCreateDate.
  ///
  /// In en, this message translates to:
  /// **'Catalog Date'**
  String get sortCreateDate;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @sortReviewCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get sortReviewCount;

  /// No description provided for @sortRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get sortRandom;

  /// No description provided for @sortDlCount.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sortDlCount;

  /// No description provided for @sortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortPrice;

  /// No description provided for @sortNsfw.
  ///
  /// In en, this message translates to:
  /// **'All Ages'**
  String get sortNsfw;

  /// No description provided for @sortUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Marked Date'**
  String get sortUpdatedAt;

  /// No description provided for @sortAsc.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAsc;

  /// No description provided for @sortDesc.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDesc;

  /// No description provided for @sortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get sortOptions;

  /// No description provided for @sortField.
  ///
  /// In en, this message translates to:
  /// **'Sort Field'**
  String get sortField;

  /// No description provided for @sortDirection.
  ///
  /// In en, this message translates to:
  /// **'Sort Direction'**
  String get sortDirection;

  /// No description provided for @displayModeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get displayModeAll;

  /// No description provided for @displayModePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get displayModePopular;

  /// No description provided for @displayModeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get displayModeRecommended;

  /// No description provided for @subtitlePriorityHighest.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get subtitlePriorityHighest;

  /// No description provided for @subtitlePriorityLowest.
  ///
  /// In en, this message translates to:
  /// **'Deferred'**
  String get subtitlePriorityLowest;

  /// No description provided for @translationSourceGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Translate'**
  String get translationSourceGoogle;

  /// No description provided for @translationSourceYoudao.
  ///
  /// In en, this message translates to:
  /// **'Youdao Translate'**
  String get translationSourceYoudao;

  /// No description provided for @translationSourceMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Translate'**
  String get translationSourceMicrosoft;

  /// No description provided for @translationSourceLlm.
  ///
  /// In en, this message translates to:
  /// **'LLM Translate'**
  String get translationSourceLlm;

  /// No description provided for @progressMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get progressMarked;

  /// No description provided for @progressListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get progressListening;

  /// No description provided for @progressListened.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get progressListened;

  /// No description provided for @progressReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get progressReplay;

  /// No description provided for @progressPostponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get progressPostponed;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Account'**
  String get registerAccount;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server Address'**
  String get serverAddress;

  /// No description provided for @serverCookie.
  ///
  /// In en, this message translates to:
  /// **'Server Cookie'**
  String get serverCookie;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailed;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 5 characters'**
  String get usernameMinLength;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 5 characters'**
  String get passwordMinLength;

  /// No description provided for @accountAdded.
  ///
  /// In en, this message translates to:
  /// **'Account \"{username}\" has been added'**
  String accountAdded(String username);

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @enterServerAddressToTest.
  ///
  /// In en, this message translates to:
  /// **'Please enter server address to test connection'**
  String get enterServerAddressToTest;

  /// No description provided for @latencyMs.
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String latencyMs(String ms);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @guestModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode Confirmation'**
  String get guestModeTitle;

  /// No description provided for @guestModeMessage.
  ///
  /// In en, this message translates to:
  /// **'Guest mode has limited functionality:\n\n• Cannot mark or rate works\n• Cannot create playlists\n• Cannot sync progress\n\nGuest mode uses a demo account to connect to the server, which may be unstable.'**
  String get guestModeMessage;

  /// No description provided for @continueGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Continue with Guest Mode'**
  String get continueGuestMode;

  /// No description provided for @guestAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Guest account has been added'**
  String get guestAccountAdded;

  /// No description provided for @guestLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest login failed'**
  String get guestLoginFailed;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @advancedFilter.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filter'**
  String get advancedFilter;

  /// No description provided for @enterSearchContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter search content'**
  String get enterSearchContent;

  /// No description provided for @searchTag.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get searchTag;

  /// No description provided for @minRating.
  ///
  /// In en, this message translates to:
  /// **'Min Rating'**
  String get minRating;

  /// No description provided for @minRatingStars.
  ///
  /// In en, this message translates to:
  /// **'{stars} stars'**
  String minRatingStars(String stars);

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchHistory;

  /// No description provided for @clearSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Search History'**
  String get clearSearchHistory;

  /// No description provided for @clearSearchHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all search history?'**
  String get clearSearchHistoryConfirm;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @searchHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Search history cleared'**
  String get searchHistoryCleared;

  /// No description provided for @noSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'No search history'**
  String get noSearchHistory;

  /// No description provided for @excludeMode.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get excludeMode;

  /// No description provided for @includeMode.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get includeMode;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get loadFailed;

  /// No description provided for @loadFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailedWithError(String error);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @getFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve'**
  String get getFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @accountManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-account management, switch accounts'**
  String get accountManagementSubtitle;

  /// No description provided for @privacyMode.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode'**
  String get privacyMode;

  /// No description provided for @privacyModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled - Playback info is hidden'**
  String get privacyModeEnabled;

  /// No description provided for @privacyModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get privacyModeDisabled;

  /// No description provided for @permissionManagement.
  ///
  /// In en, this message translates to:
  /// **'Permission Management'**
  String get permissionManagement;

  /// No description provided for @permissionManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notification permissions, background running permissions'**
  String get permissionManagementSubtitle;

  /// No description provided for @desktopFloatingLyric.
  ///
  /// In en, this message translates to:
  /// **'Desktop Floating Lyrics'**
  String get desktopFloatingLyric;

  /// No description provided for @floatingLyricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled - Lyrics will display on desktop'**
  String get floatingLyricEnabled;

  /// No description provided for @floatingLyricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get floatingLyricDisabled;

  /// No description provided for @floatingLyricTouch.
  ///
  /// In en, this message translates to:
  /// **'Floating Lyric Lock'**
  String get floatingLyricTouch;

  /// No description provided for @floatingLyricTouchEnabled.
  ///
  /// In en, this message translates to:
  /// **'Unlocked - Drag floating lyrics, long press to lock'**
  String get floatingLyricTouchEnabled;

  /// No description provided for @floatingLyricTouchDisabled.
  ///
  /// In en, this message translates to:
  /// **'Locked - Long press floating lyrics to unlock'**
  String get floatingLyricTouchDisabled;

  /// No description provided for @floatingFPS.
  ///
  /// In en, this message translates to:
  /// **'Show FPS'**
  String get floatingFPS;

  /// No description provided for @floatingFPSEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled - FPS shown at bottom-left of floating window'**
  String get floatingFPSEnabled;

  /// No description provided for @floatingFPSDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get floatingFPSDisabled;

  /// No description provided for @floatingNetworkSpeed.
  ///
  /// In en, this message translates to:
  /// **'Show Network Speed'**
  String get floatingNetworkSpeed;

  /// No description provided for @floatingNetworkSpeedEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled - Speed shown at bottom-right of floating window'**
  String get floatingNetworkSpeedEnabled;

  /// No description provided for @floatingNetworkSpeedDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get floatingNetworkSpeedDisabled;

  /// No description provided for @styleSettings.
  ///
  /// In en, this message translates to:
  /// **'Style Settings'**
  String get styleSettings;

  /// No description provided for @styleSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize font, color, transparency, etc.'**
  String get styleSettingsSubtitle;

  /// No description provided for @downloadPath.
  ///
  /// In en, this message translates to:
  /// **'Download Path'**
  String get downloadPath;

  /// No description provided for @downloadPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize download file save location'**
  String get downloadPathSubtitle;

  /// No description provided for @maxConcurrentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Max Concurrent Downloads'**
  String get maxConcurrentDownloads;

  /// No description provided for @maxConcurrentDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Limit simultaneous download tasks'**
  String get maxConcurrentDownloadsSubtitle;

  /// No description provided for @cacheManagement.
  ///
  /// In en, this message translates to:
  /// **'Cache Management'**
  String get cacheManagement;

  /// No description provided for @currentCache.
  ///
  /// In en, this message translates to:
  /// **'Current cache: {size}'**
  String currentCache(String size);

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @themeSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode, theme color, etc.'**
  String get themeSettingsSubtitle;

  /// No description provided for @uiSettings.
  ///
  /// In en, this message translates to:
  /// **'UI Settings'**
  String get uiSettings;

  /// No description provided for @uiSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Player, detail page, cards, etc.'**
  String get uiSettingsSubtitle;

  /// No description provided for @liquidGlassNavigation.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass Navigation'**
  String get liquidGlassNavigation;

  /// No description provided for @liquidGlassNavigationDesc.
  ///
  /// In en, this message translates to:
  /// **'Use translucent glass navigation and mini player surfaces. Enabled by default on iOS and macOS.'**
  String get liquidGlassNavigationDesc;

  /// No description provided for @preferenceSettings.
  ///
  /// In en, this message translates to:
  /// **'Preference Settings'**
  String get preferenceSettings;

  /// No description provided for @preferenceSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Translation source, blocking, audio preferences, etc.'**
  String get preferenceSettingsSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @unknownVersion.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownVersion;

  /// No description provided for @licenseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load LICENSE file'**
  String get licenseLoadFailed;

  /// No description provided for @licenseEmpty.
  ///
  /// In en, this message translates to:
  /// **'LICENSE content is empty'**
  String get licenseEmpty;

  /// No description provided for @failedToLoadAbout.
  ///
  /// In en, this message translates to:
  /// **'Failed to load about info'**
  String get failedToLoadAbout;

  /// No description provided for @newVersionFound.
  ///
  /// In en, this message translates to:
  /// **'New Version Found'**
  String get newVersionFound;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'{version} available (current: {current})'**
  String newVersionAvailable(String version, String current);

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version Info'**
  String get versionInfo;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version: {version}'**
  String currentVersion(String version);

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdate;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @projectRepo.
  ///
  /// In en, this message translates to:
  /// **'Project Repository'**
  String get projectRepo;

  /// No description provided for @openSourceLicense.
  ///
  /// In en, this message translates to:
  /// **'Open Source License'**
  String get openSourceLicense;

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Cannot open link'**
  String get cannotOpenLink;

  /// No description provided for @openLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open link: {error}'**
  String openLinkFailed(String error);

  /// No description provided for @foundNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Found new version {version}'**
  String foundNewVersion(String version);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @alreadyLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Already the latest version'**
  String get alreadyLatestVersion;

  /// No description provided for @checkUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed, please check network connection'**
  String get checkUpdateFailed;

  /// No description provided for @onlineMarks.
  ///
  /// In en, this message translates to:
  /// **'Online Marks'**
  String get onlineMarks;

  /// No description provided for @historyRecord.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyRecord;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloadTasks.
  ///
  /// In en, this message translates to:
  /// **'Download Tasks'**
  String get downloadTasks;

  /// No description provided for @subtitleLibrary.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Library'**
  String get subtitleLibrary;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @marked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get marked;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listening;

  /// No description provided for @listened.
  ///
  /// In en, this message translates to:
  /// **'Listened'**
  String get listened;

  /// No description provided for @replayMark.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replayMark;

  /// No description provided for @postponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get postponed;

  /// No description provided for @switchToSmallGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to small grid view'**
  String get switchToSmallGrid;

  /// No description provided for @switchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to list view'**
  String get switchToList;

  /// No description provided for @switchToLargeGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to large grid view'**
  String get switchToLargeGrid;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @noPlayHistory.
  ///
  /// In en, this message translates to:
  /// **'No play history'**
  String get noPlayHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all play history? This action cannot be undone.'**
  String get clearHistoryConfirm;

  /// No description provided for @popularNoSort.
  ///
  /// In en, this message translates to:
  /// **'Popular mode does not support sorting'**
  String get popularNoSort;

  /// No description provided for @recommendedNoSort.
  ///
  /// In en, this message translates to:
  /// **'Recommended mode does not support sorting'**
  String get recommendedNoSort;

  /// No description provided for @showAllWorks.
  ///
  /// In en, this message translates to:
  /// **'Show all works'**
  String get showAllWorks;

  /// No description provided for @showOnlySubtitled.
  ///
  /// In en, this message translates to:
  /// **'Show only subtitled works'**
  String get showOnlySubtitled;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @noDownloadTasks.
  ///
  /// In en, this message translates to:
  /// **'No download tasks'**
  String get noDownloadTasks;

  /// No description provided for @nFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String nFiles(int count);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @deletionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deletionConfirmTitle;

  /// No description provided for @deletionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected download tasks? Downloaded files will also be removed.'**
  String deletionConfirmMessage(int count);

  /// No description provided for @deletedNFiles.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} files'**
  String deletedNFiles(int count);

  /// No description provided for @downloadStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get downloadStatusPending;

  /// No description provided for @downloadStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadStatusDownloading;

  /// No description provided for @downloadStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get downloadStatusCompleted;

  /// No description provided for @downloadStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get downloadStatusFailed;

  /// No description provided for @downloadStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get downloadStatusPaused;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed: {error}'**
  String translationFailed(String error);

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied {label}: {text}'**
  String copiedToClipboard(String label, String text);

  /// No description provided for @loadingFileList.
  ///
  /// In en, this message translates to:
  /// **'Loading file list...'**
  String get loadingFileList;

  /// No description provided for @loadFileListFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file list: {error}'**
  String loadFileListFailed(String error);

  /// No description provided for @playlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistTitle;

  /// No description provided for @noAudioPlaying.
  ///
  /// In en, this message translates to:
  /// **'No audio playing'**
  String get noAudioPlaying;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @backward10s.
  ///
  /// In en, this message translates to:
  /// **'Backward 10s'**
  String get backward10s;

  /// No description provided for @forward10s.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get forward10s;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @repeatMode.
  ///
  /// In en, this message translates to:
  /// **'Repeat Mode'**
  String get repeatMode;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get repeatOff;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get repeatOne;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get repeatAll;

  /// No description provided for @addMark.
  ///
  /// In en, this message translates to:
  /// **'Add Mark'**
  String get addMark;

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Detail'**
  String get viewDetail;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @sleepTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimerTitle;

  /// No description provided for @aboutToStop.
  ///
  /// In en, this message translates to:
  /// **'About to stop'**
  String get aboutToStop;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining time'**
  String get remainingTime;

  /// No description provided for @finishCurrentTrack.
  ///
  /// In en, this message translates to:
  /// **'Stop after current track finishes'**
  String get finishCurrentTrack;

  /// No description provided for @addMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{min} min'**
  String addMinutes(int min);

  /// No description provided for @cancelTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel Timer'**
  String get cancelTimer;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @specifyTime.
  ///
  /// In en, this message translates to:
  /// **'Specify Time'**
  String get specifyTime;

  /// No description provided for @selectTimerDuration.
  ///
  /// In en, this message translates to:
  /// **'Select timer duration'**
  String get selectTimerDuration;

  /// No description provided for @selectStopTime.
  ///
  /// In en, this message translates to:
  /// **'Select the time to stop playback'**
  String get selectStopTime;

  /// No description provided for @markWork.
  ///
  /// In en, this message translates to:
  /// **'Mark Work'**
  String get markWork;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @addPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add Playlist'**
  String get addPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @enterPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterPlaylistName;

  /// No description provided for @privacySetting.
  ///
  /// In en, this message translates to:
  /// **'Privacy Setting'**
  String get privacySetting;

  /// No description provided for @playlistDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get playlistDescription;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get addDescription;

  /// No description provided for @enterPlaylistNameWarning.
  ///
  /// In en, this message translates to:
  /// **'Please enter a playlist name'**
  String get enterPlaylistNameWarning;

  /// No description provided for @enterPlaylistLink.
  ///
  /// In en, this message translates to:
  /// **'Please enter a playlist link'**
  String get enterPlaylistLink;

  /// No description provided for @switchAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switchAccountTitle;

  /// No description provided for @switchAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to switch to account \"{username}\"?'**
  String switchAccountConfirm(String username);

  /// No description provided for @switchedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Switched to account: {username}'**
  String switchedToAccount(String username);

  /// No description provided for @switchFailed.
  ///
  /// In en, this message translates to:
  /// **'Switch failed, please check account info'**
  String get switchFailed;

  /// No description provided for @switchFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Switch failed: {error}'**
  String switchFailedWithError(String error);

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get noAccounts;

  /// No description provided for @tapToAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Tap the button in the bottom right to add an account'**
  String get tapToAddAccount;

  /// No description provided for @currentAccount.
  ///
  /// In en, this message translates to:
  /// **'Current Account'**
  String get currentAccount;

  /// No description provided for @switchAction.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchAction;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete account \"{username}\"? This action cannot be undone.'**
  String deleteAccountConfirm(String username);

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @deletionFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed: {error}'**
  String deletionFailedWithError(String error);

  /// No description provided for @subtitleLibraryPriority.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Library Priority'**
  String get subtitleLibraryPriority;

  /// No description provided for @selectSubtitlePriority.
  ///
  /// In en, this message translates to:
  /// **'Select subtitle library priority for auto-loading:'**
  String get selectSubtitlePriority;

  /// No description provided for @subtitlePriorityHighestDesc.
  ///
  /// In en, this message translates to:
  /// **'Search subtitle library first, then online/downloads'**
  String get subtitlePriorityHighestDesc;

  /// No description provided for @subtitlePriorityLowestDesc.
  ///
  /// In en, this message translates to:
  /// **'Search online/downloads first, then subtitle library'**
  String get subtitlePriorityLowestDesc;

  /// No description provided for @defaultSortSettings.
  ///
  /// In en, this message translates to:
  /// **'Default Sort Settings'**
  String get defaultSortSettings;

  /// No description provided for @defaultSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default sort updated'**
  String get defaultSortUpdated;

  /// No description provided for @translationSourceSettings.
  ///
  /// In en, this message translates to:
  /// **'Translation Source Settings'**
  String get translationSourceSettings;

  /// No description provided for @selectTranslationProvider.
  ///
  /// In en, this message translates to:
  /// **'Select translation service provider:'**
  String get selectTranslationProvider;

  /// No description provided for @translationTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Target Language'**
  String get translationTargetLanguage;

  /// No description provided for @selectTranslationTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select target language:'**
  String get selectTranslationTargetLanguage;

  /// No description provided for @translationLanguageFollowApp.
  ///
  /// In en, this message translates to:
  /// **'Follow App Language'**
  String get translationLanguageFollowApp;

  /// No description provided for @translationLanguageZhHans.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get translationLanguageZhHans;

  /// No description provided for @translationLanguageZhHant.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get translationLanguageZhHant;

  /// No description provided for @translationLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get translationLanguageEnglish;

  /// No description provided for @translationLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get translationLanguageJapanese;

  /// No description provided for @translationLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get translationLanguageRussian;

  /// No description provided for @translationLanguageCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get translationLanguageCustom;

  /// No description provided for @translationCustomTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Custom Target Language'**
  String get translationCustomTargetLanguage;

  /// No description provided for @translationCustomLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Language name, e.g. Korean'**
  String get translationCustomLanguageHint;

  /// No description provided for @translationCustomLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom: {value}'**
  String translationCustomLanguageLabel(String value);

  /// No description provided for @translationCustomTargetRequiresLlm.
  ///
  /// In en, this message translates to:
  /// **'Requires LLM translation'**
  String get translationCustomTargetRequiresLlm;

  /// No description provided for @needsConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Needs configuration'**
  String get needsConfiguration;

  /// No description provided for @llmTranslation.
  ///
  /// In en, this message translates to:
  /// **'LLM Translation'**
  String get llmTranslation;

  /// No description provided for @goToConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get goToConfigure;

  /// No description provided for @subtitlePrioritySettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle library priority'**
  String get subtitlePrioritySettingSubtitle;

  /// No description provided for @defaultSortSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Default sort for home page'**
  String get defaultSortSettingTitle;

  /// No description provided for @translationSource.
  ///
  /// In en, this message translates to:
  /// **'Translation Source'**
  String get translationSource;

  /// No description provided for @llmSettings.
  ///
  /// In en, this message translates to:
  /// **'LLM Settings'**
  String get llmSettings;

  /// No description provided for @llmSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure API URL, Key, and model'**
  String get llmSettingsSubtitle;

  /// No description provided for @audioFormatPreference.
  ///
  /// In en, this message translates to:
  /// **'Audio Format Preference'**
  String get audioFormatPreference;

  /// No description provided for @audioFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set audio format priority order'**
  String get audioFormatSubtitle;

  /// No description provided for @preloadNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Preload Next Track'**
  String get preloadNextTitle;

  /// No description provided for @preloadNextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preload the next track to cache before the current one ends to avoid playback gaps'**
  String get preloadNextSubtitle;

  /// No description provided for @selectPreloadThreshold.
  ///
  /// In en, this message translates to:
  /// **'Preload starts when remaining time of the current track is below this threshold:'**
  String get selectPreloadThreshold;

  /// No description provided for @preloadOptionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get preloadOptionOff;

  /// No description provided for @preloadOptionSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String preloadOptionSeconds(int seconds);

  /// No description provided for @preloadOptionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get preloadOptionCustom;

  /// No description provided for @preloadCustomInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Preload Threshold'**
  String get preloadCustomInputTitle;

  /// No description provided for @preloadCustomInputHint.
  ///
  /// In en, this message translates to:
  /// **'Seconds (1-300)'**
  String get preloadCustomInputHint;

  /// No description provided for @preloadCustomInputRangeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number between 1 and 300'**
  String get preloadCustomInputRangeError;

  /// No description provided for @preloadCustomValueLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String preloadCustomValueLabel(int value);

  /// No description provided for @keepScreenAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep Screen Awake'**
  String get keepScreenAwake;

  /// No description provided for @keepScreenAwakeDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on while an audio track is active for easier subtitle reading.'**
  String get keepScreenAwakeDesc;

  /// No description provided for @audioHaptics.
  ///
  /// In en, this message translates to:
  /// **'Audio Haptics (Beta)'**
  String get audioHaptics;

  /// No description provided for @audioHapticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Downloaded audio only, foreground only. Make the device vibrate with audio features. May increase battery use.'**
  String get audioHapticsDesc;

  /// No description provided for @audioHapticsIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get audioHapticsIntensity;

  /// No description provided for @audioGain.
  ///
  /// In en, this message translates to:
  /// **'Global Audio Gain'**
  String get audioGain;

  /// No description provided for @audioGainDesc.
  ///
  /// In en, this message translates to:
  /// **'Attenuate or boost all audio globally. 0 dB preserves the original sound. High positive gain may cause distortion or hearing damage.'**
  String get audioGainDesc;

  /// No description provided for @audioGainAttenuationDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduce all audio globally. 0 dB preserves the original sound.'**
  String get audioGainAttenuationDesc;

  /// No description provided for @audioGainPassthroughDesc.
  ///
  /// In en, this message translates to:
  /// **'Unavailable while audio passthrough is enabled.'**
  String get audioGainPassthroughDesc;

  /// No description provided for @blockingSettings.
  ///
  /// In en, this message translates to:
  /// **'Blocking Settings'**
  String get blockingSettings;

  /// No description provided for @blockingSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked tags, voice actors, and circles'**
  String get blockingSettingsSubtitle;

  /// No description provided for @audioPassthrough.
  ///
  /// In en, this message translates to:
  /// **'Audio Passthrough (Beta)'**
  String get audioPassthrough;

  /// No description provided for @audioPassthroughDescWindows.
  ///
  /// In en, this message translates to:
  /// **'Enable WASAPI exclusive mode for lossless output (restart required)'**
  String get audioPassthroughDescWindows;

  /// No description provided for @audioPassthroughDescMac.
  ///
  /// In en, this message translates to:
  /// **'Enable CoreAudio exclusive mode for lossless output'**
  String get audioPassthroughDescMac;

  /// No description provided for @audioPassthroughDisableDesc.
  ///
  /// In en, this message translates to:
  /// **'Disable audio passthrough mode'**
  String get audioPassthroughDisableDesc;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @audioPassthroughWarning.
  ///
  /// In en, this message translates to:
  /// **'This feature is not fully tested and may cause unexpected audio output. Are you sure you want to enable it?'**
  String get audioPassthroughWarning;

  /// No description provided for @exclusiveModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Exclusive mode enabled (restart required)'**
  String get exclusiveModeEnabled;

  /// No description provided for @audioPassthroughEnabled.
  ///
  /// In en, this message translates to:
  /// **'Audio passthrough mode enabled'**
  String get audioPassthroughEnabled;

  /// No description provided for @audioPassthroughDisabled.
  ///
  /// In en, this message translates to:
  /// **'Audio passthrough mode disabled'**
  String get audioPassthroughDisabled;

  /// No description provided for @tagVoteSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get tagVoteSupport;

  /// No description provided for @tagVoteOppose.
  ///
  /// In en, this message translates to:
  /// **'Oppose'**
  String get tagVoteOppose;

  /// No description provided for @tagVoted.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get tagVoted;

  /// No description provided for @votedSupport.
  ///
  /// In en, this message translates to:
  /// **'Voted support'**
  String get votedSupport;

  /// No description provided for @votedOppose.
  ///
  /// In en, this message translates to:
  /// **'Voted oppose'**
  String get votedOppose;

  /// No description provided for @voteCancelled.
  ///
  /// In en, this message translates to:
  /// **'Vote cancelled'**
  String get voteCancelled;

  /// No description provided for @voteFailed.
  ///
  /// In en, this message translates to:
  /// **'Vote failed: {error}'**
  String voteFailed(String error);

  /// No description provided for @blockThisTag.
  ///
  /// In en, this message translates to:
  /// **'Block this tag'**
  String get blockThisTag;

  /// No description provided for @copyTag.
  ///
  /// In en, this message translates to:
  /// **'Copy Tag'**
  String get copyTag;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @loadTagsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tags: {error}'**
  String loadTagsFailed(String error);

  /// No description provided for @selectAtLeastOneTag.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one tag'**
  String get selectAtLeastOneTag;

  /// No description provided for @tagSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tags submitted successfully, awaiting server processing'**
  String get tagSubmitSuccess;

  /// No description provided for @bindEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please go to www.asmr.one to bind your email first'**
  String get bindEmailFirst;

  /// No description provided for @selectedNTags.
  ///
  /// In en, this message translates to:
  /// **'Selected {count} tags:'**
  String selectedNTags(int count);

  /// No description provided for @noMatchingTags.
  ///
  /// In en, this message translates to:
  /// **'No matching tags found'**
  String get noMatchingTags;

  /// No description provided for @loadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Load failed, tap to retry'**
  String get loadFailedRetry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @playlistPrivacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get playlistPrivacyPrivate;

  /// No description provided for @playlistPrivacyUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Unlisted'**
  String get playlistPrivacyUnlisted;

  /// No description provided for @playlistPrivacyPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get playlistPrivacyPublic;

  /// No description provided for @systemPlaylistMarked.
  ///
  /// In en, this message translates to:
  /// **'My Marked'**
  String get systemPlaylistMarked;

  /// No description provided for @systemPlaylistLiked.
  ///
  /// In en, this message translates to:
  /// **'My Liked'**
  String get systemPlaylistLiked;

  /// No description provided for @totalNWorks.
  ///
  /// In en, this message translates to:
  /// **'{count} works'**
  String totalNWorks(int count);

  /// No description provided for @pageNOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} / {total}'**
  String pageNOfTotal(int current, int total);

  /// No description provided for @translateTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateTitle;

  /// No description provided for @translateDescription.
  ///
  /// In en, this message translates to:
  /// **'Translate Description'**
  String get translateDescription;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// No description provided for @translationFallbackNotice.
  ///
  /// In en, this message translates to:
  /// **'Translation failed, auto-switched to {source}'**
  String translationFallbackNotice(String source);

  /// No description provided for @tagLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagLabel;

  /// No description provided for @vaLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice Actors'**
  String get vaLabel;

  /// No description provided for @circleLabel.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get circleLabel;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingLabel;

  /// No description provided for @salesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @ageRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Age Rating'**
  String get ageRatingLabel;

  /// No description provided for @hasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Has Subtitle'**
  String get hasSubtitle;

  /// No description provided for @noSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No Subtitle'**
  String get noSubtitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @fileList.
  ///
  /// In en, this message translates to:
  /// **'File List'**
  String get fileList;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch display language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageZhTw.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get languageZhTw;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeModeDark;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeModeLight;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get themeModeSystem;

  /// No description provided for @colorSchemeOceanBlue.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get colorSchemeOceanBlue;

  /// No description provided for @colorSchemeForestGreen.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get colorSchemeForestGreen;

  /// No description provided for @colorSchemeSunsetOrange.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get colorSchemeSunsetOrange;

  /// No description provided for @colorSchemeLavenderPurple.
  ///
  /// In en, this message translates to:
  /// **'Lavender Purple'**
  String get colorSchemeLavenderPurple;

  /// No description provided for @colorSchemeSakuraPink.
  ///
  /// In en, this message translates to:
  /// **'Sakura Pink'**
  String get colorSchemeSakuraPink;

  /// No description provided for @colorSchemeDynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get colorSchemeDynamic;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get timeout;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @startDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download'**
  String get startDownload;

  /// No description provided for @confirmDeleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this download? The downloaded file will also be removed.'**
  String get confirmDeleteDownload;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @scanSubtitleLibrary.
  ///
  /// In en, this message translates to:
  /// **'Scan Subtitle Library'**
  String get scanSubtitleLibrary;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get scanComplete;

  /// No description provided for @noSubtitleFiles.
  ///
  /// In en, this message translates to:
  /// **'No subtitle files found'**
  String get noSubtitleFiles;

  /// No description provided for @subtitleFilesFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} subtitle files'**
  String subtitleFilesFound(int count);

  /// No description provided for @selectDirectory.
  ///
  /// In en, this message translates to:
  /// **'Select Directory'**
  String get selectDirectory;

  /// No description provided for @privacyModeSettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode Settings'**
  String get privacyModeSettings;

  /// No description provided for @blurCover.
  ///
  /// In en, this message translates to:
  /// **'Blur Cover'**
  String get blurCover;

  /// No description provided for @maskTitle.
  ///
  /// In en, this message translates to:
  /// **'Mask Title'**
  String get maskTitle;

  /// No description provided for @customTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Title'**
  String get customTitle;

  /// No description provided for @privacyModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide playback information in system notifications and media controls'**
  String get privacyModeDesc;

  /// No description provided for @audioFormatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Format Settings'**
  String get audioFormatSettingsTitle;

  /// No description provided for @preferredFormat.
  ///
  /// In en, this message translates to:
  /// **'Preferred Format'**
  String get preferredFormat;

  /// No description provided for @cacheSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Cache Size Limit'**
  String get cacheSizeLimit;

  /// No description provided for @llmApiUrl.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get llmApiUrl;

  /// No description provided for @llmApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get llmApiKey;

  /// No description provided for @llmModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get llmModel;

  /// No description provided for @llmPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get llmPrompt;

  /// No description provided for @llmConcurrency.
  ///
  /// In en, this message translates to:
  /// **'Concurrency'**
  String get llmConcurrency;

  /// No description provided for @llmTestTranslation.
  ///
  /// In en, this message translates to:
  /// **'Test Translation'**
  String get llmTestTranslation;

  /// No description provided for @llmTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test successful'**
  String get llmTestSuccess;

  /// No description provided for @llmTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Test failed'**
  String get llmTestFailed;

  /// No description provided for @subtitleTimingAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Timing Adjustment'**
  String get subtitleTimingAdjustment;

  /// No description provided for @playerLyricStyle.
  ///
  /// In en, this message translates to:
  /// **'Player Lyrics Style'**
  String get playerLyricStyle;

  /// No description provided for @floatingLyricStyle.
  ///
  /// In en, this message translates to:
  /// **'Floating Lyrics Style'**
  String get floatingLyricStyle;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontColor.
  ///
  /// In en, this message translates to:
  /// **'Font Color'**
  String get fontColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @transparency.
  ///
  /// In en, this message translates to:
  /// **'Transparency'**
  String get transparency;

  /// No description provided for @windowSize.
  ///
  /// In en, this message translates to:
  /// **'Window Size'**
  String get windowSize;

  /// No description provided for @playerButtonSettings.
  ///
  /// In en, this message translates to:
  /// **'Player Button Settings'**
  String get playerButtonSettings;

  /// No description provided for @showButton.
  ///
  /// In en, this message translates to:
  /// **'Show Button'**
  String get showButton;

  /// No description provided for @buttonOrder.
  ///
  /// In en, this message translates to:
  /// **'Button Order'**
  String get buttonOrder;

  /// No description provided for @workCardDisplaySettings.
  ///
  /// In en, this message translates to:
  /// **'Work Card Display Settings'**
  String get workCardDisplaySettings;

  /// No description provided for @showTags.
  ///
  /// In en, this message translates to:
  /// **'Show Tags'**
  String get showTags;

  /// No description provided for @showVa.
  ///
  /// In en, this message translates to:
  /// **'Show Voice Actors'**
  String get showVa;

  /// No description provided for @showRating.
  ///
  /// In en, this message translates to:
  /// **'Show Rating'**
  String get showRating;

  /// No description provided for @showPrice.
  ///
  /// In en, this message translates to:
  /// **'Show Price'**
  String get showPrice;

  /// No description provided for @cardSize.
  ///
  /// In en, this message translates to:
  /// **'Card Size'**
  String get cardSize;

  /// No description provided for @compact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// No description provided for @workDetailDisplaySettings.
  ///
  /// In en, this message translates to:
  /// **'Work Detail Display Settings'**
  String get workDetailDisplaySettings;

  /// No description provided for @infoSectionVisibility.
  ///
  /// In en, this message translates to:
  /// **'Info Section Visibility'**
  String get infoSectionVisibility;

  /// No description provided for @imageSize.
  ///
  /// In en, this message translates to:
  /// **'Image Size'**
  String get imageSize;

  /// No description provided for @showMetadata.
  ///
  /// In en, this message translates to:
  /// **'Show Metadata'**
  String get showMetadata;

  /// No description provided for @relatedRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Related Works'**
  String get relatedRecommendations;

  /// No description provided for @myTabsDisplaySettings.
  ///
  /// In en, this message translates to:
  /// **'\"My\" Page Settings'**
  String get myTabsDisplaySettings;

  /// No description provided for @showTab.
  ///
  /// In en, this message translates to:
  /// **'Show Tab'**
  String get showTab;

  /// No description provided for @tabOrder.
  ///
  /// In en, this message translates to:
  /// **'Tab Order'**
  String get tabOrder;

  /// No description provided for @blockedItems.
  ///
  /// In en, this message translates to:
  /// **'Blocked Items'**
  String get blockedItems;

  /// No description provided for @blockedTags.
  ///
  /// In en, this message translates to:
  /// **'Blocked Tags'**
  String get blockedTags;

  /// No description provided for @blockedVas.
  ///
  /// In en, this message translates to:
  /// **'Blocked Voice Actors'**
  String get blockedVas;

  /// No description provided for @blockedCircles.
  ///
  /// In en, this message translates to:
  /// **'Blocked Circles'**
  String get blockedCircles;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @noBlockedItems.
  ///
  /// In en, this message translates to:
  /// **'No blocked items'**
  String get noBlockedItems;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all cache?'**
  String get clearCacheConfirm;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get imagePreview;

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save Image'**
  String get saveImage;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get imageSaved;

  /// No description provided for @saveImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveImageFailed;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @ratingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Rating Distribution'**
  String get ratingDistribution;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @ratingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings total'**
  String ratingsCount(int count);

  /// No description provided for @myReviews.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get myReviews;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews'**
  String get noReviews;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit Review'**
  String get editReview;

  /// No description provided for @deleteReview.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get deleteReview;

  /// No description provided for @deleteReviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this review?'**
  String get deleteReviewConfirm;

  /// No description provided for @reviewDeleted.
  ///
  /// In en, this message translates to:
  /// **'Review deleted'**
  String get reviewDeleted;

  /// No description provided for @reviewContent.
  ///
  /// In en, this message translates to:
  /// **'Review content'**
  String get reviewContent;

  /// No description provided for @enterReviewContent.
  ///
  /// In en, this message translates to:
  /// **'Enter review content...'**
  String get enterReviewContent;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSubmitted;

  /// No description provided for @reviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Review failed: {error}'**
  String reviewFailed(String error);

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @mediaPermission.
  ///
  /// In en, this message translates to:
  /// **'Media Library Permission'**
  String get mediaPermission;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storagePermission;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestPermission;

  /// No description provided for @localDownloads.
  ///
  /// In en, this message translates to:
  /// **'Local Downloads'**
  String get localDownloads;

  /// No description provided for @offlinePlayback.
  ///
  /// In en, this message translates to:
  /// **'Offline Playback'**
  String get offlinePlayback;

  /// No description provided for @noDownloadedWorks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded works'**
  String get noDownloadedWorks;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @ignoreThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Ignore this version'**
  String get ignoreThisVersion;

  /// No description provided for @remindLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Later'**
  String get remindLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @fetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Fetch failed'**
  String get fetchFailed;

  /// No description provided for @operationFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailedWithError(String error);

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check updates, licenses, etc.'**
  String get aboutSubtitle;

  /// No description provided for @currentCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Current Cache Size'**
  String get currentCacheSize;

  /// No description provided for @cacheLimitLabelMB.
  ///
  /// In en, this message translates to:
  /// **'Limit: {size}MB'**
  String cacheLimitLabelMB(int size);

  /// No description provided for @cacheUsagePercent.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get cacheUsagePercent;

  /// No description provided for @autoCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Clean Info'**
  String get autoCleanTitle;

  /// No description provided for @autoCleanDescription.
  ///
  /// In en, this message translates to:
  /// **'• Cache is auto-cleaned when exceeding the limit\n• Deletes until cache drops to 80% of limit\n• Uses Least Recently Used (LRU) strategy'**
  String get autoCleanDescription;

  /// No description provided for @autoCleanDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'• Cache is auto-cleaned when exceeding the limit\n• Deletes until cache drops to 80% of limit'**
  String get autoCleanDescriptionShort;

  /// No description provided for @confirmClear.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get confirmClear;

  /// No description provided for @confirmClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all cache? This action cannot be undone.'**
  String get confirmClearCacheMessage;

  /// No description provided for @clearCacheFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Clear cache failed: {error}'**
  String clearCacheFailedWithError(String error);

  /// No description provided for @hasNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get hasNewVersion;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// No description provided for @themePreview.
  ///
  /// In en, this message translates to:
  /// **'Theme Preview'**
  String get themePreview;

  /// No description provided for @themeModeSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically adapt to system dark/light mode'**
  String get themeModeSystemDesc;

  /// No description provided for @themeModeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeModeLightDesc;

  /// No description provided for @themeModeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeModeDarkDesc;

  /// No description provided for @colorSchemeOceanBlueDesc.
  ///
  /// In en, this message translates to:
  /// **'Blue, blue, blue!'**
  String get colorSchemeOceanBlueDesc;

  /// No description provided for @colorSchemeSakuraPinkDesc.
  ///
  /// In en, this message translates to:
  /// **'( ゜- ゜)つロ Cheers~'**
  String get colorSchemeSakuraPinkDesc;

  /// No description provided for @colorSchemeSunsetOrangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Themes are a must ✍🏻✍🏻✍🏻'**
  String get colorSchemeSunsetOrangeDesc;

  /// No description provided for @colorSchemeLavenderPurpleDesc.
  ///
  /// In en, this message translates to:
  /// **'Bro, bro...'**
  String get colorSchemeLavenderPurpleDesc;

  /// No description provided for @colorSchemeForestGreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Green, green, green'**
  String get colorSchemeForestGreenDesc;

  /// No description provided for @colorSchemeDynamicDesc.
  ///
  /// In en, this message translates to:
  /// **'Use wallpaper colors from system (Android 12+)'**
  String get colorSchemeDynamicDesc;

  /// No description provided for @primaryContainer.
  ///
  /// In en, this message translates to:
  /// **'Primary Container'**
  String get primaryContainer;

  /// No description provided for @secondaryContainer.
  ///
  /// In en, this message translates to:
  /// **'Secondary Container'**
  String get secondaryContainer;

  /// No description provided for @tertiaryContainer.
  ///
  /// In en, this message translates to:
  /// **'Tertiary Container'**
  String get tertiaryContainer;

  /// No description provided for @surfaceColor.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get surfaceColor;

  /// No description provided for @playerButtonSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize player control button order'**
  String get playerButtonSettingsSubtitle;

  /// No description provided for @playerLyricStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize subtitle style for mini and fullscreen player'**
  String get playerLyricStyleSubtitle;

  /// No description provided for @workDetailDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control info items on work detail page'**
  String get workDetailDisplaySubtitle;

  /// No description provided for @workCardDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control info items on work cards'**
  String get workCardDisplaySubtitle;

  /// No description provided for @myTabsDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control tab display in My page'**
  String get myTabsDisplaySubtitle;

  /// No description provided for @pageSizeSettings.
  ///
  /// In en, this message translates to:
  /// **'Items Per Page'**
  String get pageSizeSettings;

  /// No description provided for @pageSizeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {size} items/page'**
  String pageSizeCurrent(int size);

  /// No description provided for @currentSettingLabel.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String currentSettingLabel(String value);

  /// No description provided for @setToValue.
  ///
  /// In en, this message translates to:
  /// **'Set to: {value}'**
  String setToValue(String value);

  /// No description provided for @llmConfigRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'LLM translation requires an API Key. Please configure it in settings first.'**
  String get llmConfigRequiredMessage;

  /// No description provided for @autoSwitchedToLlm.
  ///
  /// In en, this message translates to:
  /// **'Auto-switched to: LLM Translation'**
  String get autoSwitchedToLlm;

  /// No description provided for @translationDescGoogle.
  ///
  /// In en, this message translates to:
  /// **'Requires network access to Google services'**
  String get translationDescGoogle;

  /// No description provided for @translationDescYoudao.
  ///
  /// In en, this message translates to:
  /// **'Works with default network'**
  String get translationDescYoudao;

  /// No description provided for @translationDescMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Works with default network'**
  String get translationDescMicrosoft;

  /// No description provided for @translationDescLlm.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible API, requires manual API Key configuration'**
  String get translationDescLlm;

  /// No description provided for @audioPassthroughDescAndroid.
  ///
  /// In en, this message translates to:
  /// **'Allow raw bitstream output (AC3/DTS) to external decoder. May take exclusive audio control.'**
  String get audioPassthroughDescAndroid;

  /// No description provided for @permissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Permission Explanation'**
  String get permissionExplanation;

  /// No description provided for @backgroundRunningPermission.
  ///
  /// In en, this message translates to:
  /// **'Background Running Permission'**
  String get backgroundRunningPermission;

  /// No description provided for @notificationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Used for showing media playback notification, allowing control from lock screen and notification bar.'**
  String get notificationPermissionDesc;

  /// No description provided for @backgroundRunningPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Exempts app from battery optimization to ensure audio continues playing in background.'**
  String get backgroundRunningPermissionDesc;

  /// No description provided for @notificationGrantedStatus.
  ///
  /// In en, this message translates to:
  /// **'Granted - Can show playback notification and controls'**
  String get notificationGrantedStatus;

  /// No description provided for @notificationDeniedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not granted - Tap to request permission'**
  String get notificationDeniedStatus;

  /// No description provided for @backgroundGrantedStatus.
  ///
  /// In en, this message translates to:
  /// **'Granted - App can run continuously in background'**
  String get backgroundGrantedStatus;

  /// No description provided for @backgroundDeniedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not granted - Tap to request permission'**
  String get backgroundDeniedStatus;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Notification permission granted'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notificationPermissionDenied;

  /// No description provided for @requestNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request notification permission: {error}'**
  String requestNotificationFailed(String error);

  /// No description provided for @backgroundPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Background running permission granted'**
  String get backgroundPermissionGranted;

  /// No description provided for @backgroundPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Background running permission denied'**
  String get backgroundPermissionDenied;

  /// No description provided for @requestBackgroundFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request background permission: {error}'**
  String requestBackgroundFailed(String error);

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'{permission} Required'**
  String permissionRequired(String permission);

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'{permission} has been permanently denied. Please enable it manually in system settings.'**
  String permissionPermanentlyDenied(String permission);

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @permissionsAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Permission management is only available on Android'**
  String get permissionsAndroidOnly;

  /// No description provided for @permissionsNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Other platforms do not require manual permission management'**
  String get permissionsNotNeeded;

  /// No description provided for @refreshPermissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh permission status'**
  String get refreshPermissionStatus;

  /// No description provided for @deleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"?'**
  String deleteFileConfirm(String fileName);

  /// No description provided for @deleteSelectedFilesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected files?'**
  String deleteSelectedFilesConfirm(int count);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @cannotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot open folder: {path}'**
  String cannotOpenFolder(String path);

  /// No description provided for @openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder: {error}'**
  String openFolderFailed(String error);

  /// No description provided for @reloadingFromDisk.
  ///
  /// In en, this message translates to:
  /// **'Reloading from disk...'**
  String get reloadingFromDisk;

  /// No description provided for @refreshComplete.
  ///
  /// In en, this message translates to:
  /// **'Refresh complete'**
  String get refreshComplete;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed: {error}'**
  String refreshFailed(String error);

  /// No description provided for @deleteSelectedWorksConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected works?'**
  String deleteSelectedWorksConfirm(int count);

  /// No description provided for @partialDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Partial deletion failed: {error}'**
  String partialDeleteFailed(String error);

  /// No description provided for @deletedNOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Deleted {success}/{total} tasks'**
  String deletedNOfTotal(int success, int total);

  /// No description provided for @deleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed: {error}'**
  String deleteFailedWithError(String error);

  /// No description provided for @noWorkMetadataForOffline.
  ///
  /// In en, this message translates to:
  /// **'This download has no saved work details and cannot be viewed offline'**
  String get noWorkMetadataForOffline;

  /// No description provided for @openWorkDetailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open work detail: {error}'**
  String openWorkDetailFailed(String error);

  /// No description provided for @noLocalDownloads.
  ///
  /// In en, this message translates to:
  /// **'No local downloads'**
  String get noLocalDownloads;

  /// No description provided for @exitSelection.
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get exitSelection;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @playlistLink.
  ///
  /// In en, this message translates to:
  /// **'Playlist Link'**
  String get playlistLink;

  /// No description provided for @playlistLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste playlist link, e.g.:\nhttps://www.asmr.one/playlist?id=...'**
  String get playlistLinkHint;

  /// No description provided for @unrecognizedPlaylistLink.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized playlist link or ID'**
  String get unrecognizedPlaylistLink;

  /// No description provided for @addingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Adding playlist...'**
  String get addingPlaylist;

  /// No description provided for @playlistAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist added successfully'**
  String get playlistAddedSuccess;

  /// No description provided for @addFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed'**
  String get addFailed;

  /// No description provided for @playlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist does not exist or has been deleted'**
  String get playlistNotFound;

  /// No description provided for @noPermissionToAccessPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No permission to access this playlist'**
  String get noPermissionToAccessPlaylist;

  /// No description provided for @networkConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed, please check network'**
  String get networkConnectionFailed;

  /// No description provided for @addFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Add failed: {error}'**
  String addFailedWithError(String error);

  /// No description provided for @creatingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Creating playlist...'**
  String get creatingPlaylist;

  /// No description provided for @playlistCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" created successfully'**
  String playlistCreatedSuccess(String name);

  /// No description provided for @createFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Creation failed: {error}'**
  String createFailedWithError(String error);

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists'**
  String get noPlaylists;

  /// No description provided for @noPlaylistsDescription.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created or favorited any playlists yet'**
  String get noPlaylistsDescription;

  /// No description provided for @myPlaylists.
  ///
  /// In en, this message translates to:
  /// **'My Playlists'**
  String get myPlaylists;

  /// No description provided for @totalNItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items total'**
  String totalNItems(int count);

  /// No description provided for @systemPlaylistCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'System playlists cannot be deleted'**
  String get systemPlaylistCannotDelete;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @unfavoritePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite Playlist'**
  String get unfavoritePlaylist;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deletion is irreversible. Users who favorited this playlist will lose access. Are you sure?'**
  String get deletePlaylistConfirm;

  /// No description provided for @unfavoritePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unfavorite \"{name}\"?'**
  String unfavoritePlaylistConfirm(String name);

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get unfavorite;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @onlyOwnerCanEdit.
  ///
  /// In en, this message translates to:
  /// **'Only the playlist owner can edit'**
  String get onlyOwnerCanEdit;

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// No description provided for @playlistNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Playlist name cannot be empty'**
  String get playlistNameRequired;

  /// No description provided for @privacyDescPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only you can view'**
  String get privacyDescPrivate;

  /// No description provided for @privacyDescUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Only people with the link can view'**
  String get privacyDescUnlisted;

  /// No description provided for @privacyDescPublic.
  ///
  /// In en, this message translates to:
  /// **'Anyone can view'**
  String get privacyDescPublic;

  /// No description provided for @addWorks.
  ///
  /// In en, this message translates to:
  /// **'Add Works'**
  String get addWorks;

  /// No description provided for @addWorksInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text containing work IDs, RJ numbers will be auto-detected'**
  String get addWorksInputHint;

  /// No description provided for @workId.
  ///
  /// In en, this message translates to:
  /// **'Work ID'**
  String get workId;

  /// No description provided for @workIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: RJ123456\nrj233333'**
  String get workIdHint;

  /// No description provided for @detectedNWorkIds.
  ///
  /// In en, this message translates to:
  /// **'Detected {count} work IDs'**
  String detectedNWorkIds(int count);

  /// No description provided for @addNWorks.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String addNWorks(int count);

  /// No description provided for @noValidWorkIds.
  ///
  /// In en, this message translates to:
  /// **'No valid work IDs found (starting with RJ)'**
  String get noValidWorkIds;

  /// No description provided for @addingNWorks.
  ///
  /// In en, this message translates to:
  /// **'Adding {count} works...'**
  String addingNWorks(int count);

  /// No description provided for @addedNWorksSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully added {count} works'**
  String addedNWorksSuccess(int count);

  /// No description provided for @removeWork.
  ///
  /// In en, this message translates to:
  /// **'Remove Work'**
  String get removeWork;

  /// No description provided for @removeWorkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{title}\" from the playlist?'**
  String removeWorkConfirm(String title);

  /// No description provided for @removeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed successfully'**
  String get removeSuccess;

  /// No description provided for @removeFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Remove failed: {error}'**
  String removeFailedWithError(String error);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// No description provided for @saveFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailedWithError(String error);

  /// No description provided for @noWorks.
  ///
  /// In en, this message translates to:
  /// **'No works'**
  String get noWorks;

  /// No description provided for @playlistNoWorksDescription.
  ///
  /// In en, this message translates to:
  /// **'No works have been added to this playlist yet'**
  String get playlistNoWorksDescription;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @createdTime.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdTime;

  /// No description provided for @nWorksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} works'**
  String nWorksCount(int count);

  /// No description provided for @nPlaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} plays'**
  String nPlaysCount(int count);

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylist;

  /// No description provided for @checkNetworkOrRetry.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection or try again later'**
  String get checkNetworkOrRetry;

  /// No description provided for @reachedEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end~'**
  String get reachedEnd;

  /// No description provided for @excludedNWorks.
  ///
  /// In en, this message translates to:
  /// **'Excluded {count} works'**
  String excludedNWorks(int count);

  /// No description provided for @pageExcludedNWorks.
  ///
  /// In en, this message translates to:
  /// **'This page excluded {count} works'**
  String pageExcludedNWorks(int count);

  /// No description provided for @noSubtitlesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subtitles available'**
  String get noSubtitlesAvailable;

  /// No description provided for @translateLyrics.
  ///
  /// In en, this message translates to:
  /// **'Translate lyrics'**
  String get translateLyrics;

  /// No description provided for @fullscreenLyrics.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen lyrics'**
  String get fullscreenLyrics;

  /// No description provided for @showOriginalLyrics.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginalLyrics;

  /// No description provided for @showTranslatedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslatedLyrics;

  /// No description provided for @translatingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translatingLyrics;

  /// No description provided for @lyricTranslationFailed.
  ///
  /// In en, this message translates to:
  /// **'Lyric translation failed'**
  String get lyricTranslationFailed;

  /// No description provided for @lyricTranslationConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'KikoFlu will translate the currently playing lyrics with your current translation settings. When finished, the translation is shown immediately and saved as a same-name .lrc file in the Saved subtitle library folder, overwriting any existing file. Switching tracks during translation discards this result.'**
  String get lyricTranslationConfirmMessage;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @backToCover.
  ///
  /// In en, this message translates to:
  /// **'Back to cover'**
  String get backToCover;

  /// No description provided for @lyricHintTapCover.
  ///
  /// In en, this message translates to:
  /// **'Tap cover or title to enter subtitle view'**
  String get lyricHintTapCover;

  /// No description provided for @floatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Floating Subtitle'**
  String get floatingSubtitle;

  /// No description provided for @appendMode.
  ///
  /// In en, this message translates to:
  /// **'Append Mode'**
  String get appendMode;

  /// No description provided for @appendModeStatusOn.
  ///
  /// In en, this message translates to:
  /// **'Append Mode: On'**
  String get appendModeStatusOn;

  /// No description provided for @appendModeStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Append Mode: Off'**
  String get appendModeStatusOff;

  /// No description provided for @playlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Playlist is empty'**
  String get playlistEmpty;

  /// No description provided for @appendModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Append Mode Enabled'**
  String get appendModeEnabled;

  /// No description provided for @appendModeHint.
  ///
  /// In en, this message translates to:
  /// **'Audio tapped next will be appended to the end of the current playlist instead of replacing it.\nDuplicate tracks won\'t be added.'**
  String get appendModeHint;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @nMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String nMinutes(int count);

  /// No description provided for @nHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hr'**
  String nHours(int count);

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @rjNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'RJ Number'**
  String get rjNumberLabel;

  /// No description provided for @workIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Work ID'**
  String get workIdLabel;

  /// No description provided for @tapToViewRatingDetail.
  ///
  /// In en, this message translates to:
  /// **'Tap to view rating details'**
  String get tapToViewRatingDetail;

  /// No description provided for @priceInYen.
  ///
  /// In en, this message translates to:
  /// **'{price} Yen'**
  String priceInYen(int price);

  /// No description provided for @soldCount.
  ///
  /// In en, this message translates to:
  /// **'Sold: {count}'**
  String soldCount(String count);

  /// No description provided for @circleAndVaSection.
  ///
  /// In en, this message translates to:
  /// **'Circle | Voice Actors'**
  String get circleAndVaSection;

  /// No description provided for @subtitleBadge.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get subtitleBadge;

  /// No description provided for @otherEditions.
  ///
  /// In en, this message translates to:
  /// **'Other Editions'**
  String get otherEditions;

  /// No description provided for @tenThousandSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count}k'**
  String tenThousandSuffix(String count);

  /// No description provided for @packingWork.
  ///
  /// In en, this message translates to:
  /// **'Packing work...'**
  String get packingWork;

  /// No description provided for @workDirectoryNotExist.
  ///
  /// In en, this message translates to:
  /// **'Work directory does not exist'**
  String get workDirectoryNotExist;

  /// No description provided for @packingFailed.
  ///
  /// In en, this message translates to:
  /// **'Packing failed'**
  String get packingFailed;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful: {path}'**
  String exportSuccess(String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @exportAsZip.
  ///
  /// In en, this message translates to:
  /// **'Export as ZIP'**
  String get exportAsZip;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineBadge;

  /// No description provided for @loadFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files: {error}'**
  String loadFilesFailed(String error);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noPlayableAudioFiles.
  ///
  /// In en, this message translates to:
  /// **'No playable audio files found'**
  String get noPlayableAudioFiles;

  /// No description provided for @cannotFindAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot find audio file: {title}'**
  String cannotFindAudioFile(String title);

  /// No description provided for @nowPlayingNOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Now playing: {title} ({current}/{total})'**
  String nowPlayingNOfTotal(String title, int current, int total);

  /// No description provided for @noAudioCannotLoadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No audio playing, cannot load subtitle'**
  String get noAudioCannotLoadSubtitle;

  /// No description provided for @loadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load Subtitle'**
  String get loadSubtitle;

  /// No description provided for @loadSubtitleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Load this file as subtitle for the current audio?'**
  String get loadSubtitleConfirm;

  /// No description provided for @subtitleFile.
  ///
  /// In en, this message translates to:
  /// **'Subtitle file'**
  String get subtitleFile;

  /// No description provided for @currentAudio.
  ///
  /// In en, this message translates to:
  /// **'Current audio'**
  String get currentAudio;

  /// No description provided for @subtitleAutoRestoreNote.
  ///
  /// In en, this message translates to:
  /// **'Subtitle will auto-restore to default matching when switching audio'**
  String get subtitleAutoRestoreNote;

  /// No description provided for @confirmLoad.
  ///
  /// In en, this message translates to:
  /// **'Confirm Load'**
  String get confirmLoad;

  /// No description provided for @loadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Loading subtitle...'**
  String get loadingSubtitle;

  /// No description provided for @subtitleLoadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subtitle loaded: {title}'**
  String subtitleLoadSuccess(String title);

  /// No description provided for @subtitleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Subtitle load failed: {error}'**
  String subtitleLoadFailed(String error);

  /// No description provided for @cannotPreviewImageMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot preview image: missing required info'**
  String get cannotPreviewImageMissingInfo;

  /// No description provided for @cannotFindImageFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot find image file'**
  String get cannotFindImageFile;

  /// No description provided for @cannotPreviewTextMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot preview text: missing required info'**
  String get cannotPreviewTextMissingInfo;

  /// No description provided for @cannotPreviewPdfMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot preview PDF: missing required info'**
  String get cannotPreviewPdfMissingInfo;

  /// No description provided for @cannotPlayVideoMissingId.
  ///
  /// In en, this message translates to:
  /// **'Cannot play video: missing file ID'**
  String get cannotPlayVideoMissingId;

  /// No description provided for @cannotPlayVideoMissingParams.
  ///
  /// In en, this message translates to:
  /// **'Cannot play video: missing required parameters'**
  String get cannotPlayVideoMissingParams;

  /// No description provided for @cannotPlayDirectly.
  ///
  /// In en, this message translates to:
  /// **'Cannot play directly'**
  String get cannotPlayDirectly;

  /// No description provided for @noVideoPlayerFound.
  ///
  /// In en, this message translates to:
  /// **'No supported video player found on this device.'**
  String get noVideoPlayerFound;

  /// No description provided for @youCan.
  ///
  /// In en, this message translates to:
  /// **'You can:'**
  String get youCan;

  /// No description provided for @copyLinkToExternalPlayer.
  ///
  /// In en, this message translates to:
  /// **'1. Copy the link to an external player (e.g. MX Player, VLC)'**
  String get copyLinkToExternalPlayer;

  /// No description provided for @openInBrowserOption.
  ///
  /// In en, this message translates to:
  /// **'2. Open in browser'**
  String get openInBrowserOption;

  /// No description provided for @playVideoError.
  ///
  /// In en, this message translates to:
  /// **'Error playing video: {error}'**
  String playVideoError(String error);

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @resourceFiles.
  ///
  /// In en, this message translates to:
  /// **'Resource Files'**
  String get resourceFiles;

  /// No description provided for @resourceFilesTranslated.
  ///
  /// In en, this message translates to:
  /// **'Resource Files (translated {count} items)'**
  String resourceFilesTranslated(int count);

  /// No description provided for @translationOriginal.
  ///
  /// In en, this message translates to:
  /// **'Orig'**
  String get translationOriginal;

  /// No description provided for @translationTranslated.
  ///
  /// In en, this message translates to:
  /// **'Trans'**
  String get translationTranslated;

  /// No description provided for @copiedName.
  ///
  /// In en, this message translates to:
  /// **'Copied name: {title}'**
  String copiedName(String title);

  /// No description provided for @translationComplete.
  ///
  /// In en, this message translates to:
  /// **'Translation complete: {count} items'**
  String translationComplete(int count);

  /// No description provided for @noContentToTranslate.
  ///
  /// In en, this message translates to:
  /// **'No content to translate'**
  String get noContentToTranslate;

  /// No description provided for @preparingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Preparing translation...'**
  String get preparingTranslation;

  /// No description provided for @translatingProgress.
  ///
  /// In en, this message translates to:
  /// **'Translating {current}/{total}'**
  String translatingProgress(int current, int total);

  /// No description provided for @nItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String nItems(int count);

  /// No description provided for @loadAsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load as subtitle'**
  String get loadAsSubtitle;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @openVideoFileError.
  ///
  /// In en, this message translates to:
  /// **'Error opening video file: {error}'**
  String openVideoFileError(String error);

  /// No description provided for @cannotOpenVideoFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open video file: {message}'**
  String cannotOpenVideoFile(String message);

  /// No description provided for @noFileTreeInfo.
  ///
  /// In en, this message translates to:
  /// **'No file tree information'**
  String get noFileTreeInfo;

  /// No description provided for @workFolderNotExist.
  ///
  /// In en, this message translates to:
  /// **'Work folder does not exist'**
  String get workFolderNotExist;

  /// No description provided for @cannotPlayAudioMissingId.
  ///
  /// In en, this message translates to:
  /// **'Cannot play audio: missing file ID'**
  String get cannotPlayAudioMissingId;

  /// No description provided for @audioFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'Audio file does not exist'**
  String get audioFileNotExist;

  /// No description provided for @noPreviewableImages.
  ///
  /// In en, this message translates to:
  /// **'No previewable images found'**
  String get noPreviewableImages;

  /// No description provided for @cannotPreviewTextMissingId.
  ///
  /// In en, this message translates to:
  /// **'Cannot preview text: missing file ID'**
  String get cannotPreviewTextMissingId;

  /// No description provided for @cannotFindFilePath.
  ///
  /// In en, this message translates to:
  /// **'Cannot find file path'**
  String get cannotFindFilePath;

  /// No description provided for @fileNotExist.
  ///
  /// In en, this message translates to:
  /// **'File does not exist: {title}'**
  String fileNotExist(String title);

  /// No description provided for @cannotPreviewPdfMissingId.
  ///
  /// In en, this message translates to:
  /// **'Cannot preview PDF: missing file ID'**
  String get cannotPreviewPdfMissingId;

  /// No description provided for @videoFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'Video file does not exist'**
  String get videoFileNotExist;

  /// No description provided for @cannotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Cannot open video'**
  String get cannotOpenVideo;

  /// No description provided for @errorInfo.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorInfo(String message);

  /// No description provided for @installVideoPlayerApp.
  ///
  /// In en, this message translates to:
  /// **'Please install a video player app (e.g. VLC, MX Player)'**
  String get installVideoPlayerApp;

  /// No description provided for @filePathLabel.
  ///
  /// In en, this message translates to:
  /// **'File path:'**
  String get filePathLabel;

  /// No description provided for @noDownloadedFiles.
  ///
  /// In en, this message translates to:
  /// **'No downloaded files'**
  String get noDownloadedFiles;

  /// No description provided for @offlineFiles.
  ///
  /// In en, this message translates to:
  /// **'Offline Files'**
  String get offlineFiles;

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported: {title}'**
  String unsupportedFileType(String title);

  /// No description provided for @deleteFilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get deleteFilePrompt;

  /// No description provided for @deletedItem.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {title}'**
  String deletedItem(String title);

  /// No description provided for @selectAtLeastOneFile.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one file'**
  String get selectAtLeastOneFile;

  /// No description provided for @addedNFilesToDownloadQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} files to download queue'**
  String addedNFilesToDownloadQueue(int count);

  /// No description provided for @downloadedAndSelected.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {downloaded} · Selected {selected}'**
  String downloadedAndSelected(int downloaded, int selected);

  /// No description provided for @downloadN.
  ///
  /// In en, this message translates to:
  /// **'Download ({count})'**
  String downloadN(int count);

  /// No description provided for @checkingDownloadedFiles.
  ///
  /// In en, this message translates to:
  /// **'Checking downloaded files...'**
  String get checkingDownloadedFiles;

  /// No description provided for @noDownloadableFiles.
  ///
  /// In en, this message translates to:
  /// **'No downloadable files'**
  String get noDownloadableFiles;

  /// No description provided for @selectFilesToDownload.
  ///
  /// In en, this message translates to:
  /// **'Select Files to Download'**
  String get selectFilesToDownload;

  /// No description provided for @downloadedNCount.
  ///
  /// In en, this message translates to:
  /// **'{count} downloaded'**
  String downloadedNCount(int count);

  /// No description provided for @selectedNCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedNCount(int count);

  /// No description provided for @pleaseEnterServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter server address'**
  String get pleaseEnterServerAddress;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get pleaseEnterUsername;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @notTestedYet.
  ///
  /// In en, this message translates to:
  /// **'Not tested yet'**
  String get notTestedYet;

  /// No description provided for @latencyResultDetail.
  ///
  /// In en, this message translates to:
  /// **'Latency {latency} ({status})'**
  String latencyResultDetail(String latency, String status);

  /// No description provided for @connectionFailedWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailedWithDetail(String error);

  /// No description provided for @noAccountTapToRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Tap to register'**
  String get noAccountTapToRegister;

  /// No description provided for @haveAccountTapToLogin.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Tap to login'**
  String get haveAccountTapToLogin;

  /// No description provided for @cannotDeleteActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the currently active account'**
  String get cannotDeleteActiveAccount;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @noSavedAccounts.
  ///
  /// In en, this message translates to:
  /// **'No saved accounts'**
  String get noSavedAccounts;

  /// No description provided for @addAccountToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add an account to get started'**
  String get addAccountToGetStarted;

  /// No description provided for @unknownHost.
  ///
  /// In en, this message translates to:
  /// **'Unknown host'**
  String get unknownHost;

  /// No description provided for @lastUsedTime.
  ///
  /// In en, this message translates to:
  /// **'Last used: {time}'**
  String lastUsedTime(String time);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @deleteSelectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected items?'**
  String deleteSelectedConfirm(int count);

  /// No description provided for @deletedNOfTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Deleted {success}/{total} items'**
  String deletedNOfTotalItems(int success, int total);

  /// No description provided for @importingSubtitleFile.
  ///
  /// In en, this message translates to:
  /// **'Importing subtitle file...'**
  String get importingSubtitleFile;

  /// No description provided for @preparingImport.
  ///
  /// In en, this message translates to:
  /// **'Preparing import...'**
  String get preparingImport;

  /// No description provided for @preparingExtract.
  ///
  /// In en, this message translates to:
  /// **'Preparing to extract...'**
  String get preparingExtract;

  /// No description provided for @importSubtitleFile.
  ///
  /// In en, this message translates to:
  /// **'Import Subtitle File'**
  String get importSubtitleFile;

  /// No description provided for @supportedSubtitleFormats.
  ///
  /// In en, this message translates to:
  /// **'Supports .srt, .vtt, .lrc and other subtitle formats'**
  String get supportedSubtitleFormats;

  /// No description provided for @importFolder.
  ///
  /// In en, this message translates to:
  /// **'Import Folder'**
  String get importFolder;

  /// No description provided for @importFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Preserves folder structure, imports only subtitle files'**
  String get importFolderDesc;

  /// No description provided for @importArchive.
  ///
  /// In en, this message translates to:
  /// **'Import Archive'**
  String get importArchive;

  /// No description provided for @importArchiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Supports password-free ZIP archives.\nFor batch import, compress them into one archive.'**
  String get importArchiveDesc;

  /// No description provided for @subtitleLibraryGuide.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Library Usage Guide'**
  String get subtitleLibraryGuide;

  /// No description provided for @subtitleLibraryFunction.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Library Function'**
  String get subtitleLibraryFunction;

  /// No description provided for @subtitleLibraryFunctionDesc.
  ///
  /// In en, this message translates to:
  /// **'Stores imported/saved subtitle files, supports auto/manual loading during playback'**
  String get subtitleLibraryFunctionDesc;

  /// No description provided for @subtitleAutoLoad.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Auto-load'**
  String get subtitleAutoLoad;

  /// No description provided for @subtitleAutoLoadDesc.
  ///
  /// In en, this message translates to:
  /// **'When playing audio, the system automatically searches for matching subtitles:'**
  String get subtitleAutoLoadDesc;

  /// No description provided for @smartCategoryAndMark.
  ///
  /// In en, this message translates to:
  /// **'Smart Categorization & Marking'**
  String get smartCategoryAndMark;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rename successful'**
  String get renameSuccess;

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get renameFailed;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteItemConfirm(String title);

  /// No description provided for @deleteFolderContentsWarning.
  ///
  /// In en, this message translates to:
  /// **'This will delete all contents in the folder.'**
  String get deleteFolderContentsWarning;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @subtitleLoaded.
  ///
  /// In en, this message translates to:
  /// **'Subtitle loaded: {title}'**
  String subtitleLoaded(String title);

  /// No description provided for @moveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Move successful'**
  String get moveSuccess;

  /// No description provided for @moveFailed.
  ///
  /// In en, this message translates to:
  /// **'Move failed'**
  String get moveFailed;

  /// No description provided for @previewFailed.
  ///
  /// In en, this message translates to:
  /// **'Preview failed: {error}'**
  String previewFailed(String error);

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Open failed: {error}'**
  String openFailed(String error);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @subtitleLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Subtitle library is empty'**
  String get subtitleLibraryEmpty;

  /// No description provided for @tapToImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to import subtitles'**
  String get tapToImportSubtitle;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import Subtitle'**
  String get importSubtitle;

  /// No description provided for @sampleSubtitleContent.
  ///
  /// In en, this message translates to:
  /// **'♪ Sample subtitle content ♪'**
  String get sampleSubtitleContent;

  /// No description provided for @presetStyles.
  ///
  /// In en, this message translates to:
  /// **'Preset Styles'**
  String get presetStyles;

  /// No description provided for @backgroundOpacity.
  ///
  /// In en, this message translates to:
  /// **'Background Opacity'**
  String get backgroundOpacity;

  /// No description provided for @colorSettings.
  ///
  /// In en, this message translates to:
  /// **'Color Settings'**
  String get colorSettings;

  /// No description provided for @shapeSettings.
  ///
  /// In en, this message translates to:
  /// **'Shape Settings'**
  String get shapeSettings;

  /// No description provided for @cornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get cornerRadius;

  /// No description provided for @horizontalPadding.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Padding'**
  String get horizontalPadding;

  /// No description provided for @verticalPadding.
  ///
  /// In en, this message translates to:
  /// **'Vertical Padding'**
  String get verticalPadding;

  /// No description provided for @resetStyle.
  ///
  /// In en, this message translates to:
  /// **'Reset Style'**
  String get resetStyle;

  /// No description provided for @resetStyleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore the default style?'**
  String get resetStyleConfirm;

  /// No description provided for @restoreDefaultStyle.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Style'**
  String get restoreDefaultStyle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @noBlockedItemsOfType.
  ///
  /// In en, this message translates to:
  /// **'No blocked {type}'**
  String noBlockedItemsOfType(String type);

  /// No description provided for @unblockedItem.
  ///
  /// In en, this message translates to:
  /// **'Unblocked: {item}'**
  String unblockedItem(String item);

  /// No description provided for @addBlockedItem.
  ///
  /// In en, this message translates to:
  /// **'Add Blocked {type}'**
  String addBlockedItem(String type);

  /// No description provided for @blockedItemName.
  ///
  /// In en, this message translates to:
  /// **'{type} name'**
  String blockedItemName(String type);

  /// No description provided for @enterBlockedItemHint.
  ///
  /// In en, this message translates to:
  /// **'Enter {type} to block'**
  String enterBlockedItemHint(String type);

  /// No description provided for @blockedItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Blocked: {item}'**
  String blockedItemAdded(String item);

  /// No description provided for @workCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Works: {count}'**
  String workCountLabel(int count);

  /// No description provided for @miniPlayer.
  ///
  /// In en, this message translates to:
  /// **'Mini Player'**
  String get miniPlayer;

  /// No description provided for @lineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get lineHeight;

  /// No description provided for @portraitPlayerBelowCover.
  ///
  /// In en, this message translates to:
  /// **'Portrait Player (Below Cover)'**
  String get portraitPlayerBelowCover;

  /// No description provided for @fullscreenSubtitleMode.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Subtitle (Portrait/Landscape)'**
  String get fullscreenSubtitleMode;

  /// No description provided for @activeSubtitleFontSize.
  ///
  /// In en, this message translates to:
  /// **'Active subtitle size'**
  String get activeSubtitleFontSize;

  /// No description provided for @inactiveSubtitleFontSize.
  ///
  /// In en, this message translates to:
  /// **'Inactive subtitle size'**
  String get inactiveSubtitleFontSize;

  /// No description provided for @restoreDefaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Settings'**
  String get restoreDefaultSettings;

  /// No description provided for @confirmRestoreDefaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore the default settings?'**
  String get confirmRestoreDefaultSettings;

  /// No description provided for @guideInPrefix.
  ///
  /// In en, this message translates to:
  /// **'In '**
  String get guideInPrefix;

  /// No description provided for @guideParsedFolder.
  ///
  /// In en, this message translates to:
  /// **'<Parsed>'**
  String get guideParsedFolder;

  /// No description provided for @guideFindWorkDesc.
  ///
  /// In en, this message translates to:
  /// **' folder, find matching works\nSupported folder format: RJ123456'**
  String get guideFindWorkDesc;

  /// No description provided for @guideSavedFolder.
  ///
  /// In en, this message translates to:
  /// **'<Saved>'**
  String get guideSavedFolder;

  /// No description provided for @guideFindSubtitleDesc.
  ///
  /// In en, this message translates to:
  /// **' folder, find individual subtitle files'**
  String get guideFindSubtitleDesc;

  /// No description provided for @guideMatchRule.
  ///
  /// In en, this message translates to:
  /// **'Matching rule: subtitle filename matches audio filename (with or without audio extension)'**
  String get guideMatchRule;

  /// No description provided for @guideRecognizedWorkPrefix.
  ///
  /// In en, this message translates to:
  /// **'Recognized works get a green '**
  String get guideRecognizedWorkPrefix;

  /// No description provided for @guideTagSuffix.
  ///
  /// In en, this message translates to:
  /// **' tag, and audio file icons get a '**
  String get guideTagSuffix;

  /// No description provided for @guideSubtitleMatchSuffix.
  ///
  /// In en, this message translates to:
  /// **' mark, indicating subtitle library match'**
  String get guideSubtitleMatchSuffix;

  /// No description provided for @guideAutoRecognizeRJ.
  ///
  /// In en, this message translates to:
  /// **'Auto-recognize RJ format on import, categorize to <Parsed>'**
  String get guideAutoRecognizeRJ;

  /// No description provided for @guideAutoAddRJPrefix.
  ///
  /// In en, this message translates to:
  /// **'Pure numeric folders auto-add RJ prefix (e.g. 123456 → RJ123456)'**
  String get guideAutoAddRJPrefix;

  /// No description provided for @unknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown file'**
  String get unknownFile;

  /// No description provided for @deleteWithCount.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String deleteWithCount(int count);

  /// No description provided for @searchSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Search subtitles...'**
  String get searchSubtitles;

  /// No description provided for @nFilesWithSize.
  ///
  /// In en, this message translates to:
  /// **'{count} files • {size}'**
  String nFilesWithSize(int count, String size);

  /// No description provided for @rootDirectory.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get rootDirectory;

  /// No description provided for @goToParent.
  ///
  /// In en, this message translates to:
  /// **'Go to parent'**
  String get goToParent;

  /// No description provided for @moveToTarget.
  ///
  /// In en, this message translates to:
  /// **'Move to: {name}'**
  String moveToTarget(String name);

  /// No description provided for @noSubfoldersHere.
  ///
  /// In en, this message translates to:
  /// **'No subfolders in this directory'**
  String get noSubfoldersHere;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to playlist \"{name}\"'**
  String addedToPlaylist(String name);

  /// No description provided for @removedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from playlist \"{name}\"'**
  String removedFromPlaylist(String name);

  /// No description provided for @alreadyFavorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get alreadyFavorited;

  /// No description provided for @loadImageFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image\n{error}'**
  String loadImageFailedWithError(String error);

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No image available'**
  String get noImageAvailable;

  /// No description provided for @storagePermissionRequiredForImage.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required to save images'**
  String get storagePermissionRequiredForImage;

  /// No description provided for @savedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get savedToGallery;

  /// No description provided for @saveCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Save Cover Image'**
  String get saveCoverImage;

  /// No description provided for @savedToPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String savedToPath(String path);

  /// No description provided for @doubleTapToZoom.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to zoom · Pinch to scale'**
  String get doubleTapToZoom;

  /// No description provided for @getStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get status: {error}'**
  String getStatusFailed(String error);

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deletePlayRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the play record for \"{title}\"?'**
  String deletePlayRecordConfirm(String title);

  /// No description provided for @notPlayedYet.
  ///
  /// In en, this message translates to:
  /// **'Not played yet'**
  String get notPlayedYet;

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed: {error}'**
  String playbackFailed(String error);

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get storagePermissionRequired;

  /// No description provided for @storagePermissionForGalleryDesc.
  ///
  /// In en, this message translates to:
  /// **'Permission to access the photo gallery is required to save images. Please grant permission in settings.'**
  String get storagePermissionForGalleryDesc;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @imageSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery'**
  String get imageSavedToGallery;

  /// No description provided for @imageSavedToPath.
  ///
  /// In en, this message translates to:
  /// **'Image saved to: {path}'**
  String imageSavedToPath(String path);

  /// No description provided for @pullDownForNextPage.
  ///
  /// In en, this message translates to:
  /// **'Pull down to go to next page'**
  String get pullDownForNextPage;

  /// No description provided for @releaseForNextPage.
  ///
  /// In en, this message translates to:
  /// **'Release to go to next page'**
  String get releaseForNextPage;

  /// No description provided for @jumpTo.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get jumpTo;

  /// No description provided for @goToPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to Page'**
  String get goToPageTitle;

  /// No description provided for @pageNumberRange.
  ///
  /// In en, this message translates to:
  /// **'Page (1-{max})'**
  String pageNumberRange(int max);

  /// No description provided for @enterPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter page number'**
  String get enterPageNumber;

  /// No description provided for @enterValidPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid page number (1-{max})'**
  String enterValidPageNumber(int max);

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextPage;

  /// No description provided for @localPdfNotExist.
  ///
  /// In en, this message translates to:
  /// **'Local PDF file does not exist'**
  String get localPdfNotExist;

  /// No description provided for @cannotOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Cannot open PDF file'**
  String get cannotOpenPdf;

  /// No description provided for @loadPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF: {error}'**
  String loadPdfFailed(String error);

  /// No description provided for @pdfPageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pdfPageOfTotal(int current, int total);

  /// No description provided for @loadingPdf.
  ///
  /// In en, this message translates to:
  /// **'Loading PDF...'**
  String get loadingPdf;

  /// No description provided for @pdfPathInvalid.
  ///
  /// In en, this message translates to:
  /// **'PDF file path is invalid'**
  String get pdfPathInvalid;

  /// No description provided for @desktopPdfPreviewNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Desktop PDF preview is not yet supported'**
  String get desktopPdfPreviewNotSupported;

  /// No description provided for @openWithSystemApp.
  ///
  /// In en, this message translates to:
  /// **'Open with system default app'**
  String get openWithSystemApp;

  /// No description provided for @renderPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF rendering failed: {error}'**
  String renderPdfFailed(String error);

  /// No description provided for @ratingDetails.
  ///
  /// In en, this message translates to:
  /// **'Rating Details'**
  String get ratingDetails;

  /// No description provided for @selectSaveDirectory.
  ///
  /// In en, this message translates to:
  /// **'Select Save Directory'**
  String get selectSaveDirectory;

  /// No description provided for @noSubtitleContentToSave.
  ///
  /// In en, this message translates to:
  /// **'No subtitle content to save'**
  String get noSubtitleContentToSave;

  /// No description provided for @savedToSubtitleLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to subtitle library'**
  String get savedToSubtitleLibrary;

  /// No description provided for @saveToLocal.
  ///
  /// In en, this message translates to:
  /// **'Save to Local'**
  String get saveToLocal;

  /// No description provided for @selectDirectoryToSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Select directory to save file'**
  String get selectDirectoryToSaveFile;

  /// No description provided for @saveToSubtitleLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to Subtitle Library'**
  String get saveToSubtitleLibrary;

  /// No description provided for @saveToSubtitleLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Save to the \"Saved\" folder in subtitle library'**
  String get saveToSubtitleLibraryDesc;

  /// No description provided for @saveToFile.
  ///
  /// In en, this message translates to:
  /// **'Save to file'**
  String get saveToFile;

  /// No description provided for @noContentToSave.
  ///
  /// In en, this message translates to:
  /// **'No content to save'**
  String get noContentToSave;

  /// No description provided for @fileSavedToPath.
  ///
  /// In en, this message translates to:
  /// **'File saved to: {path}'**
  String fileSavedToPath(String path);

  /// No description provided for @localFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'Local file does not exist, please try reloading'**
  String get localFileNotExist;

  /// No description provided for @loadTextFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load text: {error}'**
  String loadTextFailed(String error);

  /// No description provided for @previewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview Mode'**
  String get previewMode;

  /// No description provided for @editMode.
  ///
  /// In en, this message translates to:
  /// **'Edit Mode'**
  String get editMode;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show Original'**
  String get showOriginal;

  /// No description provided for @translateContent.
  ///
  /// In en, this message translates to:
  /// **'Translate Content'**
  String get translateContent;

  /// No description provided for @editTextContentHint.
  ///
  /// In en, this message translates to:
  /// **'Edit text content...'**
  String get editTextContentHint;

  /// No description provided for @markButton.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get markButton;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @setProgressAndRating.
  ///
  /// In en, this message translates to:
  /// **'Set to: {progress}, rating: {rating} stars'**
  String setProgressAndRating(String progress, int rating);

  /// No description provided for @setProgressTo.
  ///
  /// In en, this message translates to:
  /// **'Set to: {progress}'**
  String setProgressTo(String progress);

  /// No description provided for @ratingSetTo.
  ///
  /// In en, this message translates to:
  /// **'Rating set to: {rating} stars'**
  String ratingSetTo(int rating);

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @addTagFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add tag: {error}'**
  String addTagFailed(String error);

  /// No description provided for @addWithCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String addWithCount(int count);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @nStars.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String nStars(int count);

  /// No description provided for @voteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Vote removed'**
  String get voteRemoved;

  /// No description provided for @votedUp.
  ///
  /// In en, this message translates to:
  /// **'Voted up'**
  String get votedUp;

  /// No description provided for @votedDown.
  ///
  /// In en, this message translates to:
  /// **'Voted down'**
  String get votedDown;

  /// No description provided for @voteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Vote failed: {error}'**
  String voteFailedWithError(String error);

  /// No description provided for @voteFor.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get voteFor;

  /// No description provided for @voteAgainst.
  ///
  /// In en, this message translates to:
  /// **'Against'**
  String get voteAgainst;

  /// No description provided for @voted.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get voted;

  /// No description provided for @tagBlockedWithName.
  ///
  /// In en, this message translates to:
  /// **'Tag blocked: {name}'**
  String tagBlockedWithName(String name);

  /// No description provided for @subtitleParseFailedUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Parse failed, unsupported format'**
  String get subtitleParseFailedUnsupportedFormat;

  /// No description provided for @lyricPresetDynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get lyricPresetDynamic;

  /// No description provided for @lyricPresetClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get lyricPresetClassic;

  /// No description provided for @lyricPresetModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get lyricPresetModern;

  /// No description provided for @lyricPresetMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get lyricPresetMinimal;

  /// No description provided for @lyricPresetVibrant.
  ///
  /// In en, this message translates to:
  /// **'Vibrant'**
  String get lyricPresetVibrant;

  /// No description provided for @lyricPresetElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get lyricPresetElegant;

  /// No description provided for @lyricPresetDynamicDesc.
  ///
  /// In en, this message translates to:
  /// **'Follows system theme, auto color'**
  String get lyricPresetDynamicDesc;

  /// No description provided for @lyricPresetClassicDesc.
  ///
  /// In en, this message translates to:
  /// **'Black background, white text, classic'**
  String get lyricPresetClassicDesc;

  /// No description provided for @lyricPresetModernDesc.
  ///
  /// In en, this message translates to:
  /// **'Gradient background, stylish modern'**
  String get lyricPresetModernDesc;

  /// No description provided for @lyricPresetMinimalDesc.
  ///
  /// In en, this message translates to:
  /// **'Light transparent, simple and elegant'**
  String get lyricPresetMinimalDesc;

  /// No description provided for @lyricPresetVibrantDesc.
  ///
  /// In en, this message translates to:
  /// **'Vivid colors, full of energy'**
  String get lyricPresetVibrantDesc;

  /// No description provided for @lyricPresetElegantDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep blue, refined elegance'**
  String get lyricPresetElegantDesc;

  /// No description provided for @floatingLyricLoading.
  ///
  /// In en, this message translates to:
  /// **'♪ Loading subtitle ♪'**
  String get floatingLyricLoading;

  /// No description provided for @subtitleFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get subtitleFileNotExist;

  /// No description provided for @subtitleMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'Missing required info'**
  String get subtitleMissingInfo;

  /// No description provided for @privacyDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Playing Audio'**
  String get privacyDefaultTitle;

  /// No description provided for @offlineModeStartup.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed, starting in offline mode'**
  String get offlineModeStartup;

  /// No description provided for @playlistInfoNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Playlist info not loaded'**
  String get playlistInfoNotLoaded;

  /// No description provided for @encodingUnrecognized.
  ///
  /// In en, this message translates to:
  /// **'File encoding unrecognized, cannot display content correctly'**
  String get encodingUnrecognized;

  /// No description provided for @editPlaylistFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit playlist: {error}'**
  String editPlaylistFailed(String error);

  /// No description provided for @unsupportedFileTypeWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this file type: {title}'**
  String unsupportedFileTypeWithTitle(String title);

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @restoredToDefault.
  ///
  /// In en, this message translates to:
  /// **'Restored to default settings'**
  String get restoredToDefault;

  /// No description provided for @restoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore Default'**
  String get restoreDefault;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @addAtLeastOneSearchCondition.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one search condition'**
  String get addAtLeastOneSearchCondition;

  /// No description provided for @privacyModeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode Settings'**
  String get privacyModeSettingsTitle;

  /// No description provided for @whatIsPrivacyMode.
  ///
  /// In en, this message translates to:
  /// **'What is Privacy Mode?'**
  String get whatIsPrivacyMode;

  /// No description provided for @privacyModeDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, playback information displayed in system notifications, lock screen, etc. will be blurred to protect your privacy.'**
  String get privacyModeDescription;

  /// No description provided for @enablePrivacyMode.
  ///
  /// In en, this message translates to:
  /// **'Enable Privacy Mode'**
  String get enablePrivacyMode;

  /// No description provided for @privacyModeEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled - Playback info will be hidden'**
  String get privacyModeEnabledSubtitle;

  /// No description provided for @privacyModeDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disabled - Playback info displayed normally'**
  String get privacyModeDisabledSubtitle;

  /// No description provided for @blurOptions.
  ///
  /// In en, this message translates to:
  /// **'Blur Options'**
  String get blurOptions;

  /// No description provided for @blurNotificationCover.
  ///
  /// In en, this message translates to:
  /// **'Blur Notification Cover'**
  String get blurNotificationCover;

  /// No description provided for @blurNotificationCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply blur to cover art in system notifications, lock screen, or control center'**
  String get blurNotificationCoverSubtitle;

  /// No description provided for @blurInAppCover.
  ///
  /// In en, this message translates to:
  /// **'Blur In-App Cover'**
  String get blurInAppCover;

  /// No description provided for @blurInAppCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blur cover art in player, lists, and other screens'**
  String get blurInAppCoverSubtitle;

  /// No description provided for @replaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace Title'**
  String get replaceTitle;

  /// No description provided for @replaceTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace real title with a custom title'**
  String get replaceTitleSubtitle;

  /// No description provided for @replaceTitleContent.
  ///
  /// In en, this message translates to:
  /// **'Replacement Title Content'**
  String get replaceTitleContent;

  /// No description provided for @setReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Replacement Title'**
  String get setReplaceTitle;

  /// No description provided for @enterDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the title to display'**
  String get enterDisplayTitle;

  /// No description provided for @replaceTitleSaved.
  ///
  /// In en, this message translates to:
  /// **'Replacement title saved'**
  String get replaceTitleSaved;

  /// No description provided for @effectExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get effectExample;

  /// No description provided for @downloadPathSettings.
  ///
  /// In en, this message translates to:
  /// **'Download Path Settings'**
  String get downloadPathSettings;

  /// No description provided for @loadPathFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load path: {error}'**
  String loadPathFailedWithError(String error);

  /// No description provided for @platformNotSupportCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Custom download path is not supported on this platform'**
  String get platformNotSupportCustomPath;

  /// No description provided for @activeDownloadsWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} download tasks are in progress. Please cancel or complete them before switching paths'**
  String activeDownloadsWarning(int count);

  /// No description provided for @setPathFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to set path: {error}'**
  String setPathFailedWithError(String error);

  /// No description provided for @confirmMigrateFiles.
  ///
  /// In en, this message translates to:
  /// **'Confirm File Migration'**
  String get confirmMigrateFiles;

  /// No description provided for @migrateFilesToNewDir.
  ///
  /// In en, this message translates to:
  /// **'Existing downloaded files will be migrated to the new directory:'**
  String get migrateFilesToNewDir;

  /// No description provided for @migrationMayTakeTime.
  ///
  /// In en, this message translates to:
  /// **'This operation may take some time depending on the number and size of files.'**
  String get migrationMayTakeTime;

  /// No description provided for @confirmMigrate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Migration'**
  String get confirmMigrate;

  /// No description provided for @restoreDefaultPath.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Path'**
  String get restoreDefaultPath;

  /// No description provided for @restoreDefaultPathConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore download path to default location and migrate all files.\n\nContinue?'**
  String get restoreDefaultPathConfirm;

  /// No description provided for @defaultPathRestored.
  ///
  /// In en, this message translates to:
  /// **'Default path restored'**
  String get defaultPathRestored;

  /// No description provided for @resetPathFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore default path: {error}'**
  String resetPathFailedWithError(String error);

  /// No description provided for @migratingFiles.
  ///
  /// In en, this message translates to:
  /// **'Migrating files...'**
  String get migratingFiles;

  /// No description provided for @doNotCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Please do not close the app'**
  String get doNotCloseApp;

  /// No description provided for @currentDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'Current Download Path'**
  String get currentDownloadPath;

  /// No description provided for @customPath.
  ///
  /// In en, this message translates to:
  /// **'Custom Path'**
  String get customPath;

  /// No description provided for @defaultPath.
  ///
  /// In en, this message translates to:
  /// **'Default Path'**
  String get defaultPath;

  /// No description provided for @changeCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Change Custom Path'**
  String get changeCustomPath;

  /// No description provided for @setCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Path'**
  String get setCustomPath;

  /// No description provided for @usageInstructions.
  ///
  /// In en, this message translates to:
  /// **'Usage Instructions'**
  String get usageInstructions;

  /// No description provided for @downloadPathUsageDesc.
  ///
  /// In en, this message translates to:
  /// **'• After customizing the path, all existing files will be automatically migrated\n• Do not close the app during migration\n• Choose a directory with sufficient storage space\n• When restoring the default path, files will be migrated back automatically'**
  String get downloadPathUsageDesc;

  /// No description provided for @llmTranslationSettings.
  ///
  /// In en, this message translates to:
  /// **'LLM Translation Settings'**
  String get llmTranslationSettings;

  /// No description provided for @apiEndpointUrl.
  ///
  /// In en, this message translates to:
  /// **'API Endpoint URL'**
  String get apiEndpointUrl;

  /// No description provided for @openaiCompatibleEndpoint.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible endpoint URL'**
  String get openaiCompatibleEndpoint;

  /// No description provided for @pleaseEnterApiUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter API endpoint URL'**
  String get pleaseEnterApiUrl;

  /// No description provided for @pleaseEnterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get pleaseEnterValidUrl;

  /// No description provided for @pleaseEnterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter API Key'**
  String get pleaseEnterApiKey;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// No description provided for @pleaseEnterModelName.
  ///
  /// In en, this message translates to:
  /// **'Please enter model name'**
  String get pleaseEnterModelName;

  /// No description provided for @concurrencyCount.
  ///
  /// In en, this message translates to:
  /// **'Concurrency'**
  String get concurrencyCount;

  /// No description provided for @concurrencyDescription.
  ///
  /// In en, this message translates to:
  /// **'Number of concurrent translation requests, recommended 3-5'**
  String get concurrencyDescription;

  /// No description provided for @promptSection.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get promptSection;

  /// No description provided for @promptDescription.
  ///
  /// In en, this message translates to:
  /// **'Since the system uses chunked translation, please ensure the prompt clearly instructs to output only translation results without any explanation.'**
  String get promptDescription;

  /// No description provided for @enterSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter system prompt...'**
  String get enterSystemPrompt;

  /// No description provided for @pleaseEnterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a prompt'**
  String get pleaseEnterPrompt;

  /// No description provided for @restoreDefaultPrompt.
  ///
  /// In en, this message translates to:
  /// **'Restore Default Prompt'**
  String get restoreDefaultPrompt;

  /// No description provided for @confirmRestoreButtonOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore the default button order?'**
  String get confirmRestoreButtonOrder;

  /// No description provided for @buttonDisplayRules.
  ///
  /// In en, this message translates to:
  /// **'Button Display Rules'**
  String get buttonDisplayRules;

  /// No description provided for @buttonDisplayRulesDesc.
  ///
  /// In en, this message translates to:
  /// **'• The first {maxVisible} buttons will be shown at the bottom of the player\n• The remaining buttons will be in the \"More\" menu'**
  String buttonDisplayRulesDesc(int maxVisible);

  /// No description provided for @shownInPlayer.
  ///
  /// In en, this message translates to:
  /// **'Shown in player'**
  String get shownInPlayer;

  /// No description provided for @shownInMoreMenu.
  ///
  /// In en, this message translates to:
  /// **'Shown in More menu'**
  String get shownInMoreMenu;

  /// No description provided for @audioFormatPriority.
  ///
  /// In en, this message translates to:
  /// **'Audio Format Priority'**
  String get audioFormatPriority;

  /// No description provided for @confirmRestoreAudioFormat.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore the default audio format priority?'**
  String get confirmRestoreAudioFormat;

  /// No description provided for @priorityDescription.
  ///
  /// In en, this message translates to:
  /// **'Priority Description'**
  String get priorityDescription;

  /// No description provided for @audioFormatPriorityDesc.
  ///
  /// In en, this message translates to:
  /// **'• When opening a work\'s detail page, the folder with the highest priority audio format will be expanded first'**
  String get audioFormatPriorityDesc;

  /// No description provided for @ratingInfo.
  ///
  /// In en, this message translates to:
  /// **'Rating Info'**
  String get ratingInfo;

  /// No description provided for @showRatingAndReviewCount.
  ///
  /// In en, this message translates to:
  /// **'Show work rating and review count'**
  String get showRatingAndReviewCount;

  /// No description provided for @priceInfo.
  ///
  /// In en, this message translates to:
  /// **'Price Info'**
  String get priceInfo;

  /// No description provided for @showWorkPrice.
  ///
  /// In en, this message translates to:
  /// **'Show work price'**
  String get showWorkPrice;

  /// No description provided for @durationInfo.
  ///
  /// In en, this message translates to:
  /// **'Duration Info'**
  String get durationInfo;

  /// No description provided for @showWorkDuration.
  ///
  /// In en, this message translates to:
  /// **'Show work duration'**
  String get showWorkDuration;

  /// No description provided for @showWorkTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Show total work duration'**
  String get showWorkTotalDuration;

  /// No description provided for @salesInfo.
  ///
  /// In en, this message translates to:
  /// **'Sales Info'**
  String get salesInfo;

  /// No description provided for @showWorkSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Show work sales count'**
  String get showWorkSalesCount;

  /// No description provided for @externalLinkInfo.
  ///
  /// In en, this message translates to:
  /// **'External Links'**
  String get externalLinkInfo;

  /// No description provided for @showExternalLinks.
  ///
  /// In en, this message translates to:
  /// **'Show external links such as DLsite, official website, etc.'**
  String get showExternalLinks;

  /// No description provided for @releaseDateInfo.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDateInfo;

  /// No description provided for @showWorkReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Show work release date'**
  String get showWorkReleaseDate;

  /// No description provided for @translateButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Translate Button'**
  String get translateButtonLabel;

  /// No description provided for @showTranslateButton.
  ///
  /// In en, this message translates to:
  /// **'Show translate button for work title'**
  String get showTranslateButton;

  /// No description provided for @subtitleTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitle Tag'**
  String get subtitleTagLabel;

  /// No description provided for @showSubtitleTagOnCover.
  ///
  /// In en, this message translates to:
  /// **'Show subtitle tag on cover image'**
  String get showSubtitleTagOnCover;

  /// No description provided for @recommendationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Related Recommendations'**
  String get recommendationsLabel;

  /// No description provided for @showRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Show related recommendations on work detail page'**
  String get showRecommendations;

  /// No description provided for @circleInfo.
  ///
  /// In en, this message translates to:
  /// **'Circle Info'**
  String get circleInfo;

  /// No description provided for @showWorkCircle.
  ///
  /// In en, this message translates to:
  /// **'Show work\'s circle'**
  String get showWorkCircle;

  /// No description provided for @workCardSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust grid density to make covers larger or keep the current size'**
  String get workCardSizeSubtitle;

  /// No description provided for @workCardFontSize.
  ///
  /// In en, this message translates to:
  /// **'Card Text Size'**
  String get workCardFontSize;

  /// No description provided for @workCardFontSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust title and metadata text on work cards'**
  String get workCardFontSizeSubtitle;

  /// No description provided for @cardSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get cardSizeNormal;

  /// No description provided for @cardSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get cardSizeLarge;

  /// No description provided for @cardSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get cardSizeExtraLarge;

  /// No description provided for @fontSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontSizeNormal;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get fontSizeExtraLarge;

  /// No description provided for @showSubtitleTagOnCard.
  ///
  /// In en, this message translates to:
  /// **'Show subtitle tag on work card'**
  String get showSubtitleTagOnCard;

  /// No description provided for @showOnlineMarks.
  ///
  /// In en, this message translates to:
  /// **'Show online marked works'**
  String get showOnlineMarks;

  /// No description provided for @cannotBeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Cannot be disabled'**
  String get cannotBeDisabled;

  /// No description provided for @showPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Show created playlists'**
  String get showPlaylists;

  /// No description provided for @showSubtitleLibrary.
  ///
  /// In en, this message translates to:
  /// **'Show subtitle library management'**
  String get showSubtitleLibrary;

  /// No description provided for @playlistPrivacyPrivateDesc.
  ///
  /// In en, this message translates to:
  /// **'Only you can view'**
  String get playlistPrivacyPrivateDesc;

  /// No description provided for @playlistPrivacyUnlistedDesc.
  ///
  /// In en, this message translates to:
  /// **'Only people with the link can view'**
  String get playlistPrivacyUnlistedDesc;

  /// No description provided for @playlistPrivacyPublicDesc.
  ///
  /// In en, this message translates to:
  /// **'Anyone can view'**
  String get playlistPrivacyPublicDesc;

  /// No description provided for @clearTranslationCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Translation Cache'**
  String get clearTranslationCache;

  /// No description provided for @translationCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Translation cache cleared'**
  String get translationCacheCleared;

  /// No description provided for @platformHintAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android: System file picker will be used, storage permission may be required'**
  String get platformHintAndroid;

  /// No description provided for @platformHintIOS.
  ///
  /// In en, this message translates to:
  /// **'iOS: Due to system restrictions, the default path is used. Files can be accessed via the system file manager'**
  String get platformHintIOS;

  /// No description provided for @platformHintWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows: Any accessible directory can be selected'**
  String get platformHintWindows;

  /// No description provided for @platformHintMacOS.
  ///
  /// In en, this message translates to:
  /// **'macOS: Any accessible directory can be selected'**
  String get platformHintMacOS;

  /// No description provided for @platformHintLinux.
  ///
  /// In en, this message translates to:
  /// **'Linux: Any accessible directory can be selected'**
  String get platformHintLinux;

  /// No description provided for @platformHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Select a directory to save downloaded files'**
  String get platformHintDefault;

  /// No description provided for @subtitleFolderParsed.
  ///
  /// In en, this message translates to:
  /// **'Parsed'**
  String get subtitleFolderParsed;

  /// No description provided for @subtitleFolderSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get subtitleFolderSaved;

  /// No description provided for @subtitleFolderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Works'**
  String get subtitleFolderUnknown;

  /// No description provided for @sortDownloadDate.
  ///
  /// In en, this message translates to:
  /// **'Download Date'**
  String get sortDownloadDate;

  /// No description provided for @sortWorkId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get sortWorkId;

  /// No description provided for @searchDownloads.
  ///
  /// In en, this message translates to:
  /// **'Search downloaded works...'**
  String get searchDownloads;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'App Logs'**
  String get logTitle;

  /// No description provided for @logSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and export app logs'**
  String get logSubtitle;

  /// No description provided for @logSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get logSearchHint;

  /// No description provided for @logFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logFilterAll;

  /// No description provided for @logCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy Logs'**
  String get logCopy;

  /// No description provided for @logExport.
  ///
  /// In en, this message translates to:
  /// **'Export Log File'**
  String get logExport;

  /// No description provided for @logClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get logClear;

  /// No description provided for @logCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logCopied;

  /// No description provided for @logExported.
  ///
  /// In en, this message translates to:
  /// **'Logs exported to {path}'**
  String logExported(String path);

  /// No description provided for @logCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String logCount(int count);

  /// No description provided for @logAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto scroll'**
  String get logAutoScroll;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logEmpty;

  /// No description provided for @proxySettingsOptional.
  ///
  /// In en, this message translates to:
  /// **'Proxy settings (optional)'**
  String get proxySettingsOptional;

  /// No description provided for @proxyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled: {address}'**
  String proxyEnabled(String address);

  /// No description provided for @proxyAddressNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set (direct connection)'**
  String get proxyAddressNotSet;

  /// No description provided for @proxyHttpDescription.
  ///
  /// In en, this message translates to:
  /// **'Access servers through an HTTP proxy (for example, Clash)'**
  String get proxyHttpDescription;

  /// No description provided for @useProxy.
  ///
  /// In en, this message translates to:
  /// **'Use proxy'**
  String get useProxy;

  /// No description provided for @proxyAddress.
  ///
  /// In en, this message translates to:
  /// **'Proxy address'**
  String get proxyAddress;

  /// No description provided for @proxyAddressFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: host:port, for example 127.0.0.1:7890'**
  String get proxyAddressFormat;

  /// No description provided for @applyProxyAddress.
  ///
  /// In en, this message translates to:
  /// **'Apply proxy address'**
  String get applyProxyAddress;

  /// No description provided for @invalidProxyAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HTTP proxy address and port'**
  String get invalidProxyAddress;

  /// No description provided for @playlistDisplayFormat.
  ///
  /// In en, this message translates to:
  /// **'Playlist layout'**
  String get playlistDisplayFormat;

  /// No description provided for @playlistDisplayFormatMasonry.
  ///
  /// In en, this message translates to:
  /// **'Masonry'**
  String get playlistDisplayFormatMasonry;

  /// No description provided for @playlistDisplayFormatList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get playlistDisplayFormatList;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return SZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ja':
      return SJa();
    case 'ru':
      return SRu();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
