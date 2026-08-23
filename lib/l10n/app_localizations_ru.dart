// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'KikoFlu';

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navMy => 'Моё';

  @override
  String get navSettings => 'Настройки';

  @override
  String get offlineModeMessage =>
      'Автономный режим: нет подключения к сети, доступен только загруженный контент';

  @override
  String get retry => 'Повторить';

  @override
  String get searchTypeKeyword => 'Ключевое слово';

  @override
  String get searchTypeTag => 'Тег';

  @override
  String get searchTypeVa => 'Сэйю';

  @override
  String get searchTypeCircle => 'Кружок';

  @override
  String get searchTypeRjNumber => 'Номер RJ';

  @override
  String get searchHintKeyword => 'Введите название или ключевое слово...';

  @override
  String get searchHintTag => 'Введите название тега...';

  @override
  String get searchHintVa => 'Введите имя сэйю...';

  @override
  String get searchHintCircle => 'Введите название кружка...';

  @override
  String get searchHintRjNumber => 'Введите номер...';

  @override
  String get ageRatingAll => 'Все';

  @override
  String get ageRatingGeneral => 'Для всех';

  @override
  String get ageRatingR15 => 'R-15';

  @override
  String get ageRatingAdult => '18+';

  @override
  String get salesRangeAll => 'Все';

  @override
  String get sortRelease => 'Дата выхода';

  @override
  String get sortCreateAt => 'Дата добавления';

  @override
  String get sortCreateDate => 'Дата каталога';

  @override
  String get sortRating => 'Рейтинг';

  @override
  String get sortReviewCount => 'Отзывы';

  @override
  String get sortRandom => 'Случайно';

  @override
  String get sortDlCount => 'Продажи';

  @override
  String get sortPrice => 'Цена';

  @override
  String get sortNsfw => 'Для всех';

  @override
  String get sortUpdatedAt => 'Дата отметки';

  @override
  String get sortAsc => 'По возрастанию';

  @override
  String get sortDesc => 'По убыванию';

  @override
  String get sortOptions => 'Параметры сортировки';

  @override
  String get sortField => 'Поле сортировки';

  @override
  String get sortDirection => 'Направление сортировки';

  @override
  String get displayModeAll => 'Все';

  @override
  String get displayModePopular => 'Популярное';

  @override
  String get displayModeRecommended => 'Рекомендуемое';

  @override
  String get subtitlePriorityHighest => 'Приоритет';

  @override
  String get subtitlePriorityLowest => 'Отложено';

  @override
  String get translationSourceGoogle => 'Google Переводчик';

  @override
  String get translationSourceYoudao => 'Youdao Переводчик';

  @override
  String get translationSourceMicrosoft => 'Microsoft Переводчик';

  @override
  String get translationSourceLlm => 'LLM Переводчик';

  @override
  String get progressMarked => 'Хочу послушать';

  @override
  String get progressListening => 'Слушаю';

  @override
  String get progressListened => 'Прослушано';

  @override
  String get progressReplay => 'Переслушать';

  @override
  String get progressPostponed => 'Отложено';

  @override
  String get loginTitle => 'Вход';

  @override
  String get register => 'Регистрация';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get registerAccount => 'Зарегистрировать аккаунт';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get serverAddress => 'Адрес сервера';

  @override
  String get serverCookie => 'Cookie сервера';

  @override
  String get login => 'Войти';

  @override
  String get loginSuccess => 'Вход выполнен';

  @override
  String get loginFailed => 'Ошибка входа';

  @override
  String get registerFailed => 'Ошибка регистрации';

  @override
  String get usernameMinLength =>
      'Имя пользователя должно содержать не менее 5 символов';

  @override
  String get passwordMinLength => 'Пароль должен содержать не менее 5 символов';

  @override
  String accountAdded(String username) {
    return 'Аккаунт «$username» добавлен';
  }

  @override
  String get testConnection => 'Проверить соединение';

  @override
  String get testing => 'Проверка...';

  @override
  String get enterServerAddressToTest =>
      'Введите адрес сервера для проверки соединения';

  @override
  String latencyMs(String ms) {
    return '$msмс';
  }

  @override
  String get connectionFailed => 'Ошибка соединения';

  @override
  String get guestModeTitle => 'Подтверждение гостевого режима';

  @override
  String get guestModeMessage =>
      'Гостевой режим имеет ограничения:\n\n• Нельзя отмечать и оценивать работы\n• Нельзя создавать плейлисты\n• Нельзя синхронизировать прогресс\n\nГостевой режим использует демо-аккаунт, который может работать нестабильно.';

  @override
  String get continueGuestMode => 'Продолжить в гостевом режиме';

  @override
  String get guestAccountAdded => 'Гостевой аккаунт добавлен';

  @override
  String get guestLoginFailed => 'Ошибка гостевого входа';

  @override
  String get guestMode => 'Гостевой режим';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get close => 'Закрыть';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get edit => 'Редактировать';

  @override
  String get add => 'Добавить';

  @override
  String get create => 'Создать';

  @override
  String get ok => 'ОК';

  @override
  String get search => 'Поиск';

  @override
  String get filter => 'Фильтр';

  @override
  String get advancedFilter => 'Расширенный фильтр';

  @override
  String get enterSearchContent => 'Введите поисковый запрос';

  @override
  String get searchTag => 'Поиск тегов...';

  @override
  String get minRating => 'Мин. рейтинг';

  @override
  String minRatingStars(String stars) {
    return '$stars звёзд';
  }

  @override
  String get searchHistory => 'История поиска';

  @override
  String get clearSearchHistory => 'Очистить историю поиска';

  @override
  String get clearSearchHistoryConfirm =>
      'Вы уверены, что хотите очистить всю историю поиска?';

  @override
  String get clear => 'Очистить';

  @override
  String get searchHistoryCleared => 'История поиска очищена';

  @override
  String get noSearchHistory => 'Нет истории поиска';

  @override
  String get excludeMode => 'Исключить';

  @override
  String get includeMode => 'Включить';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get loadFailed => 'Ошибка загрузки';

  @override
  String loadFailedWithError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get loading => 'Загрузка...';

  @override
  String get calculating => 'Вычисление...';

  @override
  String get getFailed => 'Не удалось получить';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get accountManagement => 'Управление аккаунтами';

  @override
  String get accountManagementSubtitle => 'Управление аккаунтами, переключение';

  @override
  String get privacyMode => 'Режим конфиденциальности';

  @override
  String get privacyModeEnabled =>
      'Включён — информация о воспроизведении скрыта';

  @override
  String get privacyModeDisabled => 'Выключен';

  @override
  String get permissionManagement => 'Управление разрешениями';

  @override
  String get permissionManagementSubtitle => 'Уведомления, фоновая работа';

  @override
  String get desktopFloatingLyric => 'Плавающие субтитры';

  @override
  String get floatingLyricEnabled =>
      'Включено — субтитры отображаются на рабочем столе';

  @override
  String get floatingLyricDisabled => 'Выключено';

  @override
  String get floatingLyricTouch => 'Блокировка плавающих субтитров';

  @override
  String get floatingLyricTouchEnabled =>
      'Разблокировано — можно перетаскивать, удерживайте для блокировки';

  @override
  String get floatingLyricTouchDisabled =>
      'Заблокировано — удерживайте субтитры для разблокировки';

  @override
  String get floatingFPS => 'Показать FPS';

  @override
  String get floatingFPSEnabled =>
      'Включено — FPS в левом нижнем углу плавающего окна';

  @override
  String get floatingFPSDisabled => 'Выключено';

  @override
  String get floatingNetworkSpeed => 'Показать скорость сети';

  @override
  String get floatingNetworkSpeedEnabled =>
      'Включено — скорость в правом нижнем углу плавающего окна';

  @override
  String get floatingNetworkSpeedDisabled => 'Выключено';

  @override
  String get styleSettings => 'Настройки стиля';

  @override
  String get styleSettingsSubtitle => 'Шрифт, цвет, прозрачность и т.д.';

  @override
  String get downloadPath => 'Путь загрузки';

  @override
  String get downloadPathSubtitle =>
      'Настроить расположение загруженных файлов';

  @override
  String get maxConcurrentDownloads => 'Макс. одновременных загрузок';

  @override
  String get maxConcurrentDownloadsSubtitle =>
      'Ограничить количество одновременных задач загрузки';

  @override
  String get cacheManagement => 'Управление кешем';

  @override
  String currentCache(String size) {
    return 'Текущий кеш: $size';
  }

  @override
  String get themeSettings => 'Настройки темы';

  @override
  String get themeSettingsSubtitle => 'Тёмный режим, цвет темы и т.д.';

  @override
  String get uiSettings => 'Настройки интерфейса';

  @override
  String get uiSettingsSubtitle => 'Плеер, страница деталей, карточки и т.д.';

  @override
  String get liquidGlassNavigation => 'Навигация Liquid Glass';

  @override
  String get liquidGlassNavigationDesc =>
      'Использовать полупрозрачные стеклянные панели навигации и мини-плеера. По умолчанию включено только в поддерживаемых версиях iOS и macOS.';

  @override
  String get fallbackGlassTransparency => 'Прозрачность Liquid Glass';

  @override
  String get fallbackGlassTransparencyDesc =>
      'Настройте прозрачность стеклянных поверхностей, отрисованных приложением на этой платформе.';

  @override
  String get preferenceSettings => 'Предпочтения';

  @override
  String get preferenceSettingsSubtitle =>
      'Переводчик, блокировки, аудио и т.д.';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String get unknownVersion => 'Неизвестно';

  @override
  String get licenseLoadFailed => 'Не удалось загрузить файл LICENSE';

  @override
  String get licenseEmpty => 'Файл LICENSE пуст';

  @override
  String get failedToLoadAbout => 'Не удалось загрузить информацию';

  @override
  String get newVersionFound => 'Найдена новая версия';

  @override
  String newVersionAvailable(String version, String current) {
    return '$version доступна (текущая: $current)';
  }

  @override
  String get versionInfo => 'Информация о версии';

  @override
  String currentVersion(String version) {
    return 'Текущая версия: $version';
  }

  @override
  String get checkUpdate => 'Проверить обновления';

  @override
  String get author => 'Автор';

  @override
  String get projectRepo => 'Репозиторий проекта';

  @override
  String get openSourceLicense => 'Лицензия открытого ПО';

  @override
  String get cannotOpenLink => 'Не удаётся открыть ссылку';

  @override
  String openLinkFailed(String error) {
    return 'Не удалось открыть ссылку: $error';
  }

  @override
  String foundNewVersion(String version) {
    return 'Найдена новая версия $version';
  }

  @override
  String get view => 'Просмотр';

  @override
  String get alreadyLatestVersion => 'Установлена последняя версия';

  @override
  String get checkUpdateFailed =>
      'Не удалось проверить обновления. Проверьте подключение к сети';

  @override
  String get onlineMarks => 'Онлайн-отметки';

  @override
  String get historyRecord => 'История';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get downloaded => 'Загружено';

  @override
  String get downloadTasks => 'Задачи загрузки';

  @override
  String get subtitleLibrary => 'Библиотека субтитров';

  @override
  String get all => 'Все';

  @override
  String get marked => 'Хочу послушать';

  @override
  String get listening => 'Слушаю';

  @override
  String get listened => 'Прослушано';

  @override
  String get replayMark => 'Переслушать';

  @override
  String get postponed => 'Отложено';

  @override
  String get switchToSmallGrid => 'Мелкая сетка';

  @override
  String get switchToList => 'Список';

  @override
  String get switchToLargeGrid => 'Крупная сетка';

  @override
  String get sort => 'Сортировка';

  @override
  String get noPlayHistory => 'Нет истории прослушивания';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearHistoryTitle => 'Очистить историю';

  @override
  String get clearHistoryConfirm =>
      'Вы уверены, что хотите очистить всю историю? Это действие необратимо.';

  @override
  String get popularNoSort => 'В режиме «Популярное» сортировка недоступна';

  @override
  String get recommendedNoSort =>
      'В режиме «Рекомендуемое» сортировка недоступна';

  @override
  String get showAllWorks => 'Показать все работы';

  @override
  String get showOnlySubtitled => 'Только с субтитрами';

  @override
  String selectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get deselectAll => 'Снять выделение';

  @override
  String get select => 'Выбрать';

  @override
  String get noDownloadTasks => 'Нет задач загрузки';

  @override
  String nFiles(int count) {
    return '$count файлов';
  }

  @override
  String errorWithMessage(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get deletionConfirmTitle => 'Подтвердить удаление';

  @override
  String deletionConfirmMessage(int count) {
    return 'Удалить $count выбранных задач загрузки? Загруженные файлы тоже будут удалены.';
  }

  @override
  String deletedNFiles(int count) {
    return 'Удалено файлов: $count';
  }

  @override
  String get downloadStatusPending => 'Ожидание';

  @override
  String get downloadStatusDownloading => 'Загрузка';

  @override
  String get downloadStatusCompleted => 'Завершено';

  @override
  String get downloadStatusFailed => 'Ошибка';

  @override
  String get downloadStatusPaused => 'Приостановлено';

  @override
  String translationFailed(String error) {
    return 'Ошибка перевода: $error';
  }

  @override
  String copiedToClipboard(String label, String text) {
    return 'Скопировано $label: $text';
  }

  @override
  String get loadingFileList => 'Загрузка списка файлов...';

  @override
  String loadFileListFailed(String error) {
    return 'Не удалось загрузить список файлов: $error';
  }

  @override
  String get playlistTitle => 'Плейлист';

  @override
  String get noAudioPlaying => 'Нет воспроизводимого аудио';

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get backward10s => 'Назад 10 сек';

  @override
  String get forward10s => 'Вперёд 10 сек';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String get repeatMode => 'Режим повтора';

  @override
  String get repeatOff => 'Выкл';

  @override
  String get repeatOne => 'Один трек';

  @override
  String get repeatAll => 'Весь список';

  @override
  String get addMark => 'Добавить отметку';

  @override
  String get viewDetail => 'Подробнее';

  @override
  String get volume => 'Громкость';

  @override
  String get sleepTimerTitle => 'Таймер';

  @override
  String get aboutToStop => 'Скоро остановится';

  @override
  String get remainingTime => 'Оставшееся время';

  @override
  String get finishCurrentTrack => 'Остановить после текущего трека';

  @override
  String addMinutes(int min) {
    return '+$min мин';
  }

  @override
  String get cancelTimer => 'Отменить таймер';

  @override
  String get duration => 'Длительность';

  @override
  String get specifyTime => 'Указать время';

  @override
  String get selectTimerDuration => 'Выберите длительность таймера';

  @override
  String get selectStopTime => 'Выберите время остановки';

  @override
  String get markWork => 'Отметить работу';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get remove => 'Удалить';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get addPlaylist => 'Добавить плейлист';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get enterPlaylistName => 'Введите название';

  @override
  String get privacySetting => 'Конфиденциальность';

  @override
  String get playlistDescription => 'Описание (необязательно)';

  @override
  String get addDescription => 'Добавить описание';

  @override
  String get enterPlaylistNameWarning => 'Введите название плейлиста';

  @override
  String get enterPlaylistLink => 'Введите ссылку на плейлист';

  @override
  String get switchAccountTitle => 'Переключить аккаунт';

  @override
  String switchAccountConfirm(String username) {
    return 'Переключиться на аккаунт «$username»?';
  }

  @override
  String switchedToAccount(String username) {
    return 'Переключено на аккаунт: $username';
  }

  @override
  String get switchFailed =>
      'Не удалось переключиться. Проверьте данные аккаунта';

  @override
  String switchFailedWithError(String error) {
    return 'Ошибка переключения: $error';
  }

  @override
  String get noAccounts => 'Нет аккаунтов';

  @override
  String get tapToAddAccount =>
      'Нажмите кнопку внизу справа, чтобы добавить аккаунт';

  @override
  String get currentAccount => 'Текущий аккаунт';

  @override
  String get switchAction => 'Переключить';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String deleteAccountConfirm(String username) {
    return 'Удалить аккаунт «$username»? Это действие необратимо.';
  }

  @override
  String get accountDeleted => 'Аккаунт удалён';

  @override
  String deletionFailedWithError(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get subtitleLibraryPriority => 'Приоритет библиотеки субтитров';

  @override
  String get selectSubtitlePriority =>
      'Выберите приоритет библиотеки субтитров при автозагрузке:';

  @override
  String get subtitlePriorityHighestDesc =>
      'Сначала искать в библиотеке, потом онлайн/загрузки';

  @override
  String get subtitlePriorityLowestDesc =>
      'Сначала искать онлайн/загрузки, потом в библиотеке';

  @override
  String get defaultSortSettings => 'Сортировка по умолчанию';

  @override
  String get defaultSortUpdated => 'Сортировка по умолчанию обновлена';

  @override
  String get translationSourceSettings => 'Настройки переводчика';

  @override
  String get selectTranslationProvider => 'Выберите службу перевода:';

  @override
  String get translationTargetLanguage => 'Целевой язык';

  @override
  String get autoSaveTranslatedLyrics =>
      'Автоматически сохранять переведенный текст';

  @override
  String get autoSaveTranslatedLyricsDesc =>
      'Сохранять перевод в папку «Сохраненные» библиотеки субтитров; при отключении показывать только во время текущего воспроизведения.';

  @override
  String get selectTranslationTargetLanguage => 'Выберите целевой язык:';

  @override
  String get translationLanguageFollowApp => 'Язык приложения';

  @override
  String get translationLanguageZhHans => 'Упрощённый китайский';

  @override
  String get translationLanguageZhHant => 'Традиционный китайский';

  @override
  String get translationLanguageEnglish => 'Английский';

  @override
  String get translationLanguageJapanese => 'Японский';

  @override
  String get translationLanguageRussian => 'Русский';

  @override
  String get translationLanguageCustom => 'Свой';

  @override
  String get translationCustomTargetLanguage => 'Свой целевой язык';

  @override
  String get translationCustomLanguageHint => 'Название языка, например Korean';

  @override
  String translationCustomLanguageLabel(String value) {
    return 'Свой: $value';
  }

  @override
  String get translationCustomTargetRequiresLlm => 'Требуется LLM перевод';

  @override
  String get needsConfiguration => 'Требуется настройка';

  @override
  String get llmTranslation => 'LLM перевод';

  @override
  String get goToConfigure => 'Настроить';

  @override
  String get subtitlePrioritySettingSubtitle =>
      'Приоритет библиотеки субтитров';

  @override
  String get defaultSortSettingTitle => 'Сортировка на главной по умолчанию';

  @override
  String get translationSource => 'Источник перевода';

  @override
  String get llmSettings => 'Настройки LLM';

  @override
  String get llmSettingsSubtitle => 'API URL, ключ и модель';

  @override
  String get audioFormatPreference => 'Аудиоформат';

  @override
  String get audioFormatSubtitle => 'Приоритет аудиоформатов';

  @override
  String get preloadNextTitle => 'Предзагрузка следующего';

  @override
  String get preloadNextSubtitle =>
      'Предзагрузка следующего трека в кэш до окончания текущего, чтобы избежать пауз при переключении';

  @override
  String get selectPreloadThreshold =>
      'Предзагрузка начнётся, когда оставшееся время ниже этого порога:';

  @override
  String get preloadOptionOff => 'Выключено';

  @override
  String preloadOptionSeconds(int seconds) {
    return '$seconds сек.';
  }

  @override
  String get preloadOptionCustom => 'Своё';

  @override
  String get preloadCustomInputTitle => 'Свой порог предзагрузки';

  @override
  String get preloadCustomInputHint => 'Секунды (1-300)';

  @override
  String get preloadCustomInputRangeError => 'Введите число от 1 до 300';

  @override
  String preloadCustomValueLabel(int value) {
    return '$value сек.';
  }

  @override
  String get keepScreenAwake => 'Не выключать экран';

  @override
  String get keepScreenAwakeDesc =>
      'Если включено, экран не будет гаснуть при наличии аудиодорожки, чтобы было удобнее читать субтитры.';

  @override
  String get audioHaptics => 'Аудиотактильная отдача (Beta)';

  @override
  String get audioHapticsDesc =>
      'Только для загруженного аудио и только на переднем плане. Устройство вибрирует в соответствии с аудиопризнаками. Может увеличить расход батареи.';

  @override
  String get audioHapticsIntensity => 'Интенсивность';

  @override
  String get audioGain => 'Глобальное усиление звука';

  @override
  String get audioGainDesc =>
      'Ослабляет или усиливает весь звук. 0 дБ сохраняет исходное звучание. Слишком высокое положительное усиление может вызвать искажения или повредить слух.';

  @override
  String get audioGainAttenuationDesc =>
      'Ослабляет весь звук. 0 дБ сохраняет исходное звучание.';

  @override
  String get audioGainPassthroughDesc =>
      'Недоступно, пока включён сквозной вывод звука.';

  @override
  String get blockingSettings => 'Блокировки';

  @override
  String get blockingSettingsSubtitle => 'Заблокированные теги, сэйю и кружки';

  @override
  String get audioPassthrough => 'Аудио-проход (Beta)';

  @override
  String get audioPassthroughDescWindows =>
      'Включить эксклюзивный режим WASAPI для lossless (требуется перезапуск)';

  @override
  String get audioPassthroughDescMac =>
      'Включить эксклюзивный режим CoreAudio для lossless';

  @override
  String get audioPassthroughDisableDesc => 'Отключить режим аудио-прохода';

  @override
  String get warning => 'Предупреждение';

  @override
  String get audioPassthroughWarning =>
      'Эта функция не полностью протестирована и может вызвать неожиданный вывод звука. Включить?';

  @override
  String get exclusiveModeEnabled =>
      'Эксклюзивный режим включён (применится после перезапуска)';

  @override
  String get audioPassthroughEnabled => 'Режим аудио-прохода включён';

  @override
  String get audioPassthroughDisabled => 'Режим аудио-прохода отключён';

  @override
  String get tagVoteSupport => 'За';

  @override
  String get tagVoteOppose => 'Против';

  @override
  String get tagVoted => 'Проголосовано';

  @override
  String get votedSupport => 'Вы проголосовали «за»';

  @override
  String get votedOppose => 'Вы проголосовали «против»';

  @override
  String get voteCancelled => 'Голос отменён';

  @override
  String voteFailed(String error) {
    return 'Ошибка голосования: $error';
  }

  @override
  String get blockThisTag => 'Заблокировать этот тег';

  @override
  String get copyTag => 'Копировать тег';

  @override
  String get addTag => 'Добавить тег';

  @override
  String loadTagsFailed(String error) {
    return 'Не удалось загрузить теги: $error';
  }

  @override
  String get selectAtLeastOneTag => 'Выберите хотя бы один тег';

  @override
  String get tagSubmitSuccess =>
      'Теги отправлены, ожидается обработка сервером';

  @override
  String get bindEmailFirst => 'Пожалуйста, привяжите email на www.asmr.one';

  @override
  String selectedNTags(int count) {
    return 'Выбрано тегов: $count:';
  }

  @override
  String get noMatchingTags => 'Нет совпадающих тегов';

  @override
  String get loadFailedRetry => 'Ошибка загрузки. Нажмите для повтора';

  @override
  String get refresh => 'Обновить';

  @override
  String get playlistPrivacyPrivate => 'Приватный';

  @override
  String get playlistPrivacyUnlisted => 'По ссылке';

  @override
  String get playlistPrivacyPublic => 'Публичный';

  @override
  String get systemPlaylistMarked => 'Отмеченное';

  @override
  String get systemPlaylistLiked => 'Понравившееся';

  @override
  String totalNWorks(int count) {
    return '$count работ';
  }

  @override
  String pageNOfTotal(int current, int total) {
    return 'Страница $current / $total';
  }

  @override
  String get translateTitle => 'Перевести';

  @override
  String get translateDescription => 'Перевести описание';

  @override
  String get translating => 'Перевод...';

  @override
  String translationFallbackNotice(String source) {
    return 'Перевод не удался, автоматически переключено на $source';
  }

  @override
  String get tagLabel => 'Теги';

  @override
  String get vaLabel => 'Сэйю';

  @override
  String get circleLabel => 'Кружок';

  @override
  String get releaseDate => 'Дата выхода';

  @override
  String get ratingLabel => 'Рейтинг';

  @override
  String get salesLabel => 'Продажи';

  @override
  String get priceLabel => 'Цена';

  @override
  String get durationLabel => 'Длительность';

  @override
  String get ageRatingLabel => 'Возрастной рейтинг';

  @override
  String get hasSubtitle => 'С субтитрами';

  @override
  String get noSubtitle => 'Без субтитров';

  @override
  String get description => 'Описание';

  @override
  String get fileList => 'Список файлов';

  @override
  String get series => 'Серия';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Переключить язык интерфейса';

  @override
  String get languageSystem => 'Системный';

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
  String get themeModeDark => 'Тёмный режим';

  @override
  String get themeModeLight => 'Светлый режим';

  @override
  String get themeModeSystem => 'Системный';

  @override
  String get colorSchemeOceanBlue => 'Океанский синий';

  @override
  String get colorSchemeForestGreen => 'Лесной зелёный';

  @override
  String get colorSchemeSunsetOrange => 'Закатный оранжевый';

  @override
  String get colorSchemeLavenderPurple => 'Лавандовый';

  @override
  String get colorSchemeSakuraPink => 'Сакура';

  @override
  String get colorSchemeDynamic => 'Динамический цвет';

  @override
  String get noData => 'Нет данных';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get networkError => 'Ошибка сети';

  @override
  String get timeout => 'Время ожидания истекло';

  @override
  String get playAll => 'Воспроизвести всё';

  @override
  String get download => 'Скачать';

  @override
  String get downloadAll => 'Скачать всё';

  @override
  String get downloading => 'Загрузка';

  @override
  String get downloadComplete => 'Загрузка завершена';

  @override
  String get downloadFailed => 'Ошибка загрузки';

  @override
  String get startDownload => 'Начать загрузку';

  @override
  String get confirmDeleteDownload =>
      'Удалить эту загрузку? Загруженные файлы тоже будут удалены.';

  @override
  String get deletedSuccessfully => 'Удалено';

  @override
  String get scanSubtitleLibrary => 'Сканировать библиотеку';

  @override
  String get scanning => 'Сканирование...';

  @override
  String get scanComplete => 'Сканирование завершено';

  @override
  String get noSubtitleFiles => 'Файлы субтитров не найдены';

  @override
  String subtitleFilesFound(int count) {
    return 'Найдено файлов субтитров: $count';
  }

  @override
  String get selectDirectory => 'Выбрать каталог';

  @override
  String get privacyModeSettings => 'Режим конфиденциальности';

  @override
  String get blurCover => 'Размыть обложку';

  @override
  String get maskTitle => 'Скрыть заголовок';

  @override
  String get customTitle => 'Пользовательский заголовок';

  @override
  String get privacyModeDesc =>
      'Скрыть информацию о воспроизведении в уведомлениях и медиа-управлении';

  @override
  String get audioFormatSettingsTitle => 'Настройки аудиоформата';

  @override
  String get preferredFormat => 'Предпочтительный формат';

  @override
  String get cacheSizeLimit => 'Лимит кеша';

  @override
  String get llmApiUrl => 'API URL';

  @override
  String get llmApiKey => 'API-ключ';

  @override
  String get llmModel => 'Модель';

  @override
  String get llmPrompt => 'Системный промпт';

  @override
  String get llmConcurrency => 'Параллелизм';

  @override
  String get llmTestTranslation => 'Тест перевода';

  @override
  String get llmTestSuccess => 'Тест успешен';

  @override
  String get llmTestFailed => 'Тест не пройден';

  @override
  String get subtitleTimingAdjustment => 'Настройка тайминга субтитров';

  @override
  String get playerLyricStyle => 'Стиль текста в плеере';

  @override
  String get floatingLyricStyle => 'Стиль плавающего текста';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String get fontColor => 'Цвет шрифта';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get transparency => 'Прозрачность';

  @override
  String get windowSize => 'Размер окна';

  @override
  String get playerButtonSettings => 'Кнопки плеера';

  @override
  String get showButton => 'Показать кнопку';

  @override
  String get buttonOrder => 'Порядок кнопок';

  @override
  String get workCardDisplaySettings =>
      'Настройки отображения карточек произведений';

  @override
  String get showTags => 'Показывать теги';

  @override
  String get showVa => 'Показывать сэйю';

  @override
  String get showRating => 'Показывать рейтинг';

  @override
  String get showPrice => 'Показывать цену';

  @override
  String get cardSize => 'Размер карточки';

  @override
  String get compact => 'Компактный';

  @override
  String get medium => 'Средний';

  @override
  String get full => 'Полный';

  @override
  String get workDetailDisplaySettings =>
      'Настройки отображения деталей произведения';

  @override
  String get infoSectionVisibility => 'Видимость разделов';

  @override
  String get imageSize => 'Размер изображения';

  @override
  String get showMetadata => 'Показывать метаданные';

  @override
  String get relatedRecommendations => 'Похожие работы';

  @override
  String get myTabsDisplaySettings => 'Настройки страницы «Моё»';

  @override
  String get showTab => 'Показать вкладку';

  @override
  String get tabOrder => 'Порядок вкладок';

  @override
  String get blockedItems => 'Заблокировано';

  @override
  String get blockedTags => 'Заблокированные теги';

  @override
  String get blockedVas => 'Заблокированные сэйю';

  @override
  String get blockedCircles => 'Заблокированные кружки';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get noBlockedItems => 'Нет заблокированных элементов';

  @override
  String get clearCache => 'Очистить кеш';

  @override
  String get clearCacheConfirm => 'Очистить весь кеш?';

  @override
  String get cacheCleared => 'Кеш очищен';

  @override
  String get imagePreview => 'Просмотр изображения';

  @override
  String get saveImage => 'Сохранить изображение';

  @override
  String get imageSaved => 'Изображение сохранено';

  @override
  String get saveImageFailed => 'Ошибка сохранения';

  @override
  String get logout => 'Выход';

  @override
  String get logoutConfirm => 'Выйти из аккаунта?';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get ratingDistribution => 'Распределение оценок';

  @override
  String reviewsCount(int count) {
    return 'Отзывов: $count';
  }

  @override
  String ratingsCount(int count) {
    return 'Всего $count оценок';
  }

  @override
  String get myReviews => 'Мои отзывы';

  @override
  String get noReviews => 'Нет отзывов';

  @override
  String get writeReview => 'Написать отзыв';

  @override
  String get editReview => 'Редактировать отзыв';

  @override
  String get deleteReview => 'Удалить отзыв';

  @override
  String get deleteReviewConfirm => 'Удалить этот отзыв?';

  @override
  String get reviewDeleted => 'Отзыв удалён';

  @override
  String get reviewContent => 'Текст отзыва';

  @override
  String get enterReviewContent => 'Введите текст отзыва...';

  @override
  String get submitReview => 'Отправить';

  @override
  String get reviewSubmitted => 'Отзыв отправлен';

  @override
  String reviewFailed(String error) {
    return 'Ошибка отзыва: $error';
  }

  @override
  String get notificationPermission => 'Разрешение уведомлений';

  @override
  String get mediaPermission => 'Медиатека';

  @override
  String get storagePermission => 'Хранилище';

  @override
  String get granted => 'Разрешено';

  @override
  String get denied => 'Отказано';

  @override
  String get requestPermission => 'Запросить';

  @override
  String get localDownloads => 'Локальные загрузки';

  @override
  String get offlinePlayback => 'Автономное воспроизведение';

  @override
  String get noDownloadedWorks => 'Нет загруженных работ';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get ignoreThisVersion => 'Пропустить эту версию';

  @override
  String get remindLater => 'Напомнить позже';

  @override
  String get updateNow => 'Обновить сейчас';

  @override
  String get fetchFailed => 'Не удалось получить';

  @override
  String operationFailedWithError(String error) {
    return 'Ошибка операции: $error';
  }

  @override
  String get aboutSubtitle => 'Проверка обновлений, лицензии и др.';

  @override
  String get currentCacheSize => 'Текущий размер кэша';

  @override
  String cacheLimitLabelMB(int size) {
    return 'Лимит: $sizeМБ';
  }

  @override
  String get cacheUsagePercent => 'Использование';

  @override
  String get autoCleanTitle => 'Автоочистка';

  @override
  String get autoCleanDescription =>
      '• Кэш автоматически очищается при превышении лимита\n• Удаление до 80% от лимита\n• Используется стратегия LRU (наименее используемые)';

  @override
  String get autoCleanDescriptionShort =>
      '• Кэш автоматически очищается при превышении лимита\n• Удаление до 80% от лимита';

  @override
  String get confirmClear => 'Подтвердить очистку';

  @override
  String get confirmClearCacheMessage =>
      'Вы уверены, что хотите очистить весь кэш? Это действие нельзя отменить.';

  @override
  String clearCacheFailedWithError(String error) {
    return 'Ошибка очистки кэша: $error';
  }

  @override
  String get hasNewVersion => 'Новая версия';

  @override
  String get themeMode => 'Режим темы';

  @override
  String get colorTheme => 'Цветовая тема';

  @override
  String get themePreview => 'Предпросмотр темы';

  @override
  String get themeModeSystemDesc => 'Автоматическая адаптация к системной теме';

  @override
  String get themeModeLightDesc => 'Всегда использовать светлую тему';

  @override
  String get themeModeDarkDesc => 'Всегда использовать тёмную тему';

  @override
  String get colorSchemeOceanBlueDesc => 'Синий, синий, синий!';

  @override
  String get colorSchemeSakuraPinkDesc => '( ゜- ゜)つロ Ура~';

  @override
  String get colorSchemeSunsetOrangeDesc => 'Смена тем — обязательно ✍🏻✍🏻✍🏻';

  @override
  String get colorSchemeLavenderPurpleDesc => 'Братан, братан...';

  @override
  String get colorSchemeForestGreenDesc => 'Зелень, зелень, зелень';

  @override
  String get colorSchemeDynamicDesc =>
      'Использовать цвета обоев системы (Android 12+)';

  @override
  String get primaryContainer => 'Основной контейнер';

  @override
  String get secondaryContainer => 'Вторичный контейнер';

  @override
  String get tertiaryContainer => 'Третичный контейнер';

  @override
  String get surfaceColor => 'Поверхность';

  @override
  String get playerButtonSettingsSubtitle =>
      'Настроить порядок кнопок управления плеером';

  @override
  String get playerLyricStyleSubtitle =>
      'Настроить стиль субтитров мини- и полноэкранного плеера';

  @override
  String get workDetailDisplaySubtitle =>
      'Управление информацией на странице деталей';

  @override
  String get workCardDisplaySubtitle =>
      'Управление информацией на карточках работ';

  @override
  String get myTabsDisplaySubtitle =>
      'Управление отображением вкладок на странице «Моё»';

  @override
  String get pageSizeSettings => 'Элементов на странице';

  @override
  String pageSizeCurrent(int size) {
    return 'Текущее: $size элементов/стр.';
  }

  @override
  String currentSettingLabel(String value) {
    return 'Текущее: $value';
  }

  @override
  String setToValue(String value) {
    return 'Установлено: $value';
  }

  @override
  String get llmConfigRequiredMessage =>
      'Для перевода LLM требуется API Key. Сначала настройте его в параметрах.';

  @override
  String get autoSwitchedToLlm => 'Автопереключение: перевод LLM';

  @override
  String get translationDescGoogle => 'Требуется доступ к сервисам Google';

  @override
  String get translationDescYoudao => 'Работает с сетью по умолчанию';

  @override
  String get translationDescMicrosoft => 'Работает с сетью по умолчанию';

  @override
  String get translationDescLlm =>
      'OpenAI-совместимый API, требуется ручная настройка API Key';

  @override
  String get audioPassthroughDescAndroid =>
      'Разрешить вывод необработанного битового потока (AC3/DTS) на внешний декодер. Может занять эксклюзивный доступ к аудио.';

  @override
  String get permissionExplanation => 'Описание разрешений';

  @override
  String get backgroundRunningPermission => 'Разрешение на фоновую работу';

  @override
  String get notificationPermissionDesc =>
      'Для отображения уведомлений о воспроизведении, позволяющих управлять с экрана блокировки и панели уведомлений.';

  @override
  String get backgroundRunningPermissionDesc =>
      'Исключает приложение из оптимизации батареи для непрерывного воспроизведения в фоне.';

  @override
  String get notificationGrantedStatus =>
      'Разрешено — можно отображать уведомления и элементы управления';

  @override
  String get notificationDeniedStatus => 'Не разрешено — нажмите для запроса';

  @override
  String get backgroundGrantedStatus =>
      'Разрешено — приложение может работать в фоне';

  @override
  String get backgroundDeniedStatus => 'Не разрешено — нажмите для запроса';

  @override
  String get notificationPermissionGranted =>
      'Разрешение на уведомления получено';

  @override
  String get notificationPermissionDenied =>
      'Разрешение на уведомления отклонено';

  @override
  String requestNotificationFailed(String error) {
    return 'Ошибка запроса разрешения на уведомления: $error';
  }

  @override
  String get backgroundPermissionGranted =>
      'Разрешение на фоновую работу получено';

  @override
  String get backgroundPermissionDenied =>
      'Разрешение на фоновую работу отклонено';

  @override
  String requestBackgroundFailed(String error) {
    return 'Ошибка запроса разрешения на фоновую работу: $error';
  }

  @override
  String permissionRequired(String permission) {
    return 'Требуется $permission';
  }

  @override
  String permissionPermanentlyDenied(String permission) {
    return '$permission отклонено навсегда. Включите вручную в настройках системы.';
  }

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get permissionsAndroidOnly =>
      'Управление разрешениями доступно только на Android';

  @override
  String get permissionsNotNeeded =>
      'На других платформах ручное управление разрешениями не требуется';

  @override
  String get refreshPermissionStatus => 'Обновить статус разрешений';

  @override
  String deleteFileConfirm(String fileName) {
    return 'Удалить \"$fileName\"?';
  }

  @override
  String deleteSelectedFilesConfirm(int count) {
    return 'Удалить $count выбранных файлов?';
  }

  @override
  String get deleted => 'Удалено';

  @override
  String cannotOpenFolder(String path) {
    return 'Не удалось открыть папку: $path';
  }

  @override
  String openFolderFailed(String error) {
    return 'Ошибка открытия папки: $error';
  }

  @override
  String get reloadingFromDisk => 'Перезагрузка с диска...';

  @override
  String get refreshComplete => 'Обновление завершено';

  @override
  String refreshFailed(String error) {
    return 'Ошибка обновления: $error';
  }

  @override
  String deleteSelectedWorksConfirm(int count) {
    return 'Удалить $count выбранных работ?';
  }

  @override
  String partialDeleteFailed(String error) {
    return 'Частичная ошибка удаления: $error';
  }

  @override
  String deletedNOfTotal(int success, int total) {
    return 'Удалено $success/$total задач';
  }

  @override
  String deleteFailedWithError(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get noWorkMetadataForOffline =>
      'У этой загрузки нет сохранённых данных о работе для просмотра офлайн';

  @override
  String openWorkDetailFailed(String error) {
    return 'Ошибка открытия деталей работы: $error';
  }

  @override
  String get noLocalDownloads => 'Нет локальных загрузок';

  @override
  String get exitSelection => 'Выйти из выбора';

  @override
  String get reload => 'Перезагрузить';

  @override
  String get openFolder => 'Открыть папку';

  @override
  String get playlistLink => 'Ссылка на плейлист';

  @override
  String get playlistLinkHint =>
      'Вставьте ссылку на плейлист, например:\nhttps://www.asmr.one/playlist?id=...';

  @override
  String get unrecognizedPlaylistLink =>
      'Нераспознанная ссылка или ID плейлиста';

  @override
  String get addingPlaylist => 'Добавление плейлиста...';

  @override
  String get playlistAddedSuccess => 'Плейлист успешно добавлен';

  @override
  String get addFailed => 'Ошибка добавления';

  @override
  String get playlistNotFound => 'Плейлист не существует или был удалён';

  @override
  String get noPermissionToAccessPlaylist =>
      'Нет прав доступа к этому плейлисту';

  @override
  String get networkConnectionFailed =>
      'Ошибка сетевого подключения, проверьте сеть';

  @override
  String addFailedWithError(String error) {
    return 'Ошибка добавления: $error';
  }

  @override
  String get creatingPlaylist => 'Создание плейлиста...';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Плейлист \"$name\" создан';
  }

  @override
  String createFailedWithError(String error) {
    return 'Ошибка создания: $error';
  }

  @override
  String get noPlaylists => 'Нет плейлистов';

  @override
  String get noPlaylistsDescription =>
      'Вы ещё не создали и не добавили в избранное ни одного плейлиста';

  @override
  String get myPlaylists => 'Мои плейлисты';

  @override
  String totalNItems(int count) {
    return 'Всего $count записей';
  }

  @override
  String get systemPlaylistCannotDelete => 'Системные плейлисты нельзя удалить';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get unfavoritePlaylist => 'Убрать из избранного';

  @override
  String get deletePlaylistConfirm =>
      'Удаление необратимо. Пользователи, добавившие этот плейлист в избранное, потеряют к нему доступ. Продолжить?';

  @override
  String unfavoritePlaylistConfirm(String name) {
    return 'Убрать \"$name\" из избранного?';
  }

  @override
  String get unfavorite => 'Убрать из избранного';

  @override
  String get deleting => 'Удаление...';

  @override
  String get deleteSuccess => 'Успешно удалено';

  @override
  String get onlyOwnerCanEdit => 'Редактировать может только автор плейлиста';

  @override
  String get editPlaylist => 'Редактировать плейлист';

  @override
  String get playlistNameRequired => 'Название плейлиста не может быть пустым';

  @override
  String get privacyDescPrivate => 'Только вы можете просматривать';

  @override
  String get privacyDescUnlisted =>
      'Только люди со ссылкой могут просматривать';

  @override
  String get privacyDescPublic => 'Любой может просматривать';

  @override
  String get addWorks => 'Добавить работы';

  @override
  String get addWorksInputHint =>
      'Введите текст с номерами работ, RJ-номера определяются автоматически';

  @override
  String get workId => 'Номер работы';

  @override
  String get workIdHint => 'Например: RJ123456\nrj233333';

  @override
  String detectedNWorkIds(int count) {
    return 'Обнаружено $count номеров работ';
  }

  @override
  String addNWorks(int count) {
    return 'Добавить $count';
  }

  @override
  String get noValidWorkIds =>
      'Не найдено действительных номеров работ (начинающихся с RJ)';

  @override
  String addingNWorks(int count) {
    return 'Добавление $count работ...';
  }

  @override
  String addedNWorksSuccess(int count) {
    return 'Успешно добавлено $count работ';
  }

  @override
  String get removeWork => 'Удалить работу';

  @override
  String removeWorkConfirm(String title) {
    return 'Удалить «$title» из плейлиста?';
  }

  @override
  String get removeSuccess => 'Успешно удалено';

  @override
  String removeFailedWithError(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get saving => 'Сохранение...';

  @override
  String get saveSuccess => 'Сохранено';

  @override
  String saveFailedWithError(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get noWorks => 'Нет работ';

  @override
  String get playlistNoWorksDescription =>
      'В этот плейлист ещё не добавлено ни одной работы';

  @override
  String get lastUpdated => 'Последнее обновление';

  @override
  String get createdTime => 'Дата создания';

  @override
  String nWorksCount(int count) {
    return '$count произведений';
  }

  @override
  String nPlaysCount(int count) {
    return '$count воспроизведений';
  }

  @override
  String get removeFromPlaylist => 'Удалить из плейлиста';

  @override
  String get checkNetworkOrRetry =>
      'Проверьте сетевое подключение или повторите попытку позже';

  @override
  String get reachedEnd => 'Вы достигли конца~';

  @override
  String excludedNWorks(int count) {
    return 'Исключено $count работ';
  }

  @override
  String pageExcludedNWorks(int count) {
    return 'На этой странице исключено $count работ';
  }

  @override
  String get noSubtitlesAvailable => 'Субтитры отсутствуют';

  @override
  String get translateLyrics => 'Перевести текст';

  @override
  String get fullscreenLyrics => 'Текст на весь экран';

  @override
  String get showOriginalLyrics => 'Показать оригинал';

  @override
  String get showTranslatedLyrics => 'Показать перевод';

  @override
  String get translatingLyrics => 'Перевод...';

  @override
  String get lyricTranslationFailed => 'Не удалось перевести текст';

  @override
  String get lyricTranslationConfirmMessage =>
      'Перевести текст текущего трека и сразу показать результат. При включенном автосохранении одноименный файл .lrc в библиотеке субтитров будет перезаписан. Если переключить трек во время перевода, результат будет отброшен.';

  @override
  String get unlock => 'Разблокировать';

  @override
  String get backToCover => 'Вернуться к обложке';

  @override
  String get lyricHintTapCover =>
      'Нажмите на обложку или название для перехода к субтитрам';

  @override
  String get floatingSubtitle => 'Плавающие субтитры';

  @override
  String get appendMode => 'Режим добавления';

  @override
  String get appendModeStatusOn => 'Режим добавления: Вкл';

  @override
  String get appendModeStatusOff => 'Режим добавления: Выкл';

  @override
  String get playlistEmpty => 'Плейлист пуст';

  @override
  String get appendModeEnabled => 'Режим добавления включён';

  @override
  String get appendModeHint =>
      'Следующие нажатия на аудио добавят треки в конец текущего плейлиста, а не заменят его.\nДубликаты не добавляются.';

  @override
  String get gotIt => 'Понятно';

  @override
  String nMinutes(int count) {
    return '$count мин';
  }

  @override
  String nHours(int count) {
    return '$count ч';
  }

  @override
  String get titleLabel => 'Название';

  @override
  String get rjNumberLabel => 'RJ номер';

  @override
  String get workIdLabel => 'ID работы';

  @override
  String get tapToViewRatingDetail => 'Нажмите для просмотра деталей рейтинга';

  @override
  String priceInYen(int price) {
    return '$price иен';
  }

  @override
  String soldCount(String count) {
    return 'Продано: $count';
  }

  @override
  String get circleAndVaSection => 'Кружок | Сэйю';

  @override
  String get subtitleBadge => 'Субтитры';

  @override
  String get otherEditions => 'Другие версии';

  @override
  String tenThousandSuffix(String count) {
    return '$count тыс.';
  }

  @override
  String get packingWork => 'Упаковка работы...';

  @override
  String get workDirectoryNotExist => 'Каталог работы не существует';

  @override
  String get packingFailed => 'Ошибка упаковки';

  @override
  String exportSuccess(String path) {
    return 'Экспорт выполнен: $path';
  }

  @override
  String exportFailed(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get exportAsZip => 'Экспорт в ZIP';

  @override
  String get offlineBadge => 'Офлайн';

  @override
  String loadFilesFailed(String error) {
    return 'Ошибка загрузки файлов: $error';
  }

  @override
  String get unknown => 'Неизвестно';

  @override
  String get noPlayableAudioFiles => 'Воспроизводимые аудиофайлы не найдены';

  @override
  String cannotFindAudioFile(String title) {
    return 'Аудиофайл не найден: $title';
  }

  @override
  String nowPlayingNOfTotal(String title, int current, int total) {
    return 'Воспроизведение: $title ($current/$total)';
  }

  @override
  String get noAudioCannotLoadSubtitle =>
      'Нет воспроизводимого аудио, невозможно загрузить субтитры';

  @override
  String get loadSubtitle => 'Загрузить субтитры';

  @override
  String get loadSubtitleConfirm =>
      'Загрузить этот файл как субтитры для текущего аудио?';

  @override
  String get subtitleFile => 'Файл субтитров';

  @override
  String get currentAudio => 'Текущее аудио';

  @override
  String get subtitleAutoRestoreNote =>
      'При переключении аудио субтитры автоматически вернутся к стандартному подбору';

  @override
  String get confirmLoad => 'Подтвердить загрузку';

  @override
  String get loadingSubtitle => 'Загрузка субтитров...';

  @override
  String subtitleLoadSuccess(String title) {
    return 'Субтитры загружены: $title';
  }

  @override
  String subtitleLoadFailed(String error) {
    return 'Ошибка загрузки субтитров: $error';
  }

  @override
  String get cannotPreviewImageMissingInfo =>
      'Невозможно предпросмотр изображения: недостаточно данных';

  @override
  String get cannotFindImageFile => 'Файл изображения не найден';

  @override
  String get cannotPreviewTextMissingInfo =>
      'Невозможно предпросмотр текста: недостаточно данных';

  @override
  String get cannotPreviewPdfMissingInfo =>
      'Невозможно предпросмотр PDF: недостаточно данных';

  @override
  String get cannotPlayVideoMissingId =>
      'Невозможно воспроизвести видео: отсутствует ID файла';

  @override
  String get cannotPlayVideoMissingParams =>
      'Невозможно воспроизвести видео: отсутствуют параметры';

  @override
  String get cannotPlayDirectly => 'Невозможно воспроизвести напрямую';

  @override
  String get noVideoPlayerFound => 'Поддерживаемый видеоплеер не найден.';

  @override
  String get youCan => 'Вы можете:';

  @override
  String get copyLinkToExternalPlayer =>
      '1. Скопировать ссылку во внешний плеер (MX Player, VLC и др.)';

  @override
  String get openInBrowserOption => '2. Открыть в браузере';

  @override
  String playVideoError(String error) {
    return 'Ошибка воспроизведения видео: $error';
  }

  @override
  String get noFiles => 'Нет файлов';

  @override
  String get resourceFiles => 'Файлы ресурсов';

  @override
  String resourceFilesTranslated(int count) {
    return 'Файлы ресурсов (переведено $count)';
  }

  @override
  String get translationOriginal => 'Ориг';

  @override
  String get translationTranslated => 'Перев';

  @override
  String copiedName(String title) {
    return 'Имя скопировано: $title';
  }

  @override
  String translationComplete(int count) {
    return 'Перевод завершён: $count элементов';
  }

  @override
  String get noContentToTranslate => 'Нет содержимого для перевода';

  @override
  String get preparingTranslation => 'Подготовка перевода...';

  @override
  String translatingProgress(int current, int total) {
    return 'Перевод $current/$total';
  }

  @override
  String nItems(int count) {
    return '$count элементов';
  }

  @override
  String get loadAsSubtitle => 'Загрузить как субтитры';

  @override
  String get preview => 'Предпросмотр';

  @override
  String openVideoFileError(String error) {
    return 'Ошибка открытия видеофайла: $error';
  }

  @override
  String cannotOpenVideoFile(String message) {
    return 'Невозможно открыть видеофайл: $message';
  }

  @override
  String get noFileTreeInfo => 'Нет информации о дереве файлов';

  @override
  String get workFolderNotExist => 'Папка работы не существует';

  @override
  String get cannotPlayAudioMissingId =>
      'Невозможно воспроизвести аудио: отсутствует ID файла';

  @override
  String get audioFileNotExist => 'Аудиофайл не существует';

  @override
  String get noPreviewableImages => 'Изображения для предпросмотра не найдены';

  @override
  String get cannotPreviewTextMissingId =>
      'Невозможно предпросмотр текста: отсутствует ID файла';

  @override
  String get cannotFindFilePath => 'Путь к файлу не найден';

  @override
  String fileNotExist(String title) {
    return 'Файл не существует: $title';
  }

  @override
  String get cannotPreviewPdfMissingId =>
      'Невозможно предпросмотр PDF: отсутствует ID файла';

  @override
  String get videoFileNotExist => 'Видеофайл не существует';

  @override
  String get cannotOpenVideo => 'Невозможно открыть видео';

  @override
  String errorInfo(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get installVideoPlayerApp =>
      'Установите видеоплеер (VLC, MX Player и др.)';

  @override
  String get filePathLabel => 'Путь к файлу:';

  @override
  String get noDownloadedFiles => 'Нет загруженных файлов';

  @override
  String get offlineFiles => 'Офлайн-файлы';

  @override
  String unsupportedFileType(String title) {
    return 'Этот тип файлов не поддерживается: $title';
  }

  @override
  String get deleteFilePrompt => 'Вы уверены, что хотите удалить этот файл?';

  @override
  String deletedItem(String title) {
    return 'Удалено: $title';
  }

  @override
  String get selectAtLeastOneFile => 'Выберите хотя бы один файл';

  @override
  String addedNFilesToDownloadQueue(int count) {
    return '$count файлов добавлено в очередь загрузки';
  }

  @override
  String downloadedAndSelected(int downloaded, int selected) {
    return 'Загружено $downloaded · Выбрано $selected';
  }

  @override
  String downloadN(int count) {
    return 'Скачать ($count)';
  }

  @override
  String get checkingDownloadedFiles => 'Проверка загруженных файлов...';

  @override
  String get noDownloadableFiles => 'Нет файлов для загрузки';

  @override
  String get selectFilesToDownload => 'Выбрать файлы для загрузки';

  @override
  String downloadedNCount(int count) {
    return 'Загружено $count';
  }

  @override
  String selectedNCount(int count) {
    return 'Выбрано $count';
  }

  @override
  String get pleaseEnterServerAddress => 'Введите адрес сервера';

  @override
  String get pleaseEnterUsername => 'Введите имя пользователя';

  @override
  String get pleaseEnterPassword => 'Введите пароль';

  @override
  String get notTestedYet => 'Ещё не тестировалось';

  @override
  String latencyResultDetail(String latency, String status) {
    return 'Задержка $latency ($status)';
  }

  @override
  String connectionFailedWithDetail(String error) {
    return 'Ошибка подключения: $error';
  }

  @override
  String get noAccountTapToRegister => 'Нет аккаунта? Нажмите для регистрации';

  @override
  String get haveAccountTapToLogin => 'Есть аккаунт? Нажмите для входа';

  @override
  String get cannotDeleteActiveAccount =>
      'Невозможно удалить текущий активный аккаунт';

  @override
  String get selectAccount => 'Выбрать аккаунт';

  @override
  String get noSavedAccounts => 'Нет сохранённых аккаунтов';

  @override
  String get addAccountToGetStarted => 'Добавьте аккаунт, чтобы начать';

  @override
  String get unknownHost => 'Неизвестный хост';

  @override
  String lastUsedTime(String time) {
    return 'Последнее использование: $time';
  }

  @override
  String daysAgo(int count) {
    return '$count дней назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count часов назад';
  }

  @override
  String minutesAgo(int count) {
    return '$count минут назад';
  }

  @override
  String get justNow => 'Только что';

  @override
  String get confirmDelete => 'Подтвердить удаление';

  @override
  String deleteSelectedConfirm(int count) {
    return 'Удалить $count выбранных элементов?';
  }

  @override
  String deletedNOfTotalItems(int success, int total) {
    return 'Удалено $success/$total элементов';
  }

  @override
  String get importingSubtitleFile => 'Импорт файла субтитров...';

  @override
  String get preparingImport => 'Подготовка импорта...';

  @override
  String get preparingExtract => 'Подготовка распаковки...';

  @override
  String get importSubtitleFile => 'Импорт файла субтитров';

  @override
  String get supportedSubtitleFormats =>
      'Поддержка .srt, .vtt, .lrc и других форматов субтитров';

  @override
  String get importFolder => 'Импорт папки';

  @override
  String get importFolderDesc =>
      'Сохраняет структуру папок, импортирует только файлы субтитров';

  @override
  String get importArchive => 'Импорт архива';

  @override
  String get importArchiveDesc =>
      'Поддержка ZIP-архивов без пароля.\nДля массового импорта сожмите все в один архив.';

  @override
  String get subtitleLibraryGuide => 'Руководство по библиотеке субтитров';

  @override
  String get subtitleLibraryFunction => 'Функция библиотеки субтитров';

  @override
  String get subtitleLibraryFunctionDesc =>
      'Хранение импортированных/сохранённых субтитров с поддержкой авто/ручной загрузки при воспроизведении';

  @override
  String get subtitleAutoLoad => 'Автозагрузка субтитров';

  @override
  String get subtitleAutoLoadDesc =>
      'При воспроизведении аудио система автоматически ищет подходящие субтитры:';

  @override
  String get smartCategoryAndMark => 'Умная классификация и маркировка';

  @override
  String get open => 'Открыть';

  @override
  String get moveTo => 'Переместить в';

  @override
  String get rename => 'Переименовать';

  @override
  String get newName => 'Новое имя';

  @override
  String get renameSuccess => 'Переименование выполнено';

  @override
  String get renameFailed => 'Ошибка переименования';

  @override
  String deleteItemConfirm(String title) {
    return 'Удалить \"$title\"?';
  }

  @override
  String get deleteFolderContentsWarning =>
      'Всё содержимое папки будет удалено.';

  @override
  String get deleteFailed => 'Ошибка удаления';

  @override
  String subtitleLoaded(String title) {
    return 'Субтитры загружены: $title';
  }

  @override
  String get moveSuccess => 'Перемещение выполнено';

  @override
  String get moveFailed => 'Ошибка перемещения';

  @override
  String previewFailed(String error) {
    return 'Ошибка предпросмотра: $error';
  }

  @override
  String openFailed(String error) {
    return 'Ошибка открытия: $error';
  }

  @override
  String get back => 'Назад';

  @override
  String get subtitleLibraryEmpty => 'Библиотека субтитров пуста';

  @override
  String get tapToImportSubtitle => 'Нажмите + для импорта субтитров';

  @override
  String get importSubtitle => 'Импорт субтитров';

  @override
  String get sampleSubtitleContent => '♪ Пример субтитров ♪';

  @override
  String get presetStyles => 'Предустановленные стили';

  @override
  String get backgroundOpacity => 'Непрозрачность фона';

  @override
  String get colorSettings => 'Настройки цвета';

  @override
  String get shapeSettings => 'Настройки формы';

  @override
  String get cornerRadius => 'Радиус скругления';

  @override
  String get horizontalPadding => 'Горизонтальный отступ';

  @override
  String get verticalPadding => 'Вертикальный отступ';

  @override
  String get resetStyle => 'Сбросить стиль';

  @override
  String get resetStyleConfirm => 'Восстановить стиль по умолчанию?';

  @override
  String get restoreDefaultStyle => 'Восстановить стиль по умолчанию';

  @override
  String get reset => 'Сброс';

  @override
  String noBlockedItemsOfType(String type) {
    return 'Нет заблокированных $type';
  }

  @override
  String unblockedItem(String item) {
    return 'Разблокировано: $item';
  }

  @override
  String addBlockedItem(String type) {
    return 'Заблокировать $type';
  }

  @override
  String blockedItemName(String type) {
    return 'Название $type';
  }

  @override
  String enterBlockedItemHint(String type) {
    return 'Введите $type для блокировки';
  }

  @override
  String blockedItemAdded(String item) {
    return 'Заблокировано: $item';
  }

  @override
  String workCountLabel(int count) {
    return 'Работ: $count';
  }

  @override
  String get miniPlayer => 'Мини-плеер';

  @override
  String get lineHeight => 'Высота строки';

  @override
  String get portraitPlayerBelowCover => 'Портретный плеер (под обложкой)';

  @override
  String get fullscreenSubtitleMode =>
      'Полноэкранные субтитры (портрет/ландшафт)';

  @override
  String get activeSubtitleFontSize => 'Размер активных субтитров';

  @override
  String get inactiveSubtitleFontSize => 'Размер неактивных субтитров';

  @override
  String get restoreDefaultSettings => 'Восстановить настройки по умолчанию';

  @override
  String get confirmRestoreDefaultSettings =>
      'Восстановить настройки по умолчанию?';

  @override
  String get guideInPrefix => 'В ';

  @override
  String get guideParsedFolder => '<Распознанные>';

  @override
  String get guideFindWorkDesc =>
      ' папке найти соответствующие произведения\nПоддерживаемый формат папки: RJ123456';

  @override
  String get guideSavedFolder => '<Сохранённые>';

  @override
  String get guideFindSubtitleDesc => ' папке найти отдельные файлы субтитров';

  @override
  String get guideMatchRule =>
      'Правило соответствия: имя файла субтитров совпадает с именем аудиофайла (с расширением или без)';

  @override
  String get guideRecognizedWorkPrefix =>
      'Распознанные произведения получают зелёный ';

  @override
  String get guideTagSuffix => ' тег, а значки аудиофайлов получают ';

  @override
  String get guideSubtitleMatchSuffix =>
      ' отметку, указывающую на совпадение в библиотеке субтитров';

  @override
  String get guideAutoRecognizeRJ =>
      'Автоматическое распознавание формата RJ при импорте, категоризация в <Распознанные>';

  @override
  String get guideAutoAddRJPrefix =>
      'Папки с числовыми именами автоматически получают префикс RJ (напр. 123456 → RJ123456)';

  @override
  String get unknownFile => 'Неизвестный файл';

  @override
  String deleteWithCount(int count) {
    return 'Удалить ($count)';
  }

  @override
  String get searchSubtitles => 'Поиск субтитров...';

  @override
  String nFilesWithSize(int count, String size) {
    return '$count файлов • $size';
  }

  @override
  String get rootDirectory => 'Корень';

  @override
  String get goToParent => 'На уровень выше';

  @override
  String moveToTarget(String name) {
    return 'Переместить в: $name';
  }

  @override
  String get noSubfoldersHere => 'В этой директории нет подпапок';

  @override
  String addedToPlaylist(String name) {
    return 'Добавлено в плейлист \"$name\"';
  }

  @override
  String removedFromPlaylist(String name) {
    return 'Удалено из плейлиста \"$name\"';
  }

  @override
  String get alreadyFavorited => 'В избранном';

  @override
  String loadImageFailedWithError(String error) {
    return 'Не удалось загрузить изображение\n$error';
  }

  @override
  String get noImageAvailable => 'Нет доступных изображений';

  @override
  String get storagePermissionRequiredForImage =>
      'Для сохранения изображений требуется разрешение на хранилище';

  @override
  String get savedToGallery => 'Сохранено в галерею';

  @override
  String get saveCoverImage => 'Сохранить обложку';

  @override
  String savedToPath(String path) {
    return 'Сохранено в: $path';
  }

  @override
  String get doubleTapToZoom =>
      'Двойное нажатие для увеличения · Щипок для масштабирования';

  @override
  String getStatusFailed(String error) {
    return 'Не удалось получить статус: $error';
  }

  @override
  String get deleteRecord => 'Удалить запись';

  @override
  String deletePlayRecordConfirm(String title) {
    return 'Удалить запись воспроизведения для \"$title\"?';
  }

  @override
  String get notPlayedYet => 'Ещё не воспроизводилось';

  @override
  String playbackFailed(String error) {
    return 'Ошибка воспроизведения: $error';
  }

  @override
  String get storagePermissionRequired => 'Требуется разрешение на хранилище';

  @override
  String get storagePermissionForGalleryDesc =>
      'Для сохранения изображений требуется доступ к галерее. Предоставьте разрешение в настройках.';

  @override
  String get goToSettings => 'Перейти в настройки';

  @override
  String get imageSavedToGallery => 'Изображение сохранено в галерею';

  @override
  String imageSavedToPath(String path) {
    return 'Изображение сохранено: $path';
  }

  @override
  String get pullDownForNextPage => 'Потяните вниз для следующей страницы';

  @override
  String get releaseForNextPage =>
      'Отпустите для перехода на следующую страницу';

  @override
  String get jumpTo => 'Перейти';

  @override
  String get goToPageTitle => 'Перейти на страницу';

  @override
  String pageNumberRange(int max) {
    return 'Страница (1-$max)';
  }

  @override
  String get enterPageNumber => 'Введите номер страницы';

  @override
  String enterValidPageNumber(int max) {
    return 'Введите корректный номер страницы (1-$max)';
  }

  @override
  String get previousPage => 'Предыдущая';

  @override
  String get nextPage => 'Следующая';

  @override
  String get localPdfNotExist => 'Локальный PDF-файл не существует';

  @override
  String get cannotOpenPdf => 'Невозможно открыть PDF-файл';

  @override
  String loadPdfFailed(String error) {
    return 'Не удалось загрузить PDF: $error';
  }

  @override
  String pdfPageOfTotal(int current, int total) {
    return 'Страница $current из $total';
  }

  @override
  String get loadingPdf => 'Загрузка PDF...';

  @override
  String get pdfPathInvalid => 'Некорректный путь к PDF-файлу';

  @override
  String get desktopPdfPreviewNotSupported =>
      'Предварительный просмотр PDF на рабочем столе пока не поддерживается';

  @override
  String get openWithSystemApp => 'Открыть системным приложением';

  @override
  String renderPdfFailed(String error) {
    return 'Ошибка рендеринга PDF: $error';
  }

  @override
  String get ratingDetails => 'Подробности оценки';

  @override
  String get selectSaveDirectory => 'Выбрать папку для сохранения';

  @override
  String get noSubtitleContentToSave =>
      'Нет содержимого субтитров для сохранения';

  @override
  String get savedToSubtitleLibrary => 'Сохранено в библиотеку субтитров';

  @override
  String get translatedLyricsNotSaved =>
      'Перевод завершен; он отображается только во время текущего воспроизведения.';

  @override
  String get saveToLocal => 'Сохранить локально';

  @override
  String get selectDirectoryToSaveFile => 'Выбрать папку для сохранения файла';

  @override
  String get saveToSubtitleLibrary => 'Сохранить в библиотеку субтитров';

  @override
  String get saveToSubtitleLibraryDesc =>
      'Сохранить в папку \"Сохранённые\" в библиотеке субтитров';

  @override
  String get saveToFile => 'Сохранить в файл';

  @override
  String get noContentToSave => 'Нет содержимого для сохранения';

  @override
  String fileSavedToPath(String path) {
    return 'Файл сохранён: $path';
  }

  @override
  String get localFileNotExist =>
      'Локальный файл не существует, попробуйте перезагрузить';

  @override
  String loadTextFailed(String error) {
    return 'Не удалось загрузить текст: $error';
  }

  @override
  String get previewMode => 'Режим предпросмотра';

  @override
  String get editMode => 'Режим редактирования';

  @override
  String get showOriginal => 'Показать оригинал';

  @override
  String get translateContent => 'Перевести содержимое';

  @override
  String get editTextContentHint => 'Редактировать текст...';

  @override
  String get markButton => 'Отметить';

  @override
  String get bookmarkRemoved => 'Закладка удалена';

  @override
  String setProgressAndRating(String progress, int rating) {
    return 'Установлено: $progress, оценка: $rating звёзд';
  }

  @override
  String setProgressTo(String progress) {
    return 'Установлено: $progress';
  }

  @override
  String ratingSetTo(int rating) {
    return 'Оценка: $rating звёзд';
  }

  @override
  String get updated => 'Обновлено';

  @override
  String addTagFailed(String error) {
    return 'Не удалось добавить тег: $error';
  }

  @override
  String addWithCount(int count) {
    return 'Добавить ($count)';
  }

  @override
  String get undo => 'Отменить';

  @override
  String nStars(int count) {
    return '$count звёзд';
  }

  @override
  String get voteRemoved => 'Голос отменён';

  @override
  String get votedUp => 'Голос за';

  @override
  String get votedDown => 'Голос против';

  @override
  String voteFailedWithError(String error) {
    return 'Ошибка голосования: $error';
  }

  @override
  String get voteFor => 'За';

  @override
  String get voteAgainst => 'Против';

  @override
  String get voted => 'Проголосовали';

  @override
  String tagBlockedWithName(String name) {
    return 'Тег заблокирован: $name';
  }

  @override
  String get subtitleParseFailedUnsupportedFormat =>
      'Ошибка анализа, неподдерживаемый формат';

  @override
  String get lyricPresetDynamic => 'Динамичный';

  @override
  String get lyricPresetClassic => 'Классический';

  @override
  String get lyricPresetModern => 'Современный';

  @override
  String get lyricPresetMinimal => 'Минимальный';

  @override
  String get lyricPresetVibrant => 'Яркий';

  @override
  String get lyricPresetElegant => 'Элегантный';

  @override
  String get lyricPresetDynamicDesc =>
      'Следует за темой системы, автоматические цвета';

  @override
  String get lyricPresetClassicDesc => 'Чёрный фон, белый текст, классика';

  @override
  String get lyricPresetModernDesc => 'Градиентный фон, стильный современный';

  @override
  String get lyricPresetMinimalDesc =>
      'Лёгкая прозрачность, просто и элегантно';

  @override
  String get lyricPresetVibrantDesc => 'Яркие цвета, полны энергии';

  @override
  String get lyricPresetElegantDesc =>
      'Глубокий синий, изысканная элегантность';

  @override
  String get floatingLyricLoading => '♪ Загрузка субтитров ♪';

  @override
  String get subtitleFileNotExist => 'Файл не существует';

  @override
  String get subtitleMissingInfo => 'Недостаточно информации';

  @override
  String get privacyDefaultTitle => 'Воспроизведение аудио';

  @override
  String get offlineModeStartup => 'Ошибка подключения, запуск в офлайн-режиме';

  @override
  String get playlistInfoNotLoaded => 'Информация о плейлисте не загружена';

  @override
  String get encodingUnrecognized =>
      'Кодировка файла не распознана, невозможно корректно отобразить';

  @override
  String editPlaylistFailed(String error) {
    return 'Не удалось редактировать плейлист: $error';
  }

  @override
  String unsupportedFileTypeWithTitle(String title) {
    return 'Невозможно открыть этот тип файла: $title';
  }

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get restoredToDefault => 'Восстановлены настройки по умолчанию';

  @override
  String get restoreDefault => 'По умолчанию';

  @override
  String get saveSettings => 'Сохранить настройки';

  @override
  String get addAtLeastOneSearchCondition =>
      'Добавьте хотя бы одно условие поиска';

  @override
  String get privacyModeSettingsTitle => 'Настройки приватного режима';

  @override
  String get whatIsPrivacyMode => 'Что такое приватный режим?';

  @override
  String get privacyModeDescription =>
      'При включении информация о воспроизведении в уведомлениях и на экране блокировки будет размыта для защиты конфиденциальности.';

  @override
  String get enablePrivacyMode => 'Включить приватный режим';

  @override
  String get privacyModeEnabledSubtitle =>
      'Включено - информация о воспроизведении будет скрыта';

  @override
  String get privacyModeDisabledSubtitle =>
      'Отключено - информация отображается нормально';

  @override
  String get blurOptions => 'Параметры размытия';

  @override
  String get blurNotificationCover => 'Размытие обложки в уведомлениях';

  @override
  String get blurNotificationCoverSubtitle =>
      'Размытие обложки в системных уведомлениях, на экране блокировки и в центре управления';

  @override
  String get blurInAppCover => 'Размытие обложки в приложении';

  @override
  String get blurInAppCoverSubtitle =>
      'Размытие обложки в плеере, списках и других экранах';

  @override
  String get replaceTitle => 'Заменить заголовок';

  @override
  String get replaceTitleSubtitle =>
      'Заменить настоящее название пользовательским';

  @override
  String get replaceTitleContent => 'Содержимое замены заголовка';

  @override
  String get setReplaceTitle => 'Установить замену заголовка';

  @override
  String get enterDisplayTitle => 'Введите отображаемый заголовок';

  @override
  String get replaceTitleSaved => 'Замена заголовка сохранена';

  @override
  String get effectExample => 'Пример эффекта';

  @override
  String get downloadPathSettings => 'Настройки пути загрузки';

  @override
  String loadPathFailedWithError(String error) {
    return 'Не удалось загрузить путь: $error';
  }

  @override
  String get platformNotSupportCustomPath =>
      'Пользовательский путь загрузки не поддерживается на этой платформе';

  @override
  String activeDownloadsWarning(int count) {
    return 'Выполняется $count загрузок. Завершите или отмените их перед сменой пути';
  }

  @override
  String setPathFailedWithError(String error) {
    return 'Не удалось установить путь: $error';
  }

  @override
  String get confirmMigrateFiles => 'Подтвердите перенос файлов';

  @override
  String get migrateFilesToNewDir =>
      'Существующие загруженные файлы будут перенесены в новый каталог:';

  @override
  String get migrationMayTakeTime =>
      'Эта операция может занять некоторое время в зависимости от количества и размера файлов.';

  @override
  String get confirmMigrate => 'Подтвердить перенос';

  @override
  String get restoreDefaultPath => 'Восстановить путь по умолчанию';

  @override
  String get restoreDefaultPathConfirm =>
      'Восстановить путь загрузки по умолчанию и перенести все файлы.\n\nПродолжить?';

  @override
  String get defaultPathRestored => 'Путь по умолчанию восстановлен';

  @override
  String resetPathFailedWithError(String error) {
    return 'Не удалось восстановить путь по умолчанию: $error';
  }

  @override
  String get migratingFiles => 'Перенос файлов...';

  @override
  String get doNotCloseApp => 'Не закрывайте приложение';

  @override
  String get currentDownloadPath => 'Текущий путь загрузки';

  @override
  String get customPath => 'Пользовательский путь';

  @override
  String get defaultPath => 'Путь по умолчанию';

  @override
  String get changeCustomPath => 'Изменить пользовательский путь';

  @override
  String get setCustomPath => 'Установить пользовательский путь';

  @override
  String get usageInstructions => 'Инструкция по использованию';

  @override
  String get downloadPathUsageDesc =>
      '• После изменения пути все существующие файлы будут автоматически перенесены\n• Не закрывайте приложение во время переноса\n• Рекомендуется выбрать каталог с достаточным объёмом памяти\n• При восстановлении пути по умолчанию файлы также будут перенесены обратно';

  @override
  String get llmTranslationSettings => 'Настройки LLM-перевода';

  @override
  String get apiEndpointUrl => 'URL-адрес API';

  @override
  String get openaiCompatibleEndpoint => 'URL-адрес, совместимый с OpenAI';

  @override
  String get pleaseEnterApiUrl => 'Введите URL-адрес API';

  @override
  String get pleaseEnterValidUrl => 'Введите действительный URL';

  @override
  String get pleaseEnterApiKey => 'Введите API-ключ';

  @override
  String get modelName => 'Название модели';

  @override
  String get pleaseEnterModelName => 'Введите название модели';

  @override
  String get concurrencyCount => 'Параллельность';

  @override
  String get concurrencyDescription =>
      'Количество одновременных запросов на перевод, рекомендуется 3-5';

  @override
  String get promptSection => 'Промпт (Prompt)';

  @override
  String get promptDescription =>
      'Поскольку система использует блочный перевод, убедитесь, что промпт чётко требует выводить только результат перевода без пояснений.';

  @override
  String get enterSystemPrompt => 'Введите системный промпт...';

  @override
  String get pleaseEnterPrompt => 'Введите промпт';

  @override
  String get restoreDefaultPrompt => 'Восстановить промпт по умолчанию';

  @override
  String get confirmRestoreButtonOrder =>
      'Восстановить порядок кнопок по умолчанию?';

  @override
  String get buttonDisplayRules => 'Правила отображения кнопок';

  @override
  String buttonDisplayRulesDesc(int maxVisible) {
    return '• Первые $maxVisible кнопок отображаются внизу плеера\n• Остальные кнопки доступны в меню «Ещё»';
  }

  @override
  String get shownInPlayer => 'Отображается в плеере';

  @override
  String get shownInMoreMenu => 'Отображается в меню «Ещё»';

  @override
  String get audioFormatPriority => 'Приоритет аудиоформатов';

  @override
  String get confirmRestoreAudioFormat =>
      'Восстановить приоритет аудиоформатов по умолчанию?';

  @override
  String get priorityDescription => 'Описание приоритетов';

  @override
  String get audioFormatPriorityDesc =>
      '• При открытии страницы произведения автоматически раскрывается папка с аудио наиболее приоритетного формата';

  @override
  String get ratingInfo => 'Информация о рейтинге';

  @override
  String get showRatingAndReviewCount =>
      'Показывать рейтинг и количество оценок';

  @override
  String get priceInfo => 'Информация о цене';

  @override
  String get showWorkPrice => 'Показывать цену произведения';

  @override
  String get durationInfo => 'Информация о длительности';

  @override
  String get showWorkDuration => 'Показывать длительность произведения';

  @override
  String get showWorkTotalDuration =>
      'Показывать общую длительность произведения';

  @override
  String get salesInfo => 'Информация о продажах';

  @override
  String get showWorkSalesCount => 'Показывать количество продаж';

  @override
  String get externalLinkInfo => 'Внешние ссылки';

  @override
  String get showExternalLinks =>
      'Показывать внешние ссылки (DLsite, офиц. сайт и др.)';

  @override
  String get releaseDateInfo => 'Дата публикации';

  @override
  String get showWorkReleaseDate => 'Показывать дату публикации произведения';

  @override
  String get translateButtonLabel => 'Кнопка перевода';

  @override
  String get showTranslateButton =>
      'Показывать кнопку перевода заголовка произведения';

  @override
  String get subtitleTagLabel => 'Метка субтитров';

  @override
  String get showSubtitleTagOnCover => 'Показывать метку субтитров на обложке';

  @override
  String get showAgeRatingOnDetail =>
      'Показывать возрастной рейтинг на странице произведения';

  @override
  String get recommendationsLabel => 'Похожие рекомендации';

  @override
  String get showRecommendations =>
      'Показывать похожие рекомендации на странице произведения';

  @override
  String get circleInfo => 'Информация о кружке';

  @override
  String get showWorkCircle => 'Показывать кружок произведения';

  @override
  String get workCardSizeSubtitle =>
      'Настройте плотность сетки, чтобы увеличить обложки или оставить текущий размер';

  @override
  String get workCardFontSize => 'Размер текста карточки';

  @override
  String get workCardFontSizeSubtitle =>
      'Настройте размер заголовка и данных на карточках работ';

  @override
  String get cardSizeNormal => 'Обычный';

  @override
  String get cardSizeLarge => 'Крупный';

  @override
  String get cardSizeExtraLarge => 'XL';

  @override
  String get fontSizeNormal => 'Обычный';

  @override
  String get fontSizeLarge => 'Крупный';

  @override
  String get fontSizeExtraLarge => 'XL';

  @override
  String get showSubtitleTagOnCard =>
      'Показывать метку субтитров на карточке произведения';

  @override
  String get showAgeRatingOnCard =>
      'Показывать возрастной рейтинг на карточке произведения';

  @override
  String get showOnlineMarks => 'Показывать произведения с онлайн-метками';

  @override
  String get cannotBeDisabled => 'Нельзя отключить';

  @override
  String get showPlaylists => 'Показывать созданные плейлисты';

  @override
  String get showSubtitleLibrary =>
      'Показывать управление библиотекой субтитров';

  @override
  String get playlistPrivacyPrivateDesc => 'Только вы можете просматривать';

  @override
  String get playlistPrivacyUnlistedDesc =>
      'Могут просматривать только те, у кого есть ссылка';

  @override
  String get playlistPrivacyPublicDesc => 'Может просматривать любой';

  @override
  String get clearTranslationCache => 'Очистить кэш переводов';

  @override
  String get translationCacheCleared => 'Кэш переводов очищен';

  @override
  String get platformHintAndroid =>
      'Android: Будет использован системный выбор файлов, может потребоваться разрешение на хранилище';

  @override
  String get platformHintIOS =>
      'iOS: Из-за системных ограничений используется путь по умолчанию. Файлы можно просмотреть через системный файловый менеджер';

  @override
  String get platformHintWindows =>
      'Windows: Можно выбрать любую доступную директорию';

  @override
  String get platformHintMacOS =>
      'macOS: Можно выбрать любую доступную директорию';

  @override
  String get platformHintLinux =>
      'Linux: Можно выбрать любую доступную директорию';

  @override
  String get platformHintDefault =>
      'Выберите директорию для сохранения загруженных файлов';

  @override
  String get subtitleFolderParsed => 'Разобранные';

  @override
  String get subtitleFolderSaved => 'Сохранённые';

  @override
  String get subtitleFolderUnknown => 'Неизвестные';

  @override
  String get sortDownloadDate => 'Дата загрузки';

  @override
  String get sortWorkId => 'ID';

  @override
  String get searchDownloads => 'Поиск загруженных...';

  @override
  String get logTitle => 'Логи приложения';

  @override
  String get logSubtitle => 'Просмотр и экспорт логов';

  @override
  String get logSearchHint => 'Поиск в логах...';

  @override
  String get logFilterAll => 'Все';

  @override
  String get logCopy => 'Копировать логи';

  @override
  String get logExport => 'Экспорт лог-файла';

  @override
  String get logClear => 'Очистить логи';

  @override
  String get logCopied => 'Логи скопированы в буфер обмена';

  @override
  String logExported(String path) {
    return 'Логи экспортированы в $path';
  }

  @override
  String logCount(int count) {
    return '$count записей';
  }

  @override
  String get logAutoScroll => 'Автопрокрутка';

  @override
  String get logEmpty => 'Логов пока нет';

  @override
  String get proxySettingsOptional => 'Прокси';

  @override
  String get loginAdvancedSettings => 'Расширенные настройки';

  @override
  String proxyEnabled(String address) {
    return 'Включено: $address';
  }

  @override
  String get proxyAddressNotSet => 'Не задан (прямое подключение)';

  @override
  String get proxyHttpDescription =>
      'Подключение к серверам через HTTP-прокси (например, Clash)';

  @override
  String get useProxy => 'Использовать прокси';

  @override
  String get proxyAddress => 'Адрес прокси';

  @override
  String get proxyAddressFormat => 'Формат: хост:порт, например 127.0.0.1:7890';

  @override
  String get applyProxyAddress => 'Применить адрес прокси';

  @override
  String get invalidProxyAddress =>
      'Введите корректный адрес и порт HTTP-прокси';

  @override
  String get playlistDisplayFormat => 'Вид плейлиста';

  @override
  String get playlistDisplayFormatMasonry => 'Мозаика';

  @override
  String get playlistDisplayFormatList => 'Список';
}
