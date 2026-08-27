// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'KikoFlu';

  @override
  String get navHome => '主页';

  @override
  String get navSearch => '搜索';

  @override
  String get navMy => '我的';

  @override
  String get navSettings => '设置';

  @override
  String get offlineModeMessage => '离线模式：网络连接失败，仅可访问下载内容';

  @override
  String get retry => '重试';

  @override
  String get searchTypeKeyword => '关键词';

  @override
  String get searchTypeTag => '标签';

  @override
  String get searchTypeVa => '声优';

  @override
  String get searchTypeCircle => '社团';

  @override
  String get searchTypeRjNumber => 'RJ号';

  @override
  String get searchHintKeyword => '输入作品名称或关键词...';

  @override
  String get searchHintTag => '输入标签名...';

  @override
  String get searchHintVa => '输入声优名...';

  @override
  String get searchHintCircle => '输入社团名...';

  @override
  String get searchHintRjNumber => '输入数字...';

  @override
  String get ageRatingAll => '全部';

  @override
  String get ageRatingGeneral => '全年龄';

  @override
  String get ageRatingR15 => 'R-15';

  @override
  String get ageRatingAdult => '成人向';

  @override
  String get salesRangeAll => '全部';

  @override
  String get sortRelease => '发布日期';

  @override
  String get sortCreateAt => '添加日期';

  @override
  String get sortCreateDate => '收录日期';

  @override
  String get sortRating => '评分';

  @override
  String get sortReviewCount => '评论数';

  @override
  String get sortRandom => '随机';

  @override
  String get sortDlCount => '销量';

  @override
  String get sortPrice => '价格';

  @override
  String get sortNsfw => '全年龄';

  @override
  String get sortUpdatedAt => '标记时间';

  @override
  String get sortAsc => '升序';

  @override
  String get sortDesc => '降序';

  @override
  String get sortOptions => '排序选项';

  @override
  String get sortField => '排序字段';

  @override
  String get sortDirection => '排序方向';

  @override
  String get displayModeAll => '全部';

  @override
  String get displayModePopular => '热门';

  @override
  String get displayModeRecommended => '推荐';

  @override
  String get subtitlePriorityHighest => '优先';

  @override
  String get subtitlePriorityLowest => '滞后';

  @override
  String get translationSourceGoogle => 'Google 翻译';

  @override
  String get translationSourceYoudao => 'Youdao 翻译';

  @override
  String get translationSourceMicrosoft => 'Microsoft 翻译';

  @override
  String get translationSourceLlm => 'LLM 翻译';

  @override
  String get progressMarked => '想听';

  @override
  String get progressListening => '在听';

  @override
  String get progressListened => '听过';

  @override
  String get progressReplay => '重听';

  @override
  String get progressPostponed => '搁置';

  @override
  String get loginTitle => '登录';

  @override
  String get register => '注册';

  @override
  String get addAccount => '添加账户';

  @override
  String get registerAccount => '注册账户';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get serverCookie => '服务器Cookie';

  @override
  String get login => '登录';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginFailed => '登录失败';

  @override
  String get registerFailed => '注册失败';

  @override
  String get usernameMinLength => '用户名不能少于5个字符';

  @override
  String get passwordMinLength => '密码不能少于5个字符';

  @override
  String accountAdded(String username) {
    return '账户 \"$username\" 已添加';
  }

  @override
  String get testConnection => '测试连接';

  @override
  String get testing => '测试中...';

  @override
  String get enterServerAddressToTest => '请输入服务器地址后测试连接';

  @override
  String latencyMs(String ms) {
    return '${ms}ms';
  }

  @override
  String get connectionFailed => '连接失败';

  @override
  String get guestModeTitle => '游客模式确认';

  @override
  String get guestModeMessage =>
      '游客模式功能有限：\n\n• 无法标记或评分作品\n• 无法创建播放列表\n• 无法同步进度\n\n游客模式使用演示账号连接服务器，可能不够稳定。';

  @override
  String get continueGuestMode => '继续使用游客模式';

  @override
  String get guestAccountAdded => '游客账户已添加';

  @override
  String get guestLoginFailed => '游客登录失败';

  @override
  String get guestMode => '游客模式';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get close => '关闭';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get add => '添加';

  @override
  String get create => '创建';

  @override
  String get ok => '好的';

  @override
  String get search => '搜索';

  @override
  String get filter => '筛选';

  @override
  String get advancedFilter => '高级筛选';

  @override
  String get enterSearchContent => '请输入搜索内容';

  @override
  String get searchTag => '搜索标签...';

  @override
  String get minRating => '最低评分';

  @override
  String minRatingStars(String stars) {
    return '$stars 星';
  }

  @override
  String get searchHistory => '搜索历史';

  @override
  String get clearSearchHistory => '清除搜索历史';

  @override
  String get clearSearchHistoryConfirm => '确定要清除所有搜索历史吗？';

  @override
  String get clear => '清除';

  @override
  String get searchHistoryCleared => '搜索历史已清除';

  @override
  String get noSearchHistory => '暂无搜索历史';

  @override
  String get excludeMode => '排除';

  @override
  String get includeMode => '包含';

  @override
  String includeModeTapAgainHint(String searchType) {
    return '包含：$searchType（再次点击进入排除模式）';
  }

  @override
  String get noResults => '没有结果';

  @override
  String get loadFailed => '加载失败';

  @override
  String loadFailedWithError(String error) {
    return '加载失败: $error';
  }

  @override
  String get loading => '加载中...';

  @override
  String get calculating => '计算中...';

  @override
  String get getFailed => '获取失败';

  @override
  String get settingsTitle => '设置';

  @override
  String get accountManagement => '账户管理';

  @override
  String get accountManagementSubtitle => '多账户管理，切换账户';

  @override
  String get privacyMode => '防社死模式';

  @override
  String get privacyModeEnabled => '已启用 - 播放信息已隐藏';

  @override
  String get privacyModeDisabled => '未启用';

  @override
  String get permissionManagement => '权限管理';

  @override
  String get permissionManagementSubtitle => '通知权限、后台运行权限';

  @override
  String get desktopFloatingLyric => '桌面悬浮字幕';

  @override
  String get floatingLyricEnabled => '已启用 - 字幕将显示在桌面上';

  @override
  String get floatingLyricDisabled => '未启用';

  @override
  String get floatingLyricTouch => '悬浮字幕锁定';

  @override
  String get floatingLyricTouchEnabled => '已解锁 - 可拖动悬浮字幕，长按可锁定';

  @override
  String get floatingLyricTouchDisabled => '已锁定 - 长按悬浮字幕解锁';

  @override
  String get floatingLyricClickThrough => '悬浮字幕点击穿透';

  @override
  String get floatingLyricClickThroughEnabled => '已启用 - 悬浮字幕将忽略鼠标操作';

  @override
  String get floatingLyricClickThroughDisabled => '未启用 - 可拖动悬浮字幕';

  @override
  String get floatingFPS => '显示帧率';

  @override
  String get floatingFPSEnabled => '已开启 - 帧率显示在悬浮窗左下角';

  @override
  String get floatingFPSDisabled => '未开启';

  @override
  String get floatingNetworkSpeed => '显示网速';

  @override
  String get floatingNetworkSpeedEnabled => '已开启 - 网速显示在悬浮窗右下角';

  @override
  String get floatingNetworkSpeedDisabled => '未开启';

  @override
  String get styleSettings => '样式设置';

  @override
  String get styleSettingsSubtitle => '自定义字体、颜色、透明度等';

  @override
  String get downloadPath => '下载路径';

  @override
  String get downloadPathSubtitle => '自定义下载文件保存位置';

  @override
  String get maxConcurrentDownloads => '最大同时下载数';

  @override
  String get maxConcurrentDownloadsSubtitle => '限制同时进行的下载任务数量';

  @override
  String get cacheManagement => '缓存管理';

  @override
  String currentCache(String size) {
    return '当前缓存: $size';
  }

  @override
  String get themeSettings => '主题设置';

  @override
  String get themeSettingsSubtitle => '深色模式、主题色等';

  @override
  String get uiSettings => '界面设置';

  @override
  String get uiSettingsSubtitle => '播放器、详情页、卡片等';

  @override
  String get liquidGlassNavigation => '液态玻璃导航';

  @override
  String get liquidGlassNavigationDesc => '玻璃导航栏与迷你播放器；Apple系26+平台默认开启';

  @override
  String get fallbackGlassTransparency => '液态玻璃透明度';

  @override
  String get fallbackGlassTransparencyDesc => '调整应用绘制玻璃的透明度';

  @override
  String get preferenceSettings => '偏好设置';

  @override
  String get preferenceSettingsSubtitle => '翻译、播放与网络';

  @override
  String get aboutTitle => '关于';

  @override
  String get unknownVersion => '未知';

  @override
  String get licenseLoadFailed => '未能加载 LICENSE 文件';

  @override
  String get licenseEmpty => 'LICENSE 内容为空';

  @override
  String get failedToLoadAbout => '无法加载关于信息';

  @override
  String get newVersionFound => '发现新版本';

  @override
  String newVersionAvailable(String version, String current) {
    return '$version 可用 (当前版本: $current)';
  }

  @override
  String get versionInfo => '版本信息';

  @override
  String currentVersion(String version) {
    return '当前版本：$version';
  }

  @override
  String get checkUpdate => '检查更新';

  @override
  String get author => '作者';

  @override
  String get projectRepo => '项目仓库';

  @override
  String get openSourceLicense => '开源协议';

  @override
  String get cannotOpenLink => '无法打开链接';

  @override
  String openLinkFailed(String error) {
    return '打开链接失败：$error';
  }

  @override
  String foundNewVersion(String version) {
    return '发现新版本 $version';
  }

  @override
  String get view => '查看';

  @override
  String get alreadyLatestVersion => '当前已是最新版本';

  @override
  String get checkUpdateFailed => '检查更新失败，请检查网络连接';

  @override
  String get onlineMarks => '在线标记';

  @override
  String get historyRecord => '历史记录';

  @override
  String get playlists => '播放列表';

  @override
  String get downloaded => '已下载';

  @override
  String get downloadTasks => '下载任务';

  @override
  String get subtitleLibrary => '字幕库';

  @override
  String get all => '全部';

  @override
  String get marked => '想听';

  @override
  String get listening => '在听';

  @override
  String get listened => '听过';

  @override
  String get replayMark => '重听';

  @override
  String get postponed => '搁置';

  @override
  String get switchToSmallGrid => '切换到小网格视图';

  @override
  String get switchToList => '切换到列表视图';

  @override
  String get switchToLargeGrid => '切换到大网格视图';

  @override
  String get sort => '排序';

  @override
  String get noPlayHistory => '暂无播放历史';

  @override
  String get clearHistory => '清空历史';

  @override
  String get clearHistoryTitle => '清空历史';

  @override
  String get clearHistoryConfirm => '确定要清空所有播放历史吗？此操作无法撤销。';

  @override
  String get popularNoSort => '热门推荐模式不支持排序';

  @override
  String get recommendedNoSort => '推荐模式不支持排序';

  @override
  String get showAllWorks => '显示全部作品';

  @override
  String get showOnlySubtitled => '仅显示带字幕作品';

  @override
  String selectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get select => '选择';

  @override
  String get noDownloadTasks => '暂无下载任务';

  @override
  String nFiles(int count) {
    return '$count 个文件';
  }

  @override
  String errorWithMessage(String error) {
    return '错误: $error';
  }

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get deletionConfirmTitle => '确认删除';

  @override
  String deletionConfirmMessage(int count) {
    return '确定要删除 $count 个已选的下载任务吗？已下载的文件也将被移除。';
  }

  @override
  String deletedNFiles(int count) {
    return '已删除 $count 个文件';
  }

  @override
  String get downloadStatusPending => '等待中';

  @override
  String get downloadStatusDownloading => '下载中';

  @override
  String get downloadStatusCompleted => '已完成';

  @override
  String get downloadStatusFailed => '失败';

  @override
  String get downloadStatusPaused => '已暂停';

  @override
  String translationFailed(String error) {
    return '翻译失败: $error';
  }

  @override
  String copiedToClipboard(String label, String text) {
    return '已复制$label：$text';
  }

  @override
  String get loadingFileList => '正在加载文件列表...';

  @override
  String loadFileListFailed(String error) {
    return '加载文件列表失败: $error';
  }

  @override
  String get playlistTitle => '播放列表';

  @override
  String get noAudioPlaying => '没有正在播放的音频';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get backward10s => '后退10秒';

  @override
  String get forward10s => '前进10秒';

  @override
  String get sleepTimer => '定时停止';

  @override
  String get repeatMode => '循环模式';

  @override
  String get repeatOff => '关闭';

  @override
  String get repeatOne => '单曲';

  @override
  String get repeatAll => '列表';

  @override
  String get addMark => '添加标记';

  @override
  String get viewDetail => '查看详情';

  @override
  String get volume => '音量';

  @override
  String get sleepTimerTitle => '定时器';

  @override
  String get aboutToStop => '即将停止';

  @override
  String get remainingTime => '剩余时间';

  @override
  String get finishCurrentTrack => '完整播完后停止';

  @override
  String addMinutes(int min) {
    return '+$min分钟';
  }

  @override
  String get cancelTimer => '取消定时';

  @override
  String get duration => '时长';

  @override
  String get specifyTime => '指定时间';

  @override
  String get selectTimerDuration => '选择定时时长';

  @override
  String get selectStopTime => '选择停止播放的时间';

  @override
  String get markWork => '标记作品';

  @override
  String get addToPlaylist => '添加到播放列表';

  @override
  String get remove => '移除';

  @override
  String get createPlaylist => '创建播放列表';

  @override
  String get addPlaylist => '添加播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get enterPlaylistName => '请输入名称';

  @override
  String get privacySetting => '隐私设置';

  @override
  String get playlistDescription => '描述（可选）';

  @override
  String get addDescription => '添加一些描述信息';

  @override
  String get enterPlaylistNameWarning => '请输入播放列表名称';

  @override
  String get enterPlaylistLink => '请输入播放列表链接';

  @override
  String get switchAccountTitle => '切换账户';

  @override
  String switchAccountConfirm(String username) {
    return '确定要切换到账户 \"$username\" 吗？';
  }

  @override
  String switchedToAccount(String username) {
    return '已切换到账户: $username';
  }

  @override
  String get switchFailed => '切换失败，请检查账户信息';

  @override
  String switchFailedWithError(String error) {
    return '切换失败: $error';
  }

  @override
  String get noAccounts => '暂无账户';

  @override
  String get tapToAddAccount => '点击右下角按钮添加账户';

  @override
  String get currentAccount => '当前账户';

  @override
  String get switchAction => '切换';

  @override
  String get deleteAccount => '删除账户';

  @override
  String deleteAccountConfirm(String username) {
    return '确定要删除账户 \"$username\" 吗？此操作无法撤销。';
  }

  @override
  String get accountDeleted => '账户已删除';

  @override
  String deletionFailedWithError(String error) {
    return '删除失败: $error';
  }

  @override
  String get subtitleLibraryPriority => '字幕库优先级';

  @override
  String get selectSubtitlePriority => '选择字幕库在自动加载中的优先级：';

  @override
  String get subtitlePriorityHighestDesc => '优先查找字幕库，再查找在线/下载';

  @override
  String get subtitlePriorityLowestDesc => '优先查找在线/下载，再查找字幕库';

  @override
  String get defaultSortSettings => '默认排序设置';

  @override
  String get defaultSortUpdated => '默认排序已更新';

  @override
  String get translationSourceSettings => '翻译源设置';

  @override
  String get selectTranslationProvider => '选择翻译服务提供商：';

  @override
  String get translationTargetLanguage => '目标语言';

  @override
  String get autoSaveTranslatedLyrics => '自动保存翻译歌词';

  @override
  String get autoSaveTranslatedLyricsDesc => '翻译后保存到字幕库；关闭时仅临时显示';

  @override
  String get selectTranslationTargetLanguage => '选择目标语言：';

  @override
  String get translationLanguageFollowApp => '跟随 App 语言';

  @override
  String get translationLanguageZhHans => '简体中文';

  @override
  String get translationLanguageZhHant => '繁体中文';

  @override
  String get translationLanguageEnglish => '英语';

  @override
  String get translationLanguageJapanese => '日语';

  @override
  String get translationLanguageRussian => '俄语';

  @override
  String get translationLanguageCustom => '自定义';

  @override
  String get translationCustomTargetLanguage => '自定义目标语言';

  @override
  String get translationCustomLanguageHint => '语言名称，例如 Korean';

  @override
  String translationCustomLanguageLabel(String value) {
    return '自定义: $value';
  }

  @override
  String get translationCustomTargetRequiresLlm => '需要使用 LLM 翻译才能使用';

  @override
  String get needsConfiguration => '需要配置';

  @override
  String get llmTranslation => '大模型翻译';

  @override
  String get goToConfigure => '去配置';

  @override
  String get subtitlePrioritySettingSubtitle => '字幕库优先级';

  @override
  String get defaultSortSettingTitle => '首页默认排序方式';

  @override
  String get translationSource => '翻译源';

  @override
  String get llmSettings => 'LLM设置';

  @override
  String get llmSettingsSubtitle => 'API 地址、密钥和模型';

  @override
  String get audioFormatPreference => '音频格式偏好';

  @override
  String get audioFormatSubtitle => '调整音频格式优先级';

  @override
  String get preloadNextTitle => '预加载下一首';

  @override
  String get preloadNextSubtitle => '当前曲目播放结束前提前缓存下一首，避免切歌空档';

  @override
  String get selectPreloadThreshold => '当前曲目剩余时间低于此阈值时开始预加载：';

  @override
  String get preloadOptionOff => '关闭';

  @override
  String preloadOptionSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get preloadOptionCustom => '自定义';

  @override
  String get preloadCustomInputTitle => '自定义预加载阈值';

  @override
  String get preloadCustomInputHint => '秒数 (1-300)';

  @override
  String get preloadCustomInputRangeError => '请输入 1 到 300 之间的数字';

  @override
  String preloadCustomValueLabel(int value) {
    return '$value 秒';
  }

  @override
  String get keepScreenAwake => '屏幕常亮';

  @override
  String get keepScreenAwakeDesc => '播放时保持屏幕常亮';

  @override
  String get audioHaptics => '音频触感反馈(Beta)';

  @override
  String get audioHapticsDesc => '随已下载音频振动，仅前台生效';

  @override
  String get audioHapticsIntensity => '强度';

  @override
  String get audioGain => '全局音频增益';

  @override
  String get audioGainDesc => '0 dB 为原声；正增益过高可能失真或损伤听力';

  @override
  String get audioGainAttenuationDesc => '降低所有音频；0 dB 保持原声';

  @override
  String get audioGainPassthroughDesc => '音频直通开启时不可用';

  @override
  String get blockingSettings => '屏蔽设置';

  @override
  String get blockingSettingsSubtitle => '屏蔽标签、声优和社团';

  @override
  String get audioPassthrough => '音频直通(Beta)';

  @override
  String get audioPassthroughDescWindows => '使用 WASAPI 独占输出（需重启）';

  @override
  String get audioPassthroughDescMac => '使用 CoreAudio 独占输出';

  @override
  String get audioPassthroughDisableDesc => '关闭音频直通模式';

  @override
  String get warning => '警告';

  @override
  String get audioPassthroughWarning => '此功能未经完全测试，可能会带来意外外放等风险。确定要开启吗？';

  @override
  String get exclusiveModeEnabled => '已开启独占模式（重启生效）';

  @override
  String get audioPassthroughEnabled => '已开启音频直通模式';

  @override
  String get audioPassthroughDisabled => '已关闭音频直通模式';

  @override
  String get tagVoteSupport => '支持';

  @override
  String get tagVoteOppose => '反对';

  @override
  String get tagVoted => '已投票';

  @override
  String get votedSupport => '已投支持票';

  @override
  String get votedOppose => '已投反对票';

  @override
  String get voteCancelled => '已取消投票';

  @override
  String voteFailed(String error) {
    return '投票失败: $error';
  }

  @override
  String get blockThisTag => '屏蔽此标签';

  @override
  String get copyTag => '复制标签';

  @override
  String get addTag => '添加标签';

  @override
  String loadTagsFailed(String error) {
    return '加载标签失败: $error';
  }

  @override
  String get selectAtLeastOneTag => '请至少选择一个标签';

  @override
  String get tagSubmitSuccess => '标签提交成功，等待服务器处理';

  @override
  String get bindEmailFirst => '请先前往 www.asmr.one 绑定邮箱';

  @override
  String selectedNTags(int count) {
    return '已选择 $count 个标签:';
  }

  @override
  String get noMatchingTags => '没有找到匹配的标签';

  @override
  String get loadFailedRetry => '加载失败，点击重试';

  @override
  String get refresh => '刷新';

  @override
  String get playlistPrivacyPrivate => '私有';

  @override
  String get playlistPrivacyUnlisted => '未列出';

  @override
  String get playlistPrivacyPublic => '公开';

  @override
  String get systemPlaylistMarked => '我标记的';

  @override
  String get systemPlaylistLiked => '我喜欢的';

  @override
  String totalNWorks(int count) {
    return '$count 个作品';
  }

  @override
  String pageNOfTotal(int current, int total) {
    return '第 $current / $total 页';
  }

  @override
  String get translateTitle => '翻译';

  @override
  String get translateDescription => '翻译描述';

  @override
  String get translating => '翻译中...';

  @override
  String translationFallbackNotice(String source) {
    return '翻译失败，已自动切换至$source';
  }

  @override
  String get tagLabel => '标签';

  @override
  String get vaLabel => '声优';

  @override
  String get circleLabel => '社团';

  @override
  String get releaseDate => '发售日';

  @override
  String get ratingLabel => '评分';

  @override
  String get salesLabel => '销量';

  @override
  String get priceLabel => '价格';

  @override
  String get durationLabel => '时长';

  @override
  String get ageRatingLabel => '年龄分级';

  @override
  String get hasSubtitle => '有字幕';

  @override
  String get noSubtitle => '无字幕';

  @override
  String get description => '简介';

  @override
  String get fileList => '文件列表';

  @override
  String get series => '系列';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '切换显示语言';

  @override
  String get languageSystem => '跟随系统';

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
  String get themeModeDark => '深色模式';

  @override
  String get themeModeLight => '浅色模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get colorSchemeOceanBlue => '胖次蓝';

  @override
  String get colorSchemeForestGreen => '草原绿';

  @override
  String get colorSchemeSunsetOrange => '今日橙';

  @override
  String get colorSchemeLavenderPurple => '基佬紫';

  @override
  String get colorSchemeSakuraPink => '哔哩粉';

  @override
  String get colorSchemeDynamic => '动态取色';

  @override
  String get noData => '暂无数据';

  @override
  String get unknownError => '未知错误';

  @override
  String get networkError => '网络错误';

  @override
  String get timeout => '请求超时';

  @override
  String get playAll => '播放全部';

  @override
  String get download => '下载';

  @override
  String get downloadAll => '下载全部';

  @override
  String get downloading => '下载中';

  @override
  String get downloadComplete => '下载完成';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get startDownload => '开始下载';

  @override
  String get confirmDeleteDownload => '确定要删除此下载任务吗？已下载的文件也将被移除。';

  @override
  String get deletedSuccessfully => '删除成功';

  @override
  String get scanSubtitleLibrary => '扫描字幕库';

  @override
  String get scanning => '扫描中...';

  @override
  String get scanComplete => '扫描完成';

  @override
  String get noSubtitleFiles => '未找到字幕文件';

  @override
  String subtitleFilesFound(int count) {
    return '找到 $count 个字幕文件';
  }

  @override
  String get selectDirectory => '选择目录';

  @override
  String get privacyModeSettings => '防社死模式设置';

  @override
  String get blurCover => '模糊封面';

  @override
  String get maskTitle => '遮挡标题';

  @override
  String get customTitle => '自定义标题';

  @override
  String get privacyModeDesc => '在系统通知栏和媒体控制中隐藏播放信息';

  @override
  String get audioFormatSettingsTitle => '音频格式设置';

  @override
  String get preferredFormat => '偏好格式';

  @override
  String get cacheSizeLimit => '缓存大小限制';

  @override
  String get llmApiUrl => 'API 地址';

  @override
  String get llmApiKey => 'API Key';

  @override
  String get llmModel => '模型';

  @override
  String get llmPrompt => '系统提示词';

  @override
  String get llmConcurrency => '并发数';

  @override
  String get llmTestTranslation => '测试翻译';

  @override
  String get llmTestSuccess => '测试成功';

  @override
  String get llmTestFailed => '测试失败';

  @override
  String get subtitleTimingAdjustment => '字幕轴调整';

  @override
  String get playerLyricStyle => '播放器歌词样式';

  @override
  String get floatingLyricStyle => '悬浮歌词样式';

  @override
  String get fontSize => '字号';

  @override
  String get fontColor => '字体颜色';

  @override
  String get backgroundColor => '背景颜色';

  @override
  String get transparency => '透明度';

  @override
  String get windowSize => '窗口大小';

  @override
  String get playerButtonSettings => '播放器按钮设置';

  @override
  String get showButton => '显示按钮';

  @override
  String get buttonOrder => '按钮顺序';

  @override
  String get workCardDisplaySettings => '作品卡片显示设置';

  @override
  String get showTags => '显示标签';

  @override
  String get showVa => '显示声优';

  @override
  String get showRating => '显示评分';

  @override
  String get showPrice => '显示价格';

  @override
  String get cardSize => '卡片大小';

  @override
  String get compact => '紧凑';

  @override
  String get medium => '中等';

  @override
  String get full => '完整';

  @override
  String get workDetailDisplaySettings => '作品详情显示设置';

  @override
  String get infoSectionVisibility => '信息区域可见性';

  @override
  String get imageSize => '图片大小';

  @override
  String get showMetadata => '显示元数据';

  @override
  String get relatedRecommendations => '相关推荐';

  @override
  String get myTabsDisplaySettings => '\"我的\"界面设置';

  @override
  String get showTab => '显示标签';

  @override
  String get tabOrder => '标签顺序';

  @override
  String get blockedItems => '屏蔽项目';

  @override
  String get blockedTags => '屏蔽标签';

  @override
  String get blockedVas => '屏蔽声优';

  @override
  String get blockedCircles => '屏蔽社团';

  @override
  String get unblock => '取消屏蔽';

  @override
  String get noBlockedItems => '暂无屏蔽项目';

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheConfirm => '确定要清除所有缓存吗？';

  @override
  String get cacheCleared => '缓存已清除';

  @override
  String get imagePreview => '图片预览';

  @override
  String get saveImage => '保存图片';

  @override
  String get imageSaved => '图片已保存';

  @override
  String get saveImageFailed => '保存失败';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '确定要退出登录吗？';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get copyLink => '复制链接';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get ratingDistribution => '评分分布';

  @override
  String reviewsCount(int count) {
    return '$count 条评论';
  }

  @override
  String ratingsCount(int count) {
    return '共 $count 个评分';
  }

  @override
  String get myReviews => '我的评价';

  @override
  String get noReviews => '暂无评价';

  @override
  String get writeReview => '写评价';

  @override
  String get editReview => '编辑评价';

  @override
  String get deleteReview => '删除评价';

  @override
  String get deleteReviewConfirm => '确定要删除此评价吗？';

  @override
  String get reviewDeleted => '评价已删除';

  @override
  String get reviewContent => '评价内容';

  @override
  String get enterReviewContent => '输入评价内容...';

  @override
  String get submitReview => '提交';

  @override
  String get reviewSubmitted => '评价已提交';

  @override
  String reviewFailed(String error) {
    return '评价失败: $error';
  }

  @override
  String get notificationPermission => '通知权限';

  @override
  String get mediaPermission => '媒体库权限';

  @override
  String get storagePermission => '存储权限';

  @override
  String get granted => '已授予';

  @override
  String get denied => '已拒绝';

  @override
  String get requestPermission => '请求';

  @override
  String get localDownloads => '本地下载';

  @override
  String get offlinePlayback => '离线播放';

  @override
  String get noDownloadedWorks => '暂无已下载作品';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get ignoreThisVersion => '忽略此版本';

  @override
  String get remindLater => '稍后提醒';

  @override
  String get updateNow => '立即更新';

  @override
  String get fetchFailed => '获取失败';

  @override
  String operationFailedWithError(String error) {
    return '操作失败: $error';
  }

  @override
  String get aboutSubtitle => '检查更新、许可证等';

  @override
  String get currentCacheSize => '当前缓存大小';

  @override
  String cacheLimitLabelMB(int size) {
    return '上限: ${size}MB';
  }

  @override
  String get cacheUsagePercent => '使用率';

  @override
  String get autoCleanTitle => '自动清理说明';

  @override
  String get autoCleanDescription =>
      '• 当缓存超过上限时，会自动执行清理\n• 删除直到缓存降低到上限的80%\n• 按最近最少使用(LRU)策略删除';

  @override
  String get autoCleanDescriptionShort =>
      '• 当缓存超过上限时，会自动执行清理\n• 删除直到缓存降低到上限的80%';

  @override
  String get confirmClear => '确认清除';

  @override
  String get confirmClearCacheMessage => '确定要清除所有缓存吗？此操作无法撤销。';

  @override
  String clearCacheFailedWithError(String error) {
    return '清除缓存失败: $error';
  }

  @override
  String get hasNewVersion => '有新版本';

  @override
  String get themeMode => '主题模式';

  @override
  String get colorTheme => '颜色主题';

  @override
  String get themePreview => '主题预览';

  @override
  String get themeModeSystemDesc => '自动适应系统的深色/浅色模式';

  @override
  String get themeModeLightDesc => '始终使用浅色主题';

  @override
  String get themeModeDarkDesc => '始终使用深色主题';

  @override
  String get colorSchemeOceanBlueDesc => '蓝蓝路，蓝蓝路！';

  @override
  String get colorSchemeSakuraPinkDesc => '( ゜- ゜)つロ 乾杯~';

  @override
  String get colorSchemeSunsetOrangeDesc => '软件一定要能换主题✍🏻✍🏻✍🏻';

  @override
  String get colorSchemeLavenderPurpleDesc => '兄弟，兄弟...';

  @override
  String get colorSchemeForestGreenDesc => '艹艹艹';

  @override
  String get colorSchemeDynamicDesc => '使用系统壁纸的颜色 (Android 12+)';

  @override
  String get primaryContainer => '主色容器';

  @override
  String get secondaryContainer => '辅色容器';

  @override
  String get tertiaryContainer => '第三色容器';

  @override
  String get surfaceColor => '表面色';

  @override
  String get playerButtonSettingsSubtitle => '调整播放器按钮顺序';

  @override
  String get playerLyricStyleSubtitle => '调整迷你与全屏歌词样式';

  @override
  String get workDetailDisplaySubtitle => '选择详情页显示内容';

  @override
  String get workCardDisplaySubtitle => '选择作品卡片显示内容';

  @override
  String get myTabsDisplaySubtitle => '选择“我的”页面标签';

  @override
  String get pageSizeSettings => '每页显示数量';

  @override
  String pageSizeCurrent(int size) {
    return '每页 $size 条';
  }

  @override
  String currentSettingLabel(String value) {
    return '当前: $value';
  }

  @override
  String setToValue(String value) {
    return '已设置为: $value';
  }

  @override
  String get llmConfigRequiredMessage => '使用LLM翻译需要配置 API Key。请先前往设置进行配置。';

  @override
  String get autoSwitchedToLlm => '已自动切换至: 大模型翻译';

  @override
  String get translationDescGoogle => '需连接 Google 服务';

  @override
  String get translationDescYoudao => '使用当前网络';

  @override
  String get translationDescMicrosoft => '使用当前网络';

  @override
  String get translationDescLlm => '需配置 OpenAI 兼容 API';

  @override
  String get audioPassthroughDescAndroid => '将 AC3/DTS 原始音频交给外部解码器';

  @override
  String get permissionExplanation => '权限说明';

  @override
  String get backgroundRunningPermission => '后台运行权限';

  @override
  String get notificationPermissionDesc => '用于显示媒体播放通知栏，让您可以在锁屏和通知栏中控制播放。';

  @override
  String get backgroundRunningPermissionDesc =>
      '让应用免受电池优化限制，确保音频在后台持续播放不被系统杀死。';

  @override
  String get notificationGrantedStatus => '已授权 - 可以显示播放通知和控制器';

  @override
  String get notificationDeniedStatus => '未授权 - 点击申请权限';

  @override
  String get backgroundGrantedStatus => '已授权 - 应用可以在后台持续运行';

  @override
  String get backgroundDeniedStatus => '未授权 - 点击申请权限';

  @override
  String get notificationPermissionGranted => '通知权限已授予';

  @override
  String get notificationPermissionDenied => '通知权限被拒绝';

  @override
  String requestNotificationFailed(String error) {
    return '请求通知权限失败: $error';
  }

  @override
  String get backgroundPermissionGranted => '后台运行权限已授予';

  @override
  String get backgroundPermissionDenied => '后台运行权限被拒绝';

  @override
  String requestBackgroundFailed(String error) {
    return '请求后台运行权限失败: $error';
  }

  @override
  String permissionRequired(String permission) {
    return '需要$permission';
  }

  @override
  String permissionPermanentlyDenied(String permission) {
    return '$permission已被永久拒绝，请在系统设置中手动开启。';
  }

  @override
  String get openSettings => '打开设置';

  @override
  String get permissionsAndroidOnly => '权限管理仅在安卓平台可用';

  @override
  String get permissionsNotNeeded => '其他平台不需要手动管理这些权限';

  @override
  String get refreshPermissionStatus => '刷新权限状态';

  @override
  String deleteFileConfirm(String fileName) {
    return '确定要删除 \"$fileName\" 吗？';
  }

  @override
  String deleteSelectedFilesConfirm(int count) {
    return '确定要删除选中的 $count 个文件吗？';
  }

  @override
  String get deleted => '已删除';

  @override
  String cannotOpenFolder(String path) {
    return '无法打开文件夹: $path';
  }

  @override
  String openFolderFailed(String error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get reloadingFromDisk => '正在从硬盘重新加载...';

  @override
  String get refreshComplete => '刷新完成';

  @override
  String refreshFailed(String error) {
    return '刷新失败: $error';
  }

  @override
  String deleteSelectedWorksConfirm(int count) {
    return '确定要删除选中的 $count 个作品吗？';
  }

  @override
  String partialDeleteFailed(String error) {
    return '部分删除失败: $error';
  }

  @override
  String deletedNOfTotal(int success, int total) {
    return '已删除 $success/$total 个任务';
  }

  @override
  String deleteFailedWithError(String error) {
    return '删除失败: $error';
  }

  @override
  String get noWorkMetadataForOffline => '该下载任务没有保存作品详情，无法离线查看';

  @override
  String openWorkDetailFailed(String error) {
    return '打开作品详情失败: $error';
  }

  @override
  String get noLocalDownloads => '暂无本地下载';

  @override
  String get exitSelection => '退出选择';

  @override
  String get reload => '重载';

  @override
  String get openFolder => '打开文件夹';

  @override
  String get playlistLink => '播放列表链接';

  @override
  String get playlistLinkHint =>
      '粘贴播放列表链接，如:\nhttps://www.asmr.one/playlist?id=...';

  @override
  String get unrecognizedPlaylistLink => '无法识别的播放列表链接或ID';

  @override
  String get addingPlaylist => '正在添加播放列表...';

  @override
  String get playlistAddedSuccess => '播放列表添加成功';

  @override
  String get addFailed => '添加失败';

  @override
  String get playlistNotFound => '播放列表不存在或已被删除';

  @override
  String get noPermissionToAccessPlaylist => '没有权限访问此播放列表';

  @override
  String get networkConnectionFailed => '网络连接失败，请检查网络';

  @override
  String addFailedWithError(String error) {
    return '添加失败: $error';
  }

  @override
  String get creatingPlaylist => '正在创建播放列表...';

  @override
  String playlistCreatedSuccess(String name) {
    return '播放列表 \"$name\" 创建成功';
  }

  @override
  String createFailedWithError(String error) {
    return '创建失败: $error';
  }

  @override
  String get noPlaylists => '暂无播放列表';

  @override
  String get noPlaylistsDescription => '您还没有创建或收藏任何播放列表';

  @override
  String get myPlaylists => '我的播放列表';

  @override
  String totalNItems(int count) {
    return '共 $count 条';
  }

  @override
  String get systemPlaylistCannotDelete => '系统播放列表不能删除';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String get unfavoritePlaylist => '取消收藏播放列表';

  @override
  String get deletePlaylistConfirm => '删除后不可恢复，收藏本列表的人将无法再访问。确定要删除吗？';

  @override
  String unfavoritePlaylistConfirm(String name) {
    return '确定要取消收藏\"$name\"吗？';
  }

  @override
  String get unfavorite => '取消收藏';

  @override
  String get deleting => '正在删除...';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get onlyOwnerCanEdit => '只有播放列表作者才能编辑';

  @override
  String get editPlaylist => '编辑播放列表';

  @override
  String get playlistNameRequired => '播放列表名称不能为空';

  @override
  String get privacyDescPrivate => '只有您可以观看';

  @override
  String get privacyDescUnlisted => '知道链接的人才能观看';

  @override
  String get privacyDescPublic => '任何人都可以观看';

  @override
  String get addWorks => '添加作品';

  @override
  String get addWorksInputHint => '输入包含作品号的文本，自动识别RJ号';

  @override
  String get workId => '作品号';

  @override
  String get workIdHint => '例如：RJ123456\nrj233333';

  @override
  String detectedNWorkIds(int count) {
    return '识别到 $count 个作品号';
  }

  @override
  String addNWorks(int count) {
    return '添加 $count 个';
  }

  @override
  String get noValidWorkIds => '未找到有效的作品号（RJ开头）';

  @override
  String addingNWorks(int count) {
    return '正在添加 $count 个作品...';
  }

  @override
  String addedNWorksSuccess(int count) {
    return '成功添加 $count 个作品';
  }

  @override
  String get removeWork => '移除作品';

  @override
  String removeWorkConfirm(String title) {
    return '确定要从播放列表中移除「$title」吗？';
  }

  @override
  String get removeSuccess => '移除成功';

  @override
  String removeFailedWithError(String error) {
    return '移除失败: $error';
  }

  @override
  String get saving => '正在保存...';

  @override
  String get saveSuccess => '保存成功';

  @override
  String saveFailedWithError(String error) {
    return '保存失败: $error';
  }

  @override
  String get noWorks => '暂无作品';

  @override
  String get playlistNoWorksDescription => '此播放列表还没有添加任何作品';

  @override
  String get lastUpdated => '最近更新';

  @override
  String get createdTime => '创建时间';

  @override
  String nWorksCount(int count) {
    return '$count 个作品';
  }

  @override
  String nPlaysCount(int count) {
    return '$count 播放';
  }

  @override
  String get removeFromPlaylist => '从播放列表移除';

  @override
  String get checkNetworkOrRetry => '请检查网络连接或稍后重试';

  @override
  String get reachedEnd => '已经到底啦~杂库~';

  @override
  String excludedNWorks(int count) {
    return '已排除 $count 个作品';
  }

  @override
  String pageExcludedNWorks(int count) {
    return '本页已排除 $count 个作品';
  }

  @override
  String get noSubtitlesAvailable => '暂无字幕';

  @override
  String get translateLyrics => '翻译歌词';

  @override
  String get fullscreenLyrics => '全屏歌词';

  @override
  String get showOriginalLyrics => '显示原文';

  @override
  String get showTranslatedLyrics => '显示翻译';

  @override
  String get translatingLyrics => '翻译中...';

  @override
  String get lyricTranslationFailed => '歌词翻译失败';

  @override
  String get lyricTranslationConfirmMessage =>
      '翻译当前播放的歌词，完成后立即显示。开启自动保存时会以同名 .lrc 覆盖保存到字幕库；翻译中切歌会放弃本次结果。';

  @override
  String get unlock => '解锁';

  @override
  String get backToCover => '返回封面';

  @override
  String get lyricHintTapCover => '点击封面或标题可以进入字幕界面';

  @override
  String get floatingSubtitle => '悬浮字幕';

  @override
  String get appendMode => '追加模式';

  @override
  String get appendModeStatusOn => '追加模式：开启';

  @override
  String get appendModeStatusOff => '追加模式：关闭';

  @override
  String get playlistEmpty => '播放列表为空';

  @override
  String get appendModeEnabled => '追加模式已开启';

  @override
  String get appendModeHint => '之后点击音频会追加到当前播放列表尾部，而不是替换整个列表。\n不会重复添加同一音轨。';

  @override
  String get gotIt => '知道了';

  @override
  String nMinutes(int count) {
    return '$count分钟';
  }

  @override
  String nHours(int count) {
    return '$count小时';
  }

  @override
  String get titleLabel => '标题';

  @override
  String get rjNumberLabel => 'RJ号';

  @override
  String get workIdLabel => '作品编号';

  @override
  String get tapToViewRatingDetail => '点击查看评分详情';

  @override
  String priceInYen(int price) {
    return '$price 日元';
  }

  @override
  String soldCount(String count) {
    return '售出：$count';
  }

  @override
  String get circleAndVaSection => '社团 | 声优';

  @override
  String get subtitleBadge => '字幕';

  @override
  String get otherEditions => '其他版本';

  @override
  String tenThousandSuffix(String count) {
    return '$count万';
  }

  @override
  String get packingWork => '正在打包作品...';

  @override
  String get workDirectoryNotExist => '作品目录不存在';

  @override
  String get packingFailed => '打包失败';

  @override
  String exportSuccess(String path) {
    return '导出成功：$path';
  }

  @override
  String exportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get exportAsZip => '导出为ZIP';

  @override
  String get offlineBadge => '离线';

  @override
  String loadFilesFailed(String error) {
    return '加载文件失败: $error';
  }

  @override
  String get unknown => '未知';

  @override
  String get noPlayableAudioFiles => '没有找到可播放的音频文件';

  @override
  String cannotFindAudioFile(String title) {
    return '无法找到音频文件: $title';
  }

  @override
  String nowPlayingNOfTotal(String title, int current, int total) {
    return '正在播放: $title ($current/$total)';
  }

  @override
  String get noAudioCannotLoadSubtitle => '当前没有播放的音频，无法加载字幕';

  @override
  String get loadSubtitle => '加载字幕';

  @override
  String get loadSubtitleConfirm => '确定要将以下文件加载为当前音频的字幕吗？';

  @override
  String get subtitleFile => '字幕文件';

  @override
  String get currentAudio => '当前音频';

  @override
  String get subtitleAutoRestoreNote => '切换到其他音频时，字幕将自动恢复为默认匹配方式';

  @override
  String get confirmLoad => '确定加载';

  @override
  String get loadingSubtitle => '正在加载字幕...';

  @override
  String subtitleLoadSuccess(String title) {
    return '字幕加载成功：$title';
  }

  @override
  String subtitleLoadFailed(String error) {
    return '字幕加载失败：$error';
  }

  @override
  String get cannotPreviewImageMissingInfo => '无法预览图片：缺少必要信息';

  @override
  String get cannotFindImageFile => '无法找到图片文件';

  @override
  String get cannotPreviewTextMissingInfo => '无法预览文本：缺少必要信息';

  @override
  String get cannotPreviewPdfMissingInfo => '无法预览PDF：缺少必要信息';

  @override
  String get cannotPlayVideoMissingId => '无法播放视频：缺少文件标识';

  @override
  String get cannotPlayVideoMissingParams => '无法播放视频：缺少必要参数';

  @override
  String get cannotPlayDirectly => '无法直接播放';

  @override
  String get noVideoPlayerFound => '系统无法找到支持的视频播放器。';

  @override
  String get youCan => '您可以：';

  @override
  String get copyLinkToExternalPlayer => '1. 复制链接到外部播放器（如MX Player、VLC）';

  @override
  String get openInBrowserOption => '2. 在浏览器中打开';

  @override
  String playVideoError(String error) {
    return '播放视频时出错: $error';
  }

  @override
  String get noFiles => '没有文件';

  @override
  String get resourceFiles => '资源文件';

  @override
  String resourceFilesTranslated(int count) {
    return '资源文件 (已翻译 $count 项)';
  }

  @override
  String get translationOriginal => '原';

  @override
  String get translationTranslated => '译';

  @override
  String copiedName(String title) {
    return '已复制名称: $title';
  }

  @override
  String translationComplete(int count) {
    return '翻译完成：$count 个项目';
  }

  @override
  String get noContentToTranslate => '没有需要翻译的内容';

  @override
  String get preparingTranslation => '准备翻译...';

  @override
  String translatingProgress(int current, int total) {
    return '翻译中 $current/$total';
  }

  @override
  String nItems(int count) {
    return '$count 项';
  }

  @override
  String get loadAsSubtitle => '加载为字幕';

  @override
  String get preview => '预览';

  @override
  String openVideoFileError(String error) {
    return '打开视频文件时出错: $error';
  }

  @override
  String cannotOpenVideoFile(String message) {
    return '无法打开视频文件: $message';
  }

  @override
  String get noFileTreeInfo => '没有文件树信息';

  @override
  String get workFolderNotExist => '作品文件夹不存在';

  @override
  String get cannotPlayAudioMissingId => '无法播放音频：缺少文件标识';

  @override
  String get audioFileNotExist => '音频文件不存在';

  @override
  String get noPreviewableImages => '没有找到可预览的图片';

  @override
  String get cannotPreviewTextMissingId => '无法预览文本：缺少文件标识';

  @override
  String get cannotFindFilePath => '无法找到文件路径';

  @override
  String fileNotExist(String title) {
    return '文件不存在：$title';
  }

  @override
  String get cannotPreviewPdfMissingId => '无法预览PDF：缺少文件标识';

  @override
  String get videoFileNotExist => '视频文件不存在';

  @override
  String get cannotOpenVideo => '无法打开视频';

  @override
  String errorInfo(String message) {
    return '错误信息: $message';
  }

  @override
  String get installVideoPlayerApp => '请安装视频播放器应用（如 VLC、MX Player 等）';

  @override
  String get filePathLabel => '文件路径：';

  @override
  String get noDownloadedFiles => '没有已下载的文件';

  @override
  String get offlineFiles => '离线文件';

  @override
  String unsupportedFileType(String title) {
    return '暂不支持打开此类型文件: $title';
  }

  @override
  String get deleteFilePrompt => '确定要删除这个文件吗？';

  @override
  String deletedItem(String title) {
    return '已删除: $title';
  }

  @override
  String get selectAtLeastOneFile => '请至少选择一个文件';

  @override
  String addedNFilesToDownloadQueue(int count) {
    return '已添加 $count 个文件到下载队列';
  }

  @override
  String downloadedAndSelected(int downloaded, int selected) {
    return '已下载 $downloaded · 已选择 $selected';
  }

  @override
  String downloadN(int count) {
    return '下载 ($count)';
  }

  @override
  String get checkingDownloadedFiles => '正在检查已下载文件...';

  @override
  String get noDownloadableFiles => '没有可下载的文件';

  @override
  String get selectFilesToDownload => '选择下载文件';

  @override
  String downloadedNCount(int count) {
    return '已下载 $count 个';
  }

  @override
  String selectedNCount(int count) {
    return '已选择 $count 个';
  }

  @override
  String get pleaseEnterServerAddress => '请先输入服务器地址';

  @override
  String get pleaseEnterUsername => '请输入用户名';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get notTestedYet => '尚未测试';

  @override
  String latencyResultDetail(String latency, String status) {
    return '延迟 $latency ($status)';
  }

  @override
  String connectionFailedWithDetail(String error) {
    return '连接失败: $error';
  }

  @override
  String get noAccountTapToRegister => '没有账号？点击注册';

  @override
  String get haveAccountTapToLogin => '已有账号？点击登录';

  @override
  String get cannotDeleteActiveAccount => '无法删除当前使用的账户';

  @override
  String get selectAccount => '选择账户';

  @override
  String get noSavedAccounts => '没有保存的账户';

  @override
  String get addAccountToGetStarted => '请添加一个新账户开始使用';

  @override
  String get unknownHost => '未知主机';

  @override
  String lastUsedTime(String time) {
    return '最后使用: $time';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String get justNow => '刚刚';

  @override
  String get confirmDelete => '确认删除';

  @override
  String deleteSelectedConfirm(int count) {
    return '确定要删除选中的 $count 项吗？';
  }

  @override
  String deletedNOfTotalItems(int success, int total) {
    return '已删除 $success/$total 项';
  }

  @override
  String get importingSubtitleFile => '正在导入字幕文件...';

  @override
  String get preparingImport => '正在准备导入...';

  @override
  String get preparingExtract => '正在准备解压...';

  @override
  String get importSubtitleFile => '导入字幕文件';

  @override
  String get supportedSubtitleFormats => '支持 .srt, .vtt, .lrc 等字幕格式';

  @override
  String get importFolder => '导入文件夹';

  @override
  String get importFolderDesc => '保留文件夹结构，仅导入字幕文件';

  @override
  String get importArchive => '导入压缩包';

  @override
  String get importArchiveDesc => '支持无密码 ZIP 压缩包\n如需批量导入，将它们压缩为一个压缩包再导入';

  @override
  String get subtitleLibraryGuide => '字幕库使用说明';

  @override
  String get subtitleLibraryFunction => '字幕库功能';

  @override
  String get subtitleLibraryFunctionDesc => '用于存放主动导入或保存的字幕文件，并在播放音频时支持自动/手动加载';

  @override
  String get subtitleAutoLoad => '字幕自动加载';

  @override
  String get subtitleAutoLoadDesc => '播放音频时，系统会自动在字幕库中查找匹配的字幕文件：';

  @override
  String get smartCategoryAndMark => '智能分类与标记';

  @override
  String get open => '打开';

  @override
  String get moveTo => '移动到';

  @override
  String get rename => '重命名';

  @override
  String get newName => '新名称';

  @override
  String get renameSuccess => '重命名成功';

  @override
  String get renameFailed => '重命名失败';

  @override
  String deleteItemConfirm(String title) {
    return '确定要删除 \"$title\" 吗？';
  }

  @override
  String get deleteFolderContentsWarning => '此操作将删除文件夹内的所有内容。';

  @override
  String get deleteFailed => '删除失败';

  @override
  String subtitleLoaded(String title) {
    return '字幕已加载：$title';
  }

  @override
  String get moveSuccess => '移动成功';

  @override
  String get moveFailed => '移动失败';

  @override
  String previewFailed(String error) {
    return '预览失败: $error';
  }

  @override
  String openFailed(String error) {
    return '打开失败: $error';
  }

  @override
  String get back => '返回';

  @override
  String get subtitleLibraryEmpty => '字幕库为空';

  @override
  String get tapToImportSubtitle => '点击右下角 + 按钮导入字幕';

  @override
  String get importSubtitle => '导入字幕';

  @override
  String get sampleSubtitleContent => '♪ 示例字幕内容 ♪';

  @override
  String get presetStyles => '预设样式';

  @override
  String get backgroundOpacity => '背景不透明度';

  @override
  String get colorSettings => '颜色设置';

  @override
  String get shapeSettings => '形状设置';

  @override
  String get cornerRadius => '圆角半径';

  @override
  String get horizontalPadding => '水平内边距';

  @override
  String get verticalPadding => '垂直内边距';

  @override
  String get resetStyle => '重置样式';

  @override
  String get resetStyleConfirm => '确定要恢复默认样式吗？';

  @override
  String get restoreDefaultStyle => '恢复默认样式';

  @override
  String get reset => '重置';

  @override
  String noBlockedItemsOfType(String type) {
    return '没有屏蔽的$type';
  }

  @override
  String unblockedItem(String item) {
    return '已移除屏蔽: $item';
  }

  @override
  String addBlockedItem(String type) {
    return '添加屏蔽$type';
  }

  @override
  String blockedItemName(String type) {
    return '$type名称';
  }

  @override
  String enterBlockedItemHint(String type) {
    return '请输入要屏蔽的$type';
  }

  @override
  String blockedItemAdded(String item) {
    return '已添加屏蔽: $item';
  }

  @override
  String workCountLabel(int count) {
    return '作品数: $count';
  }

  @override
  String get miniPlayer => '迷你播放器';

  @override
  String get lineHeight => '行高';

  @override
  String get portraitPlayerBelowCover => '竖屏播放器 (封面下方)';

  @override
  String get fullscreenSubtitleMode => '全屏字幕 (竖屏/横屏)';

  @override
  String get activeSubtitleFontSize => '当前字幕大小';

  @override
  String get inactiveSubtitleFontSize => '其他字幕大小';

  @override
  String get restoreDefaultSettings => '恢复默认设置';

  @override
  String get confirmRestoreDefaultSettings => '确定要恢复默认设置吗？';

  @override
  String get guideInPrefix => '在';

  @override
  String get guideParsedFolder => '<已解析>';

  @override
  String get guideFindWorkDesc => '文件夹下查找对应作品\n支持文件夹格式：RJ123456';

  @override
  String get guideSavedFolder => '<已保存>';

  @override
  String get guideFindSubtitleDesc => '文件夹下查找单个字幕文件';

  @override
  String get guideMatchRule => '匹配规则：字幕文件名与音频文件名相同（去除或保留音频扩展名均可）';

  @override
  String get guideRecognizedWorkPrefix => '识别到的作品会被添加绿色';

  @override
  String get guideTagSuffix => '标签 ，音频文件图标也会增加 ';

  @override
  String get guideSubtitleMatchSuffix => ' 标记，表示有字幕库匹配';

  @override
  String get guideAutoRecognizeRJ => '导入时自动识别 RJ 格式，归类到<已解析>';

  @override
  String get guideAutoAddRJPrefix => '纯数字文件夹自动添加 RJ 前缀（如 123456 → RJ123456）';

  @override
  String get unknownFile => '未知文件';

  @override
  String deleteWithCount(int count) {
    return '删除 ($count)';
  }

  @override
  String get searchSubtitles => '搜索字幕...';

  @override
  String nFilesWithSize(int count, String size) {
    return '$count 个文件 • $size';
  }

  @override
  String get rootDirectory => '根目录';

  @override
  String get goToParent => '返回上级';

  @override
  String moveToTarget(String name) {
    return '移动到: $name';
  }

  @override
  String get noSubfoldersHere => '此目录下没有子文件夹';

  @override
  String addedToPlaylist(String name) {
    return '已添加到播放列表「$name」';
  }

  @override
  String removedFromPlaylist(String name) {
    return '已从播放列表「$name」中移除';
  }

  @override
  String get alreadyFavorited => '已收藏';

  @override
  String loadImageFailedWithError(String error) {
    return '加载图片失败\n$error';
  }

  @override
  String get noImageAvailable => '没有可用的图片';

  @override
  String get storagePermissionRequiredForImage => '需要存储权限才能保存图片';

  @override
  String get savedToGallery => '已保存到相册';

  @override
  String get saveCoverImage => '保存封面图片';

  @override
  String savedToPath(String path) {
    return '已保存到: $path';
  }

  @override
  String get doubleTapToZoom => '双击放大 · 双指缩放';

  @override
  String getStatusFailed(String error) {
    return '获取状态失败: $error';
  }

  @override
  String get deleteRecord => '删除记录';

  @override
  String deletePlayRecordConfirm(String title) {
    return '确定要删除 \"$title\" 的播放记录吗？';
  }

  @override
  String get notPlayedYet => '尚未播放';

  @override
  String playbackFailed(String error) {
    return '播放失败: $error';
  }

  @override
  String get storagePermissionRequired => '需要存储权限';

  @override
  String get storagePermissionForGalleryDesc => '保存图片需要访问相册的权限。请在设置中授予权限。';

  @override
  String get goToSettings => '去设置';

  @override
  String get imageSavedToGallery => '图片已保存到相册';

  @override
  String imageSavedToPath(String path) {
    return '图片已保存到: $path';
  }

  @override
  String get pullDownForNextPage => '继续下拉跳转下一页';

  @override
  String get releaseForNextPage => '释放跳转下一页';

  @override
  String get jumpTo => '跳转';

  @override
  String get goToPageTitle => '跳转到指定页';

  @override
  String pageNumberRange(int max) {
    return '页码 (1-$max)';
  }

  @override
  String get enterPageNumber => '请输入页码';

  @override
  String enterValidPageNumber(int max) {
    return '请输入有效页码 (1-$max)';
  }

  @override
  String get previousPage => '上一页';

  @override
  String get nextPage => '下一页';

  @override
  String get localPdfNotExist => '本地PDF文件不存在';

  @override
  String get cannotOpenPdf => '无法打开PDF文件';

  @override
  String loadPdfFailed(String error) {
    return '加载PDF失败: $error';
  }

  @override
  String pdfPageOfTotal(int current, int total) {
    return '第 $current 页 / 共 $total 页';
  }

  @override
  String get loadingPdf => '正在加载PDF...';

  @override
  String get pdfPathInvalid => 'PDF文件路径无效';

  @override
  String get desktopPdfPreviewNotSupported => '桌面端暂不支持直接预览 PDF';

  @override
  String get openWithSystemApp => '使用系统默认应用打开';

  @override
  String renderPdfFailed(String error) {
    return '渲染PDF失败: $error';
  }

  @override
  String get ratingDetails => '评分详情';

  @override
  String get selectSaveDirectory => '选择保存目录';

  @override
  String get noSubtitleContentToSave => '没有可保存的字幕内容';

  @override
  String get savedToSubtitleLibrary => '已保存到字幕库';

  @override
  String get translatedLyricsNotSaved => '翻译已完成，仅在当前播放中显示';

  @override
  String get saveToLocal => '保存到本地';

  @override
  String get selectDirectoryToSaveFile => '选择目录保存文件';

  @override
  String get saveToSubtitleLibrary => '保存到字幕库';

  @override
  String get saveToSubtitleLibraryDesc => '保存到字幕库的\"已保存\"目录';

  @override
  String get saveToFile => '保存到文件';

  @override
  String get noContentToSave => '没有可保存的内容';

  @override
  String fileSavedToPath(String path) {
    return '文件已保存到：$path';
  }

  @override
  String get localFileNotExist => '本地文件不存在，请尝试重载';

  @override
  String loadTextFailed(String error) {
    return '加载文本失败: $error';
  }

  @override
  String get previewMode => '预览模式';

  @override
  String get editMode => '编辑模式';

  @override
  String get showOriginal => '显示原文';

  @override
  String get translateContent => '翻译内容';

  @override
  String get editTextContentHint => '编辑文本内容...';

  @override
  String get markButton => '标记';

  @override
  String get bookmarkRemoved => '已移除标记';

  @override
  String setProgressAndRating(String progress, int rating) {
    return '已设置为：$progress，评分：$rating 星';
  }

  @override
  String setProgressTo(String progress) {
    return '已设置为：$progress';
  }

  @override
  String ratingSetTo(int rating) {
    return '评分已设置为：$rating 星';
  }

  @override
  String get updated => '已更新';

  @override
  String addTagFailed(String error) {
    return '添加标签失败: $error';
  }

  @override
  String addWithCount(int count) {
    return '添加 ($count)';
  }

  @override
  String get undo => '撤销';

  @override
  String nStars(int count) {
    return '$count 星';
  }

  @override
  String get voteRemoved => '已取消投票';

  @override
  String get votedUp => '已投支持票';

  @override
  String get votedDown => '已投反对票';

  @override
  String voteFailedWithError(String error) {
    return '投票失败: $error';
  }

  @override
  String get voteFor => '支持';

  @override
  String get voteAgainst => '反对';

  @override
  String get voted => '已投票';

  @override
  String tagBlockedWithName(String name) {
    return '已屏蔽标签: $name';
  }

  @override
  String get subtitleParseFailedUnsupportedFormat => '解析失败，格式不支持';

  @override
  String get lyricPresetDynamic => '动态';

  @override
  String get lyricPresetClassic => '经典';

  @override
  String get lyricPresetModern => '现代';

  @override
  String get lyricPresetMinimal => '极简';

  @override
  String get lyricPresetVibrant => '鲜艳';

  @override
  String get lyricPresetElegant => '优雅';

  @override
  String get lyricPresetDynamicDesc => '跟随系统主题，自动取色';

  @override
  String get lyricPresetClassicDesc => '黑底白字，经典耐看';

  @override
  String get lyricPresetModernDesc => '渐变背景，时尚现代';

  @override
  String get lyricPresetMinimalDesc => '轻透明，简约优雅';

  @override
  String get lyricPresetVibrantDesc => '色彩鲜明，活力四射';

  @override
  String get lyricPresetElegantDesc => '深蓝底，高雅气质';

  @override
  String get floatingLyricLoading => '♪ 加载字幕中 ♪';

  @override
  String get subtitleFileNotExist => '文件不存在';

  @override
  String get subtitleMissingInfo => '缺少必要信息';

  @override
  String get privacyDefaultTitle => '正在播放音频';

  @override
  String get offlineModeStartup => '网络连接失败，以离线模式启动';

  @override
  String get playlistInfoNotLoaded => '播放列表信息未加载';

  @override
  String get encodingUnrecognized => '文件编码无法识别，无法正确显示内容';

  @override
  String editPlaylistFailed(String error) {
    return '编辑播放列表失败: $error';
  }

  @override
  String unsupportedFileTypeWithTitle(String title) {
    return '暂不支持打开此类型文件: $title';
  }

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get restoredToDefault => '已恢复默认设置';

  @override
  String get restoreDefault => '恢复默认';

  @override
  String get saveSettings => '保存设置';

  @override
  String get addAtLeastOneSearchCondition => '请至少添加一个搜索条件';

  @override
  String get privacyModeSettingsTitle => '防社死设置';

  @override
  String get whatIsPrivacyMode => '什么是防社死模式？';

  @override
  String get privacyModeDescription => '启用后，在系统通知栏、锁屏等位置显示的播放信息将被模糊处理，保护您的隐私。';

  @override
  String get enablePrivacyMode => '启用防社死模式';

  @override
  String get privacyModeEnabledSubtitle => '已启用 - 播放信息将被隐藏';

  @override
  String get privacyModeDisabledSubtitle => '未启用 - 正常显示播放信息';

  @override
  String get blurOptions => '模糊处理选项';

  @override
  String get blurNotificationCover => '模糊通知封面';

  @override
  String get blurNotificationCoverSubtitle => '对系统通知、锁屏或控制中心中的封面应用模糊';

  @override
  String get blurInAppCover => '模糊应用内封面';

  @override
  String get blurInAppCoverSubtitle => '在播放器、列表等界面中模糊封面图片';

  @override
  String get replaceTitle => '替换标题';

  @override
  String get replaceTitleSubtitle => '使用自定义标题替换真实标题';

  @override
  String get replaceTitleContent => '替换标题内容';

  @override
  String get setReplaceTitle => '设置替换标题';

  @override
  String get enterDisplayTitle => '输入要显示的标题';

  @override
  String get replaceTitleSaved => '替换标题已保存';

  @override
  String get effectExample => '效果举例';

  @override
  String get downloadPathSettings => '下载路径设置';

  @override
  String loadPathFailedWithError(String error) {
    return '加载路径失败: $error';
  }

  @override
  String get platformNotSupportCustomPath => '当前平台不支持自定义下载路径';

  @override
  String activeDownloadsWarning(int count) {
    return '有 $count 个下载任务正在进行中，请先取消或完成下载后再切换路径';
  }

  @override
  String setPathFailedWithError(String error) {
    return '设置路径失败: $error';
  }

  @override
  String get confirmMigrateFiles => '确认迁移下载文件';

  @override
  String get migrateFilesToNewDir => '将把现有下载文件迁移到新目录：';

  @override
  String get migrationMayTakeTime => '此操作可能需要一些时间，具体取决于文件数量和大小。';

  @override
  String get confirmMigrate => '确认迁移';

  @override
  String get restoreDefaultPath => '恢复默认路径';

  @override
  String get restoreDefaultPathConfirm => '将下载路径恢复为默认位置，并迁移所有文件。\n\n是否继续？';

  @override
  String get defaultPathRestored => '已恢复默认路径';

  @override
  String resetPathFailedWithError(String error) {
    return '恢复默认路径失败: $error';
  }

  @override
  String get migratingFiles => '正在迁移文件...';

  @override
  String get doNotCloseApp => '请勿关闭应用';

  @override
  String get currentDownloadPath => '当前下载路径';

  @override
  String get customPath => '自定义路径';

  @override
  String get defaultPath => '默认路径';

  @override
  String get changeCustomPath => '更改自定义路径';

  @override
  String get setCustomPath => '设置自定义路径';

  @override
  String get usageInstructions => '使用说明';

  @override
  String get downloadPathUsageDesc =>
      '• 自定义路径后，所有现有文件将自动迁移到新位置\n• 迁移过程中请勿关闭应用\n• 建议选择空间充足的目录\n• 恢复默认路径时，文件也会自动迁移回去';

  @override
  String get llmTranslationSettings => 'LLM翻译设置';

  @override
  String get apiEndpointUrl => 'API 接口地址';

  @override
  String get openaiCompatibleEndpoint => 'OpenAI 兼容接口地址';

  @override
  String get pleaseEnterApiUrl => '请输入 API 接口地址';

  @override
  String get pleaseEnterValidUrl => '请输入有效的 URL';

  @override
  String get pleaseEnterApiKey => '请输入 API Key';

  @override
  String get modelName => '模型名称';

  @override
  String get pleaseEnterModelName => '请输入模型名称';

  @override
  String get concurrencyCount => '并发数';

  @override
  String get concurrencyDescription => '同时进行的翻译请求数量，建议 3-5';

  @override
  String get promptSection => '提示词 (Prompt)';

  @override
  String get promptDescription =>
      '由于系统采用分块翻译机制，请确保 Prompt 指令明确，要求只输出翻译结果，不包含任何解释。';

  @override
  String get enterSystemPrompt => '输入系统提示词...';

  @override
  String get pleaseEnterPrompt => '请输入提示词';

  @override
  String get restoreDefaultPrompt => '恢复默认提示词';

  @override
  String get confirmRestoreButtonOrder => '确定要恢复默认的按钮顺序吗？';

  @override
  String get buttonDisplayRules => '按钮显示规则';

  @override
  String buttonDisplayRulesDesc(int maxVisible) {
    return '• 前 $maxVisible 个按钮会显示在播放器底部\n• 其余按钮会收纳在\"更多\"菜单中';
  }

  @override
  String get shownInPlayer => '显示在播放器';

  @override
  String get shownInMoreMenu => '显示在更多菜单';

  @override
  String get audioFormatPriority => '音频格式优先级';

  @override
  String get confirmRestoreAudioFormat => '确定要恢复默认的音频格式优先级吗？';

  @override
  String get priorityDescription => '优先级说明';

  @override
  String get audioFormatPriorityDesc => '• 打开作品详情页时，会自动优先展开优先级更高格式音频的文件夹';

  @override
  String get ratingInfo => '评分信息';

  @override
  String get showRatingAndReviewCount => '显示作品评分和评价人数';

  @override
  String get priceInfo => '售价信息';

  @override
  String get showWorkPrice => '显示作品价格';

  @override
  String get durationInfo => '时长信息';

  @override
  String get showWorkDuration => '显示作品时长';

  @override
  String get showWorkTotalDuration => '显示作品总时长';

  @override
  String get salesInfo => '售出信息';

  @override
  String get showWorkSalesCount => '显示作品售出数量';

  @override
  String get externalLinkInfo => '外部链接信息';

  @override
  String get showExternalLinks => '显示DLsite、官网等外部链接';

  @override
  String get releaseDateInfo => '发布日期';

  @override
  String get showWorkReleaseDate => '显示作品发布日期';

  @override
  String get translateButtonLabel => '翻译按钮';

  @override
  String get showTranslateButton => '显示作品标题的翻译按钮';

  @override
  String get subtitleTagLabel => '字幕标签';

  @override
  String get showSubtitleTagOnCover => '在封面图上显示字幕标签';

  @override
  String get showAgeRatingOnDetail => '在作品详情页显示年龄分级';

  @override
  String get recommendationsLabel => '相关推荐';

  @override
  String get showRecommendations => '在作品详情页显示相关推荐';

  @override
  String get circleInfo => '社团信息';

  @override
  String get showWorkCircle => '显示作品所属社团';

  @override
  String get workCardSizeSubtitle => '调整网格密度，让封面更大或保持当前大小';

  @override
  String get workCardFontSize => '卡片文字大小';

  @override
  String get workCardFontSizeSubtitle => '调整作品卡片的标题和信息文字大小';

  @override
  String get cardSizeNormal => '默认';

  @override
  String get cardSizeLarge => '大';

  @override
  String get cardSizeExtraLarge => '特大';

  @override
  String get fontSizeNormal => '默认';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeExtraLarge => '特大';

  @override
  String get showSubtitleTagOnCard => '显示作品卡片上的字幕标签';

  @override
  String get showAgeRatingOnCard => '显示作品卡片上的年龄分级';

  @override
  String get showOnlineMarks => '显示在线标记的作品';

  @override
  String get cannotBeDisabled => '不可关闭';

  @override
  String get showPlaylists => '显示创建的播放列表';

  @override
  String get showSubtitleLibrary => '显示字幕库管理';

  @override
  String get playlistPrivacyPrivateDesc => '只有您可以查看';

  @override
  String get playlistPrivacyUnlistedDesc => '知道链接的人才能查看';

  @override
  String get playlistPrivacyPublicDesc => '任何人都可以查看';

  @override
  String get clearTranslationCache => '清除翻译缓存';

  @override
  String get translationCacheCleared => '翻译缓存已清除';

  @override
  String get platformHintAndroid => 'Android: 将使用系统文件选择器，可能需要存储权限';

  @override
  String get platformHintIOS => 'iOS: 受系统限制，使用默认路径，可使用系统默认文件浏览器查看';

  @override
  String get platformHintWindows => 'Windows: 可选择任意可访问的目录';

  @override
  String get platformHintMacOS => 'macOS: 可选择任意可访问的目录';

  @override
  String get platformHintLinux => 'Linux: 可选择任意可访问的目录';

  @override
  String get platformHintDefault => '选择一个用于保存下载文件的目录';

  @override
  String get subtitleFolderParsed => '已解析';

  @override
  String get subtitleFolderSaved => '已保存';

  @override
  String get subtitleFolderUnknown => '未知作品';

  @override
  String get sortDownloadDate => '下载日期';

  @override
  String get sortWorkId => 'ID';

  @override
  String get searchDownloads => '搜索已下载作品...';

  @override
  String get logTitle => '应用日志';

  @override
  String get logSubtitle => '查看、导出应用运行日志';

  @override
  String get logSearchHint => '搜索日志...';

  @override
  String get logFilterAll => '全部';

  @override
  String get logCopy => '复制日志';

  @override
  String get logExport => '导出日志文件';

  @override
  String get logClear => '清空日志';

  @override
  String get logCopied => '日志已复制到剪贴板';

  @override
  String logExported(String path) {
    return '日志已导出到 $path';
  }

  @override
  String logCount(int count) {
    return '$count 条日志';
  }

  @override
  String get logAutoScroll => '自动滚动';

  @override
  String get logEmpty => '暂无日志';

  @override
  String get proxySettingsOptional => '代理';

  @override
  String get loginAdvancedSettings => '高级配置';

  @override
  String proxyEnabled(String address) {
    return '已启用：$address';
  }

  @override
  String get proxyAddressNotSet => '未设置（默认直连）';

  @override
  String get proxyHttpDescription => '通过 HTTP 代理连接服务器';

  @override
  String get useProxy => '使用代理';

  @override
  String get proxyAddress => '代理地址';

  @override
  String get proxyAddressFormat => '格式：主机:端口，例如 127.0.0.1:7890';

  @override
  String get applyProxyAddress => '应用代理地址';

  @override
  String get invalidProxyAddress => '请输入有效的 HTTP 代理地址和端口';

  @override
  String get proxyModeDirect => '直连';

  @override
  String get proxyModeSystem => '系统代理';

  @override
  String get proxyModeManual => '手动代理';

  @override
  String get proxyModeDirectDescription => '不使用代理直接连接';

  @override
  String get proxyModeSystemDescription => '使用操作系统的代理设置';

  @override
  String get proxyModeManualDescription => '使用下方配置的 HTTP 代理';

  @override
  String get playlistDisplayFormat => '播放列表布局';

  @override
  String get playlistDisplayFormatMasonry => '瀑布流';

  @override
  String get playlistDisplayFormatList => '列表';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class SZhHant extends SZh {
  SZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'KikoFlu';

  @override
  String get navHome => '首頁';

  @override
  String get navSearch => '搜尋';

  @override
  String get navMy => '我的';

  @override
  String get navSettings => '設定';

  @override
  String get offlineModeMessage => '離線模式：網路連線失敗，僅可存取已下載內容';

  @override
  String get retry => '重試';

  @override
  String get searchTypeKeyword => '關鍵字';

  @override
  String get searchTypeTag => '標籤';

  @override
  String get searchTypeVa => '聲優';

  @override
  String get searchTypeCircle => '社團';

  @override
  String get searchTypeRjNumber => 'RJ號';

  @override
  String get searchHintKeyword => '輸入作品名稱或關鍵字...';

  @override
  String get searchHintTag => '輸入標籤名...';

  @override
  String get searchHintVa => '輸入聲優名...';

  @override
  String get searchHintCircle => '輸入社團名...';

  @override
  String get searchHintRjNumber => '輸入數字...';

  @override
  String get ageRatingAll => '全部';

  @override
  String get ageRatingGeneral => '全年齡';

  @override
  String get ageRatingR15 => 'R-15';

  @override
  String get ageRatingAdult => '成人向';

  @override
  String get salesRangeAll => '全部';

  @override
  String get sortRelease => '發布日期';

  @override
  String get sortCreateAt => '添加日期';

  @override
  String get sortCreateDate => '收錄日期';

  @override
  String get sortRating => '評分';

  @override
  String get sortReviewCount => '評論數';

  @override
  String get sortRandom => '隨機';

  @override
  String get sortDlCount => '銷量';

  @override
  String get sortPrice => '價格';

  @override
  String get sortNsfw => '全年齡';

  @override
  String get sortUpdatedAt => '標記時間';

  @override
  String get sortAsc => '升序';

  @override
  String get sortDesc => '降序';

  @override
  String get sortOptions => '排序選項';

  @override
  String get sortField => '排序欄位';

  @override
  String get sortDirection => '排序方向';

  @override
  String get displayModeAll => '全部';

  @override
  String get displayModePopular => '熱門';

  @override
  String get displayModeRecommended => '推薦';

  @override
  String get subtitlePriorityHighest => '優先';

  @override
  String get subtitlePriorityLowest => '滯後';

  @override
  String get translationSourceGoogle => 'Google 翻譯';

  @override
  String get translationSourceYoudao => 'Youdao 翻譯';

  @override
  String get translationSourceMicrosoft => 'Microsoft 翻譯';

  @override
  String get translationSourceLlm => 'LLM 翻譯';

  @override
  String get progressMarked => '想聽';

  @override
  String get progressListening => '在聽';

  @override
  String get progressListened => '聽過';

  @override
  String get progressReplay => '重聽';

  @override
  String get progressPostponed => '擱置';

  @override
  String get loginTitle => '登入';

  @override
  String get register => '註冊';

  @override
  String get addAccount => '新增帳戶';

  @override
  String get registerAccount => '註冊帳戶';

  @override
  String get username => '使用者名稱';

  @override
  String get password => '密碼';

  @override
  String get serverAddress => '伺服器位址';

  @override
  String get serverCookie => '伺服器Cookie';

  @override
  String get login => '登入';

  @override
  String get loginSuccess => '登入成功';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get registerFailed => '註冊失敗';

  @override
  String get usernameMinLength => '使用者名稱不能少於5個字元';

  @override
  String get passwordMinLength => '密碼不能少於5個字元';

  @override
  String accountAdded(String username) {
    return '帳戶 \"$username\" 已新增';
  }

  @override
  String get testConnection => '測試連線';

  @override
  String get testing => '測試中...';

  @override
  String get enterServerAddressToTest => '請輸入伺服器位址後測試連線';

  @override
  String latencyMs(String ms) {
    return '${ms}ms';
  }

  @override
  String get connectionFailed => '連線失敗';

  @override
  String get guestModeTitle => '訪客模式確認';

  @override
  String get guestModeMessage =>
      '訪客模式功能有限：\n\n• 無法標記或評分作品\n• 無法建立播放清單\n• 無法同步進度\n\n訪客模式使用示範帳號連線伺服器，可能不夠穩定。';

  @override
  String get continueGuestMode => '繼續使用訪客模式';

  @override
  String get guestAccountAdded => '訪客帳戶已新增';

  @override
  String get guestLoginFailed => '訪客登入失敗';

  @override
  String get guestMode => '訪客模式';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確定';

  @override
  String get close => '關閉';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get edit => '編輯';

  @override
  String get add => '新增';

  @override
  String get create => '建立';

  @override
  String get ok => '好的';

  @override
  String get search => '搜尋';

  @override
  String get filter => '篩選';

  @override
  String get advancedFilter => '進階篩選';

  @override
  String get enterSearchContent => '請輸入搜尋內容';

  @override
  String get searchTag => '搜尋標籤...';

  @override
  String get minRating => '最低評分';

  @override
  String minRatingStars(String stars) {
    return '$stars 星';
  }

  @override
  String get searchHistory => '搜尋歷史';

  @override
  String get clearSearchHistory => '清除搜尋歷史';

  @override
  String get clearSearchHistoryConfirm => '確定要清除所有搜尋歷史嗎？';

  @override
  String get clear => '清除';

  @override
  String get searchHistoryCleared => '搜尋歷史已清除';

  @override
  String get noSearchHistory => '暫無搜尋歷史';

  @override
  String get excludeMode => '排除';

  @override
  String get includeMode => '包含';

  @override
  String includeModeTapAgainHint(String searchType) {
    return '包含：$searchType（再次點擊進入排除模式）';
  }

  @override
  String get noResults => '沒有結果';

  @override
  String get loadFailed => '載入失敗';

  @override
  String loadFailedWithError(String error) {
    return '載入失敗: $error';
  }

  @override
  String get loading => '載入中...';

  @override
  String get calculating => '計算中...';

  @override
  String get getFailed => '取得失敗';

  @override
  String get settingsTitle => '設定';

  @override
  String get accountManagement => '帳戶管理';

  @override
  String get accountManagementSubtitle => '多帳戶管理、切換帳戶';

  @override
  String get privacyMode => '防社死模式';

  @override
  String get privacyModeEnabled => '已啟用 - 播放資訊已隱藏';

  @override
  String get privacyModeDisabled => '未啟用';

  @override
  String get permissionManagement => '權限管理';

  @override
  String get permissionManagementSubtitle => '通知權限、背景執行權限';

  @override
  String get desktopFloatingLyric => '桌面懸浮字幕';

  @override
  String get floatingLyricEnabled => '已啟用 - 字幕將顯示在桌面上';

  @override
  String get floatingLyricDisabled => '未啟用';

  @override
  String get floatingLyricTouch => '懸浮字幕鎖定';

  @override
  String get floatingLyricTouchEnabled => '已解鎖 - 可拖動懸浮字幕，長按可鎖定';

  @override
  String get floatingLyricTouchDisabled => '已鎖定 - 長按懸浮字幕解鎖';

  @override
  String get floatingLyricClickThrough => '懸浮字幕點擊穿透';

  @override
  String get floatingLyricClickThroughEnabled => '已啟用 - 懸浮字幕將忽略滑鼠操作';

  @override
  String get floatingLyricClickThroughDisabled => '未啟用 - 可拖動懸浮字幕';

  @override
  String get floatingFPS => '顯示幀率';

  @override
  String get floatingFPSEnabled => '已開啟 - 幀率顯示在懸浮窗左下角';

  @override
  String get floatingFPSDisabled => '未開啟';

  @override
  String get floatingNetworkSpeed => '顯示網速';

  @override
  String get floatingNetworkSpeedEnabled => '已開啟 - 網速顯示在懸浮窗右下角';

  @override
  String get floatingNetworkSpeedDisabled => '未開啟';

  @override
  String get styleSettings => '樣式設定';

  @override
  String get styleSettingsSubtitle => '自訂字型、顏色、透明度等';

  @override
  String get downloadPath => '下載路徑';

  @override
  String get downloadPathSubtitle => '自訂下載檔案儲存位置';

  @override
  String get maxConcurrentDownloads => '最大同時下載數';

  @override
  String get maxConcurrentDownloadsSubtitle => '限制同時進行的下載任務數量';

  @override
  String get cacheManagement => '快取管理';

  @override
  String currentCache(String size) {
    return '目前快取: $size';
  }

  @override
  String get themeSettings => '主題設定';

  @override
  String get themeSettingsSubtitle => '深色模式、主題色等';

  @override
  String get uiSettings => '介面設定';

  @override
  String get uiSettingsSubtitle => '播放器、詳情頁、卡片等';

  @override
  String get liquidGlassNavigation => '液態玻璃導覽';

  @override
  String get liquidGlassNavigationDesc => '玻璃導覽列與迷你播放器；Apple 系 26+ 平台預設開啟';

  @override
  String get fallbackGlassTransparency => '液態玻璃透明度';

  @override
  String get fallbackGlassTransparencyDesc => '調整應用程式繪製玻璃的透明度';

  @override
  String get preferenceSettings => '偏好設定';

  @override
  String get preferenceSettingsSubtitle => '翻譯、播放與網路';

  @override
  String get aboutTitle => '關於';

  @override
  String get unknownVersion => '未知';

  @override
  String get licenseLoadFailed => '無法載入 LICENSE 檔案';

  @override
  String get licenseEmpty => 'LICENSE 內容為空';

  @override
  String get failedToLoadAbout => '無法載入關於資訊';

  @override
  String get newVersionFound => '發現新版本';

  @override
  String newVersionAvailable(String version, String current) {
    return '$version 可用（目前版本: $current）';
  }

  @override
  String get versionInfo => '版本資訊';

  @override
  String currentVersion(String version) {
    return '目前版本：$version';
  }

  @override
  String get checkUpdate => '檢查更新';

  @override
  String get author => '作者';

  @override
  String get projectRepo => '專案倉庫';

  @override
  String get openSourceLicense => '開源協議';

  @override
  String get cannotOpenLink => '無法開啟連結';

  @override
  String openLinkFailed(String error) {
    return '開啟連結失敗：$error';
  }

  @override
  String foundNewVersion(String version) {
    return '發現新版本 $version';
  }

  @override
  String get view => '檢視';

  @override
  String get alreadyLatestVersion => '目前已是最新版本';

  @override
  String get checkUpdateFailed => '檢查更新失敗，請檢查網路連線';

  @override
  String get onlineMarks => '線上標記';

  @override
  String get historyRecord => '歷史記錄';

  @override
  String get playlists => '播放清單';

  @override
  String get downloaded => '已下載';

  @override
  String get downloadTasks => '下載任務';

  @override
  String get subtitleLibrary => '字幕庫';

  @override
  String get all => '全部';

  @override
  String get marked => '想聽';

  @override
  String get listening => '在聽';

  @override
  String get listened => '聽過';

  @override
  String get replayMark => '重聽';

  @override
  String get postponed => '擱置';

  @override
  String get switchToSmallGrid => '切換到小網格檢視';

  @override
  String get switchToList => '切換到清單檢視';

  @override
  String get switchToLargeGrid => '切換到大網格檢視';

  @override
  String get sort => '排序';

  @override
  String get noPlayHistory => '暫無播放歷史';

  @override
  String get clearHistory => '清空歷史';

  @override
  String get clearHistoryTitle => '清空歷史';

  @override
  String get clearHistoryConfirm => '確定要清空所有播放歷史嗎？此操作無法復原。';

  @override
  String get popularNoSort => '熱門推薦模式不支援排序';

  @override
  String get recommendedNoSort => '推薦模式不支援排序';

  @override
  String get showAllWorks => '顯示全部作品';

  @override
  String get showOnlySubtitled => '僅顯示帶字幕作品';

  @override
  String selectedCount(int count) {
    return '已選擇 $count 項';
  }

  @override
  String get selectAll => '全選';

  @override
  String get deselectAll => '取消全選';

  @override
  String get select => '選擇';

  @override
  String get noDownloadTasks => '暫無下載任務';

  @override
  String nFiles(int count) {
    return '$count 個檔案';
  }

  @override
  String errorWithMessage(String error) {
    return '錯誤: $error';
  }

  @override
  String get pause => '暫停';

  @override
  String get resume => '繼續';

  @override
  String get deletionConfirmTitle => '確認刪除';

  @override
  String deletionConfirmMessage(int count) {
    return '確定要刪除 $count 個已選的下載任務嗎？已下載的檔案也將被移除。';
  }

  @override
  String deletedNFiles(int count) {
    return '已刪除 $count 個檔案';
  }

  @override
  String get downloadStatusPending => '等待中';

  @override
  String get downloadStatusDownloading => '下載中';

  @override
  String get downloadStatusCompleted => '已完成';

  @override
  String get downloadStatusFailed => '失敗';

  @override
  String get downloadStatusPaused => '已暫停';

  @override
  String translationFailed(String error) {
    return '翻譯失敗: $error';
  }

  @override
  String copiedToClipboard(String label, String text) {
    return '已複製$label：$text';
  }

  @override
  String get loadingFileList => '正在載入檔案清單...';

  @override
  String loadFileListFailed(String error) {
    return '載入檔案清單失敗: $error';
  }

  @override
  String get playlistTitle => '播放清單';

  @override
  String get noAudioPlaying => '沒有正在播放的音訊';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get backward10s => '後退10秒';

  @override
  String get forward10s => '前進10秒';

  @override
  String get sleepTimer => '定時停止';

  @override
  String get repeatMode => '循環模式';

  @override
  String get repeatOff => '關閉';

  @override
  String get repeatOne => '單曲';

  @override
  String get repeatAll => '清單';

  @override
  String get addMark => '新增標記';

  @override
  String get viewDetail => '檢視詳情';

  @override
  String get volume => '音量';

  @override
  String get sleepTimerTitle => '定時器';

  @override
  String get aboutToStop => '即將停止';

  @override
  String get remainingTime => '剩餘時間';

  @override
  String get finishCurrentTrack => '完整播完後停止';

  @override
  String addMinutes(int min) {
    return '+$min分鐘';
  }

  @override
  String get cancelTimer => '取消定時';

  @override
  String get duration => '時長';

  @override
  String get specifyTime => '指定時間';

  @override
  String get selectTimerDuration => '選擇定時時長';

  @override
  String get selectStopTime => '選擇停止播放的時間';

  @override
  String get markWork => '標記作品';

  @override
  String get addToPlaylist => '新增到播放清單';

  @override
  String get remove => '移除';

  @override
  String get createPlaylist => '建立播放清單';

  @override
  String get addPlaylist => '新增播放清單';

  @override
  String get playlistName => '播放清單名稱';

  @override
  String get enterPlaylistName => '請輸入名稱';

  @override
  String get privacySetting => '隱私設定';

  @override
  String get playlistDescription => '描述（可選）';

  @override
  String get addDescription => '新增一些描述資訊';

  @override
  String get enterPlaylistNameWarning => '請輸入播放清單名稱';

  @override
  String get enterPlaylistLink => '請輸入播放清單連結';

  @override
  String get switchAccountTitle => '切換帳戶';

  @override
  String switchAccountConfirm(String username) {
    return '確定要切換到帳戶 \"$username\" 嗎？';
  }

  @override
  String switchedToAccount(String username) {
    return '已切換到帳戶: $username';
  }

  @override
  String get switchFailed => '切換失敗，請檢查帳戶資訊';

  @override
  String switchFailedWithError(String error) {
    return '切換失敗: $error';
  }

  @override
  String get noAccounts => '暫無帳戶';

  @override
  String get tapToAddAccount => '點擊右下角按鈕新增帳戶';

  @override
  String get currentAccount => '目前帳戶';

  @override
  String get switchAction => '切換';

  @override
  String get deleteAccount => '刪除帳戶';

  @override
  String deleteAccountConfirm(String username) {
    return '確定要刪除帳戶 \"$username\" 嗎？此操作無法復原。';
  }

  @override
  String get accountDeleted => '帳戶已刪除';

  @override
  String deletionFailedWithError(String error) {
    return '刪除失敗: $error';
  }

  @override
  String get subtitleLibraryPriority => '字幕庫優先順序';

  @override
  String get selectSubtitlePriority => '選擇字幕庫在自動載入中的優先順序：';

  @override
  String get subtitlePriorityHighestDesc => '優先查找字幕庫，再查找線上/下載';

  @override
  String get subtitlePriorityLowestDesc => '優先查找線上/下載，再查找字幕庫';

  @override
  String get defaultSortSettings => '預設排序設定';

  @override
  String get defaultSortUpdated => '預設排序已更新';

  @override
  String get translationSourceSettings => '翻譯源設定';

  @override
  String get selectTranslationProvider => '選擇翻譯服務提供商：';

  @override
  String get translationTargetLanguage => '目標語言';

  @override
  String get autoSaveTranslatedLyrics => '自動儲存翻譯歌詞';

  @override
  String get autoSaveTranslatedLyricsDesc => '翻譯後儲存到字幕庫；關閉時僅暫時顯示';

  @override
  String get selectTranslationTargetLanguage => '選擇目標語言：';

  @override
  String get translationLanguageFollowApp => '跟隨 App 語言';

  @override
  String get translationLanguageZhHans => '簡體中文';

  @override
  String get translationLanguageZhHant => '繁體中文';

  @override
  String get translationLanguageEnglish => '英語';

  @override
  String get translationLanguageJapanese => '日語';

  @override
  String get translationLanguageRussian => '俄語';

  @override
  String get translationLanguageCustom => '自訂';

  @override
  String get translationCustomTargetLanguage => '自訂目標語言';

  @override
  String get translationCustomLanguageHint => '語言名稱，例如 Korean';

  @override
  String translationCustomLanguageLabel(String value) {
    return '自訂: $value';
  }

  @override
  String get translationCustomTargetRequiresLlm => '需要使用 LLM 翻譯才能使用';

  @override
  String get needsConfiguration => '需要設定';

  @override
  String get llmTranslation => '大模型翻譯';

  @override
  String get goToConfigure => '前往設定';

  @override
  String get subtitlePrioritySettingSubtitle => '字幕庫優先順序';

  @override
  String get defaultSortSettingTitle => '首頁預設排序方式';

  @override
  String get translationSource => '翻譯源';

  @override
  String get llmSettings => 'LLM設定';

  @override
  String get llmSettingsSubtitle => 'API 位址、金鑰和模型';

  @override
  String get audioFormatPreference => '音訊格式偏好';

  @override
  String get audioFormatSubtitle => '調整音訊格式優先順序';

  @override
  String get preloadNextTitle => '預載下一首';

  @override
  String get preloadNextSubtitle => '當前曲目播放結束前提早快取下一首，避免切歌空檔';

  @override
  String get selectPreloadThreshold => '當前曲目剩餘時間低於此閾值時開始預載：';

  @override
  String get preloadOptionOff => '關閉';

  @override
  String preloadOptionSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get preloadOptionCustom => '自訂';

  @override
  String get preloadCustomInputTitle => '自訂預載閾值';

  @override
  String get preloadCustomInputHint => '秒數 (1-300)';

  @override
  String get preloadCustomInputRangeError => '請輸入 1 到 300 之間的數字';

  @override
  String preloadCustomValueLabel(int value) {
    return '$value 秒';
  }

  @override
  String get keepScreenAwake => '螢幕常亮';

  @override
  String get keepScreenAwakeDesc => '播放時保持螢幕常亮';

  @override
  String get audioHaptics => '音訊觸感回饋(Beta)';

  @override
  String get audioHapticsDesc => '隨已下載音訊震動，僅前台生效';

  @override
  String get audioHapticsIntensity => '強度';

  @override
  String get audioGain => '全域音訊增益';

  @override
  String get audioGainDesc => '0 dB 為原聲；正增益過高可能失真或損傷聽力';

  @override
  String get audioGainAttenuationDesc => '降低所有音訊；0 dB 保持原聲';

  @override
  String get audioGainPassthroughDesc => '音訊直通開啟時無法使用';

  @override
  String get blockingSettings => '封鎖設定';

  @override
  String get blockingSettingsSubtitle => '封鎖標籤、聲優和社團';

  @override
  String get audioPassthrough => '音訊直通(Beta)';

  @override
  String get audioPassthroughDescWindows => '使用 WASAPI 獨佔輸出（需重新啟動）';

  @override
  String get audioPassthroughDescMac => '使用 CoreAudio 獨佔輸出';

  @override
  String get audioPassthroughDisableDesc => '關閉音訊直通模式';

  @override
  String get warning => '警告';

  @override
  String get audioPassthroughWarning => '此功能未經完全測試，可能會帶來意外外放等風險。確定要開啟嗎？';

  @override
  String get exclusiveModeEnabled => '已開啟獨佔模式（重新啟動後生效）';

  @override
  String get audioPassthroughEnabled => '已開啟音訊直通模式';

  @override
  String get audioPassthroughDisabled => '已關閉音訊直通模式';

  @override
  String get tagVoteSupport => '支持';

  @override
  String get tagVoteOppose => '反對';

  @override
  String get tagVoted => '已投票';

  @override
  String get votedSupport => '已投支持票';

  @override
  String get votedOppose => '已投反對票';

  @override
  String get voteCancelled => '已取消投票';

  @override
  String voteFailed(String error) {
    return '投票失敗: $error';
  }

  @override
  String get blockThisTag => '屏蔽此標籤';

  @override
  String get copyTag => '複製標籤';

  @override
  String get addTag => '新增標籤';

  @override
  String loadTagsFailed(String error) {
    return '載入標籤失敗: $error';
  }

  @override
  String get selectAtLeastOneTag => '請至少選擇一個標籤';

  @override
  String get tagSubmitSuccess => '標籤提交成功，等待伺服器處理';

  @override
  String get bindEmailFirst => '請先前往 www.asmr.one 綁定電子郵件';

  @override
  String selectedNTags(int count) {
    return '已選擇 $count 個標籤:';
  }

  @override
  String get noMatchingTags => '沒有找到匹配的標籤';

  @override
  String get loadFailedRetry => '載入失敗，點擊重試';

  @override
  String get refresh => '重新整理';

  @override
  String get playlistPrivacyPrivate => '私有';

  @override
  String get playlistPrivacyUnlisted => '未列出';

  @override
  String get playlistPrivacyPublic => '公開';

  @override
  String get systemPlaylistMarked => '我標記的';

  @override
  String get systemPlaylistLiked => '我喜歡的';

  @override
  String totalNWorks(int count) {
    return '$count 個作品';
  }

  @override
  String pageNOfTotal(int current, int total) {
    return '第 $current / $total 頁';
  }

  @override
  String get translateTitle => '翻譯';

  @override
  String get translateDescription => '翻譯描述';

  @override
  String get translating => '翻譯中...';

  @override
  String translationFallbackNotice(String source) {
    return '翻譯失敗，已自動切換至$source';
  }

  @override
  String get tagLabel => '標籤';

  @override
  String get vaLabel => '聲優';

  @override
  String get circleLabel => '社團';

  @override
  String get releaseDate => '發售日';

  @override
  String get ratingLabel => '評分';

  @override
  String get salesLabel => '銷量';

  @override
  String get priceLabel => '價格';

  @override
  String get durationLabel => '時長';

  @override
  String get ageRatingLabel => '年齡分級';

  @override
  String get hasSubtitle => '有字幕';

  @override
  String get noSubtitle => '無字幕';

  @override
  String get description => '簡介';

  @override
  String get fileList => '檔案清單';

  @override
  String get series => '系列';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLanguageSubtitle => '切換顯示語言';

  @override
  String get languageSystem => '跟隨系統';

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
  String get themeModeDark => '深色模式';

  @override
  String get themeModeLight => '淺色模式';

  @override
  String get themeModeSystem => '跟隨系統';

  @override
  String get colorSchemeOceanBlue => '胖次藍';

  @override
  String get colorSchemeForestGreen => '草原綠';

  @override
  String get colorSchemeSunsetOrange => '今日橙';

  @override
  String get colorSchemeLavenderPurple => '基佬紫';

  @override
  String get colorSchemeSakuraPink => '嗶哩粉';

  @override
  String get colorSchemeDynamic => '動態取色';

  @override
  String get noData => '暫無資料';

  @override
  String get unknownError => '未知錯誤';

  @override
  String get networkError => '網路錯誤';

  @override
  String get timeout => '請求逾時';

  @override
  String get playAll => '播放全部';

  @override
  String get download => '下載';

  @override
  String get downloadAll => '下載全部';

  @override
  String get downloading => '下載中';

  @override
  String get downloadComplete => '下載完成';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String get startDownload => '開始下載';

  @override
  String get confirmDeleteDownload => '確定要刪除此下載任務嗎？已下載的檔案也將被移除。';

  @override
  String get deletedSuccessfully => '刪除成功';

  @override
  String get scanSubtitleLibrary => '掃描字幕庫';

  @override
  String get scanning => '掃描中...';

  @override
  String get scanComplete => '掃描完成';

  @override
  String get noSubtitleFiles => '未找到字幕檔案';

  @override
  String subtitleFilesFound(int count) {
    return '找到 $count 個字幕檔案';
  }

  @override
  String get selectDirectory => '選擇目錄';

  @override
  String get privacyModeSettings => '防社死模式設定';

  @override
  String get blurCover => '模糊封面';

  @override
  String get maskTitle => '遮擋標題';

  @override
  String get customTitle => '自訂標題';

  @override
  String get privacyModeDesc => '在系統通知列和媒體控制中隱藏播放資訊';

  @override
  String get audioFormatSettingsTitle => '音訊格式設定';

  @override
  String get preferredFormat => '偏好格式';

  @override
  String get cacheSizeLimit => '快取大小限制';

  @override
  String get llmApiUrl => 'API 位址';

  @override
  String get llmApiKey => 'API Key';

  @override
  String get llmModel => '模型';

  @override
  String get llmPrompt => '系統提示詞';

  @override
  String get llmConcurrency => '並行數';

  @override
  String get llmTestTranslation => '測試翻譯';

  @override
  String get llmTestSuccess => '測試成功';

  @override
  String get llmTestFailed => '測試失敗';

  @override
  String get subtitleTimingAdjustment => '字幕軸調整';

  @override
  String get playerLyricStyle => '播放器歌詞樣式';

  @override
  String get floatingLyricStyle => '懸浮歌詞樣式';

  @override
  String get fontSize => '字型大小';

  @override
  String get fontColor => '字型顏色';

  @override
  String get backgroundColor => '背景顏色';

  @override
  String get transparency => '透明度';

  @override
  String get windowSize => '視窗大小';

  @override
  String get playerButtonSettings => '播放器按鈕設定';

  @override
  String get showButton => '顯示按鈕';

  @override
  String get buttonOrder => '按鈕順序';

  @override
  String get workCardDisplaySettings => '作品卡片顯示設定';

  @override
  String get showTags => '顯示標籤';

  @override
  String get showVa => '顯示聲優';

  @override
  String get showRating => '顯示評分';

  @override
  String get showPrice => '顯示價格';

  @override
  String get cardSize => '卡片大小';

  @override
  String get compact => '緊湊';

  @override
  String get medium => '中等';

  @override
  String get full => '完整';

  @override
  String get workDetailDisplaySettings => '作品詳情顯示設定';

  @override
  String get infoSectionVisibility => '資訊區域可見性';

  @override
  String get imageSize => '圖片大小';

  @override
  String get showMetadata => '顯示元資料';

  @override
  String get relatedRecommendations => '相關推薦';

  @override
  String get myTabsDisplaySettings => '「我的」介面設定';

  @override
  String get showTab => '顯示標籤';

  @override
  String get tabOrder => '標籤順序';

  @override
  String get blockedItems => '封鎖項目';

  @override
  String get blockedTags => '封鎖標籤';

  @override
  String get blockedVas => '封鎖聲優';

  @override
  String get blockedCircles => '封鎖社團';

  @override
  String get unblock => '取消封鎖';

  @override
  String get noBlockedItems => '暫無封鎖項目';

  @override
  String get clearCache => '清除快取';

  @override
  String get clearCacheConfirm => '確定要清除所有快取嗎？';

  @override
  String get cacheCleared => '快取已清除';

  @override
  String get imagePreview => '圖片預覽';

  @override
  String get saveImage => '儲存圖片';

  @override
  String get imageSaved => '圖片已儲存';

  @override
  String get saveImageFailed => '儲存失敗';

  @override
  String get logout => '登出';

  @override
  String get logoutConfirm => '確定要登出嗎？';

  @override
  String get openInBrowser => '在瀏覽器中開啟';

  @override
  String get copyLink => '複製連結';

  @override
  String get linkCopied => '連結已複製';

  @override
  String get ratingDistribution => '評分分佈';

  @override
  String reviewsCount(int count) {
    return '$count 條評論';
  }

  @override
  String ratingsCount(int count) {
    return '共 $count 個評分';
  }

  @override
  String get myReviews => '我的評價';

  @override
  String get noReviews => '暫無評價';

  @override
  String get writeReview => '撰寫評價';

  @override
  String get editReview => '編輯評價';

  @override
  String get deleteReview => '刪除評價';

  @override
  String get deleteReviewConfirm => '確定要刪除此評價嗎？';

  @override
  String get reviewDeleted => '評價已刪除';

  @override
  String get reviewContent => '評價內容';

  @override
  String get enterReviewContent => '輸入評價內容...';

  @override
  String get submitReview => '提交';

  @override
  String get reviewSubmitted => '評價已提交';

  @override
  String reviewFailed(String error) {
    return '評價失敗: $error';
  }

  @override
  String get notificationPermission => '通知權限';

  @override
  String get mediaPermission => '媒體庫權限';

  @override
  String get storagePermission => '儲存空間權限';

  @override
  String get granted => '已授予';

  @override
  String get denied => '已拒絕';

  @override
  String get requestPermission => '請求';

  @override
  String get localDownloads => '本機下載';

  @override
  String get offlinePlayback => '離線播放';

  @override
  String get noDownloadedWorks => '暫無已下載作品';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get ignoreThisVersion => '忽略此版本';

  @override
  String get remindLater => '稍後提醒';

  @override
  String get updateNow => '立即更新';

  @override
  String get fetchFailed => '取得失敗';

  @override
  String operationFailedWithError(String error) {
    return '操作失敗: $error';
  }

  @override
  String get aboutSubtitle => '檢查更新、授權等';

  @override
  String get currentCacheSize => '目前快取大小';

  @override
  String cacheLimitLabelMB(int size) {
    return '上限: ${size}MB';
  }

  @override
  String get cacheUsagePercent => '使用率';

  @override
  String get autoCleanTitle => '自動清理說明';

  @override
  String get autoCleanDescription =>
      '• 當快取超過上限時，會自動執行清理\n• 刪除直到快取降低到上限的80%\n• 按最近最少使用(LRU)策略刪除';

  @override
  String get autoCleanDescriptionShort =>
      '• 當快取超過上限時，會自動執行清理\n• 刪除直到快取降低到上限的80%';

  @override
  String get confirmClear => '確認清除';

  @override
  String get confirmClearCacheMessage => '確定要清除所有快取嗎？此操作無法撤銷。';

  @override
  String clearCacheFailedWithError(String error) {
    return '清除快取失敗: $error';
  }

  @override
  String get hasNewVersion => '有新版本';

  @override
  String get themeMode => '主題模式';

  @override
  String get colorTheme => '顏色主題';

  @override
  String get themePreview => '主題預覽';

  @override
  String get themeModeSystemDesc => '自動適應系統的深色/淺色模式';

  @override
  String get themeModeLightDesc => '始終使用淺色主題';

  @override
  String get themeModeDarkDesc => '始終使用深色主題';

  @override
  String get colorSchemeOceanBlueDesc => '藍藍路，藍藍路！';

  @override
  String get colorSchemeSakuraPinkDesc => '( ゜- ゜)つロ 乾杯~';

  @override
  String get colorSchemeSunsetOrangeDesc => '軟體一定要能換主題✍🏻✍🏻✍🏻';

  @override
  String get colorSchemeLavenderPurpleDesc => '兄弟，兄弟...';

  @override
  String get colorSchemeForestGreenDesc => '草草草';

  @override
  String get colorSchemeDynamicDesc => '使用系統桌布的顏色 (Android 12+)';

  @override
  String get primaryContainer => '主色容器';

  @override
  String get secondaryContainer => '輔色容器';

  @override
  String get tertiaryContainer => '第三色容器';

  @override
  String get surfaceColor => '表面色';

  @override
  String get playerButtonSettingsSubtitle => '調整播放器按鈕順序';

  @override
  String get playerLyricStyleSubtitle => '調整迷你與全螢幕歌詞樣式';

  @override
  String get workDetailDisplaySubtitle => '選擇詳情頁顯示內容';

  @override
  String get workCardDisplaySubtitle => '選擇作品卡片顯示內容';

  @override
  String get myTabsDisplaySubtitle => '選擇「我的」頁面標籤';

  @override
  String get pageSizeSettings => '每頁顯示數量';

  @override
  String pageSizeCurrent(int size) {
    return '每頁 $size 條';
  }

  @override
  String currentSettingLabel(String value) {
    return '目前: $value';
  }

  @override
  String setToValue(String value) {
    return '已設定為: $value';
  }

  @override
  String get llmConfigRequiredMessage => '使用LLM翻譯需要設定 API Key。請先前往設定進行配置。';

  @override
  String get autoSwitchedToLlm => '已自動切換至: 大型語言模型翻譯';

  @override
  String get translationDescGoogle => '需連接 Google 服務';

  @override
  String get translationDescYoudao => '使用目前網路';

  @override
  String get translationDescMicrosoft => '使用目前網路';

  @override
  String get translationDescLlm => '需設定 OpenAI 相容 API';

  @override
  String get audioPassthroughDescAndroid => '將 AC3/DTS 原始音訊交給外部解碼器';

  @override
  String get permissionExplanation => '權限說明';

  @override
  String get backgroundRunningPermission => '背景執行權限';

  @override
  String get notificationPermissionDesc => '用於顯示媒體播放通知欄，讓您可以在鎖定畫面和通知欄中控制播放。';

  @override
  String get backgroundRunningPermissionDesc =>
      '讓應用免受電池最佳化限制，確保音訊在背景持續播放不被系統終止。';

  @override
  String get notificationGrantedStatus => '已授權 - 可以顯示播放通知和控制器';

  @override
  String get notificationDeniedStatus => '未授權 - 點擊申請權限';

  @override
  String get backgroundGrantedStatus => '已授權 - 應用可以在背景持續執行';

  @override
  String get backgroundDeniedStatus => '未授權 - 點擊申請權限';

  @override
  String get notificationPermissionGranted => '通知權限已授予';

  @override
  String get notificationPermissionDenied => '通知權限被拒絕';

  @override
  String requestNotificationFailed(String error) {
    return '請求通知權限失敗: $error';
  }

  @override
  String get backgroundPermissionGranted => '背景執行權限已授予';

  @override
  String get backgroundPermissionDenied => '背景執行權限被拒絕';

  @override
  String requestBackgroundFailed(String error) {
    return '請求背景執行權限失敗: $error';
  }

  @override
  String permissionRequired(String permission) {
    return '需要$permission';
  }

  @override
  String permissionPermanentlyDenied(String permission) {
    return '$permission已被永久拒絕，請在系統設定中手動開啟。';
  }

  @override
  String get openSettings => '開啟設定';

  @override
  String get permissionsAndroidOnly => '權限管理僅在安卓平台可用';

  @override
  String get permissionsNotNeeded => '其他平台不需要手動管理這些權限';

  @override
  String get refreshPermissionStatus => '重新整理權限狀態';

  @override
  String deleteFileConfirm(String fileName) {
    return '確定要刪除 \"$fileName\" 嗎？';
  }

  @override
  String deleteSelectedFilesConfirm(int count) {
    return '確定要刪除選中的 $count 個檔案嗎？';
  }

  @override
  String get deleted => '已刪除';

  @override
  String cannotOpenFolder(String path) {
    return '無法開啟資料夾: $path';
  }

  @override
  String openFolderFailed(String error) {
    return '開啟資料夾失敗: $error';
  }

  @override
  String get reloadingFromDisk => '正在從硬碟重新載入...';

  @override
  String get refreshComplete => '重新整理完成';

  @override
  String refreshFailed(String error) {
    return '重新整理失敗: $error';
  }

  @override
  String deleteSelectedWorksConfirm(int count) {
    return '確定要刪除選中的 $count 個作品嗎？';
  }

  @override
  String partialDeleteFailed(String error) {
    return '部分刪除失敗: $error';
  }

  @override
  String deletedNOfTotal(int success, int total) {
    return '已刪除 $success/$total 個任務';
  }

  @override
  String deleteFailedWithError(String error) {
    return '刪除失敗: $error';
  }

  @override
  String get noWorkMetadataForOffline => '該下載任務沒有儲存作品詳情，無法離線查看';

  @override
  String openWorkDetailFailed(String error) {
    return '開啟作品詳情失敗: $error';
  }

  @override
  String get noLocalDownloads => '暫無本地下載';

  @override
  String get exitSelection => '退出選擇';

  @override
  String get reload => '重新載入';

  @override
  String get openFolder => '開啟資料夾';

  @override
  String get playlistLink => '播放清單連結';

  @override
  String get playlistLinkHint =>
      '貼上播放清單連結，如:\nhttps://www.asmr.one/playlist?id=...';

  @override
  String get unrecognizedPlaylistLink => '無法辨識的播放清單連結或ID';

  @override
  String get addingPlaylist => '正在新增播放清單...';

  @override
  String get playlistAddedSuccess => '播放清單新增成功';

  @override
  String get addFailed => '新增失敗';

  @override
  String get playlistNotFound => '播放清單不存在或已被刪除';

  @override
  String get noPermissionToAccessPlaylist => '沒有權限存取此播放清單';

  @override
  String get networkConnectionFailed => '網路連線失敗，請檢查網路';

  @override
  String addFailedWithError(String error) {
    return '新增失敗: $error';
  }

  @override
  String get creatingPlaylist => '正在建立播放清單...';

  @override
  String playlistCreatedSuccess(String name) {
    return '播放清單 \"$name\" 建立成功';
  }

  @override
  String createFailedWithError(String error) {
    return '建立失敗: $error';
  }

  @override
  String get noPlaylists => '暫無播放清單';

  @override
  String get noPlaylistsDescription => '您還沒有建立或收藏任何播放清單';

  @override
  String get myPlaylists => '我的播放清單';

  @override
  String totalNItems(int count) {
    return '共 $count 條';
  }

  @override
  String get systemPlaylistCannotDelete => '系統播放清單不能刪除';

  @override
  String get deletePlaylist => '刪除播放清單';

  @override
  String get unfavoritePlaylist => '取消收藏播放清單';

  @override
  String get deletePlaylistConfirm => '刪除後不可恢復，收藏本清單的人將無法再存取。確定要刪除嗎？';

  @override
  String unfavoritePlaylistConfirm(String name) {
    return '確定要取消收藏「$name」嗎？';
  }

  @override
  String get unfavorite => '取消收藏';

  @override
  String get deleting => '正在刪除...';

  @override
  String get deleteSuccess => '刪除成功';

  @override
  String get onlyOwnerCanEdit => '只有播放清單作者才能編輯';

  @override
  String get editPlaylist => '編輯播放清單';

  @override
  String get playlistNameRequired => '播放清單名稱不能為空';

  @override
  String get privacyDescPrivate => '只有您可以觀看';

  @override
  String get privacyDescUnlisted => '知道連結的人才能觀看';

  @override
  String get privacyDescPublic => '任何人都可以觀看';

  @override
  String get addWorks => '新增作品';

  @override
  String get addWorksInputHint => '輸入包含作品號的文字，自動辨識RJ號';

  @override
  String get workId => '作品號';

  @override
  String get workIdHint => '例如：RJ123456\nrj233333';

  @override
  String detectedNWorkIds(int count) {
    return '辨識到 $count 個作品號';
  }

  @override
  String addNWorks(int count) {
    return '新增 $count 個';
  }

  @override
  String get noValidWorkIds => '未找到有效的作品號（RJ開頭）';

  @override
  String addingNWorks(int count) {
    return '正在新增 $count 個作品...';
  }

  @override
  String addedNWorksSuccess(int count) {
    return '成功新增 $count 個作品';
  }

  @override
  String get removeWork => '移除作品';

  @override
  String removeWorkConfirm(String title) {
    return '確定要從播放清單中移除「$title」嗎？';
  }

  @override
  String get removeSuccess => '移除成功';

  @override
  String removeFailedWithError(String error) {
    return '移除失敗: $error';
  }

  @override
  String get saving => '正在儲存...';

  @override
  String get saveSuccess => '儲存成功';

  @override
  String saveFailedWithError(String error) {
    return '儲存失敗: $error';
  }

  @override
  String get noWorks => '暫無作品';

  @override
  String get playlistNoWorksDescription => '此播放清單還沒有新增任何作品';

  @override
  String get lastUpdated => '最近更新';

  @override
  String get createdTime => '建立時間';

  @override
  String nWorksCount(int count) {
    return '$count 個作品';
  }

  @override
  String nPlaysCount(int count) {
    return '$count 播放';
  }

  @override
  String get removeFromPlaylist => '從播放清單移除';

  @override
  String get checkNetworkOrRetry => '請檢查網路連線或稍後重試';

  @override
  String get reachedEnd => '已經到底了~';

  @override
  String excludedNWorks(int count) {
    return '已排除 $count 個作品';
  }

  @override
  String pageExcludedNWorks(int count) {
    return '本頁已排除 $count 個作品';
  }

  @override
  String get noSubtitlesAvailable => '暫無字幕';

  @override
  String get translateLyrics => '翻譯歌詞';

  @override
  String get fullscreenLyrics => '全螢幕歌詞';

  @override
  String get showOriginalLyrics => '顯示原文';

  @override
  String get showTranslatedLyrics => '顯示翻譯';

  @override
  String get translatingLyrics => '翻譯中...';

  @override
  String get lyricTranslationFailed => '歌詞翻譯失敗';

  @override
  String get lyricTranslationConfirmMessage =>
      '翻譯目前播放的歌詞，完成後立即顯示。開啟自動儲存時會以同名 .lrc 覆蓋儲存到字幕庫；翻譯中切歌會放棄本次結果。';

  @override
  String get unlock => '解鎖';

  @override
  String get backToCover => '返回封面';

  @override
  String get lyricHintTapCover => '點擊封面或標題可以進入字幕介面';

  @override
  String get floatingSubtitle => '懸浮字幕';

  @override
  String get appendMode => '追加模式';

  @override
  String get appendModeStatusOn => '追加模式：開啟';

  @override
  String get appendModeStatusOff => '追加模式：關閉';

  @override
  String get playlistEmpty => '播放列表為空';

  @override
  String get appendModeEnabled => '追加模式已開啟';

  @override
  String get appendModeHint => '之後點擊音訊會追加到目前播放列表尾部，而不是替換整個列表。\n不會重複新增同一音軌。';

  @override
  String get gotIt => '知道了';

  @override
  String nMinutes(int count) {
    return '$count分鐘';
  }

  @override
  String nHours(int count) {
    return '$count小時';
  }

  @override
  String get titleLabel => '標題';

  @override
  String get rjNumberLabel => 'RJ號';

  @override
  String get workIdLabel => '作品編號';

  @override
  String get tapToViewRatingDetail => '點擊查看評分詳情';

  @override
  String priceInYen(int price) {
    return '$price 日元';
  }

  @override
  String soldCount(String count) {
    return '售出：$count';
  }

  @override
  String get circleAndVaSection => '社團 | 聲優';

  @override
  String get subtitleBadge => '字幕';

  @override
  String get otherEditions => '其他版本';

  @override
  String tenThousandSuffix(String count) {
    return '$count萬';
  }

  @override
  String get packingWork => '正在打包作品...';

  @override
  String get workDirectoryNotExist => '作品目錄不存在';

  @override
  String get packingFailed => '打包失敗';

  @override
  String exportSuccess(String path) {
    return '匯出成功：$path';
  }

  @override
  String exportFailed(String error) {
    return '匯出失敗: $error';
  }

  @override
  String get exportAsZip => '匯出為ZIP';

  @override
  String get offlineBadge => '離線';

  @override
  String loadFilesFailed(String error) {
    return '載入檔案失敗: $error';
  }

  @override
  String get unknown => '未知';

  @override
  String get noPlayableAudioFiles => '沒有找到可播放的音訊檔案';

  @override
  String cannotFindAudioFile(String title) {
    return '無法找到音訊檔案: $title';
  }

  @override
  String nowPlayingNOfTotal(String title, int current, int total) {
    return '正在播放: $title ($current/$total)';
  }

  @override
  String get noAudioCannotLoadSubtitle => '目前沒有播放的音訊，無法載入字幕';

  @override
  String get loadSubtitle => '載入字幕';

  @override
  String get loadSubtitleConfirm => '確定要將以下檔案載入為目前音訊的字幕嗎？';

  @override
  String get subtitleFile => '字幕檔案';

  @override
  String get currentAudio => '目前音訊';

  @override
  String get subtitleAutoRestoreNote => '切换到其他音訊時，字幕將自動恢復為預設配對方式';

  @override
  String get confirmLoad => '確定載入';

  @override
  String get loadingSubtitle => '正在載入字幕...';

  @override
  String subtitleLoadSuccess(String title) {
    return '字幕載入成功：$title';
  }

  @override
  String subtitleLoadFailed(String error) {
    return '字幕載入失敗：$error';
  }

  @override
  String get cannotPreviewImageMissingInfo => '無法預覽圖片：缺少必要資訊';

  @override
  String get cannotFindImageFile => '無法找到圖片檔案';

  @override
  String get cannotPreviewTextMissingInfo => '無法預覽文字：缺少必要資訊';

  @override
  String get cannotPreviewPdfMissingInfo => '無法預覽PDF：缺少必要資訊';

  @override
  String get cannotPlayVideoMissingId => '無法播放影片：缺少檔案標識';

  @override
  String get cannotPlayVideoMissingParams => '無法播放影片：缺少必要參數';

  @override
  String get cannotPlayDirectly => '無法直接播放';

  @override
  String get noVideoPlayerFound => '系統無法找到支援的影片播放器。';

  @override
  String get youCan => '您可以：';

  @override
  String get copyLinkToExternalPlayer => '1. 複製連結到外部播放器（如MX Player、VLC）';

  @override
  String get openInBrowserOption => '2. 在瀏覽器中開啟';

  @override
  String playVideoError(String error) {
    return '播放影片時出錯: $error';
  }

  @override
  String get noFiles => '沒有檔案';

  @override
  String get resourceFiles => '資源檔案';

  @override
  String resourceFilesTranslated(int count) {
    return '資源檔案 (已翻譯 $count 項)';
  }

  @override
  String get translationOriginal => '原';

  @override
  String get translationTranslated => '譯';

  @override
  String copiedName(String title) {
    return '已複製名稱: $title';
  }

  @override
  String translationComplete(int count) {
    return '翻譯完成：$count 個項目';
  }

  @override
  String get noContentToTranslate => '沒有需要翻譯的內容';

  @override
  String get preparingTranslation => '準備翻譯...';

  @override
  String translatingProgress(int current, int total) {
    return '翻譯中 $current/$total';
  }

  @override
  String nItems(int count) {
    return '$count 項';
  }

  @override
  String get loadAsSubtitle => '載入為字幕';

  @override
  String get preview => '預覽';

  @override
  String openVideoFileError(String error) {
    return '開啟影片檔案時出錯: $error';
  }

  @override
  String cannotOpenVideoFile(String message) {
    return '無法開啟影片檔案: $message';
  }

  @override
  String get noFileTreeInfo => '沒有檔案樹資訊';

  @override
  String get workFolderNotExist => '作品資料夾不存在';

  @override
  String get cannotPlayAudioMissingId => '無法播放音訊：缺少檔案標識';

  @override
  String get audioFileNotExist => '音訊檔案不存在';

  @override
  String get noPreviewableImages => '沒有找到可預覽的圖片';

  @override
  String get cannotPreviewTextMissingId => '無法預覽文字：缺少檔案標識';

  @override
  String get cannotFindFilePath => '無法找到檔案路徑';

  @override
  String fileNotExist(String title) {
    return '檔案不存在：$title';
  }

  @override
  String get cannotPreviewPdfMissingId => '無法預覽PDF：缺少檔案標識';

  @override
  String get videoFileNotExist => '影片檔案不存在';

  @override
  String get cannotOpenVideo => '無法開啟影片';

  @override
  String errorInfo(String message) {
    return '錯誤資訊: $message';
  }

  @override
  String get installVideoPlayerApp => '請安裝影片播放器應用程式（如 VLC、MX Player 等）';

  @override
  String get filePathLabel => '檔案路徑：';

  @override
  String get noDownloadedFiles => '沒有已下載的檔案';

  @override
  String get offlineFiles => '離線檔案';

  @override
  String unsupportedFileType(String title) {
    return '暫不支援開啟此類型檔案: $title';
  }

  @override
  String get deleteFilePrompt => '確定要刪除這個檔案嗎？';

  @override
  String deletedItem(String title) {
    return '已刪除: $title';
  }

  @override
  String get selectAtLeastOneFile => '請至少選擇一個檔案';

  @override
  String addedNFilesToDownloadQueue(int count) {
    return '已新增 $count 個檔案到下載佇列';
  }

  @override
  String downloadedAndSelected(int downloaded, int selected) {
    return '已下載 $downloaded · 已選擇 $selected';
  }

  @override
  String downloadN(int count) {
    return '下載 ($count)';
  }

  @override
  String get checkingDownloadedFiles => '正在檢查已下載檔案...';

  @override
  String get noDownloadableFiles => '沒有可下載的檔案';

  @override
  String get selectFilesToDownload => '選擇下載檔案';

  @override
  String downloadedNCount(int count) {
    return '已下載 $count 個';
  }

  @override
  String selectedNCount(int count) {
    return '已選擇 $count 個';
  }

  @override
  String get pleaseEnterServerAddress => '請先輸入伺服器位址';

  @override
  String get pleaseEnterUsername => '請輸入使用者名稱';

  @override
  String get pleaseEnterPassword => '請輸入密碼';

  @override
  String get notTestedYet => '尚未測試';

  @override
  String latencyResultDetail(String latency, String status) {
    return '延遲 $latency ($status)';
  }

  @override
  String connectionFailedWithDetail(String error) {
    return '連線失敗: $error';
  }

  @override
  String get noAccountTapToRegister => '沒有帳號？點擊註冊';

  @override
  String get haveAccountTapToLogin => '已有帳號？點擊登入';

  @override
  String get cannotDeleteActiveAccount => '無法刪除目前使用的帳戶';

  @override
  String get selectAccount => '選擇帳戶';

  @override
  String get noSavedAccounts => '沒有儲存的帳戶';

  @override
  String get addAccountToGetStarted => '請新增一個帳戶開始使用';

  @override
  String get unknownHost => '未知主機';

  @override
  String lastUsedTime(String time) {
    return '最後使用: $time';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小時前';
  }

  @override
  String minutesAgo(int count) {
    return '$count分鐘前';
  }

  @override
  String get justNow => '剛剛';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String deleteSelectedConfirm(int count) {
    return '確定要刪除選中的 $count 項嗎？';
  }

  @override
  String deletedNOfTotalItems(int success, int total) {
    return '已刪除 $success/$total 項';
  }

  @override
  String get importingSubtitleFile => '正在匯入字幕檔案...';

  @override
  String get preparingImport => '正在準備匯入...';

  @override
  String get preparingExtract => '正在準備解壓...';

  @override
  String get importSubtitleFile => '匯入字幕檔案';

  @override
  String get supportedSubtitleFormats => '支援 .srt, .vtt, .lrc 等字幕格式';

  @override
  String get importFolder => '匯入資料夾';

  @override
  String get importFolderDesc => '保留資料夾結構，僅匯入字幕檔案';

  @override
  String get importArchive => '匯入壓縮檔';

  @override
  String get importArchiveDesc => '支援無密碼 ZIP 壓縮檔\n如需批量匯入，將它們壓縮為一個壓縮檔再匯入';

  @override
  String get subtitleLibraryGuide => '字幕庫使用說明';

  @override
  String get subtitleLibraryFunction => '字幕庫功能';

  @override
  String get subtitleLibraryFunctionDesc => '用於存放主動匯入或儲存的字幕檔案，並在播放音訊時支援自動/手動載入';

  @override
  String get subtitleAutoLoad => '字幕自動載入';

  @override
  String get subtitleAutoLoadDesc => '播放音訊時，系統會自動在字幕庫中查找配對的字幕檔案：';

  @override
  String get smartCategoryAndMark => '智慧分類與標記';

  @override
  String get open => '開啟';

  @override
  String get moveTo => '移動到';

  @override
  String get rename => '重新命名';

  @override
  String get newName => '新名稱';

  @override
  String get renameSuccess => '重新命名成功';

  @override
  String get renameFailed => '重新命名失敗';

  @override
  String deleteItemConfirm(String title) {
    return '確定要刪除 \"$title\" 嗎？';
  }

  @override
  String get deleteFolderContentsWarning => '此操作將刪除資料夾內的所有內容。';

  @override
  String get deleteFailed => '刪除失敗';

  @override
  String subtitleLoaded(String title) {
    return '字幕已載入：$title';
  }

  @override
  String get moveSuccess => '移動成功';

  @override
  String get moveFailed => '移動失敗';

  @override
  String previewFailed(String error) {
    return '預覽失敗: $error';
  }

  @override
  String openFailed(String error) {
    return '開啟失敗: $error';
  }

  @override
  String get back => '返回';

  @override
  String get subtitleLibraryEmpty => '字幕庫為空';

  @override
  String get tapToImportSubtitle => '點擊右下角 + 按鈕匯入字幕';

  @override
  String get importSubtitle => '匯入字幕';

  @override
  String get sampleSubtitleContent => '♪ 示例字幕內容 ♪';

  @override
  String get presetStyles => '預設樣式';

  @override
  String get backgroundOpacity => '背景不透明度';

  @override
  String get colorSettings => '顏色設定';

  @override
  String get shapeSettings => '形狀設定';

  @override
  String get cornerRadius => '圓角半徑';

  @override
  String get horizontalPadding => '水平內邊距';

  @override
  String get verticalPadding => '垂直內邊距';

  @override
  String get resetStyle => '重設樣式';

  @override
  String get resetStyleConfirm => '確定要恢復預設樣式嗎？';

  @override
  String get restoreDefaultStyle => '恢復預設樣式';

  @override
  String get reset => '重設';

  @override
  String noBlockedItemsOfType(String type) {
    return '沒有封鎖的$type';
  }

  @override
  String unblockedItem(String item) {
    return '已移除封鎖: $item';
  }

  @override
  String addBlockedItem(String type) {
    return '新增封鎖$type';
  }

  @override
  String blockedItemName(String type) {
    return '$type名稱';
  }

  @override
  String enterBlockedItemHint(String type) {
    return '請輸入要封鎖的$type';
  }

  @override
  String blockedItemAdded(String item) {
    return '已新增封鎖: $item';
  }

  @override
  String workCountLabel(int count) {
    return '作品數: $count';
  }

  @override
  String get miniPlayer => '迷你播放器';

  @override
  String get lineHeight => '行高';

  @override
  String get portraitPlayerBelowCover => '直屏播放器 (封面下方)';

  @override
  String get fullscreenSubtitleMode => '全螢幕字幕 (直屏/橫屏)';

  @override
  String get activeSubtitleFontSize => '目前字幕大小';

  @override
  String get inactiveSubtitleFontSize => '其他字幕大小';

  @override
  String get restoreDefaultSettings => '恢復預設設定';

  @override
  String get confirmRestoreDefaultSettings => '確定要恢復預設設定嗎？';

  @override
  String get guideInPrefix => '在';

  @override
  String get guideParsedFolder => '<已解析>';

  @override
  String get guideFindWorkDesc => '資料夾下查找對應作品\n支援資料夾格式：RJ123456';

  @override
  String get guideSavedFolder => '<已儲存>';

  @override
  String get guideFindSubtitleDesc => '資料夾下查找單個字幕檔案';

  @override
  String get guideMatchRule => '匹配規則：字幕檔名與音訊檔名相同（去除或保留音訊副檔名均可）';

  @override
  String get guideRecognizedWorkPrefix => '識別到的作品會被新增綠色';

  @override
  String get guideTagSuffix => '標籤，音訊檔案圖示也會增加 ';

  @override
  String get guideSubtitleMatchSuffix => ' 標記，表示有字幕庫匹配';

  @override
  String get guideAutoRecognizeRJ => '匯入時自動識別 RJ 格式，歸類到<已解析>';

  @override
  String get guideAutoAddRJPrefix => '純數字資料夾自動新增 RJ 前綴（如 123456 → RJ123456）';

  @override
  String get unknownFile => '未知檔案';

  @override
  String deleteWithCount(int count) {
    return '刪除 ($count)';
  }

  @override
  String get searchSubtitles => '搜尋字幕...';

  @override
  String nFilesWithSize(int count, String size) {
    return '$count 個檔案 • $size';
  }

  @override
  String get rootDirectory => '根目錄';

  @override
  String get goToParent => '返回上級';

  @override
  String moveToTarget(String name) {
    return '移動到: $name';
  }

  @override
  String get noSubfoldersHere => '此目錄下沒有子資料夾';

  @override
  String addedToPlaylist(String name) {
    return '已新增到播放清單「$name」';
  }

  @override
  String removedFromPlaylist(String name) {
    return '已從播放清單「$name」中移除';
  }

  @override
  String get alreadyFavorited => '已收藏';

  @override
  String loadImageFailedWithError(String error) {
    return '載入圖片失敗\n$error';
  }

  @override
  String get noImageAvailable => '沒有可用的圖片';

  @override
  String get storagePermissionRequiredForImage => '需要儲存權限才能儲存圖片';

  @override
  String get savedToGallery => '已儲存到相簿';

  @override
  String get saveCoverImage => '儲存封面圖片';

  @override
  String savedToPath(String path) {
    return '已儲存到: $path';
  }

  @override
  String get doubleTapToZoom => '雙擊放大 · 雙指縮放';

  @override
  String getStatusFailed(String error) {
    return '取得狀態失敗: $error';
  }

  @override
  String get deleteRecord => '刪除記錄';

  @override
  String deletePlayRecordConfirm(String title) {
    return '確定要刪除 \"$title\" 的播放記錄嗎？';
  }

  @override
  String get notPlayedYet => '尚未播放';

  @override
  String playbackFailed(String error) {
    return '播放失敗: $error';
  }

  @override
  String get storagePermissionRequired => '需要儲存權限';

  @override
  String get storagePermissionForGalleryDesc => '儲存圖片需要存取相簿的權限。請在設定中授予權限。';

  @override
  String get goToSettings => '前往設定';

  @override
  String get imageSavedToGallery => '圖片已儲存到相簿';

  @override
  String imageSavedToPath(String path) {
    return '圖片已儲存到: $path';
  }

  @override
  String get pullDownForNextPage => '繼續下拉跳轉下一頁';

  @override
  String get releaseForNextPage => '釋放跳轉下一頁';

  @override
  String get jumpTo => '跳轉';

  @override
  String get goToPageTitle => '跳轉到指定頁';

  @override
  String pageNumberRange(int max) {
    return '頁碼 (1-$max)';
  }

  @override
  String get enterPageNumber => '請輸入頁碼';

  @override
  String enterValidPageNumber(int max) {
    return '請輸入有效頁碼 (1-$max)';
  }

  @override
  String get previousPage => '上一頁';

  @override
  String get nextPage => '下一頁';

  @override
  String get localPdfNotExist => '本地PDF檔案不存在';

  @override
  String get cannotOpenPdf => '無法開啟PDF檔案';

  @override
  String loadPdfFailed(String error) {
    return '載入PDF失敗: $error';
  }

  @override
  String pdfPageOfTotal(int current, int total) {
    return '第 $current 頁 / 共 $total 頁';
  }

  @override
  String get loadingPdf => '正在載入PDF...';

  @override
  String get pdfPathInvalid => 'PDF檔案路徑無效';

  @override
  String get desktopPdfPreviewNotSupported => '桌面端暫不支援直接預覽 PDF';

  @override
  String get openWithSystemApp => '使用系統預設應用開啟';

  @override
  String renderPdfFailed(String error) {
    return '渲染PDF失敗: $error';
  }

  @override
  String get ratingDetails => '評分詳情';

  @override
  String get selectSaveDirectory => '選擇儲存目錄';

  @override
  String get noSubtitleContentToSave => '沒有可儲存的字幕內容';

  @override
  String get savedToSubtitleLibrary => '已儲存到字幕庫';

  @override
  String get translatedLyricsNotSaved => '翻譯已完成，僅在目前播放中顯示';

  @override
  String get saveToLocal => '儲存到本地';

  @override
  String get selectDirectoryToSaveFile => '選擇目錄儲存檔案';

  @override
  String get saveToSubtitleLibrary => '儲存到字幕庫';

  @override
  String get saveToSubtitleLibraryDesc => '儲存到字幕庫的\"已儲存\"目錄';

  @override
  String get saveToFile => '儲存到檔案';

  @override
  String get noContentToSave => '沒有可儲存的內容';

  @override
  String fileSavedToPath(String path) {
    return '檔案已儲存到：$path';
  }

  @override
  String get localFileNotExist => '本地檔案不存在，請嘗試重新載入';

  @override
  String loadTextFailed(String error) {
    return '載入文字失敗: $error';
  }

  @override
  String get previewMode => '預覽模式';

  @override
  String get editMode => '編輯模式';

  @override
  String get showOriginal => '顯示原文';

  @override
  String get translateContent => '翻譯內容';

  @override
  String get editTextContentHint => '編輯文字內容...';

  @override
  String get markButton => '標記';

  @override
  String get bookmarkRemoved => '已移除標記';

  @override
  String setProgressAndRating(String progress, int rating) {
    return '已設定為：$progress，評分：$rating 星';
  }

  @override
  String setProgressTo(String progress) {
    return '已設定為：$progress';
  }

  @override
  String ratingSetTo(int rating) {
    return '評分已設定為：$rating 星';
  }

  @override
  String get updated => '已更新';

  @override
  String addTagFailed(String error) {
    return '新增標籤失敗: $error';
  }

  @override
  String addWithCount(int count) {
    return '新增 ($count)';
  }

  @override
  String get undo => '撤銷';

  @override
  String nStars(int count) {
    return '$count 星';
  }

  @override
  String get voteRemoved => '已取消投票';

  @override
  String get votedUp => '已投支持票';

  @override
  String get votedDown => '已投反對票';

  @override
  String voteFailedWithError(String error) {
    return '投票失敗: $error';
  }

  @override
  String get voteFor => '支持';

  @override
  String get voteAgainst => '反對';

  @override
  String get voted => '已投票';

  @override
  String tagBlockedWithName(String name) {
    return '已屏蔽標籤: $name';
  }

  @override
  String get subtitleParseFailedUnsupportedFormat => '解析失敗，格式不支援';

  @override
  String get lyricPresetDynamic => '動態';

  @override
  String get lyricPresetClassic => '經典';

  @override
  String get lyricPresetModern => '現代';

  @override
  String get lyricPresetMinimal => '極簡';

  @override
  String get lyricPresetVibrant => '鮮豔';

  @override
  String get lyricPresetElegant => '優雅';

  @override
  String get lyricPresetDynamicDesc => '跟隨系統主題，自動取色';

  @override
  String get lyricPresetClassicDesc => '黑底白字，經典耐看';

  @override
  String get lyricPresetModernDesc => '漸變背景，時尚現代';

  @override
  String get lyricPresetMinimalDesc => '輕透明，簡約優雅';

  @override
  String get lyricPresetVibrantDesc => '色彩鮮明，活力四射';

  @override
  String get lyricPresetElegantDesc => '深藍底，高雅氣質';

  @override
  String get floatingLyricLoading => '♪ 載入字幕中 ♪';

  @override
  String get subtitleFileNotExist => '檔案不存在';

  @override
  String get subtitleMissingInfo => '缺少必要資訊';

  @override
  String get privacyDefaultTitle => '正在播放音訊';

  @override
  String get offlineModeStartup => '網路連線失敗，以離線模式啟動';

  @override
  String get playlistInfoNotLoaded => '播放清單資訊未載入';

  @override
  String get encodingUnrecognized => '檔案編碼無法識別，無法正確顯示內容';

  @override
  String editPlaylistFailed(String error) {
    return '編輯播放清單失敗: $error';
  }

  @override
  String unsupportedFileTypeWithTitle(String title) {
    return '暫不支援開啟此類型檔案: $title';
  }

  @override
  String get settingsSaved => '設定已儲存';

  @override
  String get restoredToDefault => '已恢復預設設定';

  @override
  String get restoreDefault => '恢復預設';

  @override
  String get saveSettings => '儲存設定';

  @override
  String get addAtLeastOneSearchCondition => '請至少新增一個搜尋條件';

  @override
  String get privacyModeSettingsTitle => '防社死設定';

  @override
  String get whatIsPrivacyMode => '什麼是防社死模式？';

  @override
  String get privacyModeDescription => '啟用後，在系統通知欄、鎖屏等位置顯示的播放資訊將被模糊處理，保護您的隱私。';

  @override
  String get enablePrivacyMode => '啟用防社死模式';

  @override
  String get privacyModeEnabledSubtitle => '已啟用 - 播放資訊將被隱藏';

  @override
  String get privacyModeDisabledSubtitle => '未啟用 - 正常顯示播放資訊';

  @override
  String get blurOptions => '模糊處理選項';

  @override
  String get blurNotificationCover => '模糊通知封面';

  @override
  String get blurNotificationCoverSubtitle => '對系統通知、鎖屏或控制中心中的封面應用模糊';

  @override
  String get blurInAppCover => '模糊應用內封面';

  @override
  String get blurInAppCoverSubtitle => '在播放器、列表等介面中模糊封面圖片';

  @override
  String get replaceTitle => '替換標題';

  @override
  String get replaceTitleSubtitle => '使用自訂標題替換真實標題';

  @override
  String get replaceTitleContent => '替換標題內容';

  @override
  String get setReplaceTitle => '設定替換標題';

  @override
  String get enterDisplayTitle => '輸入要顯示的標題';

  @override
  String get replaceTitleSaved => '替換標題已儲存';

  @override
  String get effectExample => '效果舉例';

  @override
  String get downloadPathSettings => '下載路徑設定';

  @override
  String loadPathFailedWithError(String error) {
    return '載入路徑失敗: $error';
  }

  @override
  String get platformNotSupportCustomPath => '目前平台不支援自訂下載路徑';

  @override
  String activeDownloadsWarning(int count) {
    return '有 $count 個下載任務正在進行中，請先取消或完成下載後再切換路徑';
  }

  @override
  String setPathFailedWithError(String error) {
    return '設定路徑失敗: $error';
  }

  @override
  String get confirmMigrateFiles => '確認遷移下載檔案';

  @override
  String get migrateFilesToNewDir => '將把現有下載檔案遷移到新目錄：';

  @override
  String get migrationMayTakeTime => '此操作可能需要一些時間，具體取決於檔案數量和大小。';

  @override
  String get confirmMigrate => '確認遷移';

  @override
  String get restoreDefaultPath => '恢復預設路徑';

  @override
  String get restoreDefaultPathConfirm => '將下載路徑恢復為預設位置，並遷移所有檔案。\n\n是否繼續？';

  @override
  String get defaultPathRestored => '已恢復預設路徑';

  @override
  String resetPathFailedWithError(String error) {
    return '恢復預設路徑失敗: $error';
  }

  @override
  String get migratingFiles => '正在遷移檔案...';

  @override
  String get doNotCloseApp => '請勿關閉應用';

  @override
  String get currentDownloadPath => '目前下載路徑';

  @override
  String get customPath => '自訂路徑';

  @override
  String get defaultPath => '預設路徑';

  @override
  String get changeCustomPath => '更改自訂路徑';

  @override
  String get setCustomPath => '設定自訂路徑';

  @override
  String get usageInstructions => '使用說明';

  @override
  String get downloadPathUsageDesc =>
      '• 自訂路徑後，所有現有檔案將自動遷移到新位置\n• 遷移過程中請勿關閉應用\n• 建議選擇空間充足的目錄\n• 恢復預設路徑時，檔案也會自動遷移回去';

  @override
  String get llmTranslationSettings => 'LLM翻譯設定';

  @override
  String get apiEndpointUrl => 'API 介面地址';

  @override
  String get openaiCompatibleEndpoint => 'OpenAI 相容介面地址';

  @override
  String get pleaseEnterApiUrl => '請輸入 API 介面地址';

  @override
  String get pleaseEnterValidUrl => '請輸入有效的 URL';

  @override
  String get pleaseEnterApiKey => '請輸入 API Key';

  @override
  String get modelName => '模型名稱';

  @override
  String get pleaseEnterModelName => '請輸入模型名稱';

  @override
  String get concurrencyCount => '並行數';

  @override
  String get concurrencyDescription => '同時進行的翻譯請求數量，建議 3-5';

  @override
  String get promptSection => '提示詞 (Prompt)';

  @override
  String get promptDescription =>
      '由於系統採用分塊翻譯機制，請確保 Prompt 指令明確，要求只輸出翻譯結果，不包含任何解釋。';

  @override
  String get enterSystemPrompt => '輸入系統提示詞...';

  @override
  String get pleaseEnterPrompt => '請輸入提示詞';

  @override
  String get restoreDefaultPrompt => '恢復預設提示詞';

  @override
  String get confirmRestoreButtonOrder => '確定要恢復預設的按鈕順序嗎？';

  @override
  String get buttonDisplayRules => '按鈕顯示規則';

  @override
  String buttonDisplayRulesDesc(int maxVisible) {
    return '• 前 $maxVisible 個按鈕會顯示在播放器底部\n• 其餘按鈕會收納在「更多」選單中';
  }

  @override
  String get shownInPlayer => '顯示在播放器';

  @override
  String get shownInMoreMenu => '顯示在更多選單';

  @override
  String get audioFormatPriority => '音訊格式優先級';

  @override
  String get confirmRestoreAudioFormat => '確定要恢復預設的音訊格式優先級嗎？';

  @override
  String get priorityDescription => '優先級說明';

  @override
  String get audioFormatPriorityDesc => '• 打開作品詳情頁時，會自動優先展開優先級更高格式音訊的資料夾';

  @override
  String get ratingInfo => '評分資訊';

  @override
  String get showRatingAndReviewCount => '顯示作品評分和評價人數';

  @override
  String get priceInfo => '售價資訊';

  @override
  String get showWorkPrice => '顯示作品價格';

  @override
  String get durationInfo => '時長資訊';

  @override
  String get showWorkDuration => '顯示作品時長';

  @override
  String get showWorkTotalDuration => '顯示作品總時長';

  @override
  String get salesInfo => '售出資訊';

  @override
  String get showWorkSalesCount => '顯示作品售出數量';

  @override
  String get externalLinkInfo => '外部連結資訊';

  @override
  String get showExternalLinks => '顯示DLsite、官網等外部連結';

  @override
  String get releaseDateInfo => '發布日期';

  @override
  String get showWorkReleaseDate => '顯示作品發布日期';

  @override
  String get translateButtonLabel => '翻譯按鈕';

  @override
  String get showTranslateButton => '顯示作品標題的翻譯按鈕';

  @override
  String get subtitleTagLabel => '字幕標籤';

  @override
  String get showSubtitleTagOnCover => '在封面圖上顯示字幕標籤';

  @override
  String get showAgeRatingOnDetail => '在作品詳情頁顯示年齡分級';

  @override
  String get recommendationsLabel => '相關推薦';

  @override
  String get showRecommendations => '在作品詳情頁顯示相關推薦';

  @override
  String get circleInfo => '社團資訊';

  @override
  String get showWorkCircle => '顯示作品所屬社團';

  @override
  String get workCardSizeSubtitle => '調整網格密度，讓封面更大或維持目前大小';

  @override
  String get workCardFontSize => '卡片文字大小';

  @override
  String get workCardFontSizeSubtitle => '調整作品卡片的標題和資訊文字大小';

  @override
  String get cardSizeNormal => '預設';

  @override
  String get cardSizeLarge => '大';

  @override
  String get cardSizeExtraLarge => '特大';

  @override
  String get fontSizeNormal => '預設';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeExtraLarge => '特大';

  @override
  String get showSubtitleTagOnCard => '顯示作品卡片上的字幕標籤';

  @override
  String get showAgeRatingOnCard => '顯示作品卡片上的年齡分級';

  @override
  String get showOnlineMarks => '顯示線上標記的作品';

  @override
  String get cannotBeDisabled => '不可關閉';

  @override
  String get showPlaylists => '顯示建立的播放列表';

  @override
  String get showSubtitleLibrary => '顯示字幕庫管理';

  @override
  String get playlistPrivacyPrivateDesc => '只有您可以查看';

  @override
  String get playlistPrivacyUnlistedDesc => '知道連結的人才能查看';

  @override
  String get playlistPrivacyPublicDesc => '任何人都可以查看';

  @override
  String get clearTranslationCache => '清除翻譯快取';

  @override
  String get translationCacheCleared => '翻譯快取已清除';

  @override
  String get platformHintAndroid => 'Android: 將使用系統檔案選擇器，可能需要儲存權限';

  @override
  String get platformHintIOS => 'iOS: 受系統限制，使用預設路徑，可使用系統預設檔案瀏覽器查看';

  @override
  String get platformHintWindows => 'Windows: 可選擇任意可存取的目錄';

  @override
  String get platformHintMacOS => 'macOS: 可選擇任意可存取的目錄';

  @override
  String get platformHintLinux => 'Linux: 可選擇任意可存取的目錄';

  @override
  String get platformHintDefault => '選擇一個用於儲存下載檔案的目錄';

  @override
  String get subtitleFolderParsed => '已解析';

  @override
  String get subtitleFolderSaved => '已儲存';

  @override
  String get subtitleFolderUnknown => '未知作品';

  @override
  String get sortDownloadDate => '下載日期';

  @override
  String get sortWorkId => 'ID';

  @override
  String get searchDownloads => '搜尋已下載作品...';

  @override
  String get logTitle => '應用日誌';

  @override
  String get logSubtitle => '查看、匯出應用運行日誌';

  @override
  String get logSearchHint => '搜尋日誌...';

  @override
  String get logFilterAll => '全部';

  @override
  String get logCopy => '複製日誌';

  @override
  String get logExport => '匯出日誌檔案';

  @override
  String get logClear => '清空日誌';

  @override
  String get logCopied => '日誌已複製到剪貼簿';

  @override
  String logExported(String path) {
    return '日誌已匯出到 $path';
  }

  @override
  String logCount(int count) {
    return '$count 條日誌';
  }

  @override
  String get logAutoScroll => '自動捲動';

  @override
  String get logEmpty => '暫無日誌';

  @override
  String get proxySettingsOptional => '代理';

  @override
  String get loginAdvancedSettings => '進階設定';

  @override
  String proxyEnabled(String address) {
    return '已啟用：$address';
  }

  @override
  String get proxyAddressNotSet => '未設定（預設直連）';

  @override
  String get proxyHttpDescription => '透過 HTTP 代理連接伺服器';

  @override
  String get useProxy => '使用代理';

  @override
  String get proxyAddress => '代理位址';

  @override
  String get proxyAddressFormat => '格式：主機:連接埠，例如 127.0.0.1:7890';

  @override
  String get applyProxyAddress => '套用代理位址';

  @override
  String get invalidProxyAddress => '請輸入有效的 HTTP 代理位址和連接埠';

  @override
  String get proxyModeDirect => '直連';

  @override
  String get proxyModeSystem => '系統代理';

  @override
  String get proxyModeManual => '手動代理';

  @override
  String get proxyModeDirectDescription => '不使用代理直接連接';

  @override
  String get proxyModeSystemDescription => '使用作業系統的代理設定';

  @override
  String get proxyModeManualDescription => '使用下方設定的 HTTP 代理';

  @override
  String get playlistDisplayFormat => '播放清單版面';

  @override
  String get playlistDisplayFormatMasonry => '瀑布流';

  @override
  String get playlistDisplayFormatList => '列表';
}
