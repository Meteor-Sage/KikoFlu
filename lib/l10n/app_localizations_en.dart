// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KikoFlu';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navMy => 'My';

  @override
  String get navSettings => 'Settings';

  @override
  String get offlineModeMessage =>
      'Offline mode: Network connection failed, only downloaded content is accessible';

  @override
  String get retry => 'Retry';

  @override
  String get searchTypeKeyword => 'Keyword';

  @override
  String get searchTypeTag => 'Tag';

  @override
  String get searchTypeVa => 'Voice Actor';

  @override
  String get searchTypeCircle => 'Circle';

  @override
  String get searchTypeRjNumber => 'RJ Number';

  @override
  String get searchHintKeyword => 'Enter work name or keyword...';

  @override
  String get searchHintTag => 'Enter tag name...';

  @override
  String get searchHintVa => 'Enter voice actor name...';

  @override
  String get searchHintCircle => 'Enter circle name...';

  @override
  String get searchHintRjNumber => 'Enter number...';

  @override
  String get ageRatingAll => 'All';

  @override
  String get ageRatingGeneral => 'All Ages';

  @override
  String get ageRatingR15 => 'R-15';

  @override
  String get ageRatingAdult => 'Adult';

  @override
  String get salesRangeAll => 'All';

  @override
  String get sortRelease => 'Release Date';

  @override
  String get sortCreateAt => 'Added Date';

  @override
  String get sortCreateDate => 'Catalog Date';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortReviewCount => 'Reviews';

  @override
  String get sortRandom => 'Random';

  @override
  String get sortDlCount => 'Sales';

  @override
  String get sortPrice => 'Price';

  @override
  String get sortNsfw => 'All Ages';

  @override
  String get sortUpdatedAt => 'Marked Date';

  @override
  String get sortAsc => 'Ascending';

  @override
  String get sortDesc => 'Descending';

  @override
  String get sortOptions => 'Sort Options';

  @override
  String get sortField => 'Sort Field';

  @override
  String get sortDirection => 'Sort Direction';

  @override
  String get displayModeAll => 'All';

  @override
  String get displayModePopular => 'Popular';

  @override
  String get displayModeRecommended => 'Recommended';

  @override
  String get subtitlePriorityHighest => 'Priority';

  @override
  String get subtitlePriorityLowest => 'Deferred';

  @override
  String get translationSourceGoogle => 'Google Translate';

  @override
  String get translationSourceYoudao => 'Youdao Translate';

  @override
  String get translationSourceMicrosoft => 'Microsoft Translate';

  @override
  String get translationSourceLlm => 'LLM Translate';

  @override
  String get progressMarked => 'Marked';

  @override
  String get progressListening => 'Listening';

  @override
  String get progressListened => 'Listened';

  @override
  String get progressReplay => 'Replay';

  @override
  String get progressPostponed => 'Postponed';

  @override
  String get loginTitle => 'Login';

  @override
  String get register => 'Register';

  @override
  String get addAccount => 'Add Account';

  @override
  String get registerAccount => 'Register Account';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get serverCookie => 'Server Cookie';

  @override
  String get login => 'Login';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registerFailed => 'Registration failed';

  @override
  String get usernameMinLength => 'Username must be at least 5 characters';

  @override
  String get passwordMinLength => 'Password must be at least 5 characters';

  @override
  String accountAdded(String username) {
    return 'Account \"$username\" has been added';
  }

  @override
  String get testConnection => 'Test Connection';

  @override
  String get testing => 'Testing...';

  @override
  String get enterServerAddressToTest =>
      'Please enter server address to test connection';

  @override
  String latencyMs(String ms) {
    return '${ms}ms';
  }

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get guestModeTitle => 'Guest Mode Confirmation';

  @override
  String get guestModeMessage =>
      'Guest mode has limited functionality:\n\n• Cannot mark or rate works\n• Cannot create playlists\n• Cannot sync progress\n\nGuest mode uses a demo account to connect to the server, which may be unstable.';

  @override
  String get continueGuestMode => 'Continue with Guest Mode';

  @override
  String get guestAccountAdded => 'Guest account has been added';

  @override
  String get guestLoginFailed => 'Guest login failed';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get create => 'Create';

  @override
  String get ok => 'OK';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get advancedFilter => 'Advanced Filter';

  @override
  String get enterSearchContent => 'Please enter search content';

  @override
  String get searchTag => 'Search tags...';

  @override
  String get minRating => 'Min Rating';

  @override
  String minRatingStars(String stars) {
    return '$stars stars';
  }

  @override
  String get searchHistory => 'Search History';

  @override
  String get clearSearchHistory => 'Clear Search History';

  @override
  String get clearSearchHistoryConfirm =>
      'Are you sure you want to clear all search history?';

  @override
  String get clear => 'Clear';

  @override
  String get searchHistoryCleared => 'Search history cleared';

  @override
  String get noSearchHistory => 'No search history';

  @override
  String get excludeMode => 'Exclude';

  @override
  String get includeMode => 'Include';

  @override
  String get noResults => 'No results';

  @override
  String get loadFailed => 'Load failed';

  @override
  String loadFailedWithError(String error) {
    return 'Load failed: $error';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get calculating => 'Calculating...';

  @override
  String get getFailed => 'Failed to retrieve';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountManagement => 'Account Management';

  @override
  String get accountManagementSubtitle =>
      'Multi-account management, switch accounts';

  @override
  String get privacyMode => 'Privacy Mode';

  @override
  String get privacyModeEnabled => 'Enabled - Playback info is hidden';

  @override
  String get privacyModeDisabled => 'Disabled';

  @override
  String get permissionManagement => 'Permission Management';

  @override
  String get permissionManagementSubtitle =>
      'Notification permissions, background running permissions';

  @override
  String get desktopFloatingLyric => 'Desktop Floating Lyrics';

  @override
  String get floatingLyricEnabled => 'Enabled - Lyrics will display on desktop';

  @override
  String get floatingLyricDisabled => 'Disabled';

  @override
  String get floatingLyricTouch => 'Floating Lyric Lock';

  @override
  String get floatingLyricTouchEnabled =>
      'Unlocked - Drag floating lyrics, long press to lock';

  @override
  String get floatingLyricTouchDisabled =>
      'Locked - Long press floating lyrics to unlock';

  @override
  String get floatingFPS => 'Show FPS';

  @override
  String get floatingFPSEnabled =>
      'Enabled - FPS shown at bottom-left of floating window';

  @override
  String get floatingFPSDisabled => 'Disabled';

  @override
  String get floatingNetworkSpeed => 'Show Network Speed';

  @override
  String get floatingNetworkSpeedEnabled =>
      'Enabled - Speed shown at bottom-right of floating window';

  @override
  String get floatingNetworkSpeedDisabled => 'Disabled';

  @override
  String get styleSettings => 'Style Settings';

  @override
  String get styleSettingsSubtitle =>
      'Customize font, color, transparency, etc.';

  @override
  String get downloadPath => 'Download Path';

  @override
  String get downloadPathSubtitle => 'Customize download file save location';

  @override
  String get maxConcurrentDownloads => 'Max Concurrent Downloads';

  @override
  String get maxConcurrentDownloadsSubtitle =>
      'Limit simultaneous download tasks';

  @override
  String get cacheManagement => 'Cache Management';

  @override
  String currentCache(String size) {
    return 'Current cache: $size';
  }

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get themeSettingsSubtitle => 'Dark mode, theme color, etc.';

  @override
  String get uiSettings => 'UI Settings';

  @override
  String get uiSettingsSubtitle => 'Player, detail page, cards, etc.';

  @override
  String get liquidGlassNavigation => 'Liquid Glass Navigation';

  @override
  String get liquidGlassNavigationDesc =>
      'Glass navigation and mini player; enabled by default where supported.';

  @override
  String get fallbackGlassTransparency => 'Liquid Glass Transparency';

  @override
  String get fallbackGlassTransparencyDesc =>
      'Adjust app-rendered glass transparency.';

  @override
  String get preferenceSettings => 'Preference Settings';

  @override
  String get preferenceSettingsSubtitle => 'Translation, playback, and network';

  @override
  String get aboutTitle => 'About';

  @override
  String get unknownVersion => 'Unknown';

  @override
  String get licenseLoadFailed => 'Failed to load LICENSE file';

  @override
  String get licenseEmpty => 'LICENSE content is empty';

  @override
  String get failedToLoadAbout => 'Failed to load about info';

  @override
  String get newVersionFound => 'New Version Found';

  @override
  String newVersionAvailable(String version, String current) {
    return '$version available (current: $current)';
  }

  @override
  String get versionInfo => 'Version Info';

  @override
  String currentVersion(String version) {
    return 'Current version: $version';
  }

  @override
  String get checkUpdate => 'Check for Updates';

  @override
  String get author => 'Author';

  @override
  String get projectRepo => 'Project Repository';

  @override
  String get openSourceLicense => 'Open Source License';

  @override
  String get cannotOpenLink => 'Cannot open link';

  @override
  String openLinkFailed(String error) {
    return 'Failed to open link: $error';
  }

  @override
  String foundNewVersion(String version) {
    return 'Found new version $version';
  }

  @override
  String get view => 'View';

  @override
  String get alreadyLatestVersion => 'Already the latest version';

  @override
  String get checkUpdateFailed =>
      'Update check failed, please check network connection';

  @override
  String get onlineMarks => 'Online Marks';

  @override
  String get historyRecord => 'History';

  @override
  String get playlists => 'Playlists';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloadTasks => 'Download Tasks';

  @override
  String get subtitleLibrary => 'Subtitle Library';

  @override
  String get all => 'All';

  @override
  String get marked => 'Marked';

  @override
  String get listening => 'Listening';

  @override
  String get listened => 'Listened';

  @override
  String get replayMark => 'Replay';

  @override
  String get postponed => 'Postponed';

  @override
  String get switchToSmallGrid => 'Switch to small grid view';

  @override
  String get switchToList => 'Switch to list view';

  @override
  String get switchToLargeGrid => 'Switch to large grid view';

  @override
  String get sort => 'Sort';

  @override
  String get noPlayHistory => 'No play history';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryTitle => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear all play history? This action cannot be undone.';

  @override
  String get popularNoSort => 'Popular mode does not support sorting';

  @override
  String get recommendedNoSort => 'Recommended mode does not support sorting';

  @override
  String get showAllWorks => 'Show all works';

  @override
  String get showOnlySubtitled => 'Show only subtitled works';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get select => 'Select';

  @override
  String get noDownloadTasks => 'No download tasks';

  @override
  String nFiles(int count) {
    return '$count files';
  }

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get deletionConfirmTitle => 'Confirm Delete';

  @override
  String deletionConfirmMessage(int count) {
    return 'Are you sure you want to delete $count selected download tasks? Downloaded files will also be removed.';
  }

  @override
  String deletedNFiles(int count) {
    return 'Deleted $count files';
  }

  @override
  String get downloadStatusPending => 'Pending';

  @override
  String get downloadStatusDownloading => 'Downloading';

  @override
  String get downloadStatusCompleted => 'Completed';

  @override
  String get downloadStatusFailed => 'Failed';

  @override
  String get downloadStatusPaused => 'Paused';

  @override
  String translationFailed(String error) {
    return 'Translation failed: $error';
  }

  @override
  String copiedToClipboard(String label, String text) {
    return 'Copied $label: $text';
  }

  @override
  String get loadingFileList => 'Loading file list...';

  @override
  String loadFileListFailed(String error) {
    return 'Failed to load file list: $error';
  }

  @override
  String get playlistTitle => 'Playlist';

  @override
  String get noAudioPlaying => 'No audio playing';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get backward10s => 'Backward 10s';

  @override
  String get forward10s => 'Forward 10s';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get repeatMode => 'Repeat Mode';

  @override
  String get repeatOff => 'Off';

  @override
  String get repeatOne => 'Single';

  @override
  String get repeatAll => 'All';

  @override
  String get addMark => 'Add Mark';

  @override
  String get viewDetail => 'View Detail';

  @override
  String get volume => 'Volume';

  @override
  String get sleepTimerTitle => 'Sleep Timer';

  @override
  String get aboutToStop => 'About to stop';

  @override
  String get remainingTime => 'Remaining time';

  @override
  String get finishCurrentTrack => 'Stop after current track finishes';

  @override
  String addMinutes(int min) {
    return '+$min min';
  }

  @override
  String get cancelTimer => 'Cancel Timer';

  @override
  String get duration => 'Duration';

  @override
  String get specifyTime => 'Specify Time';

  @override
  String get selectTimerDuration => 'Select timer duration';

  @override
  String get selectStopTime => 'Select the time to stop playback';

  @override
  String get markWork => 'Mark Work';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get remove => 'Remove';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get addPlaylist => 'Add Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get enterPlaylistName => 'Enter name';

  @override
  String get privacySetting => 'Privacy Setting';

  @override
  String get playlistDescription => 'Description (optional)';

  @override
  String get addDescription => 'Add a description';

  @override
  String get enterPlaylistNameWarning => 'Please enter a playlist name';

  @override
  String get enterPlaylistLink => 'Please enter a playlist link';

  @override
  String get switchAccountTitle => 'Switch Account';

  @override
  String switchAccountConfirm(String username) {
    return 'Are you sure you want to switch to account \"$username\"?';
  }

  @override
  String switchedToAccount(String username) {
    return 'Switched to account: $username';
  }

  @override
  String get switchFailed => 'Switch failed, please check account info';

  @override
  String switchFailedWithError(String error) {
    return 'Switch failed: $error';
  }

  @override
  String get noAccounts => 'No accounts';

  @override
  String get tapToAddAccount =>
      'Tap the button in the bottom right to add an account';

  @override
  String get currentAccount => 'Current Account';

  @override
  String get switchAction => 'Switch';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String deleteAccountConfirm(String username) {
    return 'Are you sure you want to delete account \"$username\"? This action cannot be undone.';
  }

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String deletionFailedWithError(String error) {
    return 'Deletion failed: $error';
  }

  @override
  String get subtitleLibraryPriority => 'Subtitle Library Priority';

  @override
  String get selectSubtitlePriority =>
      'Select subtitle library priority for auto-loading:';

  @override
  String get subtitlePriorityHighestDesc =>
      'Search subtitle library first, then online/downloads';

  @override
  String get subtitlePriorityLowestDesc =>
      'Search online/downloads first, then subtitle library';

  @override
  String get defaultSortSettings => 'Default Sort Settings';

  @override
  String get defaultSortUpdated => 'Default sort updated';

  @override
  String get translationSourceSettings => 'Translation Source Settings';

  @override
  String get selectTranslationProvider =>
      'Select translation service provider:';

  @override
  String get translationTargetLanguage => 'Target Language';

  @override
  String get autoSaveTranslatedLyrics => 'Automatically save translated lyrics';

  @override
  String get autoSaveTranslatedLyricsDesc =>
      'Save translations to the subtitle library; otherwise show them temporarily.';

  @override
  String get selectTranslationTargetLanguage => 'Select target language:';

  @override
  String get translationLanguageFollowApp => 'Follow App Language';

  @override
  String get translationLanguageZhHans => 'Simplified Chinese';

  @override
  String get translationLanguageZhHant => 'Traditional Chinese';

  @override
  String get translationLanguageEnglish => 'English';

  @override
  String get translationLanguageJapanese => 'Japanese';

  @override
  String get translationLanguageRussian => 'Russian';

  @override
  String get translationLanguageCustom => 'Custom';

  @override
  String get translationCustomTargetLanguage => 'Custom Target Language';

  @override
  String get translationCustomLanguageHint => 'Language name, e.g. Korean';

  @override
  String translationCustomLanguageLabel(String value) {
    return 'Custom: $value';
  }

  @override
  String get translationCustomTargetRequiresLlm => 'Requires LLM translation';

  @override
  String get needsConfiguration => 'Needs configuration';

  @override
  String get llmTranslation => 'LLM Translation';

  @override
  String get goToConfigure => 'Configure';

  @override
  String get subtitlePrioritySettingSubtitle => 'Subtitle library priority';

  @override
  String get defaultSortSettingTitle => 'Default sort for home page';

  @override
  String get translationSource => 'Translation Source';

  @override
  String get llmSettings => 'LLM Settings';

  @override
  String get llmSettingsSubtitle => 'API URL, key, and model';

  @override
  String get audioFormatPreference => 'Audio Format Preference';

  @override
  String get audioFormatSubtitle => 'Audio format priority';

  @override
  String get preloadNextTitle => 'Preload Next Track';

  @override
  String get preloadNextSubtitle =>
      'Preload the next track to cache before the current one ends to avoid playback gaps';

  @override
  String get selectPreloadThreshold =>
      'Preload starts when remaining time of the current track is below this threshold:';

  @override
  String get preloadOptionOff => 'Off';

  @override
  String preloadOptionSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get preloadOptionCustom => 'Custom';

  @override
  String get preloadCustomInputTitle => 'Custom Preload Threshold';

  @override
  String get preloadCustomInputHint => 'Seconds (1-300)';

  @override
  String get preloadCustomInputRangeError =>
      'Please enter a number between 1 and 300';

  @override
  String preloadCustomValueLabel(int value) {
    return '$value s';
  }

  @override
  String get keepScreenAwake => 'Keep Screen Awake';

  @override
  String get keepScreenAwakeDesc => 'Keep the screen on during playback';

  @override
  String get audioHaptics => 'Audio Haptics (Beta)';

  @override
  String get audioHapticsDesc =>
      'Vibrate with downloaded audio while the app is foregrounded';

  @override
  String get audioHapticsIntensity => 'Intensity';

  @override
  String get audioGain => 'Global Audio Gain';

  @override
  String get audioGainDesc =>
      '0 dB is original audio; excessive boost may distort or damage hearing';

  @override
  String get audioGainAttenuationDesc =>
      'Reduce all audio; 0 dB keeps the original level';

  @override
  String get audioGainPassthroughDesc =>
      'Unavailable while audio passthrough is on';

  @override
  String get blockingSettings => 'Blocking Settings';

  @override
  String get blockingSettingsSubtitle =>
      'Blocked tags, voice actors, and circles';

  @override
  String get audioPassthrough => 'Audio Passthrough (Beta)';

  @override
  String get audioPassthroughDescWindows =>
      'Use WASAPI exclusive output (restart required)';

  @override
  String get audioPassthroughDescMac => 'Use CoreAudio exclusive output';

  @override
  String get audioPassthroughDisableDesc => 'Disable audio passthrough mode';

  @override
  String get warning => 'Warning';

  @override
  String get audioPassthroughWarning =>
      'This feature is not fully tested and may cause unexpected audio output. Are you sure you want to enable it?';

  @override
  String get exclusiveModeEnabled =>
      'Exclusive mode enabled (restart required)';

  @override
  String get audioPassthroughEnabled => 'Audio passthrough mode enabled';

  @override
  String get audioPassthroughDisabled => 'Audio passthrough mode disabled';

  @override
  String get tagVoteSupport => 'Support';

  @override
  String get tagVoteOppose => 'Oppose';

  @override
  String get tagVoted => 'Voted';

  @override
  String get votedSupport => 'Voted support';

  @override
  String get votedOppose => 'Voted oppose';

  @override
  String get voteCancelled => 'Vote cancelled';

  @override
  String voteFailed(String error) {
    return 'Vote failed: $error';
  }

  @override
  String get blockThisTag => 'Block this tag';

  @override
  String get copyTag => 'Copy Tag';

  @override
  String get addTag => 'Add Tag';

  @override
  String loadTagsFailed(String error) {
    return 'Failed to load tags: $error';
  }

  @override
  String get selectAtLeastOneTag => 'Please select at least one tag';

  @override
  String get tagSubmitSuccess =>
      'Tags submitted successfully, awaiting server processing';

  @override
  String get bindEmailFirst =>
      'Please go to www.asmr.one to bind your email first';

  @override
  String selectedNTags(int count) {
    return 'Selected $count tags:';
  }

  @override
  String get noMatchingTags => 'No matching tags found';

  @override
  String get loadFailedRetry => 'Load failed, tap to retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get playlistPrivacyPrivate => 'Private';

  @override
  String get playlistPrivacyUnlisted => 'Unlisted';

  @override
  String get playlistPrivacyPublic => 'Public';

  @override
  String get systemPlaylistMarked => 'My Marked';

  @override
  String get systemPlaylistLiked => 'My Liked';

  @override
  String totalNWorks(int count) {
    return '$count works';
  }

  @override
  String pageNOfTotal(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get translateTitle => 'Translate';

  @override
  String get translateDescription => 'Translate Description';

  @override
  String get translating => 'Translating...';

  @override
  String translationFallbackNotice(String source) {
    return 'Translation failed, auto-switched to $source';
  }

  @override
  String get tagLabel => 'Tags';

  @override
  String get vaLabel => 'Voice Actors';

  @override
  String get circleLabel => 'Circle';

  @override
  String get releaseDate => 'Release Date';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get salesLabel => 'Sales';

  @override
  String get priceLabel => 'Price';

  @override
  String get durationLabel => 'Duration';

  @override
  String get ageRatingLabel => 'Age Rating';

  @override
  String get hasSubtitle => 'Has Subtitle';

  @override
  String get noSubtitle => 'No Subtitle';

  @override
  String get description => 'Description';

  @override
  String get fileList => 'File List';

  @override
  String get series => 'Series';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Switch display language';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageRu => 'Русский';

  @override
  String get themeModeDark => 'Dark Mode';

  @override
  String get themeModeLight => 'Light Mode';

  @override
  String get themeModeSystem => 'Follow System';

  @override
  String get colorSchemeOceanBlue => 'Ocean Blue';

  @override
  String get colorSchemeForestGreen => 'Forest Green';

  @override
  String get colorSchemeSunsetOrange => 'Sunset Orange';

  @override
  String get colorSchemeLavenderPurple => 'Lavender Purple';

  @override
  String get colorSchemeSakuraPink => 'Sakura Pink';

  @override
  String get colorSchemeDynamic => 'Dynamic Color';

  @override
  String get noData => 'No data';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get networkError => 'Network error';

  @override
  String get timeout => 'Request timeout';

  @override
  String get playAll => 'Play All';

  @override
  String get download => 'Download';

  @override
  String get downloadAll => 'Download All';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get startDownload => 'Starting download';

  @override
  String get confirmDeleteDownload =>
      'Are you sure you want to delete this download? The downloaded file will also be removed.';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get scanSubtitleLibrary => 'Scan Subtitle Library';

  @override
  String get scanning => 'Scanning...';

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get noSubtitleFiles => 'No subtitle files found';

  @override
  String subtitleFilesFound(int count) {
    return 'Found $count subtitle files';
  }

  @override
  String get selectDirectory => 'Select Directory';

  @override
  String get privacyModeSettings => 'Privacy Mode Settings';

  @override
  String get blurCover => 'Blur Cover';

  @override
  String get maskTitle => 'Mask Title';

  @override
  String get customTitle => 'Custom Title';

  @override
  String get privacyModeDesc =>
      'Hide playback information in system notifications and media controls';

  @override
  String get audioFormatSettingsTitle => 'Audio Format Settings';

  @override
  String get preferredFormat => 'Preferred Format';

  @override
  String get cacheSizeLimit => 'Cache Size Limit';

  @override
  String get llmApiUrl => 'API URL';

  @override
  String get llmApiKey => 'API Key';

  @override
  String get llmModel => 'Model';

  @override
  String get llmPrompt => 'System Prompt';

  @override
  String get llmConcurrency => 'Concurrency';

  @override
  String get llmTestTranslation => 'Test Translation';

  @override
  String get llmTestSuccess => 'Test successful';

  @override
  String get llmTestFailed => 'Test failed';

  @override
  String get subtitleTimingAdjustment => 'Subtitle Timing Adjustment';

  @override
  String get playerLyricStyle => 'Player Lyrics Style';

  @override
  String get floatingLyricStyle => 'Floating Lyrics Style';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontColor => 'Font Color';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get transparency => 'Transparency';

  @override
  String get windowSize => 'Window Size';

  @override
  String get playerButtonSettings => 'Player Button Settings';

  @override
  String get showButton => 'Show Button';

  @override
  String get buttonOrder => 'Button Order';

  @override
  String get workCardDisplaySettings => 'Work Card Display Settings';

  @override
  String get showTags => 'Show Tags';

  @override
  String get showVa => 'Show Voice Actors';

  @override
  String get showRating => 'Show Rating';

  @override
  String get showPrice => 'Show Price';

  @override
  String get cardSize => 'Card Size';

  @override
  String get compact => 'Compact';

  @override
  String get medium => 'Medium';

  @override
  String get full => 'Full';

  @override
  String get workDetailDisplaySettings => 'Work Detail Display Settings';

  @override
  String get infoSectionVisibility => 'Info Section Visibility';

  @override
  String get imageSize => 'Image Size';

  @override
  String get showMetadata => 'Show Metadata';

  @override
  String get relatedRecommendations => 'Related Works';

  @override
  String get myTabsDisplaySettings => '\"My\" Page Settings';

  @override
  String get showTab => 'Show Tab';

  @override
  String get tabOrder => 'Tab Order';

  @override
  String get blockedItems => 'Blocked Items';

  @override
  String get blockedTags => 'Blocked Tags';

  @override
  String get blockedVas => 'Blocked Voice Actors';

  @override
  String get blockedCircles => 'Blocked Circles';

  @override
  String get unblock => 'Unblock';

  @override
  String get noBlockedItems => 'No blocked items';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheConfirm => 'Are you sure you want to clear all cache?';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get imagePreview => 'Image Preview';

  @override
  String get saveImage => 'Save Image';

  @override
  String get imageSaved => 'Image saved';

  @override
  String get saveImageFailed => 'Save failed';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get ratingDistribution => 'Rating Distribution';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String ratingsCount(int count) {
    return '$count ratings total';
  }

  @override
  String get myReviews => 'My Reviews';

  @override
  String get noReviews => 'No reviews';

  @override
  String get writeReview => 'Write Review';

  @override
  String get editReview => 'Edit Review';

  @override
  String get deleteReview => 'Delete Review';

  @override
  String get deleteReviewConfirm =>
      'Are you sure you want to delete this review?';

  @override
  String get reviewDeleted => 'Review deleted';

  @override
  String get reviewContent => 'Review content';

  @override
  String get enterReviewContent => 'Enter review content...';

  @override
  String get submitReview => 'Submit';

  @override
  String get reviewSubmitted => 'Review submitted';

  @override
  String reviewFailed(String error) {
    return 'Review failed: $error';
  }

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get mediaPermission => 'Media Library Permission';

  @override
  String get storagePermission => 'Storage Permission';

  @override
  String get granted => 'Granted';

  @override
  String get denied => 'Denied';

  @override
  String get requestPermission => 'Request';

  @override
  String get localDownloads => 'Local Downloads';

  @override
  String get offlinePlayback => 'Offline Playback';

  @override
  String get noDownloadedWorks => 'No downloaded works';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get ignoreThisVersion => 'Ignore this version';

  @override
  String get remindLater => 'Remind Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get fetchFailed => 'Fetch failed';

  @override
  String operationFailedWithError(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get aboutSubtitle => 'Check updates, licenses, etc.';

  @override
  String get currentCacheSize => 'Current Cache Size';

  @override
  String cacheLimitLabelMB(int size) {
    return 'Limit: ${size}MB';
  }

  @override
  String get cacheUsagePercent => 'Usage';

  @override
  String get autoCleanTitle => 'Auto Clean Info';

  @override
  String get autoCleanDescription =>
      '• Cache is auto-cleaned when exceeding the limit\n• Deletes until cache drops to 80% of limit\n• Uses Least Recently Used (LRU) strategy';

  @override
  String get autoCleanDescriptionShort =>
      '• Cache is auto-cleaned when exceeding the limit\n• Deletes until cache drops to 80% of limit';

  @override
  String get confirmClear => 'Confirm Clear';

  @override
  String get confirmClearCacheMessage =>
      'Are you sure you want to clear all cache? This action cannot be undone.';

  @override
  String clearCacheFailedWithError(String error) {
    return 'Clear cache failed: $error';
  }

  @override
  String get hasNewVersion => 'New version';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get colorTheme => 'Color Theme';

  @override
  String get themePreview => 'Theme Preview';

  @override
  String get themeModeSystemDesc =>
      'Automatically adapt to system dark/light mode';

  @override
  String get themeModeLightDesc => 'Always use light theme';

  @override
  String get themeModeDarkDesc => 'Always use dark theme';

  @override
  String get colorSchemeOceanBlueDesc => 'Blue, blue, blue!';

  @override
  String get colorSchemeSakuraPinkDesc => '( ゜- ゜)つロ Cheers~';

  @override
  String get colorSchemeSunsetOrangeDesc => 'Themes are a must ✍🏻✍🏻✍🏻';

  @override
  String get colorSchemeLavenderPurpleDesc => 'Bro, bro...';

  @override
  String get colorSchemeForestGreenDesc => 'Green, green, green';

  @override
  String get colorSchemeDynamicDesc =>
      'Use wallpaper colors from system (Android 12+)';

  @override
  String get primaryContainer => 'Primary Container';

  @override
  String get secondaryContainer => 'Secondary Container';

  @override
  String get tertiaryContainer => 'Tertiary Container';

  @override
  String get surfaceColor => 'Surface';

  @override
  String get playerButtonSettingsSubtitle => 'Player button order';

  @override
  String get playerLyricStyleSubtitle => 'Mini and fullscreen lyric styles';

  @override
  String get workDetailDisplaySubtitle => 'Detail page content';

  @override
  String get workCardDisplaySubtitle => 'Work card content';

  @override
  String get myTabsDisplaySubtitle => 'Tabs shown on My';

  @override
  String get pageSizeSettings => 'Items Per Page';

  @override
  String pageSizeCurrent(int size) {
    return '$size items per page';
  }

  @override
  String currentSettingLabel(String value) {
    return 'Current: $value';
  }

  @override
  String setToValue(String value) {
    return 'Set to: $value';
  }

  @override
  String get llmConfigRequiredMessage =>
      'LLM translation requires an API Key. Please configure it in settings first.';

  @override
  String get autoSwitchedToLlm => 'Auto-switched to: LLM Translation';

  @override
  String get translationDescGoogle => 'Requires Google services';

  @override
  String get translationDescYoudao => 'Uses the current network';

  @override
  String get translationDescMicrosoft => 'Uses the current network';

  @override
  String get translationDescLlm => 'Requires an OpenAI-compatible API';

  @override
  String get audioPassthroughDescAndroid =>
      'Send raw AC3/DTS audio to an external decoder';

  @override
  String get permissionExplanation => 'Permission Explanation';

  @override
  String get backgroundRunningPermission => 'Background Running Permission';

  @override
  String get notificationPermissionDesc =>
      'Used for showing media playback notification, allowing control from lock screen and notification bar.';

  @override
  String get backgroundRunningPermissionDesc =>
      'Exempts app from battery optimization to ensure audio continues playing in background.';

  @override
  String get notificationGrantedStatus =>
      'Granted - Can show playback notification and controls';

  @override
  String get notificationDeniedStatus =>
      'Not granted - Tap to request permission';

  @override
  String get backgroundGrantedStatus =>
      'Granted - App can run continuously in background';

  @override
  String get backgroundDeniedStatus =>
      'Not granted - Tap to request permission';

  @override
  String get notificationPermissionGranted => 'Notification permission granted';

  @override
  String get notificationPermissionDenied => 'Notification permission denied';

  @override
  String requestNotificationFailed(String error) {
    return 'Failed to request notification permission: $error';
  }

  @override
  String get backgroundPermissionGranted =>
      'Background running permission granted';

  @override
  String get backgroundPermissionDenied =>
      'Background running permission denied';

  @override
  String requestBackgroundFailed(String error) {
    return 'Failed to request background permission: $error';
  }

  @override
  String permissionRequired(String permission) {
    return '$permission Required';
  }

  @override
  String permissionPermanentlyDenied(String permission) {
    return '$permission has been permanently denied. Please enable it manually in system settings.';
  }

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionsAndroidOnly =>
      'Permission management is only available on Android';

  @override
  String get permissionsNotNeeded =>
      'Other platforms do not require manual permission management';

  @override
  String get refreshPermissionStatus => 'Refresh permission status';

  @override
  String deleteFileConfirm(String fileName) {
    return 'Are you sure you want to delete \"$fileName\"?';
  }

  @override
  String deleteSelectedFilesConfirm(int count) {
    return 'Are you sure you want to delete $count selected files?';
  }

  @override
  String get deleted => 'Deleted';

  @override
  String cannotOpenFolder(String path) {
    return 'Cannot open folder: $path';
  }

  @override
  String openFolderFailed(String error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get reloadingFromDisk => 'Reloading from disk...';

  @override
  String get refreshComplete => 'Refresh complete';

  @override
  String refreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String deleteSelectedWorksConfirm(int count) {
    return 'Are you sure you want to delete $count selected works?';
  }

  @override
  String partialDeleteFailed(String error) {
    return 'Partial deletion failed: $error';
  }

  @override
  String deletedNOfTotal(int success, int total) {
    return 'Deleted $success/$total tasks';
  }

  @override
  String deleteFailedWithError(String error) {
    return 'Deletion failed: $error';
  }

  @override
  String get noWorkMetadataForOffline =>
      'This download has no saved work details and cannot be viewed offline';

  @override
  String openWorkDetailFailed(String error) {
    return 'Failed to open work detail: $error';
  }

  @override
  String get noLocalDownloads => 'No local downloads';

  @override
  String get exitSelection => 'Exit selection';

  @override
  String get reload => 'Reload';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get playlistLink => 'Playlist Link';

  @override
  String get playlistLinkHint =>
      'Paste playlist link, e.g.:\nhttps://www.asmr.one/playlist?id=...';

  @override
  String get unrecognizedPlaylistLink => 'Unrecognized playlist link or ID';

  @override
  String get addingPlaylist => 'Adding playlist...';

  @override
  String get playlistAddedSuccess => 'Playlist added successfully';

  @override
  String get addFailed => 'Add failed';

  @override
  String get playlistNotFound => 'Playlist does not exist or has been deleted';

  @override
  String get noPermissionToAccessPlaylist =>
      'No permission to access this playlist';

  @override
  String get networkConnectionFailed =>
      'Network connection failed, please check network';

  @override
  String addFailedWithError(String error) {
    return 'Add failed: $error';
  }

  @override
  String get creatingPlaylist => 'Creating playlist...';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Playlist \"$name\" created successfully';
  }

  @override
  String createFailedWithError(String error) {
    return 'Creation failed: $error';
  }

  @override
  String get noPlaylists => 'No playlists';

  @override
  String get noPlaylistsDescription =>
      'You haven\'t created or favorited any playlists yet';

  @override
  String get myPlaylists => 'My Playlists';

  @override
  String totalNItems(int count) {
    return '$count items total';
  }

  @override
  String get systemPlaylistCannotDelete => 'System playlists cannot be deleted';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get unfavoritePlaylist => 'Unfavorite Playlist';

  @override
  String get deletePlaylistConfirm =>
      'Deletion is irreversible. Users who favorited this playlist will lose access. Are you sure?';

  @override
  String unfavoritePlaylistConfirm(String name) {
    return 'Are you sure you want to unfavorite \"$name\"?';
  }

  @override
  String get unfavorite => 'Unfavorite';

  @override
  String get deleting => 'Deleting...';

  @override
  String get deleteSuccess => 'Deleted successfully';

  @override
  String get onlyOwnerCanEdit => 'Only the playlist owner can edit';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get playlistNameRequired => 'Playlist name cannot be empty';

  @override
  String get privacyDescPrivate => 'Only you can view';

  @override
  String get privacyDescUnlisted => 'Only people with the link can view';

  @override
  String get privacyDescPublic => 'Anyone can view';

  @override
  String get addWorks => 'Add Works';

  @override
  String get addWorksInputHint =>
      'Enter text containing work IDs, RJ numbers will be auto-detected';

  @override
  String get workId => 'Work ID';

  @override
  String get workIdHint => 'e.g.: RJ123456\nrj233333';

  @override
  String detectedNWorkIds(int count) {
    return 'Detected $count work IDs';
  }

  @override
  String addNWorks(int count) {
    return 'Add $count';
  }

  @override
  String get noValidWorkIds => 'No valid work IDs found (starting with RJ)';

  @override
  String addingNWorks(int count) {
    return 'Adding $count works...';
  }

  @override
  String addedNWorksSuccess(int count) {
    return 'Successfully added $count works';
  }

  @override
  String get removeWork => 'Remove Work';

  @override
  String removeWorkConfirm(String title) {
    return 'Are you sure you want to remove \"$title\" from the playlist?';
  }

  @override
  String get removeSuccess => 'Removed successfully';

  @override
  String removeFailedWithError(String error) {
    return 'Remove failed: $error';
  }

  @override
  String get saving => 'Saving...';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String saveFailedWithError(String error) {
    return 'Save failed: $error';
  }

  @override
  String get noWorks => 'No works';

  @override
  String get playlistNoWorksDescription =>
      'No works have been added to this playlist yet';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get createdTime => 'Created';

  @override
  String nWorksCount(int count) {
    return '$count works';
  }

  @override
  String nPlaysCount(int count) {
    return '$count plays';
  }

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get checkNetworkOrRetry =>
      'Please check your network connection or try again later';

  @override
  String get reachedEnd => 'You\'ve reached the end~';

  @override
  String excludedNWorks(int count) {
    return 'Excluded $count works';
  }

  @override
  String pageExcludedNWorks(int count) {
    return 'This page excluded $count works';
  }

  @override
  String get noSubtitlesAvailable => 'No subtitles available';

  @override
  String get translateLyrics => 'Translate lyrics';

  @override
  String get fullscreenLyrics => 'Fullscreen lyrics';

  @override
  String get showOriginalLyrics => 'Show original';

  @override
  String get showTranslatedLyrics => 'Show translation';

  @override
  String get translatingLyrics => 'Translating...';

  @override
  String get lyricTranslationFailed => 'Lyric translation failed';

  @override
  String get lyricTranslationConfirmMessage =>
      'Translate the currently playing lyrics and show the result immediately. When automatic saving is enabled, the same-name .lrc file in the subtitle library will be overwritten. Switching tracks during translation discards the result.';

  @override
  String get unlock => 'Unlock';

  @override
  String get backToCover => 'Back to cover';

  @override
  String get lyricHintTapCover => 'Tap cover or title to enter subtitle view';

  @override
  String get floatingSubtitle => 'Floating Subtitle';

  @override
  String get appendMode => 'Append Mode';

  @override
  String get appendModeStatusOn => 'Append Mode: On';

  @override
  String get appendModeStatusOff => 'Append Mode: Off';

  @override
  String get playlistEmpty => 'Playlist is empty';

  @override
  String get appendModeEnabled => 'Append Mode Enabled';

  @override
  String get appendModeHint =>
      'Audio tapped next will be appended to the end of the current playlist instead of replacing it.\nDuplicate tracks won\'t be added.';

  @override
  String get gotIt => 'Got it';

  @override
  String nMinutes(int count) {
    return '$count min';
  }

  @override
  String nHours(int count) {
    return '$count hr';
  }

  @override
  String get titleLabel => 'Title';

  @override
  String get rjNumberLabel => 'RJ Number';

  @override
  String get workIdLabel => 'Work ID';

  @override
  String get tapToViewRatingDetail => 'Tap to view rating details';

  @override
  String priceInYen(int price) {
    return '$price Yen';
  }

  @override
  String soldCount(String count) {
    return 'Sold: $count';
  }

  @override
  String get circleAndVaSection => 'Circle | Voice Actors';

  @override
  String get subtitleBadge => 'Subtitle';

  @override
  String get otherEditions => 'Other Editions';

  @override
  String tenThousandSuffix(String count) {
    return '${count}k';
  }

  @override
  String get packingWork => 'Packing work...';

  @override
  String get workDirectoryNotExist => 'Work directory does not exist';

  @override
  String get packingFailed => 'Packing failed';

  @override
  String exportSuccess(String path) {
    return 'Export successful: $path';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportAsZip => 'Export as ZIP';

  @override
  String get offlineBadge => 'Offline';

  @override
  String loadFilesFailed(String error) {
    return 'Failed to load files: $error';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get noPlayableAudioFiles => 'No playable audio files found';

  @override
  String cannotFindAudioFile(String title) {
    return 'Cannot find audio file: $title';
  }

  @override
  String nowPlayingNOfTotal(String title, int current, int total) {
    return 'Now playing: $title ($current/$total)';
  }

  @override
  String get noAudioCannotLoadSubtitle =>
      'No audio playing, cannot load subtitle';

  @override
  String get loadSubtitle => 'Load Subtitle';

  @override
  String get loadSubtitleConfirm =>
      'Load this file as subtitle for the current audio?';

  @override
  String get subtitleFile => 'Subtitle file';

  @override
  String get currentAudio => 'Current audio';

  @override
  String get subtitleAutoRestoreNote =>
      'Subtitle will auto-restore to default matching when switching audio';

  @override
  String get confirmLoad => 'Confirm Load';

  @override
  String get loadingSubtitle => 'Loading subtitle...';

  @override
  String subtitleLoadSuccess(String title) {
    return 'Subtitle loaded: $title';
  }

  @override
  String subtitleLoadFailed(String error) {
    return 'Subtitle load failed: $error';
  }

  @override
  String get cannotPreviewImageMissingInfo =>
      'Cannot preview image: missing required info';

  @override
  String get cannotFindImageFile => 'Cannot find image file';

  @override
  String get cannotPreviewTextMissingInfo =>
      'Cannot preview text: missing required info';

  @override
  String get cannotPreviewPdfMissingInfo =>
      'Cannot preview PDF: missing required info';

  @override
  String get cannotPlayVideoMissingId => 'Cannot play video: missing file ID';

  @override
  String get cannotPlayVideoMissingParams =>
      'Cannot play video: missing required parameters';

  @override
  String get cannotPlayDirectly => 'Cannot play directly';

  @override
  String get noVideoPlayerFound =>
      'No supported video player found on this device.';

  @override
  String get youCan => 'You can:';

  @override
  String get copyLinkToExternalPlayer =>
      '1. Copy the link to an external player (e.g. MX Player, VLC)';

  @override
  String get openInBrowserOption => '2. Open in browser';

  @override
  String playVideoError(String error) {
    return 'Error playing video: $error';
  }

  @override
  String get noFiles => 'No files';

  @override
  String get resourceFiles => 'Resource Files';

  @override
  String resourceFilesTranslated(int count) {
    return 'Resource Files (translated $count items)';
  }

  @override
  String get translationOriginal => 'Orig';

  @override
  String get translationTranslated => 'Trans';

  @override
  String copiedName(String title) {
    return 'Copied name: $title';
  }

  @override
  String translationComplete(int count) {
    return 'Translation complete: $count items';
  }

  @override
  String get noContentToTranslate => 'No content to translate';

  @override
  String get preparingTranslation => 'Preparing translation...';

  @override
  String translatingProgress(int current, int total) {
    return 'Translating $current/$total';
  }

  @override
  String nItems(int count) {
    return '$count items';
  }

  @override
  String get loadAsSubtitle => 'Load as subtitle';

  @override
  String get preview => 'Preview';

  @override
  String openVideoFileError(String error) {
    return 'Error opening video file: $error';
  }

  @override
  String cannotOpenVideoFile(String message) {
    return 'Cannot open video file: $message';
  }

  @override
  String get noFileTreeInfo => 'No file tree information';

  @override
  String get workFolderNotExist => 'Work folder does not exist';

  @override
  String get cannotPlayAudioMissingId => 'Cannot play audio: missing file ID';

  @override
  String get audioFileNotExist => 'Audio file does not exist';

  @override
  String get noPreviewableImages => 'No previewable images found';

  @override
  String get cannotPreviewTextMissingId =>
      'Cannot preview text: missing file ID';

  @override
  String get cannotFindFilePath => 'Cannot find file path';

  @override
  String fileNotExist(String title) {
    return 'File does not exist: $title';
  }

  @override
  String get cannotPreviewPdfMissingId => 'Cannot preview PDF: missing file ID';

  @override
  String get videoFileNotExist => 'Video file does not exist';

  @override
  String get cannotOpenVideo => 'Cannot open video';

  @override
  String errorInfo(String message) {
    return 'Error: $message';
  }

  @override
  String get installVideoPlayerApp =>
      'Please install a video player app (e.g. VLC, MX Player)';

  @override
  String get filePathLabel => 'File path:';

  @override
  String get noDownloadedFiles => 'No downloaded files';

  @override
  String get offlineFiles => 'Offline Files';

  @override
  String unsupportedFileType(String title) {
    return 'This file type is not supported: $title';
  }

  @override
  String get deleteFilePrompt => 'Are you sure you want to delete this file?';

  @override
  String deletedItem(String title) {
    return 'Deleted: $title';
  }

  @override
  String get selectAtLeastOneFile => 'Please select at least one file';

  @override
  String addedNFilesToDownloadQueue(int count) {
    return 'Added $count files to download queue';
  }

  @override
  String downloadedAndSelected(int downloaded, int selected) {
    return 'Downloaded $downloaded · Selected $selected';
  }

  @override
  String downloadN(int count) {
    return 'Download ($count)';
  }

  @override
  String get checkingDownloadedFiles => 'Checking downloaded files...';

  @override
  String get noDownloadableFiles => 'No downloadable files';

  @override
  String get selectFilesToDownload => 'Select Files to Download';

  @override
  String downloadedNCount(int count) {
    return '$count downloaded';
  }

  @override
  String selectedNCount(int count) {
    return '$count selected';
  }

  @override
  String get pleaseEnterServerAddress => 'Please enter server address';

  @override
  String get pleaseEnterUsername => 'Please enter username';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get notTestedYet => 'Not tested yet';

  @override
  String latencyResultDetail(String latency, String status) {
    return 'Latency $latency ($status)';
  }

  @override
  String connectionFailedWithDetail(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get noAccountTapToRegister => 'No account? Tap to register';

  @override
  String get haveAccountTapToLogin => 'Have an account? Tap to login';

  @override
  String get cannotDeleteActiveAccount =>
      'Cannot delete the currently active account';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get noSavedAccounts => 'No saved accounts';

  @override
  String get addAccountToGetStarted => 'Add an account to get started';

  @override
  String get unknownHost => 'Unknown host';

  @override
  String lastUsedTime(String time) {
    return 'Last used: $time';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Delete $count selected items?';
  }

  @override
  String deletedNOfTotalItems(int success, int total) {
    return 'Deleted $success/$total items';
  }

  @override
  String get importingSubtitleFile => 'Importing subtitle file...';

  @override
  String get preparingImport => 'Preparing import...';

  @override
  String get preparingExtract => 'Preparing to extract...';

  @override
  String get importSubtitleFile => 'Import Subtitle File';

  @override
  String get supportedSubtitleFormats =>
      'Supports .srt, .vtt, .lrc and other subtitle formats';

  @override
  String get importFolder => 'Import Folder';

  @override
  String get importFolderDesc =>
      'Preserves folder structure, imports only subtitle files';

  @override
  String get importArchive => 'Import Archive';

  @override
  String get importArchiveDesc =>
      'Supports password-free ZIP archives.\nFor batch import, compress them into one archive.';

  @override
  String get subtitleLibraryGuide => 'Subtitle Library Usage Guide';

  @override
  String get subtitleLibraryFunction => 'Subtitle Library Function';

  @override
  String get subtitleLibraryFunctionDesc =>
      'Stores imported/saved subtitle files, supports auto/manual loading during playback';

  @override
  String get subtitleAutoLoad => 'Subtitle Auto-load';

  @override
  String get subtitleAutoLoadDesc =>
      'When playing audio, the system automatically searches for matching subtitles:';

  @override
  String get smartCategoryAndMark => 'Smart Categorization & Marking';

  @override
  String get open => 'Open';

  @override
  String get moveTo => 'Move to';

  @override
  String get rename => 'Rename';

  @override
  String get newName => 'New name';

  @override
  String get renameSuccess => 'Rename successful';

  @override
  String get renameFailed => 'Rename failed';

  @override
  String deleteItemConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deleteFolderContentsWarning =>
      'This will delete all contents in the folder.';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String subtitleLoaded(String title) {
    return 'Subtitle loaded: $title';
  }

  @override
  String get moveSuccess => 'Move successful';

  @override
  String get moveFailed => 'Move failed';

  @override
  String previewFailed(String error) {
    return 'Preview failed: $error';
  }

  @override
  String openFailed(String error) {
    return 'Open failed: $error';
  }

  @override
  String get back => 'Back';

  @override
  String get subtitleLibraryEmpty => 'Subtitle library is empty';

  @override
  String get tapToImportSubtitle => 'Tap the + button to import subtitles';

  @override
  String get importSubtitle => 'Import Subtitle';

  @override
  String get sampleSubtitleContent => '♪ Sample subtitle content ♪';

  @override
  String get presetStyles => 'Preset Styles';

  @override
  String get backgroundOpacity => 'Background Opacity';

  @override
  String get colorSettings => 'Color Settings';

  @override
  String get shapeSettings => 'Shape Settings';

  @override
  String get cornerRadius => 'Corner Radius';

  @override
  String get horizontalPadding => 'Horizontal Padding';

  @override
  String get verticalPadding => 'Vertical Padding';

  @override
  String get resetStyle => 'Reset Style';

  @override
  String get resetStyleConfirm =>
      'Are you sure you want to restore the default style?';

  @override
  String get restoreDefaultStyle => 'Restore Default Style';

  @override
  String get reset => 'Reset';

  @override
  String noBlockedItemsOfType(String type) {
    return 'No blocked $type';
  }

  @override
  String unblockedItem(String item) {
    return 'Unblocked: $item';
  }

  @override
  String addBlockedItem(String type) {
    return 'Add Blocked $type';
  }

  @override
  String blockedItemName(String type) {
    return '$type name';
  }

  @override
  String enterBlockedItemHint(String type) {
    return 'Enter $type to block';
  }

  @override
  String blockedItemAdded(String item) {
    return 'Blocked: $item';
  }

  @override
  String workCountLabel(int count) {
    return 'Works: $count';
  }

  @override
  String get miniPlayer => 'Mini Player';

  @override
  String get lineHeight => 'Line Height';

  @override
  String get portraitPlayerBelowCover => 'Portrait Player (Below Cover)';

  @override
  String get fullscreenSubtitleMode =>
      'Fullscreen Subtitle (Portrait/Landscape)';

  @override
  String get activeSubtitleFontSize => 'Active subtitle size';

  @override
  String get inactiveSubtitleFontSize => 'Inactive subtitle size';

  @override
  String get restoreDefaultSettings => 'Restore Default Settings';

  @override
  String get confirmRestoreDefaultSettings =>
      'Are you sure you want to restore the default settings?';

  @override
  String get guideInPrefix => 'In ';

  @override
  String get guideParsedFolder => '<Parsed>';

  @override
  String get guideFindWorkDesc =>
      ' folder, find matching works\nSupported folder format: RJ123456';

  @override
  String get guideSavedFolder => '<Saved>';

  @override
  String get guideFindSubtitleDesc => ' folder, find individual subtitle files';

  @override
  String get guideMatchRule =>
      'Matching rule: subtitle filename matches audio filename (with or without audio extension)';

  @override
  String get guideRecognizedWorkPrefix => 'Recognized works get a green ';

  @override
  String get guideTagSuffix => ' tag, and audio file icons get a ';

  @override
  String get guideSubtitleMatchSuffix =>
      ' mark, indicating subtitle library match';

  @override
  String get guideAutoRecognizeRJ =>
      'Auto-recognize RJ format on import, categorize to <Parsed>';

  @override
  String get guideAutoAddRJPrefix =>
      'Pure numeric folders auto-add RJ prefix (e.g. 123456 → RJ123456)';

  @override
  String get unknownFile => 'Unknown file';

  @override
  String deleteWithCount(int count) {
    return 'Delete ($count)';
  }

  @override
  String get searchSubtitles => 'Search subtitles...';

  @override
  String nFilesWithSize(int count, String size) {
    return '$count files • $size';
  }

  @override
  String get rootDirectory => 'Root';

  @override
  String get goToParent => 'Go to parent';

  @override
  String moveToTarget(String name) {
    return 'Move to: $name';
  }

  @override
  String get noSubfoldersHere => 'No subfolders in this directory';

  @override
  String addedToPlaylist(String name) {
    return 'Added to playlist \"$name\"';
  }

  @override
  String removedFromPlaylist(String name) {
    return 'Removed from playlist \"$name\"';
  }

  @override
  String get alreadyFavorited => 'Favorited';

  @override
  String loadImageFailedWithError(String error) {
    return 'Failed to load image\n$error';
  }

  @override
  String get noImageAvailable => 'No image available';

  @override
  String get storagePermissionRequiredForImage =>
      'Storage permission required to save images';

  @override
  String get savedToGallery => 'Saved to gallery';

  @override
  String get saveCoverImage => 'Save Cover Image';

  @override
  String savedToPath(String path) {
    return 'Saved to: $path';
  }

  @override
  String get doubleTapToZoom => 'Double-tap to zoom · Pinch to scale';

  @override
  String getStatusFailed(String error) {
    return 'Failed to get status: $error';
  }

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String deletePlayRecordConfirm(String title) {
    return 'Are you sure you want to delete the play record for \"$title\"?';
  }

  @override
  String get notPlayedYet => 'Not played yet';

  @override
  String playbackFailed(String error) {
    return 'Playback failed: $error';
  }

  @override
  String get storagePermissionRequired => 'Storage Permission Required';

  @override
  String get storagePermissionForGalleryDesc =>
      'Permission to access the photo gallery is required to save images. Please grant permission in settings.';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get imageSavedToGallery => 'Image saved to gallery';

  @override
  String imageSavedToPath(String path) {
    return 'Image saved to: $path';
  }

  @override
  String get pullDownForNextPage => 'Pull down to go to next page';

  @override
  String get releaseForNextPage => 'Release to go to next page';

  @override
  String get jumpTo => 'Jump';

  @override
  String get goToPageTitle => 'Go to Page';

  @override
  String pageNumberRange(int max) {
    return 'Page (1-$max)';
  }

  @override
  String get enterPageNumber => 'Enter page number';

  @override
  String enterValidPageNumber(int max) {
    return 'Please enter a valid page number (1-$max)';
  }

  @override
  String get previousPage => 'Previous';

  @override
  String get nextPage => 'Next';

  @override
  String get localPdfNotExist => 'Local PDF file does not exist';

  @override
  String get cannotOpenPdf => 'Cannot open PDF file';

  @override
  String loadPdfFailed(String error) {
    return 'Failed to load PDF: $error';
  }

  @override
  String pdfPageOfTotal(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get loadingPdf => 'Loading PDF...';

  @override
  String get pdfPathInvalid => 'PDF file path is invalid';

  @override
  String get desktopPdfPreviewNotSupported =>
      'Desktop PDF preview is not yet supported';

  @override
  String get openWithSystemApp => 'Open with system default app';

  @override
  String renderPdfFailed(String error) {
    return 'PDF rendering failed: $error';
  }

  @override
  String get ratingDetails => 'Rating Details';

  @override
  String get selectSaveDirectory => 'Select Save Directory';

  @override
  String get noSubtitleContentToSave => 'No subtitle content to save';

  @override
  String get savedToSubtitleLibrary => 'Saved to subtitle library';

  @override
  String get translatedLyricsNotSaved =>
      'Translation complete; shown only during current playback.';

  @override
  String get saveToLocal => 'Save to Local';

  @override
  String get selectDirectoryToSaveFile => 'Select directory to save file';

  @override
  String get saveToSubtitleLibrary => 'Save to Subtitle Library';

  @override
  String get saveToSubtitleLibraryDesc =>
      'Save to the \"Saved\" folder in subtitle library';

  @override
  String get saveToFile => 'Save to file';

  @override
  String get noContentToSave => 'No content to save';

  @override
  String fileSavedToPath(String path) {
    return 'File saved to: $path';
  }

  @override
  String get localFileNotExist =>
      'Local file does not exist, please try reloading';

  @override
  String loadTextFailed(String error) {
    return 'Failed to load text: $error';
  }

  @override
  String get previewMode => 'Preview Mode';

  @override
  String get editMode => 'Edit Mode';

  @override
  String get showOriginal => 'Show Original';

  @override
  String get translateContent => 'Translate Content';

  @override
  String get editTextContentHint => 'Edit text content...';

  @override
  String get markButton => 'Mark';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String setProgressAndRating(String progress, int rating) {
    return 'Set to: $progress, rating: $rating stars';
  }

  @override
  String setProgressTo(String progress) {
    return 'Set to: $progress';
  }

  @override
  String ratingSetTo(int rating) {
    return 'Rating set to: $rating stars';
  }

  @override
  String get updated => 'Updated';

  @override
  String addTagFailed(String error) {
    return 'Failed to add tag: $error';
  }

  @override
  String addWithCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get undo => 'Undo';

  @override
  String nStars(int count) {
    return '$count stars';
  }

  @override
  String get voteRemoved => 'Vote removed';

  @override
  String get votedUp => 'Voted up';

  @override
  String get votedDown => 'Voted down';

  @override
  String voteFailedWithError(String error) {
    return 'Vote failed: $error';
  }

  @override
  String get voteFor => 'Support';

  @override
  String get voteAgainst => 'Against';

  @override
  String get voted => 'Voted';

  @override
  String tagBlockedWithName(String name) {
    return 'Tag blocked: $name';
  }

  @override
  String get subtitleParseFailedUnsupportedFormat =>
      'Parse failed, unsupported format';

  @override
  String get lyricPresetDynamic => 'Dynamic';

  @override
  String get lyricPresetClassic => 'Classic';

  @override
  String get lyricPresetModern => 'Modern';

  @override
  String get lyricPresetMinimal => 'Minimal';

  @override
  String get lyricPresetVibrant => 'Vibrant';

  @override
  String get lyricPresetElegant => 'Elegant';

  @override
  String get lyricPresetDynamicDesc => 'Follows system theme, auto color';

  @override
  String get lyricPresetClassicDesc => 'Black background, white text, classic';

  @override
  String get lyricPresetModernDesc => 'Gradient background, stylish modern';

  @override
  String get lyricPresetMinimalDesc => 'Light transparent, simple and elegant';

  @override
  String get lyricPresetVibrantDesc => 'Vivid colors, full of energy';

  @override
  String get lyricPresetElegantDesc => 'Deep blue, refined elegance';

  @override
  String get floatingLyricLoading => '♪ Loading subtitle ♪';

  @override
  String get subtitleFileNotExist => 'File does not exist';

  @override
  String get subtitleMissingInfo => 'Missing required info';

  @override
  String get privacyDefaultTitle => 'Playing Audio';

  @override
  String get offlineModeStartup =>
      'Network connection failed, starting in offline mode';

  @override
  String get playlistInfoNotLoaded => 'Playlist info not loaded';

  @override
  String get encodingUnrecognized =>
      'File encoding unrecognized, cannot display content correctly';

  @override
  String editPlaylistFailed(String error) {
    return 'Failed to edit playlist: $error';
  }

  @override
  String unsupportedFileTypeWithTitle(String title) {
    return 'Cannot open this file type: $title';
  }

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get restoredToDefault => 'Restored to default settings';

  @override
  String get restoreDefault => 'Restore Default';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get addAtLeastOneSearchCondition =>
      'Please add at least one search condition';

  @override
  String get privacyModeSettingsTitle => 'Privacy Mode Settings';

  @override
  String get whatIsPrivacyMode => 'What is Privacy Mode?';

  @override
  String get privacyModeDescription =>
      'When enabled, playback information displayed in system notifications, lock screen, etc. will be blurred to protect your privacy.';

  @override
  String get enablePrivacyMode => 'Enable Privacy Mode';

  @override
  String get privacyModeEnabledSubtitle =>
      'Enabled - Playback info will be hidden';

  @override
  String get privacyModeDisabledSubtitle =>
      'Disabled - Playback info displayed normally';

  @override
  String get blurOptions => 'Blur Options';

  @override
  String get blurNotificationCover => 'Blur Notification Cover';

  @override
  String get blurNotificationCoverSubtitle =>
      'Apply blur to cover art in system notifications, lock screen, or control center';

  @override
  String get blurInAppCover => 'Blur In-App Cover';

  @override
  String get blurInAppCoverSubtitle =>
      'Blur cover art in player, lists, and other screens';

  @override
  String get replaceTitle => 'Replace Title';

  @override
  String get replaceTitleSubtitle => 'Replace real title with a custom title';

  @override
  String get replaceTitleContent => 'Replacement Title Content';

  @override
  String get setReplaceTitle => 'Set Replacement Title';

  @override
  String get enterDisplayTitle => 'Enter the title to display';

  @override
  String get replaceTitleSaved => 'Replacement title saved';

  @override
  String get effectExample => 'Example';

  @override
  String get downloadPathSettings => 'Download Path Settings';

  @override
  String loadPathFailedWithError(String error) {
    return 'Failed to load path: $error';
  }

  @override
  String get platformNotSupportCustomPath =>
      'Custom download path is not supported on this platform';

  @override
  String activeDownloadsWarning(int count) {
    return '$count download tasks are in progress. Please cancel or complete them before switching paths';
  }

  @override
  String setPathFailedWithError(String error) {
    return 'Failed to set path: $error';
  }

  @override
  String get confirmMigrateFiles => 'Confirm File Migration';

  @override
  String get migrateFilesToNewDir =>
      'Existing downloaded files will be migrated to the new directory:';

  @override
  String get migrationMayTakeTime =>
      'This operation may take some time depending on the number and size of files.';

  @override
  String get confirmMigrate => 'Confirm Migration';

  @override
  String get restoreDefaultPath => 'Restore Default Path';

  @override
  String get restoreDefaultPathConfirm =>
      'Restore download path to default location and migrate all files.\n\nContinue?';

  @override
  String get defaultPathRestored => 'Default path restored';

  @override
  String resetPathFailedWithError(String error) {
    return 'Failed to restore default path: $error';
  }

  @override
  String get migratingFiles => 'Migrating files...';

  @override
  String get doNotCloseApp => 'Please do not close the app';

  @override
  String get currentDownloadPath => 'Current Download Path';

  @override
  String get customPath => 'Custom Path';

  @override
  String get defaultPath => 'Default Path';

  @override
  String get changeCustomPath => 'Change Custom Path';

  @override
  String get setCustomPath => 'Set Custom Path';

  @override
  String get usageInstructions => 'Usage Instructions';

  @override
  String get downloadPathUsageDesc =>
      '• After customizing the path, all existing files will be automatically migrated\n• Do not close the app during migration\n• Choose a directory with sufficient storage space\n• When restoring the default path, files will be migrated back automatically';

  @override
  String get llmTranslationSettings => 'LLM Translation Settings';

  @override
  String get apiEndpointUrl => 'API Endpoint URL';

  @override
  String get openaiCompatibleEndpoint => 'OpenAI-compatible endpoint URL';

  @override
  String get pleaseEnterApiUrl => 'Please enter API endpoint URL';

  @override
  String get pleaseEnterValidUrl => 'Please enter a valid URL';

  @override
  String get pleaseEnterApiKey => 'Please enter API Key';

  @override
  String get modelName => 'Model Name';

  @override
  String get pleaseEnterModelName => 'Please enter model name';

  @override
  String get concurrencyCount => 'Concurrency';

  @override
  String get concurrencyDescription =>
      'Number of concurrent translation requests, recommended 3-5';

  @override
  String get promptSection => 'Prompt';

  @override
  String get promptDescription =>
      'Since the system uses chunked translation, please ensure the prompt clearly instructs to output only translation results without any explanation.';

  @override
  String get enterSystemPrompt => 'Enter system prompt...';

  @override
  String get pleaseEnterPrompt => 'Please enter a prompt';

  @override
  String get restoreDefaultPrompt => 'Restore Default Prompt';

  @override
  String get confirmRestoreButtonOrder =>
      'Are you sure you want to restore the default button order?';

  @override
  String get buttonDisplayRules => 'Button Display Rules';

  @override
  String buttonDisplayRulesDesc(int maxVisible) {
    return '• The first $maxVisible buttons will be shown at the bottom of the player\n• The remaining buttons will be in the \"More\" menu';
  }

  @override
  String get shownInPlayer => 'Shown in player';

  @override
  String get shownInMoreMenu => 'Shown in More menu';

  @override
  String get audioFormatPriority => 'Audio Format Priority';

  @override
  String get confirmRestoreAudioFormat =>
      'Are you sure you want to restore the default audio format priority?';

  @override
  String get priorityDescription => 'Priority Description';

  @override
  String get audioFormatPriorityDesc =>
      '• When opening a work\'s detail page, the folder with the highest priority audio format will be expanded first';

  @override
  String get ratingInfo => 'Rating Info';

  @override
  String get showRatingAndReviewCount => 'Show work rating and review count';

  @override
  String get priceInfo => 'Price Info';

  @override
  String get showWorkPrice => 'Show work price';

  @override
  String get durationInfo => 'Duration Info';

  @override
  String get showWorkDuration => 'Show work duration';

  @override
  String get showWorkTotalDuration => 'Show total work duration';

  @override
  String get salesInfo => 'Sales Info';

  @override
  String get showWorkSalesCount => 'Show work sales count';

  @override
  String get externalLinkInfo => 'External Links';

  @override
  String get showExternalLinks =>
      'Show external links such as DLsite, official website, etc.';

  @override
  String get releaseDateInfo => 'Release Date';

  @override
  String get showWorkReleaseDate => 'Show work release date';

  @override
  String get translateButtonLabel => 'Translate Button';

  @override
  String get showTranslateButton => 'Show translate button for work title';

  @override
  String get subtitleTagLabel => 'Subtitle Tag';

  @override
  String get showSubtitleTagOnCover => 'Show subtitle tag on cover image';

  @override
  String get showAgeRatingOnDetail => 'Show age rating on work detail page';

  @override
  String get recommendationsLabel => 'Related Recommendations';

  @override
  String get showRecommendations =>
      'Show related recommendations on work detail page';

  @override
  String get circleInfo => 'Circle Info';

  @override
  String get showWorkCircle => 'Show work\'s circle';

  @override
  String get workCardSizeSubtitle =>
      'Adjust grid density to make covers larger or keep the current size';

  @override
  String get workCardFontSize => 'Card Text Size';

  @override
  String get workCardFontSizeSubtitle =>
      'Adjust title and metadata text on work cards';

  @override
  String get cardSizeNormal => 'Normal';

  @override
  String get cardSizeLarge => 'Large';

  @override
  String get cardSizeExtraLarge => 'XL';

  @override
  String get fontSizeNormal => 'Normal';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeExtraLarge => 'XL';

  @override
  String get showSubtitleTagOnCard => 'Show subtitle tag on work card';

  @override
  String get showAgeRatingOnCard => 'Show age rating on work card';

  @override
  String get showOnlineMarks => 'Show online marked works';

  @override
  String get cannotBeDisabled => 'Cannot be disabled';

  @override
  String get showPlaylists => 'Show created playlists';

  @override
  String get showSubtitleLibrary => 'Show subtitle library management';

  @override
  String get playlistPrivacyPrivateDesc => 'Only you can view';

  @override
  String get playlistPrivacyUnlistedDesc =>
      'Only people with the link can view';

  @override
  String get playlistPrivacyPublicDesc => 'Anyone can view';

  @override
  String get clearTranslationCache => 'Clear Translation Cache';

  @override
  String get translationCacheCleared => 'Translation cache cleared';

  @override
  String get platformHintAndroid =>
      'Android: System file picker will be used, storage permission may be required';

  @override
  String get platformHintIOS =>
      'iOS: Due to system restrictions, the default path is used. Files can be accessed via the system file manager';

  @override
  String get platformHintWindows =>
      'Windows: Any accessible directory can be selected';

  @override
  String get platformHintMacOS =>
      'macOS: Any accessible directory can be selected';

  @override
  String get platformHintLinux =>
      'Linux: Any accessible directory can be selected';

  @override
  String get platformHintDefault =>
      'Select a directory to save downloaded files';

  @override
  String get subtitleFolderParsed => 'Parsed';

  @override
  String get subtitleFolderSaved => 'Saved';

  @override
  String get subtitleFolderUnknown => 'Unknown Works';

  @override
  String get sortDownloadDate => 'Download Date';

  @override
  String get sortWorkId => 'ID';

  @override
  String get searchDownloads => 'Search downloaded works...';

  @override
  String get logTitle => 'App Logs';

  @override
  String get logSubtitle => 'View and export app logs';

  @override
  String get logSearchHint => 'Search logs...';

  @override
  String get logFilterAll => 'All';

  @override
  String get logCopy => 'Copy Logs';

  @override
  String get logExport => 'Export Log File';

  @override
  String get logClear => 'Clear Logs';

  @override
  String get logCopied => 'Logs copied to clipboard';

  @override
  String logExported(String path) {
    return 'Logs exported to $path';
  }

  @override
  String logCount(int count) {
    return '$count entries';
  }

  @override
  String get logAutoScroll => 'Auto scroll';

  @override
  String get logEmpty => 'No logs yet';

  @override
  String get proxySettingsOptional => 'Proxy';

  @override
  String get loginAdvancedSettings => 'Advanced settings';

  @override
  String proxyEnabled(String address) {
    return 'Enabled: $address';
  }

  @override
  String get proxyAddressNotSet => 'Not set (direct connection)';

  @override
  String get proxyHttpDescription => 'Connect through an HTTP proxy';

  @override
  String get useProxy => 'Use proxy';

  @override
  String get proxyAddress => 'Proxy address';

  @override
  String get proxyAddressFormat =>
      'Format: host:port, for example 127.0.0.1:7890';

  @override
  String get applyProxyAddress => 'Apply proxy address';

  @override
  String get invalidProxyAddress => 'Enter a valid HTTP proxy address and port';

  @override
  String get playlistDisplayFormat => 'Playlist layout';

  @override
  String get playlistDisplayFormatMasonry => 'Masonry';

  @override
  String get playlistDisplayFormatList => 'List';
}
