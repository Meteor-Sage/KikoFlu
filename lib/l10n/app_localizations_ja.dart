// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'KikoFlu';

  @override
  String get navHome => 'ホーム';

  @override
  String get navSearch => '検索';

  @override
  String get navMy => 'マイ';

  @override
  String get navSettings => '設定';

  @override
  String get offlineModeMessage =>
      'オフラインモード：ネットワーク接続に失敗しました。ダウンロード済みコンテンツのみアクセスできます';

  @override
  String get retry => '再試行';

  @override
  String get searchTypeKeyword => 'キーワード';

  @override
  String get searchTypeTag => 'タグ';

  @override
  String get searchTypeVa => '声優';

  @override
  String get searchTypeCircle => 'サークル';

  @override
  String get searchTypeRjNumber => 'RJ番号';

  @override
  String get searchHintKeyword => '作品名やキーワードを入力...';

  @override
  String get searchHintTag => 'タグ名を入力...';

  @override
  String get searchHintVa => '声優名を入力...';

  @override
  String get searchHintCircle => 'サークル名を入力...';

  @override
  String get searchHintRjNumber => '番号を入力...';

  @override
  String get ageRatingAll => 'すべて';

  @override
  String get ageRatingGeneral => '全年齢';

  @override
  String get ageRatingR15 => 'R-15';

  @override
  String get ageRatingAdult => '成人向け';

  @override
  String get salesRangeAll => 'すべて';

  @override
  String get sortRelease => '発売日';

  @override
  String get sortCreateAt => '追加日';

  @override
  String get sortCreateDate => '登録日';

  @override
  String get sortRating => '評価';

  @override
  String get sortReviewCount => 'レビュー数';

  @override
  String get sortRandom => 'ランダム';

  @override
  String get sortDlCount => '販売数';

  @override
  String get sortPrice => '価格';

  @override
  String get sortNsfw => '全年齢';

  @override
  String get sortUpdatedAt => 'マーク日時';

  @override
  String get sortAsc => '昇順';

  @override
  String get sortDesc => '降順';

  @override
  String get sortOptions => '並べ替えオプション';

  @override
  String get sortField => '並べ替え項目';

  @override
  String get sortDirection => '並べ替え方向';

  @override
  String get displayModeAll => 'すべて';

  @override
  String get displayModePopular => '人気';

  @override
  String get displayModeRecommended => 'おすすめ';

  @override
  String get subtitlePriorityHighest => '優先';

  @override
  String get subtitlePriorityLowest => '後回し';

  @override
  String get translationSourceGoogle => 'Google 翻訳';

  @override
  String get translationSourceYoudao => 'Youdao 翻訳';

  @override
  String get translationSourceMicrosoft => 'Microsoft 翻訳';

  @override
  String get translationSourceLlm => 'LLM 翻訳';

  @override
  String get progressMarked => '気になる';

  @override
  String get progressListening => '聴取中';

  @override
  String get progressListened => '聴取済み';

  @override
  String get progressReplay => '再聴';

  @override
  String get progressPostponed => '保留';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get register => '登録';

  @override
  String get addAccount => 'アカウント追加';

  @override
  String get registerAccount => 'アカウント登録';

  @override
  String get username => 'ユーザー名';

  @override
  String get password => 'パスワード';

  @override
  String get serverAddress => 'サーバーアドレス';

  @override
  String get serverCookie => 'サーバークッキー';

  @override
  String get login => 'ログイン';

  @override
  String get loginSuccess => 'ログイン成功';

  @override
  String get loginFailed => 'ログイン失敗';

  @override
  String get registerFailed => '登録失敗';

  @override
  String get usernameMinLength => 'ユーザー名は5文字以上必要です';

  @override
  String get passwordMinLength => 'パスワードは5文字以上必要です';

  @override
  String accountAdded(String username) {
    return 'アカウント「$username」が追加されました';
  }

  @override
  String get testConnection => '接続テスト';

  @override
  String get testing => 'テスト中...';

  @override
  String get enterServerAddressToTest => 'サーバーアドレスを入力して接続テストしてください';

  @override
  String latencyMs(String ms) {
    return '${ms}ms';
  }

  @override
  String get connectionFailed => '接続失敗';

  @override
  String get guestModeTitle => 'ゲストモードの確認';

  @override
  String get guestModeMessage =>
      'ゲストモードは機能が制限されています：\n\n• 作品のマークや評価ができません\n• プレイリストの作成ができません\n• 進捗の同期ができません\n\nゲストモードはデモアカウントでサーバーに接続するため、不安定になる場合があります。';

  @override
  String get continueGuestMode => 'ゲストモードで続行';

  @override
  String get guestAccountAdded => 'ゲストアカウントが追加されました';

  @override
  String get guestLoginFailed => 'ゲストログイン失敗';

  @override
  String get guestMode => 'ゲストモード';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確定';

  @override
  String get close => '閉じる';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get edit => '編集';

  @override
  String get add => '追加';

  @override
  String get create => '作成';

  @override
  String get ok => 'OK';

  @override
  String get search => '検索';

  @override
  String get filter => 'フィルター';

  @override
  String get advancedFilter => '詳細フィルター';

  @override
  String get enterSearchContent => '検索内容を入力してください';

  @override
  String get searchTag => 'タグを検索...';

  @override
  String get minRating => '最低評価';

  @override
  String minRatingStars(String stars) {
    return '$starsつ星';
  }

  @override
  String get searchHistory => '検索履歴';

  @override
  String get clearSearchHistory => '検索履歴をクリア';

  @override
  String get clearSearchHistoryConfirm => 'すべての検索履歴をクリアしますか？';

  @override
  String get clear => 'クリア';

  @override
  String get searchHistoryCleared => '検索履歴をクリアしました';

  @override
  String get noSearchHistory => '検索履歴はありません';

  @override
  String get excludeMode => '除外';

  @override
  String get includeMode => '含む';

  @override
  String includeModeTapAgainHint(String searchType) {
    return '含む：$searchType（もう一度タップすると除外モードに切り替わります）';
  }

  @override
  String get noResults => '結果なし';

  @override
  String get loadFailed => '読み込み失敗';

  @override
  String loadFailedWithError(String error) {
    return '読み込み失敗: $error';
  }

  @override
  String get loading => '読み込み中...';

  @override
  String get calculating => '計算中...';

  @override
  String get getFailed => '取得失敗';

  @override
  String get settingsTitle => '設定';

  @override
  String get accountManagement => 'アカウント管理';

  @override
  String get accountManagementSubtitle => 'マルチアカウント管理、アカウント切り替え';

  @override
  String get privacyMode => 'プライバシーモード';

  @override
  String get privacyModeEnabled => '有効 - 再生情報が非表示';

  @override
  String get privacyModeDisabled => '無効';

  @override
  String get permissionManagement => '権限管理';

  @override
  String get permissionManagementSubtitle => '通知権限、バックグラウンド実行権限';

  @override
  String get desktopFloatingLyric => 'デスクトップフローティング字幕';

  @override
  String get floatingLyricEnabled => '有効 - 字幕がデスクトップに表示されます';

  @override
  String get floatingLyricDisabled => '無効';

  @override
  String get floatingLyricTouch => 'フローティング字幕ロック';

  @override
  String get floatingLyricTouchEnabled => 'ロック解除 - ドラッグ可能、長押しでロック';

  @override
  String get floatingLyricTouchDisabled => 'ロック中 - 長押しでロック解除';

  @override
  String get floatingLyricClickThrough => 'フローティング字幕のクリック透過';

  @override
  String get floatingLyricClickThroughEnabled => '有効 - フローティング字幕がマウス操作を無視します';

  @override
  String get floatingLyricClickThroughDisabled => '無効 - フローティング字幕をドラッグできます';

  @override
  String get floatingFPS => 'FPS表示';

  @override
  String get floatingFPSEnabled => 'オン - フローティングウィンドウの左下にFPSを表示';

  @override
  String get floatingFPSDisabled => 'オフ';

  @override
  String get floatingNetworkSpeed => '通信速度表示';

  @override
  String get floatingNetworkSpeedEnabled => 'オン - フローティングウィンドウの右下に通信速度を表示';

  @override
  String get floatingNetworkSpeedDisabled => 'オフ';

  @override
  String get styleSettings => 'スタイル設定';

  @override
  String get styleSettingsSubtitle => 'フォント、色、透明度などをカスタマイズ';

  @override
  String get downloadPath => 'ダウンロードパス';

  @override
  String get downloadPathSubtitle => 'ダウンロードファイルの保存先をカスタマイズ';

  @override
  String get maxConcurrentDownloads => '最大同時ダウンロード数';

  @override
  String get maxConcurrentDownloadsSubtitle => '同時に実行するダウンロードタスクの上限';

  @override
  String get cacheManagement => 'キャッシュ管理';

  @override
  String currentCache(String size) {
    return '現在のキャッシュ: $size';
  }

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get themeSettingsSubtitle => 'ダークモード、テーマカラーなど';

  @override
  String get uiSettings => 'UI設定';

  @override
  String get uiSettingsSubtitle => 'プレーヤー、詳細ページ、カードなど';

  @override
  String get liquidGlassNavigation => 'リキッドグラスナビゲーション';

  @override
  String get liquidGlassNavigationDesc =>
      'ガラス素材のナビゲーションとミニプレーヤー。Apple 系 OS 26 以降ではデフォルトで有効';

  @override
  String get fallbackGlassTransparency => 'リキッドグラスの透明度';

  @override
  String get fallbackGlassTransparencyDesc => 'アプリ描画のガラス透明度を調整';

  @override
  String get preferenceSettings => '環境設定';

  @override
  String get preferenceSettingsSubtitle => '翻訳、再生、ネットワーク';

  @override
  String get aboutTitle => 'について';

  @override
  String get unknownVersion => '不明';

  @override
  String get licenseLoadFailed => 'LICENSEファイルの読み込みに失敗しました';

  @override
  String get licenseEmpty => 'LICENSEの内容が空です';

  @override
  String get failedToLoadAbout => '概要情報の読み込みに失敗しました';

  @override
  String get newVersionFound => '新バージョンが見つかりました';

  @override
  String newVersionAvailable(String version, String current) {
    return '$version が利用可能です（現在: $current）';
  }

  @override
  String get versionInfo => 'バージョン情報';

  @override
  String currentVersion(String version) {
    return '現在のバージョン: $version';
  }

  @override
  String get checkUpdate => 'アップデートを確認';

  @override
  String get author => '作者';

  @override
  String get projectRepo => 'プロジェクトリポジトリ';

  @override
  String get openSourceLicense => 'オープンソースライセンス';

  @override
  String get cannotOpenLink => 'リンクを開けません';

  @override
  String openLinkFailed(String error) {
    return 'リンクを開けませんでした: $error';
  }

  @override
  String foundNewVersion(String version) {
    return '新バージョン $version が見つかりました';
  }

  @override
  String get view => '表示';

  @override
  String get alreadyLatestVersion => '最新バージョンです';

  @override
  String get checkUpdateFailed => 'アップデートの確認に失敗しました。ネットワーク接続を確認してください';

  @override
  String get onlineMarks => 'オンラインマーク';

  @override
  String get historyRecord => '再生履歴';

  @override
  String get playlists => 'プレイリスト';

  @override
  String get downloaded => 'ダウンロード済み';

  @override
  String get downloadTasks => 'ダウンロードタスク';

  @override
  String get subtitleLibrary => '字幕ライブラリ';

  @override
  String get all => 'すべて';

  @override
  String get marked => '気になる';

  @override
  String get listening => '聴取中';

  @override
  String get listened => '聴取済み';

  @override
  String get replayMark => '再聴';

  @override
  String get postponed => '保留';

  @override
  String get switchToSmallGrid => '小グリッド表示に切り替え';

  @override
  String get switchToList => 'リスト表示に切り替え';

  @override
  String get switchToLargeGrid => '大グリッド表示に切り替え';

  @override
  String get sort => '並べ替え';

  @override
  String get noPlayHistory => '再生履歴はありません';

  @override
  String get clearHistory => '履歴をクリア';

  @override
  String get clearHistoryTitle => '履歴をクリア';

  @override
  String get clearHistoryConfirm => 'すべての再生履歴をクリアしますか？この操作は取り消せません。';

  @override
  String get popularNoSort => '人気モードでは並べ替えできません';

  @override
  String get recommendedNoSort => 'おすすめモードでは並べ替えできません';

  @override
  String get showAllWorks => 'すべての作品を表示';

  @override
  String get showOnlySubtitled => '字幕付き作品のみ表示';

  @override
  String selectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get selectAll => 'すべて選択';

  @override
  String get deselectAll => '選択解除';

  @override
  String get select => '選択';

  @override
  String get noDownloadTasks => 'ダウンロードタスクはありません';

  @override
  String nFiles(int count) {
    return '$countファイル';
  }

  @override
  String errorWithMessage(String error) {
    return 'エラー: $error';
  }

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get deletionConfirmTitle => '削除の確認';

  @override
  String deletionConfirmMessage(int count) {
    return '選択した$count件のダウンロードタスクを削除しますか？ダウンロード済みファイルも削除されます。';
  }

  @override
  String deletedNFiles(int count) {
    return '$countファイルを削除しました';
  }

  @override
  String get downloadStatusPending => '待機中';

  @override
  String get downloadStatusDownloading => 'ダウンロード中';

  @override
  String get downloadStatusCompleted => '完了';

  @override
  String get downloadStatusFailed => '失敗';

  @override
  String get downloadStatusPaused => '一時停止中';

  @override
  String translationFailed(String error) {
    return '翻訳失敗: $error';
  }

  @override
  String copiedToClipboard(String label, String text) {
    return '$labelをコピーしました：$text';
  }

  @override
  String get loadingFileList => 'ファイルリストを読み込み中...';

  @override
  String loadFileListFailed(String error) {
    return 'ファイルリストの読み込みに失敗: $error';
  }

  @override
  String get playlistTitle => 'プレイリスト';

  @override
  String get noAudioPlaying => '再生中のオーディオはありません';

  @override
  String get playbackSpeed => '再生速度';

  @override
  String get backward10s => '10秒戻る';

  @override
  String get forward10s => '10秒進む';

  @override
  String get sleepTimer => 'スリープタイマー';

  @override
  String get repeatMode => 'リピートモード';

  @override
  String get repeatOff => 'オフ';

  @override
  String get repeatOne => '1曲リピート';

  @override
  String get repeatAll => '全曲リピート';

  @override
  String get addMark => 'マーク追加';

  @override
  String get viewDetail => '詳細を見る';

  @override
  String get volume => '音量';

  @override
  String get sleepTimerTitle => 'タイマー';

  @override
  String get aboutToStop => 'まもなく停止';

  @override
  String get remainingTime => '残り時間';

  @override
  String get finishCurrentTrack => '現在のトラック終了後に停止';

  @override
  String addMinutes(int min) {
    return '+$min分';
  }

  @override
  String get cancelTimer => 'タイマーをキャンセル';

  @override
  String get duration => '長さ';

  @override
  String get specifyTime => '時刻指定';

  @override
  String get selectTimerDuration => 'タイマーの長さを選択';

  @override
  String get selectStopTime => '再生を停止する時刻を選択';

  @override
  String get markWork => '作品をマーク';

  @override
  String get addToPlaylist => 'プレイリストに追加';

  @override
  String get remove => '削除';

  @override
  String get createPlaylist => 'プレイリストを作成';

  @override
  String get addPlaylist => 'プレイリストを追加';

  @override
  String get playlistName => 'プレイリスト名';

  @override
  String get enterPlaylistName => '名前を入力';

  @override
  String get privacySetting => 'プライバシー設定';

  @override
  String get playlistDescription => '説明（任意）';

  @override
  String get addDescription => '説明を追加';

  @override
  String get enterPlaylistNameWarning => 'プレイリスト名を入力してください';

  @override
  String get enterPlaylistLink => 'プレイリストのリンクを入力してください';

  @override
  String get switchAccountTitle => 'アカウント切り替え';

  @override
  String switchAccountConfirm(String username) {
    return 'アカウント「$username」に切り替えますか？';
  }

  @override
  String switchedToAccount(String username) {
    return 'アカウントを切り替えました: $username';
  }

  @override
  String get switchFailed => '切り替え失敗。アカウント情報を確認してください';

  @override
  String switchFailedWithError(String error) {
    return '切り替え失敗: $error';
  }

  @override
  String get noAccounts => 'アカウントがありません';

  @override
  String get tapToAddAccount => '右下のボタンをタップしてアカウントを追加';

  @override
  String get currentAccount => '現在のアカウント';

  @override
  String get switchAction => '切替';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String deleteAccountConfirm(String username) {
    return 'アカウント「$username」を削除しますか？この操作は取り消せません。';
  }

  @override
  String get accountDeleted => 'アカウントを削除しました';

  @override
  String deletionFailedWithError(String error) {
    return '削除失敗: $error';
  }

  @override
  String get subtitleLibraryPriority => '字幕ライブラリの優先度';

  @override
  String get selectSubtitlePriority => '自動読み込みでの字幕ライブラリの優先度を選択：';

  @override
  String get subtitlePriorityHighestDesc => '字幕ライブラリを優先して検索';

  @override
  String get subtitlePriorityLowestDesc => 'オンライン/ダウンロードを優先して検索';

  @override
  String get defaultSortSettings => 'デフォルトの並べ替え設定';

  @override
  String get defaultSortUpdated => 'デフォルトの並べ替えを更新しました';

  @override
  String get translationSourceSettings => '翻訳ソース設定';

  @override
  String get selectTranslationProvider => '翻訳サービスプロバイダーを選択：';

  @override
  String get translationTargetLanguage => 'ターゲット言語';

  @override
  String get autoSaveTranslatedLyrics => '翻訳した歌詞を自動保存';

  @override
  String get autoSaveTranslatedLyricsDesc => '翻訳を字幕ライブラリに保存。オフでは一時表示のみ';

  @override
  String get selectTranslationTargetLanguage => 'ターゲット言語を選択：';

  @override
  String get translationLanguageFollowApp => 'アプリ言語に従う';

  @override
  String get translationLanguageZhHans => '簡体字中国語';

  @override
  String get translationLanguageZhHant => '繁体字中国語';

  @override
  String get translationLanguageEnglish => '英語';

  @override
  String get translationLanguageJapanese => '日本語';

  @override
  String get translationLanguageRussian => 'ロシア語';

  @override
  String get translationLanguageCustom => 'カスタム';

  @override
  String get translationCustomTargetLanguage => 'カスタムターゲット言語';

  @override
  String get translationCustomLanguageHint => '言語名、例: Korean';

  @override
  String translationCustomLanguageLabel(String value) {
    return 'カスタム: $value';
  }

  @override
  String get translationCustomTargetRequiresLlm => 'LLM翻訳が必要です';

  @override
  String get needsConfiguration => '設定が必要';

  @override
  String get llmTranslation => 'LLM翻訳';

  @override
  String get goToConfigure => '設定へ';

  @override
  String get subtitlePrioritySettingSubtitle => '字幕ライブラリの優先度';

  @override
  String get defaultSortSettingTitle => 'ホームのデフォルト並べ替え';

  @override
  String get translationSource => '翻訳ソース';

  @override
  String get llmSettings => 'LLM設定';

  @override
  String get llmSettingsSubtitle => 'API URL、キー、モデル';

  @override
  String get audioFormatPreference => 'オーディオフォーマット設定';

  @override
  String get audioFormatSubtitle => '音声形式の優先順位';

  @override
  String get audioTapPlaylistMode => 'プレイリストへの追加方法';

  @override
  String get selectAudioTapPlaylistMode => '音声をタップしたときのプレイリスト更新方法を選択：';

  @override
  String get audioTapPlaylistModeReplace => 'リスト全体を置き換え';

  @override
  String get audioTapPlaylistModeReplaceDescription =>
      'タップした音声と同じフォルダー内の再生可能な音声すべてで現在のプレイリストを置き換えます。';

  @override
  String get audioTapPlaylistModeAppendDirectory => 'フォルダー内を追加';

  @override
  String get audioTapPlaylistModeAppendDirectoryDescription =>
      'タップした音声と同じフォルダー内の再生可能な音声をすべて末尾に追加します。既存のトラックは重複しません。';

  @override
  String get audioTapPlaylistModeAppendSingle => 'タップした音声のみ追加';

  @override
  String get audioTapPlaylistModeAppendSingleDescription =>
      'タップした音声だけを末尾に追加します。既存のトラックは重複しません。';

  @override
  String get preloadNextTitle => '次をプリロード';

  @override
  String get preloadNextSubtitle => '現在のトラックが終わる前に次のトラックをキャッシュし、切り替え時の途切れを防ぐ';

  @override
  String get selectPreloadThreshold => '残り時間がこの閾値を下回ったらプリロードを開始：';

  @override
  String get preloadOptionOff => 'オフ';

  @override
  String preloadOptionSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get preloadOptionCustom => 'カスタム';

  @override
  String get preloadCustomInputTitle => 'カスタムプリロード閾値';

  @override
  String get preloadCustomInputHint => '秒数 (1-300)';

  @override
  String get preloadCustomInputRangeError => '1 から 300 までの数字を入力してください';

  @override
  String preloadCustomValueLabel(int value) {
    return '$value 秒';
  }

  @override
  String get keepScreenAwake => '画面を常にオン';

  @override
  String get keepScreenAwakeDesc => '再生中は画面を点灯';

  @override
  String get audioHaptics => 'オーディオ触覚フィードバック(Beta)';

  @override
  String get audioHapticsDesc => 'ダウンロード音声に合わせて振動（フォアグラウンドのみ）';

  @override
  String get audioHapticsIntensity => '強度';

  @override
  String get audioGain => 'グローバルオーディオゲイン';

  @override
  String get audioGainDesc => '0 dB は原音。過度な増幅は歪みや聴力障害の原因になります';

  @override
  String get audioGainAttenuationDesc => '全音声を減衰。0 dB は原音';

  @override
  String get audioGainPassthroughDesc => 'オーディオパススルー中は使用不可';

  @override
  String get blockingSettings => 'ブロック設定';

  @override
  String get blockingSettingsSubtitle => 'ブロック中のタグ、声優、サークル';

  @override
  String get audioPassthrough => 'オーディオパススルー(Beta)';

  @override
  String get audioPassthroughDescWindows => 'WASAPI 排他出力を使用（再起動が必要）';

  @override
  String get audioPassthroughDescMac => 'CoreAudio 排他出力を使用';

  @override
  String get audioPassthroughDisableDesc => 'オーディオパススルーモードを無効にする';

  @override
  String get warning => '警告';

  @override
  String get audioPassthroughWarning =>
      'この機能は十分にテストされておらず、予期しない音声出力などのリスクがあります。有効にしますか？';

  @override
  String get exclusiveModeEnabled => '排他モードを有効にしました（再起動後に反映）';

  @override
  String get audioPassthroughEnabled => 'オーディオパススルーモードを有効にしました';

  @override
  String get audioPassthroughDisabled => 'オーディオパススルーモードを無効にしました';

  @override
  String get tagVoteSupport => '賛成';

  @override
  String get tagVoteOppose => '反対';

  @override
  String get tagVoted => '投票済み';

  @override
  String get votedSupport => '賛成に投票しました';

  @override
  String get votedOppose => '反対に投票しました';

  @override
  String get voteCancelled => '投票を取り消しました';

  @override
  String voteFailed(String error) {
    return '投票失敗: $error';
  }

  @override
  String get blockThisTag => 'このタグをブロック';

  @override
  String get copyTag => 'タグをコピー';

  @override
  String get addTag => 'タグを追加';

  @override
  String loadTagsFailed(String error) {
    return 'タグの読み込みに失敗: $error';
  }

  @override
  String get selectAtLeastOneTag => 'タグを少なくとも1つ選択してください';

  @override
  String get tagSubmitSuccess => 'タグを送信しました、サーバー処理待ち';

  @override
  String get bindEmailFirst => 'www.asmr.one でメールアドレスを登録してください';

  @override
  String selectedNTags(int count) {
    return '$count個のタグを選択中:';
  }

  @override
  String get noMatchingTags => '一致するタグが見つかりません';

  @override
  String get loadFailedRetry => '読み込み失敗。タップして再試行';

  @override
  String get refresh => '更新';

  @override
  String get playlistPrivacyPrivate => '非公開';

  @override
  String get playlistPrivacyUnlisted => '限定公開';

  @override
  String get playlistPrivacyPublic => '公開';

  @override
  String get systemPlaylistMarked => 'マーク済み';

  @override
  String get systemPlaylistLiked => 'お気に入り';

  @override
  String totalNWorks(int count) {
    return '$count作品';
  }

  @override
  String pageNOfTotal(int current, int total) {
    return '$current / $total ページ';
  }

  @override
  String get translateTitle => '翻訳';

  @override
  String get translateDescription => '説明を翻訳';

  @override
  String get translating => '翻訳中...';

  @override
  String translationFallbackNotice(String source) {
    return '翻訳に失敗しました。$sourceに自動切り替えしました';
  }

  @override
  String get tagLabel => 'タグ';

  @override
  String get vaLabel => '声優';

  @override
  String get circleLabel => 'サークル';

  @override
  String get releaseDate => '発売日';

  @override
  String get ratingLabel => '評価';

  @override
  String get salesLabel => '販売数';

  @override
  String get priceLabel => '価格';

  @override
  String get durationLabel => '長さ';

  @override
  String get ageRatingLabel => '年齢区分';

  @override
  String get hasSubtitle => '字幕あり';

  @override
  String get noSubtitle => '字幕なし';

  @override
  String get description => '概要';

  @override
  String get fileList => 'ファイル一覧';

  @override
  String get series => 'シリーズ';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSubtitle => '表示言語を切り替え';

  @override
  String get languageSystem => 'システムに従う';

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
  String get themeModeDark => 'ダークモード';

  @override
  String get themeModeLight => 'ライトモード';

  @override
  String get themeModeSystem => 'システムに従う';

  @override
  String get colorSchemeOceanBlue => 'オーシャンブルー';

  @override
  String get colorSchemeForestGreen => 'フォレストグリーン';

  @override
  String get colorSchemeSunsetOrange => 'サンセットオレンジ';

  @override
  String get colorSchemeLavenderPurple => 'ラベンダーパープル';

  @override
  String get colorSchemeSakuraPink => 'サクラピンク';

  @override
  String get colorSchemeDynamic => 'ダイナミックカラー';

  @override
  String get noData => 'データなし';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get networkError => 'ネットワークエラー';

  @override
  String get timeout => 'リクエストタイムアウト';

  @override
  String get playAll => 'すべて再生';

  @override
  String get download => 'ダウンロード';

  @override
  String get downloadAll => 'すべてダウンロード';

  @override
  String get downloading => 'ダウンロード中';

  @override
  String get downloadComplete => 'ダウンロード完了';

  @override
  String get downloadFailed => 'ダウンロード失敗';

  @override
  String get startDownload => 'ダウンロード開始';

  @override
  String get confirmDeleteDownload => 'このダウンロードタスクを削除しますか？ダウンロード済みファイルも削除されます。';

  @override
  String get deletedSuccessfully => '削除しました';

  @override
  String get scanSubtitleLibrary => '字幕ライブラリをスキャン';

  @override
  String get scanning => 'スキャン中...';

  @override
  String get scanComplete => 'スキャン完了';

  @override
  String get noSubtitleFiles => '字幕ファイルが見つかりません';

  @override
  String subtitleFilesFound(int count) {
    return '$count個の字幕ファイルが見つかりました';
  }

  @override
  String get selectDirectory => 'ディレクトリを選択';

  @override
  String get privacyModeSettings => 'プライバシーモード設定';

  @override
  String get blurCover => 'カバーをぼかす';

  @override
  String get maskTitle => 'タイトルを隠す';

  @override
  String get customTitle => 'カスタムタイトル';

  @override
  String get privacyModeDesc => 'システム通知とメディアコントロールで再生情報を非表示にする';

  @override
  String get audioFormatSettingsTitle => 'オーディオフォーマット設定';

  @override
  String get preferredFormat => '優先フォーマット';

  @override
  String get cacheSizeLimit => 'キャッシュサイズ上限';

  @override
  String get llmApiUrl => 'API URL';

  @override
  String get llmApiKey => 'APIキー';

  @override
  String get llmModel => 'モデル';

  @override
  String get llmPrompt => 'システムプロンプト';

  @override
  String get llmConcurrency => '同時実行数';

  @override
  String get llmTestTranslation => '翻訳テスト';

  @override
  String get llmTestSuccess => 'テスト成功';

  @override
  String get llmTestFailed => 'テスト失敗';

  @override
  String get subtitleTimingAdjustment => '字幕タイミング調整';

  @override
  String get playerLyricStyle => 'プレーヤー歌詞スタイル';

  @override
  String get floatingLyricStyle => 'フローティング歌詞スタイル';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get fontColor => 'フォントカラー';

  @override
  String get backgroundColor => '背景色';

  @override
  String get transparency => '透明度';

  @override
  String get windowSize => 'ウィンドウサイズ';

  @override
  String get playerButtonSettings => 'プレーヤーボタン設定';

  @override
  String get showButton => 'ボタンを表示';

  @override
  String get buttonOrder => 'ボタンの順序';

  @override
  String get workCardDisplaySettings => '作品カード表示設定';

  @override
  String get showTags => 'タグを表示';

  @override
  String get showVa => '声優を表示';

  @override
  String get showRating => '評価を表示';

  @override
  String get showPrice => '価格を表示';

  @override
  String get cardSize => 'カードサイズ';

  @override
  String get compact => 'コンパクト';

  @override
  String get medium => 'ミディアム';

  @override
  String get full => 'フル';

  @override
  String get workDetailDisplaySettings => '作品詳細表示設定';

  @override
  String get infoSectionVisibility => '情報セクションの表示';

  @override
  String get imageSize => '画像サイズ';

  @override
  String get showMetadata => 'メタデータを表示';

  @override
  String get relatedRecommendations => '関連作品';

  @override
  String get myTabsDisplaySettings => '「マイ」ページ設定';

  @override
  String get showTab => 'タブを表示';

  @override
  String get tabOrder => 'タブの順序';

  @override
  String get blockedItems => 'ブロック項目';

  @override
  String get blockedTags => 'ブロック中のタグ';

  @override
  String get blockedVas => 'ブロック中の声優';

  @override
  String get blockedCircles => 'ブロック中のサークル';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get noBlockedItems => 'ブロック項目はありません';

  @override
  String get clearCache => 'キャッシュをクリア';

  @override
  String get clearCacheConfirm => 'すべてのキャッシュをクリアしますか？';

  @override
  String get cacheCleared => 'キャッシュをクリアしました';

  @override
  String get imagePreview => '画像プレビュー';

  @override
  String get saveImage => '画像を保存';

  @override
  String get imageSaved => '画像を保存しました';

  @override
  String get saveImageFailed => '保存失敗';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => 'ログアウトしますか？';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get linkCopied => 'リンクをコピーしました';

  @override
  String get ratingDistribution => '評価分布';

  @override
  String reviewsCount(int count) {
    return '$count件のレビュー';
  }

  @override
  String ratingsCount(int count) {
    return '全 $count 件の評価';
  }

  @override
  String get myReviews => 'マイレビュー';

  @override
  String get noReviews => 'レビューはありません';

  @override
  String get writeReview => 'レビューを書く';

  @override
  String get editReview => 'レビューを編集';

  @override
  String get deleteReview => 'レビューを削除';

  @override
  String get deleteReviewConfirm => 'このレビューを削除しますか？';

  @override
  String get reviewDeleted => 'レビューを削除しました';

  @override
  String get reviewContent => 'レビュー内容';

  @override
  String get enterReviewContent => 'レビュー内容を入力...';

  @override
  String get submitReview => '送信';

  @override
  String get reviewSubmitted => 'レビューを送信しました';

  @override
  String reviewFailed(String error) {
    return 'レビュー失敗: $error';
  }

  @override
  String get notificationPermission => '通知権限';

  @override
  String get mediaPermission => 'メディアライブラリ権限';

  @override
  String get storagePermission => 'ストレージ権限';

  @override
  String get granted => '許可済み';

  @override
  String get denied => '拒否';

  @override
  String get requestPermission => 'リクエスト';

  @override
  String get localDownloads => 'ローカルダウンロード';

  @override
  String get offlinePlayback => 'オフライン再生';

  @override
  String get noDownloadedWorks => 'ダウンロード済み作品はありません';

  @override
  String get updateAvailable => 'アップデートが利用可能です';

  @override
  String get ignoreThisVersion => 'このバージョンを無視';

  @override
  String get remindLater => '後で通知';

  @override
  String get updateNow => '今すぐアップデート';

  @override
  String get fetchFailed => '取得に失敗';

  @override
  String operationFailedWithError(String error) {
    return '操作失敗: $error';
  }

  @override
  String get aboutSubtitle => '更新確認、ライセンスなど';

  @override
  String get currentCacheSize => '現在のキャッシュサイズ';

  @override
  String cacheLimitLabelMB(int size) {
    return '上限: ${size}MB';
  }

  @override
  String get cacheUsagePercent => '使用率';

  @override
  String get autoCleanTitle => '自動クリーニングについて';

  @override
  String get autoCleanDescription =>
      '• キャッシュが上限を超えると自動的にクリーニングされます\n• 上限の80%まで削除します\n• LRU（最も使われていないもの）方式で削除';

  @override
  String get autoCleanDescriptionShort =>
      '• キャッシュが上限を超えると自動的にクリーニングされます\n• 上限の80%まで削除します';

  @override
  String get confirmClear => 'クリアを確認';

  @override
  String get confirmClearCacheMessage => 'すべてのキャッシュをクリアしますか？この操作は取り消せません。';

  @override
  String clearCacheFailedWithError(String error) {
    return 'キャッシュのクリアに失敗: $error';
  }

  @override
  String get hasNewVersion => '新しいバージョン';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get colorTheme => 'カラーテーマ';

  @override
  String get themePreview => 'テーマプレビュー';

  @override
  String get themeModeSystemDesc => 'システムのダーク/ライトモードに自動対応';

  @override
  String get themeModeLightDesc => '常にライトテーマを使用';

  @override
  String get themeModeDarkDesc => '常にダークテーマを使用';

  @override
  String get colorSchemeOceanBlueDesc => 'ブルー、ブルー、ブルー！';

  @override
  String get colorSchemeSakuraPinkDesc => '( ゜- ゜)つロ 乾杯~';

  @override
  String get colorSchemeSunsetOrangeDesc => 'テーマ変更は必須✍🏻✍🏻✍🏻';

  @override
  String get colorSchemeLavenderPurpleDesc => 'ブラザー、ブラザー...';

  @override
  String get colorSchemeForestGreenDesc => 'グリーン、グリーン、グリーン';

  @override
  String get colorSchemeDynamicDesc => 'システム壁紙の色を使用 (Android 12+)';

  @override
  String get primaryContainer => 'プライマリコンテナ';

  @override
  String get secondaryContainer => 'セカンダリコンテナ';

  @override
  String get tertiaryContainer => 'ターシャリコンテナ';

  @override
  String get surfaceColor => 'サーフェス';

  @override
  String get playerButtonSettingsSubtitle => 'プレーヤーボタンの順序';

  @override
  String get playerLyricStyleSubtitle => 'ミニ・全画面の歌詞スタイル';

  @override
  String get workDetailDisplaySubtitle => '詳細ページの表示内容';

  @override
  String get workCardDisplaySubtitle => '作品カードの表示内容';

  @override
  String get myTabsDisplaySubtitle => 'マイページに表示するタブ';

  @override
  String get pageSizeSettings => 'ページあたりの表示数';

  @override
  String pageSizeCurrent(int size) {
    return '1ページ $size 件';
  }

  @override
  String currentSettingLabel(String value) {
    return '現在: $value';
  }

  @override
  String setToValue(String value) {
    return '設定: $value';
  }

  @override
  String get llmConfigRequiredMessage =>
      'LLM翻訳にはAPI Keyの設定が必要です。先に設定画面で設定してください。';

  @override
  String get autoSwitchedToLlm => '自動切替: LLM翻訳';

  @override
  String get translationDescGoogle => 'Google サービスへの接続が必要';

  @override
  String get translationDescYoudao => '現在のネットワークを使用';

  @override
  String get translationDescMicrosoft => '現在のネットワークを使用';

  @override
  String get translationDescLlm => 'OpenAI 互換 API の設定が必要';

  @override
  String get audioPassthroughDescAndroid => 'AC3/DTS の生音声を外部デコーダーへ出力';

  @override
  String get permissionExplanation => '権限の説明';

  @override
  String get backgroundRunningPermission => 'バックグラウンド実行権限';

  @override
  String get notificationPermissionDesc =>
      'メディア再生通知バーの表示に使用し、ロック画面や通知バーから再生を制御できます。';

  @override
  String get backgroundRunningPermissionDesc =>
      'バッテリー最適化の制限を解除し、バックグラウンドでのオーディオ再生を維持します。';

  @override
  String get notificationGrantedStatus => '許可済み - 再生通知とコントローラーを表示可能';

  @override
  String get notificationDeniedStatus => '未許可 - タップして権限を申請';

  @override
  String get backgroundGrantedStatus => '許可済み - バックグラウンドで継続実行可能';

  @override
  String get backgroundDeniedStatus => '未許可 - タップして権限を申請';

  @override
  String get notificationPermissionGranted => '通知権限が許可されました';

  @override
  String get notificationPermissionDenied => '通知権限が拒否されました';

  @override
  String requestNotificationFailed(String error) {
    return '通知権限の申請に失敗: $error';
  }

  @override
  String get backgroundPermissionGranted => 'バックグラウンド実行権限が許可されました';

  @override
  String get backgroundPermissionDenied => 'バックグラウンド実行権限が拒否されました';

  @override
  String requestBackgroundFailed(String error) {
    return 'バックグラウンド権限の申請に失敗: $error';
  }

  @override
  String permissionRequired(String permission) {
    return '$permissionが必要です';
  }

  @override
  String permissionPermanentlyDenied(String permission) {
    return '$permissionが永久に拒否されています。システム設定で手動で有効にしてください。';
  }

  @override
  String get openSettings => '設定を開く';

  @override
  String get permissionsAndroidOnly => '権限管理はAndroidでのみ利用可能です';

  @override
  String get permissionsNotNeeded => '他のプラットフォームでは手動での権限管理は不要です';

  @override
  String get refreshPermissionStatus => '権限状態を更新';

  @override
  String deleteFileConfirm(String fileName) {
    return '「$fileName」を削除しますか？';
  }

  @override
  String deleteSelectedFilesConfirm(int count) {
    return '選択した $count 個のファイルを削除しますか？';
  }

  @override
  String get deleted => '削除済み';

  @override
  String cannotOpenFolder(String path) {
    return 'フォルダを開けません: $path';
  }

  @override
  String openFolderFailed(String error) {
    return 'フォルダを開けませんでした: $error';
  }

  @override
  String get reloadingFromDisk => 'ディスクから再読み込み中...';

  @override
  String get refreshComplete => '更新完了';

  @override
  String refreshFailed(String error) {
    return '更新失敗: $error';
  }

  @override
  String deleteSelectedWorksConfirm(int count) {
    return '選択した $count 個の作品を削除しますか？';
  }

  @override
  String partialDeleteFailed(String error) {
    return '一部の削除に失敗: $error';
  }

  @override
  String deletedNOfTotal(int success, int total) {
    return '$success/$total 個のタスクを削除';
  }

  @override
  String deleteFailedWithError(String error) {
    return '削除失敗: $error';
  }

  @override
  String get noWorkMetadataForOffline =>
      'このダウンロードには作品詳細が保存されていないため、オフラインで表示できません';

  @override
  String openWorkDetailFailed(String error) {
    return '作品詳細を開けませんでした: $error';
  }

  @override
  String get noLocalDownloads => 'ローカルダウンロードなし';

  @override
  String get exitSelection => '選択を終了';

  @override
  String get reload => '再読み込み';

  @override
  String get openFolder => 'フォルダを開く';

  @override
  String get playlistLink => 'プレイリストリンク';

  @override
  String get playlistLinkHint =>
      'プレイリストリンクを貼り付け、例:\nhttps://www.asmr.one/playlist?id=...';

  @override
  String get unrecognizedPlaylistLink => '認識できないプレイリストリンクまたはID';

  @override
  String get addingPlaylist => 'プレイリストを追加中...';

  @override
  String get playlistAddedSuccess => 'プレイリストの追加に成功';

  @override
  String get addFailed => '追加失敗';

  @override
  String get playlistNotFound => 'プレイリストが存在しないか、削除されています';

  @override
  String get noPermissionToAccessPlaylist => 'このプレイリストへのアクセス権限がありません';

  @override
  String get networkConnectionFailed => 'ネットワーク接続に失敗しました。接続を確認してください';

  @override
  String addFailedWithError(String error) {
    return '追加失敗: $error';
  }

  @override
  String get creatingPlaylist => 'プレイリストを作成中...';

  @override
  String playlistCreatedSuccess(String name) {
    return 'プレイリスト「$name」を作成しました';
  }

  @override
  String createFailedWithError(String error) {
    return '作成失敗: $error';
  }

  @override
  String get noPlaylists => 'プレイリストなし';

  @override
  String get noPlaylistsDescription => 'プレイリストはまだ作成・お気に入り登録されていません';

  @override
  String get myPlaylists => 'マイプレイリスト';

  @override
  String totalNItems(int count) {
    return '全 $count 件';
  }

  @override
  String get systemPlaylistCannotDelete => 'システムプレイリストは削除できません';

  @override
  String get deletePlaylist => 'プレイリストを削除';

  @override
  String get unfavoritePlaylist => 'お気に入りを解除';

  @override
  String get deletePlaylistConfirm =>
      '削除すると元に戻せません。このプレイリストをお気に入りに登録しているユーザーもアクセスできなくなります。削除しますか？';

  @override
  String unfavoritePlaylistConfirm(String name) {
    return '「$name」のお気に入りを解除しますか？';
  }

  @override
  String get unfavorite => 'お気に入り解除';

  @override
  String get deleting => '削除中...';

  @override
  String get deleteSuccess => '削除成功';

  @override
  String get onlyOwnerCanEdit => 'プレイリストの作成者のみ編集できます';

  @override
  String get editPlaylist => 'プレイリストを編集';

  @override
  String get playlistNameRequired => 'プレイリスト名は必須です';

  @override
  String get privacyDescPrivate => '自分のみ閲覧可能';

  @override
  String get privacyDescUnlisted => 'リンクを知っている人のみ閲覧可能';

  @override
  String get privacyDescPublic => '誰でも閲覧可能';

  @override
  String get addWorks => '作品を追加';

  @override
  String get addWorksInputHint => '作品番号を含むテキストを入力、RJ番号を自動検出';

  @override
  String get workId => '作品番号';

  @override
  String get workIdHint => '例: RJ123456\nrj233333';

  @override
  String detectedNWorkIds(int count) {
    return '$count 個の作品番号を検出';
  }

  @override
  String addNWorks(int count) {
    return '$count 個追加';
  }

  @override
  String get noValidWorkIds => '有効な作品番号が見つかりません（RJで始まるもの）';

  @override
  String addingNWorks(int count) {
    return '$count 個の作品を追加中...';
  }

  @override
  String addedNWorksSuccess(int count) {
    return '$count 個の作品を追加しました';
  }

  @override
  String get removeWork => '作品を削除';

  @override
  String removeWorkConfirm(String title) {
    return 'プレイリストから「$title」を削除しますか？';
  }

  @override
  String get removeSuccess => '削除成功';

  @override
  String removeFailedWithError(String error) {
    return '削除失敗: $error';
  }

  @override
  String get saving => '保存中...';

  @override
  String get saveSuccess => '保存成功';

  @override
  String saveFailedWithError(String error) {
    return '保存失敗: $error';
  }

  @override
  String get noWorks => '作品なし';

  @override
  String get playlistNoWorksDescription => 'このプレイリストにはまだ作品が追加されていません';

  @override
  String get lastUpdated => '最終更新';

  @override
  String get createdTime => '作成日';

  @override
  String nWorksCount(int count) {
    return '$count 作品';
  }

  @override
  String nPlaysCount(int count) {
    return '$count 再生';
  }

  @override
  String get removeFromPlaylist => 'プレイリストから削除';

  @override
  String get checkNetworkOrRetry => 'ネットワーク接続を確認するか、後で再試行してください';

  @override
  String get reachedEnd => '最後まで読みました~';

  @override
  String excludedNWorks(int count) {
    return '$count 作品を除外';
  }

  @override
  String pageExcludedNWorks(int count) {
    return 'このページで $count 作品を除外しました';
  }

  @override
  String get noSubtitlesAvailable => '字幕がありません';

  @override
  String get translateLyrics => '歌詞を翻訳';

  @override
  String get fullscreenLyrics => '全画面歌詞';

  @override
  String get showOriginalLyrics => '原文を表示';

  @override
  String get showTranslatedLyrics => '翻訳を表示';

  @override
  String get translatingLyrics => '翻訳中...';

  @override
  String get lyricTranslationFailed => '歌詞の翻訳に失敗しました';

  @override
  String get lyricTranslationConfirmMessage =>
      '再生中の歌詞を翻訳し、完了後すぐに表示します。自動保存がオンの場合は、字幕ライブラリの同名 .lrc を上書きします。翻訳中に曲を切り替えると結果は破棄されます。';

  @override
  String get unlock => 'ロック解除';

  @override
  String get backToCover => 'カバーに戻る';

  @override
  String get lyricHintTapCover => 'カバーまたはタイトルをタップして字幕画面に入る';

  @override
  String get floatingSubtitle => 'フローティング字幕';

  @override
  String get playlistEmpty => 'プレイリストが空です';

  @override
  String get gotIt => '了解';

  @override
  String nMinutes(int count) {
    return '$count分';
  }

  @override
  String nHours(int count) {
    return '$count時間';
  }

  @override
  String get titleLabel => 'タイトル';

  @override
  String get rjNumberLabel => 'RJ番号';

  @override
  String get workIdLabel => '作品番号';

  @override
  String get tapToViewRatingDetail => 'タップして評価詳細を表示';

  @override
  String priceInYen(int price) {
    return '$price 円';
  }

  @override
  String soldCount(String count) {
    return '販売数：$count';
  }

  @override
  String get circleAndVaSection => 'サークル | 声優';

  @override
  String get subtitleBadge => '字幕';

  @override
  String get otherEditions => '他のバージョン';

  @override
  String tenThousandSuffix(String count) {
    return '$count万';
  }

  @override
  String get packingWork => '作品をパッキング中...';

  @override
  String get workDirectoryNotExist => '作品ディレクトリが存在しません';

  @override
  String get packingFailed => 'パッキング失敗';

  @override
  String exportSuccess(String path) {
    return 'エクスポート成功：$path';
  }

  @override
  String exportFailed(String error) {
    return 'エクスポート失敗: $error';
  }

  @override
  String get exportAsZip => 'ZIPでエクスポート';

  @override
  String get offlineBadge => 'オフライン';

  @override
  String loadFilesFailed(String error) {
    return 'ファイルの読み込みに失敗: $error';
  }

  @override
  String get unknown => '不明';

  @override
  String get noPlayableAudioFiles => '再生可能な音声ファイルが見つかりません';

  @override
  String cannotFindAudioFile(String title) {
    return '音声ファイルが見つかりません: $title';
  }

  @override
  String nowPlayingNOfTotal(String title, int current, int total) {
    return '再生中: $title ($current/$total)';
  }

  @override
  String get noAudioCannotLoadSubtitle => '再生中の音声がないため、字幕を読み込めません';

  @override
  String get loadSubtitle => '字幕を読み込む';

  @override
  String get loadSubtitleConfirm => 'このファイルを現在の音声の字幕として読み込みますか？';

  @override
  String get subtitleFile => '字幕ファイル';

  @override
  String get currentAudio => '現在の音声';

  @override
  String get subtitleAutoRestoreNote => '他の音声に切り替えると、字幕はデフォルトのマッチングに自動復元されます';

  @override
  String get confirmLoad => '読み込み確定';

  @override
  String get loadingSubtitle => '字幕を読み込み中...';

  @override
  String subtitleLoadSuccess(String title) {
    return '字幕読み込み成功：$title';
  }

  @override
  String subtitleLoadFailed(String error) {
    return '字幕読み込み失敗：$error';
  }

  @override
  String get cannotPreviewImageMissingInfo => '画像をプレビューできません：必要な情報が不足';

  @override
  String get cannotFindImageFile => '画像ファイルが見つかりません';

  @override
  String get cannotPreviewTextMissingInfo => 'テキストをプレビューできません：必要な情報が不足';

  @override
  String get cannotPreviewPdfMissingInfo => 'PDFをプレビューできません：必要な情報が不足';

  @override
  String get cannotPlayVideoMissingId => '動画を再生できません：ファイルIDが不足';

  @override
  String get cannotPlayVideoMissingParams => '動画を再生できません：必要なパラメータが不足';

  @override
  String get cannotPlayDirectly => '直接再生できません';

  @override
  String get noVideoPlayerFound => '対応する動画プレーヤーが見つかりません。';

  @override
  String get youCan => '次の方法があります：';

  @override
  String get copyLinkToExternalPlayer => '1. 外部プレーヤーにリンクをコピー（MX Player、VLCなど）';

  @override
  String get openInBrowserOption => '2. ブラウザで開く';

  @override
  String playVideoError(String error) {
    return '動画再生エラー: $error';
  }

  @override
  String get noFiles => 'ファイルがありません';

  @override
  String get resourceFiles => 'リソースファイル';

  @override
  String resourceFilesTranslated(int count) {
    return 'リソースファイル (翻訳済み $count 項目)';
  }

  @override
  String get translationOriginal => '原';

  @override
  String get translationTranslated => '訳';

  @override
  String copiedName(String title) {
    return '名前をコピー: $title';
  }

  @override
  String translationComplete(int count) {
    return '翻訳完了：$count 項目';
  }

  @override
  String get noContentToTranslate => '翻訳するコンテンツがありません';

  @override
  String get preparingTranslation => '翻訳を準備中...';

  @override
  String translatingProgress(int current, int total) {
    return '翻訳中 $current/$total';
  }

  @override
  String nItems(int count) {
    return '$count 項目';
  }

  @override
  String get loadAsSubtitle => '字幕として読み込む';

  @override
  String get preview => 'プレビュー';

  @override
  String openVideoFileError(String error) {
    return '動画ファイルを開くエラー: $error';
  }

  @override
  String cannotOpenVideoFile(String message) {
    return '動画ファイルを開けません: $message';
  }

  @override
  String get noFileTreeInfo => 'ファイルツリー情報がありません';

  @override
  String get workFolderNotExist => '作品フォルダが存在しません';

  @override
  String get cannotPlayAudioMissingId => '音声を再生できません：ファイルIDが不足';

  @override
  String get audioFileNotExist => '音声ファイルが存在しません';

  @override
  String get noPreviewableImages => 'プレビュー可能な画像が見つかりません';

  @override
  String get cannotPreviewTextMissingId => 'テキストをプレビューできません：ファイルIDが不足';

  @override
  String get cannotFindFilePath => 'ファイルパスが見つかりません';

  @override
  String fileNotExist(String title) {
    return 'ファイルが存在しません：$title';
  }

  @override
  String get cannotPreviewPdfMissingId => 'PDFをプレビューできません：ファイルIDが不足';

  @override
  String get videoFileNotExist => '動画ファイルが存在しません';

  @override
  String get cannotOpenVideo => '動画を開けません';

  @override
  String errorInfo(String message) {
    return 'エラー情報: $message';
  }

  @override
  String get installVideoPlayerApp =>
      '動画プレーヤーアプリをインストールしてください（VLC、MX Playerなど）';

  @override
  String get filePathLabel => 'ファイルパス：';

  @override
  String get noDownloadedFiles => 'ダウンロード済みファイルがありません';

  @override
  String get offlineFiles => 'オフラインファイル';

  @override
  String unsupportedFileType(String title) {
    return 'このファイル形式は未対応です: $title';
  }

  @override
  String get deleteFilePrompt => 'このファイルを削除しますか？';

  @override
  String deletedItem(String title) {
    return '削除済み: $title';
  }

  @override
  String get selectAtLeastOneFile => 'ファイルを少なくとも1つ選択してください';

  @override
  String addedNFilesToDownloadQueue(int count) {
    return '$count ファイルをダウンロードキューに追加';
  }

  @override
  String downloadedAndSelected(int downloaded, int selected) {
    return 'ダウンロード済み $downloaded · 選択中 $selected';
  }

  @override
  String downloadN(int count) {
    return 'ダウンロード ($count)';
  }

  @override
  String get checkingDownloadedFiles => 'ダウンロード済みファイルを確認中...';

  @override
  String get noDownloadableFiles => 'ダウンロード可能なファイルがありません';

  @override
  String get selectFilesToDownload => 'ダウンロードファイルを選択';

  @override
  String downloadedNCount(int count) {
    return 'ダウンロード済み $count 個';
  }

  @override
  String selectedNCount(int count) {
    return '選択中 $count 個';
  }

  @override
  String get pleaseEnterServerAddress => 'サーバーアドレスを入力してください';

  @override
  String get pleaseEnterUsername => 'ユーザー名を入力してください';

  @override
  String get pleaseEnterPassword => 'パスワードを入力してください';

  @override
  String get notTestedYet => '未テスト';

  @override
  String latencyResultDetail(String latency, String status) {
    return '遅延 $latency ($status)';
  }

  @override
  String connectionFailedWithDetail(String error) {
    return '接続失敗: $error';
  }

  @override
  String get noAccountTapToRegister => 'アカウントがない？タップして登録';

  @override
  String get haveAccountTapToLogin => 'アカウントをお持ちですか？タップしてログイン';

  @override
  String get cannotDeleteActiveAccount => '現在使用中のアカウントは削除できません';

  @override
  String get selectAccount => 'アカウントを選択';

  @override
  String get noSavedAccounts => '保存されたアカウントがありません';

  @override
  String get addAccountToGetStarted => 'アカウントを追加して始めましょう';

  @override
  String get unknownHost => '不明なホスト';

  @override
  String lastUsedTime(String time) {
    return '最終使用: $time';
  }

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String hoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String minutesAgo(int count) {
    return '$count分前';
  }

  @override
  String get justNow => 'たった今';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String deleteSelectedConfirm(int count) {
    return '選択した $count 項目を削除しますか？';
  }

  @override
  String deletedNOfTotalItems(int success, int total) {
    return '$success/$total 項目を削除';
  }

  @override
  String get importingSubtitleFile => '字幕ファイルをインポート中...';

  @override
  String get preparingImport => 'インポートを準備中...';

  @override
  String get preparingExtract => '解凍を準備中...';

  @override
  String get importSubtitleFile => '字幕ファイルをインポート';

  @override
  String get supportedSubtitleFormats => '.srt, .vtt, .lrc などの字幕形式に対応';

  @override
  String get importFolder => 'フォルダをインポート';

  @override
  String get importFolderDesc => 'フォルダ構造を保持し、字幕ファイルのみインポート';

  @override
  String get importArchive => 'アーカイブをインポート';

  @override
  String get importArchiveDesc =>
      'パスワードなしZIPアーカイブに対応\n一括インポートする場合は1つのアーカイブにまとめてください';

  @override
  String get subtitleLibraryGuide => '字幕ライブラリ使用ガイド';

  @override
  String get subtitleLibraryFunction => '字幕ライブラリ機能';

  @override
  String get subtitleLibraryFunctionDesc =>
      'インポート/保存した字幕ファイルを管理し、再生時の自動/手動読み込みに対応';

  @override
  String get subtitleAutoLoad => '字幕自動読み込み';

  @override
  String get subtitleAutoLoadDesc => '音声再生時、システムが自動的に字幕ライブラリからマッチする字幕を検索：';

  @override
  String get smartCategoryAndMark => 'スマート分類とマーキング';

  @override
  String get open => '開く';

  @override
  String get moveTo => '移動先';

  @override
  String get rename => '名前変更';

  @override
  String get newName => '新しい名前';

  @override
  String get renameSuccess => '名前変更成功';

  @override
  String get renameFailed => '名前変更失敗';

  @override
  String deleteItemConfirm(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get deleteFolderContentsWarning => 'フォルダ内のすべてのコンテンツが削除されます。';

  @override
  String get deleteFailed => '削除失敗';

  @override
  String subtitleLoaded(String title) {
    return '字幕を読み込みました：$title';
  }

  @override
  String get moveSuccess => '移動成功';

  @override
  String get moveFailed => '移動失敗';

  @override
  String previewFailed(String error) {
    return 'プレビュー失敗: $error';
  }

  @override
  String openFailed(String error) {
    return '開く失敗: $error';
  }

  @override
  String get back => '戻る';

  @override
  String get subtitleLibraryEmpty => '字幕ライブラリが空です';

  @override
  String get tapToImportSubtitle => '右下の + ボタンをタップして字幕をインポート';

  @override
  String get importSubtitle => '字幕をインポート';

  @override
  String get sampleSubtitleContent => '♪ サンプル字幕コンテンツ ♪';

  @override
  String get presetStyles => 'プリセットスタイル';

  @override
  String get backgroundOpacity => '背景の不透明度';

  @override
  String get colorSettings => '色設定';

  @override
  String get shapeSettings => '形状設定';

  @override
  String get cornerRadius => '角の半径';

  @override
  String get horizontalPadding => '水平パディング';

  @override
  String get verticalPadding => '垂直パディング';

  @override
  String get resetStyle => 'スタイルをリセット';

  @override
  String get resetStyleConfirm => 'デフォルトスタイルに戻しますか？';

  @override
  String get restoreDefaultStyle => 'デフォルトスタイルに戻す';

  @override
  String get reset => 'リセット';

  @override
  String noBlockedItemsOfType(String type) {
    return 'ブロック中の$typeはありません';
  }

  @override
  String unblockedItem(String item) {
    return 'ブロック解除: $item';
  }

  @override
  String addBlockedItem(String type) {
    return '$typeをブロックに追加';
  }

  @override
  String blockedItemName(String type) {
    return '$type名';
  }

  @override
  String enterBlockedItemHint(String type) {
    return 'ブロックする$typeを入力';
  }

  @override
  String blockedItemAdded(String item) {
    return 'ブロックに追加: $item';
  }

  @override
  String workCountLabel(int count) {
    return '作品数: $count';
  }

  @override
  String get miniPlayer => 'ミニプレーヤー';

  @override
  String get lineHeight => '行の高さ';

  @override
  String get portraitPlayerBelowCover => '縦画面プレーヤー（カバー下）';

  @override
  String get fullscreenSubtitleMode => '全画面字幕（縦画面/横画面）';

  @override
  String get activeSubtitleFontSize => 'アクティブ字幕サイズ';

  @override
  String get inactiveSubtitleFontSize => 'その他の字幕サイズ';

  @override
  String get restoreDefaultSettings => 'デフォルト設定に戻す';

  @override
  String get confirmRestoreDefaultSettings => 'デフォルト設定に戻しますか？';

  @override
  String get guideInPrefix => '';

  @override
  String get guideParsedFolder => '<解析済み>';

  @override
  String get guideFindWorkDesc => 'フォルダで対応する作品を検索\nサポートされるフォルダ形式：RJ123456';

  @override
  String get guideSavedFolder => '<保存済み>';

  @override
  String get guideFindSubtitleDesc => 'フォルダで個別の字幕ファイルを検索';

  @override
  String get guideMatchRule => 'マッチルール：字幕ファイル名がオーディオファイル名と一致（拡張子の有無は問わない）';

  @override
  String get guideRecognizedWorkPrefix => '認識された作品には緑色の';

  @override
  String get guideTagSuffix => 'タグが追加され、オーディオファイルのアイコンにも';

  @override
  String get guideSubtitleMatchSuffix => 'マークが付き、字幕ライブラリとの一致を示します';

  @override
  String get guideAutoRecognizeRJ => 'インポート時にRJ形式を自動認識し、<解析済み>に分類';

  @override
  String get guideAutoAddRJPrefix =>
      '数字のみのフォルダにRJプレフィックスを自動追加（例：123456 → RJ123456）';

  @override
  String get unknownFile => '不明なファイル';

  @override
  String deleteWithCount(int count) {
    return '削除 ($count)';
  }

  @override
  String get searchSubtitles => '字幕を検索...';

  @override
  String nFilesWithSize(int count, String size) {
    return '$count ファイル • $size';
  }

  @override
  String get rootDirectory => 'ルート';

  @override
  String get goToParent => '上の階層へ';

  @override
  String moveToTarget(String name) {
    return '移動先: $name';
  }

  @override
  String get noSubfoldersHere => 'このディレクトリにサブフォルダはありません';

  @override
  String addedToPlaylist(String name) {
    return '「$name」に追加しました';
  }

  @override
  String removedFromPlaylist(String name) {
    return '「$name」から削除しました';
  }

  @override
  String get alreadyFavorited => 'お気に入り済み';

  @override
  String loadImageFailedWithError(String error) {
    return '画像の読み込みに失敗\n$error';
  }

  @override
  String get noImageAvailable => '利用可能な画像はありません';

  @override
  String get storagePermissionRequiredForImage => '画像を保存するにはストレージ権限が必要です';

  @override
  String get savedToGallery => 'アルバムに保存しました';

  @override
  String get saveCoverImage => 'カバー画像を保存';

  @override
  String savedToPath(String path) {
    return '$path に保存しました';
  }

  @override
  String get doubleTapToZoom => 'ダブルタップで拡大 · ピンチでズーム';

  @override
  String getStatusFailed(String error) {
    return 'ステータスの取得に失敗: $error';
  }

  @override
  String get deleteRecord => '記録を削除';

  @override
  String deletePlayRecordConfirm(String title) {
    return '\"$title\" の再生記録を削除しますか？';
  }

  @override
  String get notPlayedYet => '未再生';

  @override
  String playbackFailed(String error) {
    return '再生失敗: $error';
  }

  @override
  String get storagePermissionRequired => 'ストレージ権限が必要';

  @override
  String get storagePermissionForGalleryDesc =>
      '画像を保存するにはフォトアルバムへのアクセス権限が必要です。設定で権限を付与してください。';

  @override
  String get goToSettings => '設定へ';

  @override
  String get imageSavedToGallery => '画像をアルバムに保存しました';

  @override
  String imageSavedToPath(String path) {
    return '画像を保存しました: $path';
  }

  @override
  String get pullDownForNextPage => '下に引いて次のページへ';

  @override
  String get releaseForNextPage => '離して次のページへ';

  @override
  String get jumpTo => 'ジャンプ';

  @override
  String get goToPageTitle => 'ページへ移動';

  @override
  String pageNumberRange(int max) {
    return 'ページ (1-$max)';
  }

  @override
  String get enterPageNumber => 'ページ番号を入力';

  @override
  String enterValidPageNumber(int max) {
    return '有効なページ番号を入力してください (1-$max)';
  }

  @override
  String get previousPage => '前のページ';

  @override
  String get nextPage => '次のページ';

  @override
  String get localPdfNotExist => 'ローカルPDFファイルが存在しません';

  @override
  String get cannotOpenPdf => 'PDFファイルを開けません';

  @override
  String loadPdfFailed(String error) {
    return 'PDFの読み込みに失敗: $error';
  }

  @override
  String pdfPageOfTotal(int current, int total) {
    return '$current / $total ページ';
  }

  @override
  String get loadingPdf => 'PDFを読み込み中...';

  @override
  String get pdfPathInvalid => 'PDFファイルパスが無効です';

  @override
  String get desktopPdfPreviewNotSupported => 'デスクトップでのPDFプレビューはまだサポートされていません';

  @override
  String get openWithSystemApp => 'システムデフォルトアプリで開く';

  @override
  String renderPdfFailed(String error) {
    return 'PDFのレンダリングに失敗: $error';
  }

  @override
  String get ratingDetails => '評価詳細';

  @override
  String get selectSaveDirectory => '保存先を選択';

  @override
  String get noSubtitleContentToSave => '保存する字幕コンテンツがありません';

  @override
  String get savedToSubtitleLibrary => '字幕ライブラリに保存しました';

  @override
  String get translatedLyricsNotSaved => '翻訳が完了しました。現在の再生中のみ表示します。';

  @override
  String get saveToLocal => 'ローカルに保存';

  @override
  String get selectDirectoryToSaveFile => 'ファイルの保存先を選択';

  @override
  String get saveToSubtitleLibrary => '字幕ライブラリに保存';

  @override
  String get saveToSubtitleLibraryDesc => '字幕ライブラリの\"保存済み\"フォルダに保存';

  @override
  String get saveToFile => 'ファイルに保存';

  @override
  String get noContentToSave => '保存するコンテンツがありません';

  @override
  String fileSavedToPath(String path) {
    return 'ファイルを保存しました：$path';
  }

  @override
  String get localFileNotExist => 'ローカルファイルが存在しません。再読み込みしてください';

  @override
  String loadTextFailed(String error) {
    return 'テキストの読み込みに失敗: $error';
  }

  @override
  String get previewMode => 'プレビューモード';

  @override
  String get editMode => '編集モード';

  @override
  String get showOriginal => '原文を表示';

  @override
  String get translateContent => 'コンテンツを翻訳';

  @override
  String get editTextContentHint => 'テキストを編集...';

  @override
  String get markButton => 'マーク';

  @override
  String get bookmarkRemoved => 'ブックマークを削除しました';

  @override
  String setProgressAndRating(String progress, int rating) {
    return '$progressに設定、評価: $rating 星';
  }

  @override
  String setProgressTo(String progress) {
    return '$progressに設定';
  }

  @override
  String ratingSetTo(int rating) {
    return '評価を$rating星に設定';
  }

  @override
  String get updated => '更新しました';

  @override
  String addTagFailed(String error) {
    return 'タグの追加に失敗: $error';
  }

  @override
  String addWithCount(int count) {
    return '追加 ($count)';
  }

  @override
  String get undo => '元に戻す';

  @override
  String nStars(int count) {
    return '$count 星';
  }

  @override
  String get voteRemoved => '投票を取り消しました';

  @override
  String get votedUp => '賛成票を投じました';

  @override
  String get votedDown => '反対票を投じました';

  @override
  String voteFailedWithError(String error) {
    return '投票に失敗: $error';
  }

  @override
  String get voteFor => '賛成';

  @override
  String get voteAgainst => '反対';

  @override
  String get voted => '投票済み';

  @override
  String tagBlockedWithName(String name) {
    return 'タグをブロックしました: $name';
  }

  @override
  String get subtitleParseFailedUnsupportedFormat => '解析失敗、サポートされていない形式';

  @override
  String get lyricPresetDynamic => 'ダイナミック';

  @override
  String get lyricPresetClassic => 'クラシック';

  @override
  String get lyricPresetModern => 'モダン';

  @override
  String get lyricPresetMinimal => 'ミニマル';

  @override
  String get lyricPresetVibrant => 'ビビッド';

  @override
  String get lyricPresetElegant => 'エレガント';

  @override
  String get lyricPresetDynamicDesc => 'システムテーマに合わせて自動配色';

  @override
  String get lyricPresetClassicDesc => '黒背景に白文字、クラシック';

  @override
  String get lyricPresetModernDesc => 'グラデーション背景、スタイリッシュ';

  @override
  String get lyricPresetMinimalDesc => '軽い透明感、シンプルで優雅';

  @override
  String get lyricPresetVibrantDesc => '鮮やかな色彩、活気あふれる';

  @override
  String get lyricPresetElegantDesc => '深いブルー、上品な雰囲気';

  @override
  String get floatingLyricLoading => '♪ 字幕を読み込み中 ♪';

  @override
  String get subtitleFileNotExist => 'ファイルが存在しません';

  @override
  String get subtitleMissingInfo => '必要な情報が不足しています';

  @override
  String get privacyDefaultTitle => 'オーディオ再生中';

  @override
  String get offlineModeStartup => 'ネットワーク接続に失敗、オフラインモードで開始';

  @override
  String get playlistInfoNotLoaded => 'プレイリスト情報が読み込まれていません';

  @override
  String get encodingUnrecognized => 'ファイルエンコーディングを認識できず、正しく表示できません';

  @override
  String editPlaylistFailed(String error) {
    return 'プレイリストの編集に失敗: $error';
  }

  @override
  String unsupportedFileTypeWithTitle(String title) {
    return 'このファイルタイプは開けません: $title';
  }

  @override
  String get settingsSaved => '設定を保存しました';

  @override
  String get restoredToDefault => 'デフォルト設定に復元しました';

  @override
  String get restoreDefault => 'デフォルトに戻す';

  @override
  String get saveSettings => '設定を保存';

  @override
  String get addAtLeastOneSearchCondition => '検索条件を少なくとも1つ追加してください';

  @override
  String get privacyModeSettingsTitle => 'プライバシーモード設定';

  @override
  String get whatIsPrivacyMode => 'プライバシーモードとは？';

  @override
  String get privacyModeDescription =>
      '有効にすると、システム通知やロック画面に表示される再生情報がぼかし処理され、プライバシーが保護されます。';

  @override
  String get enablePrivacyMode => 'プライバシーモードを有効にする';

  @override
  String get privacyModeEnabledSubtitle => '有効 - 再生情報が非表示になります';

  @override
  String get privacyModeDisabledSubtitle => '無効 - 再生情報が通常表示されます';

  @override
  String get blurOptions => 'ぼかしオプション';

  @override
  String get blurNotificationCover => '通知カバーをぼかす';

  @override
  String get blurNotificationCoverSubtitle =>
      'システム通知、ロック画面、コントロールセンターのカバーにぼかしを適用';

  @override
  String get blurInAppCover => 'アプリ内カバーをぼかす';

  @override
  String get blurInAppCoverSubtitle => 'プレーヤーやリストなどの画面でカバー画像をぼかす';

  @override
  String get replaceTitle => 'タイトルを置換';

  @override
  String get replaceTitleSubtitle => '実際のタイトルをカスタムタイトルに置換';

  @override
  String get replaceTitleContent => '置換タイトルの内容';

  @override
  String get setReplaceTitle => '置換タイトルを設定';

  @override
  String get enterDisplayTitle => '表示するタイトルを入力';

  @override
  String get replaceTitleSaved => '置換タイトルを保存しました';

  @override
  String get effectExample => '効果の例';

  @override
  String get downloadPathSettings => 'ダウンロードパス設定';

  @override
  String loadPathFailedWithError(String error) {
    return 'パスの読み込みに失敗: $error';
  }

  @override
  String get platformNotSupportCustomPath =>
      'このプラットフォームではカスタムダウンロードパスはサポートされていません';

  @override
  String activeDownloadsWarning(int count) {
    return '$count 件のダウンロードが進行中です。パスを切り替える前に完了またはキャンセルしてください';
  }

  @override
  String setPathFailedWithError(String error) {
    return 'パスの設定に失敗: $error';
  }

  @override
  String get confirmMigrateFiles => 'ファイル移行の確認';

  @override
  String get migrateFilesToNewDir => '既存のダウンロードファイルを新しいディレクトリに移行します：';

  @override
  String get migrationMayTakeTime => 'この操作はファイルの数とサイズによって時間がかかる場合があります。';

  @override
  String get confirmMigrate => '移行を確認';

  @override
  String get restoreDefaultPath => 'デフォルトパスに戻す';

  @override
  String get restoreDefaultPathConfirm =>
      'ダウンロードパスをデフォルトの場所に戻し、すべてのファイルを移行します。\n\n続行しますか？';

  @override
  String get defaultPathRestored => 'デフォルトパスに復元しました';

  @override
  String resetPathFailedWithError(String error) {
    return 'デフォルトパスの復元に失敗: $error';
  }

  @override
  String get migratingFiles => 'ファイルを移行中...';

  @override
  String get doNotCloseApp => 'アプリを閉じないでください';

  @override
  String get currentDownloadPath => '現在のダウンロードパス';

  @override
  String get customPath => 'カスタムパス';

  @override
  String get defaultPath => 'デフォルトパス';

  @override
  String get changeCustomPath => 'カスタムパスを変更';

  @override
  String get setCustomPath => 'カスタムパスを設定';

  @override
  String get usageInstructions => '使用方法';

  @override
  String get downloadPathUsageDesc =>
      '• パスをカスタマイズすると、既存のファイルは自動的に新しい場所に移行されます\n• 移行中はアプリを閉じないでください\n• 十分な空き容量のあるディレクトリを選択してください\n• デフォルトパスに戻すと、ファイルも自動的に戻されます';

  @override
  String get llmTranslationSettings => 'LLM翻訳設定';

  @override
  String get apiEndpointUrl => 'APIエンドポイントURL';

  @override
  String get openaiCompatibleEndpoint => 'OpenAI互換エンドポイントURL';

  @override
  String get pleaseEnterApiUrl => 'APIエンドポイントURLを入力してください';

  @override
  String get pleaseEnterValidUrl => '有効なURLを入力してください';

  @override
  String get pleaseEnterApiKey => 'APIキーを入力してください';

  @override
  String get modelName => 'モデル名';

  @override
  String get pleaseEnterModelName => 'モデル名を入力してください';

  @override
  String get concurrencyCount => '同時実行数';

  @override
  String get concurrencyDescription => '同時翻訳リクエスト数、推奨 3-5';

  @override
  String get promptSection => 'プロンプト (Prompt)';

  @override
  String get promptDescription =>
      'システムはチャンク翻訳を使用しているため、翻訳結果のみを出力し説明を含めないようプロンプトを明確にしてください。';

  @override
  String get enterSystemPrompt => 'システムプロンプトを入力...';

  @override
  String get pleaseEnterPrompt => 'プロンプトを入力してください';

  @override
  String get restoreDefaultPrompt => 'デフォルトプロンプトに戻す';

  @override
  String get confirmRestoreButtonOrder => 'デフォルトのボタン順序に戻しますか？';

  @override
  String get buttonDisplayRules => 'ボタン表示ルール';

  @override
  String buttonDisplayRulesDesc(int maxVisible) {
    return '• 最初の $maxVisible 個のボタンがプレーヤーの下部に表示されます\n• 残りのボタンは「その他」メニューに格納されます';
  }

  @override
  String get shownInPlayer => 'プレーヤーに表示';

  @override
  String get shownInMoreMenu => 'その他メニューに表示';

  @override
  String get audioFormatPriority => 'オーディオ形式の優先順位';

  @override
  String get confirmRestoreAudioFormat => 'デフォルトのオーディオ形式優先順位に戻しますか？';

  @override
  String get priorityDescription => '優先順位の説明';

  @override
  String get audioFormatPriorityDesc =>
      '• 作品詳細ページを開くと、優先度の高い形式のオーディオフォルダが自動的に展開されます';

  @override
  String get ratingInfo => '評価情報';

  @override
  String get showRatingAndReviewCount => '作品の評価とレビュー数を表示';

  @override
  String get priceInfo => '価格情報';

  @override
  String get showWorkPrice => '作品の価格を表示';

  @override
  String get durationInfo => '再生時間情報';

  @override
  String get showWorkDuration => '作品の再生時間を表示';

  @override
  String get showWorkTotalDuration => '作品の合計再生時間を表示';

  @override
  String get salesInfo => '販売情報';

  @override
  String get showWorkSalesCount => '作品の販売数を表示';

  @override
  String get externalLinkInfo => '外部リンク情報';

  @override
  String get showExternalLinks => 'DLsiteや公式サイトなどの外部リンクを表示';

  @override
  String get releaseDateInfo => '発売日';

  @override
  String get showWorkReleaseDate => '作品の発売日を表示';

  @override
  String get translateButtonLabel => '翻訳ボタン';

  @override
  String get showTranslateButton => '作品タイトルの翻訳ボタンを表示';

  @override
  String get subtitleTagLabel => '字幕タグ';

  @override
  String get showSubtitleTagOnCover => 'カバー画像に字幕タグを表示';

  @override
  String get showAgeRatingOnDetail => '作品詳細ページに年齢区分を表示';

  @override
  String get recommendationsLabel => '関連おすすめ';

  @override
  String get showRecommendations => '作品詳細ページに関連おすすめを表示';

  @override
  String get circleInfo => 'サークル情報';

  @override
  String get showWorkCircle => '作品のサークルを表示';

  @override
  String get workCardSizeSubtitle => 'グリッド密度を調整して、カバーを大きくするか現在のサイズを保ちます';

  @override
  String get workCardFontSize => 'カード文字サイズ';

  @override
  String get workCardFontSizeSubtitle => '作品カードのタイトルと情報テキストのサイズを調整します';

  @override
  String get cardSizeNormal => '標準';

  @override
  String get cardSizeLarge => '大';

  @override
  String get cardSizeExtraLarge => '特大';

  @override
  String get fontSizeNormal => '標準';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeExtraLarge => '特大';

  @override
  String get showSubtitleTagOnCard => '作品カードに字幕タグを表示';

  @override
  String get showAgeRatingOnCard => '作品カードに年齢区分を表示';

  @override
  String get showOnlineMarks => 'オンラインマークの作品を表示';

  @override
  String get cannotBeDisabled => '無効にできません';

  @override
  String get showPlaylists => '作成したプレイリストを表示';

  @override
  String get showSubtitleLibrary => '字幕ライブラリ管理を表示';

  @override
  String get playlistPrivacyPrivateDesc => '自分だけが閲覧可能';

  @override
  String get playlistPrivacyUnlistedDesc => 'リンクを知っている人だけが閲覧可能';

  @override
  String get playlistPrivacyPublicDesc => '誰でも閲覧可能';

  @override
  String get clearTranslationCache => '翻訳キャッシュをクリア';

  @override
  String get translationCacheCleared => '翻訳キャッシュをクリアしました';

  @override
  String get platformHintAndroid =>
      'Android: システムのファイルピッカーを使用します。ストレージ権限が必要な場合があります';

  @override
  String get platformHintIOS =>
      'iOS: システム制限によりデフォルトパスを使用します。システムのファイルマネージャーで確認できます';

  @override
  String get platformHintWindows => 'Windows: 任意のアクセス可能なディレクトリを選択できます';

  @override
  String get platformHintMacOS => 'macOS: 任意のアクセス可能なディレクトリを選択できます';

  @override
  String get platformHintLinux => 'Linux: 任意のアクセス可能なディレクトリを選択できます';

  @override
  String get platformHintDefault => 'ダウンロードファイルを保存するディレクトリを選択してください';

  @override
  String get subtitleFolderParsed => '解析済み';

  @override
  String get subtitleFolderSaved => '保存済み';

  @override
  String get subtitleFolderUnknown => '不明な作品';

  @override
  String get sortDownloadDate => 'ダウンロード日';

  @override
  String get sortWorkId => 'ID';

  @override
  String get searchDownloads => 'ダウンロード済み作品を検索...';

  @override
  String get logTitle => 'アプリログ';

  @override
  String get logSubtitle => 'アプリログの表示とエクスポート';

  @override
  String get logSearchHint => 'ログを検索...';

  @override
  String get logFilterAll => 'すべて';

  @override
  String get logCopy => 'ログをコピー';

  @override
  String get logExport => 'ログファイルをエクスポート';

  @override
  String get logClear => 'ログをクリア';

  @override
  String get logCopied => 'ログをクリップボードにコピーしました';

  @override
  String logExported(String path) {
    return 'ログを $path にエクスポートしました';
  }

  @override
  String logCount(int count) {
    return '$count 件のログ';
  }

  @override
  String get logAutoScroll => '自動スクロール';

  @override
  String get logEmpty => 'ログはありません';

  @override
  String get proxySettingsOptional => 'プロキシ';

  @override
  String get loginAdvancedSettings => '詳細設定';

  @override
  String proxyEnabled(String address) {
    return '有効: $address';
  }

  @override
  String get proxyAddressNotSet => '未設定（直接接続）';

  @override
  String get proxyHttpDescription => 'HTTP プロキシ経由で接続';

  @override
  String get useProxy => 'プロキシを使用';

  @override
  String get proxyAddress => 'プロキシアドレス';

  @override
  String get proxyAddressFormat => '形式: ホスト:ポート（例: 127.0.0.1:7890）';

  @override
  String get applyProxyAddress => 'プロキシアドレスを適用';

  @override
  String get invalidProxyAddress => '有効な HTTP プロキシのアドレスとポートを入力してください';

  @override
  String get proxyModeDirect => '直接接続';

  @override
  String get proxyModeSystem => 'システムプロキシ';

  @override
  String get proxyModeManual => '手動プロキシ';

  @override
  String get proxyModeDirectDescription => 'プロキシを使用せずに接続';

  @override
  String get proxyModeSystemDescription => 'オペレーティングシステムのプロキシ設定を使用';

  @override
  String get proxyModeManualDescription => '下で設定した HTTP プロキシを使用';

  @override
  String get playlistDisplayFormat => 'プレイリストの表示形式';

  @override
  String get playlistDisplayFormatMasonry => 'ウォーターフォール';

  @override
  String get playlistDisplayFormatList => 'リスト';
}
