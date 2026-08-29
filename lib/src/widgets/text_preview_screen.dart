import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/cache_service.dart';
import '../services/log_service.dart';
import '../services/translation_service.dart';
import '../services/subtitle_library_service.dart';
import '../services/storage_service.dart';
import '../utils/snackbar_util.dart';
import '../utils/encoding_utils.dart';
import '../utils/local_file_url.dart';
import '../utils/scroll_optimization.dart';
import '../../l10n/app_localizations.dart';
import 'scrollable_appbar.dart';
import 'translation_toggle_button.dart';
import 'responsive_dialog.dart';

/// 文本预览屏幕
class TextPreviewScreen extends StatefulWidget {
  final String textUrl;
  final String title;
  final int? workId;
  final String? hash;
  final VoidCallback? onSavedToLibrary;

  const TextPreviewScreen({
    super.key,
    required this.textUrl,
    required this.title,
    this.workId,
    this.hash,
    this.onSavedToLibrary,
  });

  @override
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  static const TextStyle _contentTextStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
  );

  bool _isLoading = true;
  String? _content;
  String? _translatedContent;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  final ScrollThrottler _scrollThrottler = ScrollThrottler();
  double _scrollProgress = 0.0;
  bool _showTranslation = false;
  bool _isTranslating = false;
  String _translationProgress = '';
  bool _isEditMode = false;
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<_TextSearchMatch> _searchMatches = const [];
  int _currentSearchMatchIndex = -1;
  bool _hasLoadedContent = false;
  late TextEditingController _textController;
  late TextEditingController _translatedTextController;
  String _detectedEncoding = 'UTF-8'; // 记录检测到的原始编码

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _translatedTextController = TextEditingController();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedContent) return;

    _hasLoadedContent = true;
    _loadTextContent();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    _scrollThrottler.dispose();
    _textController.dispose();
    _translatedTextController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    _scrollThrottler.throttle(() {
      if (mounted && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        setState(() {
          _scrollProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
        });
      }
    });
  }

  /// 智能检测文件编码并读取内容
  /// 支持 UTF-8、GBK、Shift-JIS 等常见编码
  Future<String> _readFileWithEncoding(File file) async {
    try {
      final (content, encoding) =
          await EncodingUtils.readFileWithEncoding(file);
      _detectedEncoding = encoding;
      LogService.instance.debug('检测到文件编码: $encoding', tag: 'TextPreview');
      return content;
    } catch (e) {
      LogService.instance.error('读取文件失败: $e', tag: 'TextPreview');
      rethrow;
    }
  }

  /// 智能解码字节数组
  /// 尝试多种编码格式：UTF-16LE/BE -> UTF-8 -> GBK -> Shift-JIS -> Latin1
  String _decodeBytes(List<int> bytes) {
    final (content, encoding) = EncodingUtils.decodeBytes(bytes);
    _detectedEncoding = encoding;
    LogService.instance.debug('检测到编码: $encoding', tag: 'TextPreview');
    return content;
  }

  /// 将字符串编码为字节数组
  /// 使用检测到的原始编码，保持文件编码一致性
  List<int> _encodeString(String content) {
    LogService.instance.debug('使用 $_detectedEncoding 编码保存', tag: 'TextPreview');
    return EncodingUtils.encodeString(content, _detectedEncoding);
  }

  void _showSaveOptions() {
    showBottomSheetMenu(
      context: context,
      children: [
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(S.of(context).saveToLocal),
          subtitle: Text(S.of(context).selectDirectoryToSaveFile),
          onTap: () {
            Navigator.pop(context);
            _saveToLocal();
          },
        ),
        ListTile(
          leading: const Icon(Icons.library_books),
          title: Text(S.of(context).saveToSubtitleLibrary),
          subtitle: Text(S.of(context).saveToSubtitleLibraryDesc),
          onTap: () {
            Navigator.pop(context);
            _saveToSubtitleLibrary();
          },
        ),
      ],
    );
  }

  Future<void> _saveToLocal() async {
    final l10n = S.of(context);
    // 获取当前显示的内容（可能是编辑后的）
    final contentToSave = _getCurrentContent();
    if (contentToSave == null || contentToSave.isEmpty) {
      if (mounted) {
        SnackBarUtil.showWarning(context, l10n.noContentToSave);
      }
      return;
    }

    try {
      // 生成文件名
      String fileName = widget.title;
      if (!fileName.contains('.')) {
        fileName = '$fileName.txt';
      }

      if (Platform.isIOS) {
        // iOS: 通过分享面板保存
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(path.join(tempDir.path, fileName));
        final bytes = _encodeString(contentToSave);
        await tempFile.writeAsBytes(bytes);
        if (!mounted) return;
        try {
          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(tempFile.path)],
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, 80),
          );
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      } else {
        // 其他平台: 选择目录后写入
        final directoryPath = await FilePicker.platform.getDirectoryPath();
        if (directoryPath == null) return;

        // 检查文件是否已存在，如果存在则添加序号
        String finalPath = path.join(directoryPath, fileName);
        int counter = 1;
        while (await File(finalPath).exists()) {
          final nameWithoutExt = path.basenameWithoutExtension(fileName);
          final ext = path.extension(fileName);
          finalPath =
              path.join(directoryPath, '${nameWithoutExt}_$counter$ext');
          counter++;
        }

        // 写入文件
        final file = File(finalPath);
        final bytes = _encodeString(contentToSave);
        await file.writeAsBytes(bytes);

        if (!mounted) return;
        SnackBarUtil.showSuccess(context, l10n.fileSavedToPath(finalPath));
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showError(
        context,
        l10n.saveFailedWithError(e.toString()),
      );
    }
  }

  Future<void> _saveToSubtitleLibrary() async {
    final l10n = S.of(context);
    // 获取当前显示的内容（可能是编辑后的）
    final contentToSave = _getCurrentContent();
    if (contentToSave == null || contentToSave.isEmpty) {
      if (mounted) {
        SnackBarUtil.showWarning(context, l10n.noContentToSave);
      }
      return;
    }

    try {
      // 获取字幕库目录
      final libraryDir =
          await SubtitleLibraryService.getSubtitleLibraryDirectory();

      // 创建“已保存”目录
      final savedDir = Directory(
          path.join(libraryDir.path, SubtitleLibraryService.savedFolderName));
      if (!await savedDir.exists()) {
        await savedDir.create();
      }

      // 生成文件名
      String fileName = widget.title;
      if (!fileName.contains('.')) {
        fileName = '$fileName.txt';
      }

      // 检查文件是否已存在，如果存在则添加序号
      String finalPath = path.join(savedDir.path, fileName);
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final ext = path.extension(fileName);
        finalPath = path.join(savedDir.path, '${nameWithoutExt}_$counter$ext');
        counter++;
      }

      // 写入文件
      final file = File(finalPath);
      // 使用原始编码保存，保持编码一致性
      final bytes = _encodeString(contentToSave);
      await file.writeAsBytes(bytes);

      // 局部刷新缓存以便字幕库更新该目录
      await SubtitleLibraryService.refreshDirectoryCache(savedDir.path);

      // 触发字幕库重载回调
      if (!mounted) return;
      widget.onSavedToLibrary?.call();

      // 等待下一帧再显示成功提示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackBarUtil.showSuccess(context, l10n.savedToSubtitleLibrary);
        }
      });
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showError(
        context,
        l10n.saveFailedWithError(e.toString()),
      );
    }
  }

  String? _getCurrentContent() {
    if (_showTranslation && _translatedContent != null) {
      return _isEditMode ? _translatedTextController.text : _translatedContent;
    } else {
      return _isEditMode ? _textController.text : _content;
    }
  }

  void _openSearch() {
    setState(() {
      _isSearchMode = true;
    });
    _updateSearchResults(_searchController.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _isSearchMode = false;
      _searchMatches = const [];
      _currentSearchMatchIndex = -1;
    });
  }

  void _toggleSearch() {
    if (_isSearchMode) {
      _closeSearch();
    } else {
      _openSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _updateSearchResults('');
    _searchFocusNode.requestFocus();
  }

  void _refreshSearchResults() {
    if (!_isSearchMode) return;
    _updateSearchResults(_searchController.text);
  }

  void _updateSearchResults(String query) {
    final content = _getCurrentContent() ?? '';
    final matches = _findTextMatches(content, query);

    setState(() {
      _searchMatches = matches;
      _currentSearchMatchIndex = matches.isEmpty ? -1 : 0;
    });

    if (matches.isNotEmpty) {
      _scheduleScrollToCurrentMatch();
    }
  }

  void _moveToSearchMatch(int offset) {
    if (_searchMatches.isEmpty) return;

    final nextIndex =
        (_currentSearchMatchIndex + offset) % _searchMatches.length;
    setState(() {
      _currentSearchMatchIndex = nextIndex;
    });
    _scheduleScrollToCurrentMatch();
  }

  void _scheduleScrollToCurrentMatch() {
    final scheduledIndex = _currentSearchMatchIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scheduledIndex != _currentSearchMatchIndex) return;
      _scrollToCurrentMatch();
    });
  }

  void _scrollToCurrentMatch() {
    if (!_scrollController.hasClients ||
        _currentSearchMatchIndex < 0 ||
        _currentSearchMatchIndex >= _searchMatches.length) {
      return;
    }

    final content = _getCurrentContent() ?? '';
    if (content.isEmpty) return;

    final match = _searchMatches[_currentSearchMatchIndex];
    final position = _scrollController.position;
    final matchProgress = match.start / content.length;
    final centeredOffset =
        position.maxScrollExtent * matchProgress -
        position.viewportDimension * 0.25;
    final targetOffset = centeredOffset
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildSearchBar() {
    final l10n = S.of(context);
    final hasMatches = _searchMatches.isNotEmpty;
    final resultLabel = hasMatches
        ? '${_currentSearchMatchIndex + 1}/${_searchMatches.length}'
        : '0/0';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('text-preview-search-field'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchSubtitles,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('text-preview-search-clear'),
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                          tooltip: l10n.clear,
                        ),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _updateSearchResults,
                onSubmitted: (_) => _moveToSearchMatch(1),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                resultLabel,
                key: const ValueKey('text-preview-search-count'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            IconButton(
              key: const ValueKey('text-preview-search-previous'),
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: hasMatches ? () => _moveToSearchMatch(-1) : null,
              tooltip: l10n.previousPage,
            ),
            IconButton(
              key: const ValueKey('text-preview-search-next'),
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: hasMatches ? () => _moveToSearchMatch(1) : null,
              tooltip: l10n.nextPage,
            ),
            IconButton(
              key: const ValueKey('text-preview-search-close'),
              icon: const Icon(Icons.close),
              onPressed: _closeSearch,
              tooltip: l10n.close,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(String content) {
    final validMatches = _searchMatches
        .where((match) => match.start >= 0 && match.end <= content.length)
        .toList(growable: false);
    if (!_isSearchMode || validMatches.isEmpty) {
      return SelectableText(
        content,
        key: const ValueKey('text-preview-content'),
        style: _contentTextStyle,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var index = 0; index < validMatches.length; index++) {
      final match = validMatches[index];
      if (match.start > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, match.start)));
      }

      final isCurrent = index == _currentSearchMatchIndex;
      spans.add(
        TextSpan(
          text: content.substring(match.start, match.end),
          style: TextStyle(
            backgroundColor: isCurrent
                ? colorScheme.primaryContainer
                : colorScheme.tertiaryContainer.withValues(alpha: 0.7),
            color: isCurrent ? colorScheme.onPrimaryContainer : null,
            fontWeight: isCurrent ? FontWeight.w700 : null,
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < content.length) {
      spans.add(TextSpan(text: content.substring(cursor)));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      key: const ValueKey('text-preview-content'),
      style: _contentTextStyle,
    );
  }

  Future<void> _loadTextContent() async {
    final l10n = S.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 优先检查是否是本地文件（file:// 协议）
      final localPath = LocalFileUrl.pathFromUrl(widget.textUrl);
      if (localPath != null) {
        final localFile = File(localPath);

        if (await localFile.exists()) {
          // 使用智能编码检测读取文件
          final content = await _readFileWithEncoding(localFile);
          if (!mounted) return;
          setState(() {
            _content = content;
            _textController.text = content;
            _isLoading = false;
          });
          return;
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = l10n.localFileNotExist;
            _isLoading = false;
          });
          return;
        }
      }

      if (widget.workId != null &&
          widget.hash != null &&
          widget.hash!.isNotEmpty) {
        final cachedContent = await CacheService.getCachedTextContent(
          workId: widget.workId!,
          hash: widget.hash!,
          fileName: null, // TextPreviewScreen doesn't track fileName
        );

        if (cachedContent != null) {
          if (!mounted) return;
          setState(() {
            _content = cachedContent;
            _textController.text = cachedContent;
            _isLoading = false;
          });
          return;
        }
      }

      final dio = Dio();
      final response = await dio.get(
        widget.textUrl,
        options: Options(
          responseType: ResponseType.bytes, // 改为获取字节数据
          receiveTimeout: const Duration(seconds: 30),
          headers: StorageService.serverCookieHeaders,
        ),
      );

      if (response.statusCode == 200) {
        // 使用智能编码检测解码
        final bytes = response.data as List<int>;
        final content = _decodeBytes(bytes);

        if (widget.workId != null &&
            widget.hash != null &&
            widget.hash!.isNotEmpty) {
          await CacheService.cacheTextContent(
            workId: widget.workId!,
            hash: widget.hash!,
            content: content,
          );
        }

        if (!mounted) return;
        setState(() {
          _content = content;
          _textController.text = content;
          _isLoading = false;
        });
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = l10n.loadTextFailed(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _translateContent() async {
    if (_content == null || _content!.isEmpty) return;

    final l10n = S.of(context);
    setState(() {
      _isTranslating = true;
      _translationProgress = l10n.preparingTranslation;
    });

    try {
      final translationService = TranslationService();
      final translated = await translationService.translateLongText(
        _content!,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _translationProgress = l10n.translatingProgress(current, total);
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _translatedContent = translated;
        _translatedTextController.text = translated;
        _showTranslation = true;
        _isTranslating = false;
        _translationProgress = '';
      });
      _refreshSearchResults();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTranslating = false;
        _translationProgress = '';
      });
      SnackBarUtil.showError(context, l10n.translationFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScrollableAppBar(
        title: Text(widget.title),
        bottom: _isSearchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: _buildSearchBar(),
              )
            : null,
        actions: [
          if (_content != null && _content!.isNotEmpty)
            IconButton(
              key: const ValueKey('text-preview-search-action'),
              icon: Icon(
                Icons.search,
                color: _isSearchMode
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: _toggleSearch,
              tooltip: S.of(context).search,
            ),
          if (_content != null && _content!.isNotEmpty)
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.visibility : Icons.edit,
                color:
                    _isEditMode ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
                _refreshSearchResults();
              },
              tooltip: _isEditMode
                  ? S.of(context).previewMode
                  : S.of(context).editMode,
            ),
          if (_content != null && _content!.isNotEmpty)
            TranslationToolbarButton(
              isTranslated: _showTranslation,
              isLoading: _isTranslating,
              onPressed: _isTranslating
                  ? null
                  : () {
                      if (_translatedContent != null) {
                        setState(() {
                          _showTranslation = !_showTranslation;
                        });
                        _refreshSearchResults();
                      } else {
                        _translateContent();
                      }
                    },
              tooltip: _showTranslation
                  ? S.of(context).showOriginal
                  : S.of(context).translateContent,
            ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showSaveOptions,
            tooltip: S.of(context).save,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTextContent,
              child: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: _scrollProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          minHeight: 3,
        ),
        if (_isTranslating)
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(_translationProgress),
              ],
            ),
          ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: _isEditMode
                  ? TextField(
                      controller: _showTranslation && _translatedContent != null
                          ? _translatedTextController
                          : _textController,
                      maxLines: null,
                      style: _contentTextStyle,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: S.of(context).editTextContentHint,
                      ),
                      onChanged: (_) => _refreshSearchResults(),
                    )
                  : _buildPreviewContent(
                      _showTranslation && _translatedContent != null
                          ? _translatedContent!
                          : _content ?? '',
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextSearchMatch {
  const _TextSearchMatch(this.start, this.end);

  final int start;
  final int end;
}

List<_TextSearchMatch> _findTextMatches(String content, String query) {
  final normalizedQuery = query.trim();
  if (content.isEmpty || normalizedQuery.isEmpty) return const [];

  final expression = RegExp(
    RegExp.escape(normalizedQuery),
    caseSensitive: false,
    unicode: true,
  );
  return expression
      .allMatches(content)
      .map((match) => _TextSearchMatch(match.start, match.end))
      .toList(growable: false);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
