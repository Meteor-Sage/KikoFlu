import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:gbk_codec/gbk_codec.dart';
import 'package:charset/charset.dart';

import '../services/cache_service.dart';
import '../services/translation_service.dart';
import '../services/subtitle_library_service.dart';
import '../utils/snackbar_util.dart';
import 'scrollable_appbar.dart';

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
  bool _isLoading = true;
  String? _content;
  String? _translatedContent;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  bool _showTranslation = false;
  bool _isTranslating = false;
  String _translationProgress = '';
  bool _isEditMode = false;
  late TextEditingController _textController;
  late TextEditingController _translatedTextController;
  String _detectedEncoding = 'UTF-8'; // 记录检测到的原始编码

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _translatedTextController = TextEditingController();
    _loadTextContent();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    _textController.dispose();
    _translatedTextController.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      setState(() {
        _scrollProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
      });
    }
  }

  /// 智能检测文件编码并读取内容
  /// 支持 UTF-8、GBK、Shift-JIS 等常见编码
  Future<String> _readFileWithEncoding(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return _decodeBytes(bytes);
    } catch (e) {
      print('[TextPreview] 读取文件失败: $e');
      rethrow;
    }
  }

  /// 智能解码字节数组
  /// 尝试多种编码格式：UTF-16LE/BE -> UTF-8 -> GBK -> Shift-JIS -> Latin1
  String _decodeBytes(List<int> bytes) {
    // 1. 检查 UTF-16LE BOM (FF FE)
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      print('[TextPreview] 检测到 UTF-16LE BOM');
      _detectedEncoding = 'UTF-16LE';
      try {
        // UTF-16LE: 小端序，移除 BOM
        final utf16Bytes = bytes.sublist(2);
        final utf16Codes = <int>[];
        for (int i = 0; i < utf16Bytes.length; i += 2) {
          if (i + 1 < utf16Bytes.length) {
            // 小端序：低字节在前
            final code = utf16Bytes[i] | (utf16Bytes[i + 1] << 8);
            utf16Codes.add(code);
          }
        }
        return String.fromCharCodes(utf16Codes);
      } catch (e) {
        print('[TextPreview] UTF-16LE 解码失败: $e');
      }
    }

    // 2. 检查 UTF-16BE BOM (FE FF)
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      print('[TextPreview] 检测到 UTF-16BE BOM');
      _detectedEncoding = 'UTF-16BE';
      try {
        // UTF-16BE: 大端序，移除 BOM
        final utf16Bytes = bytes.sublist(2);
        final utf16Codes = <int>[];
        for (int i = 0; i < utf16Bytes.length; i += 2) {
          if (i + 1 < utf16Bytes.length) {
            // 大端序：高字节在前
            final code = (utf16Bytes[i] << 8) | utf16Bytes[i + 1];
            utf16Codes.add(code);
          }
        }
        return String.fromCharCodes(utf16Codes);
      } catch (e) {
        print('[TextPreview] UTF-16BE 解码失败: $e');
      }
    }

    // 3. 检查 UTF-8 BOM (EF BB BF)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      print('[TextPreview] 检测到 UTF-8 BOM');
      _detectedEncoding = 'UTF-8';
      return utf8.decode(bytes.sublist(3));
    }

    // 4. 尝试 UTF-8 解码
    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      // 检查是否有乱码字符（通常是解码错误的标志）
      if (!decoded.contains('�')) {
        print('[TextPreview] 使用 UTF-8 编码');
        _detectedEncoding = 'UTF-8';
        return decoded;
      }
    } catch (e) {
      // UTF-8 解码失败，继续尝试其他编码
    }

    // 5. 尝试 GBK 解码（简体中文）
    try {
      final decoded = gbk_bytes.decode(bytes);
      // 简单验证：检查是否包含常见中文字符
      if (decoded.isNotEmpty && !decoded.contains('�')) {
        print('[TextPreview] 使用 GBK 编码');
        _detectedEncoding = 'GBK';
        return decoded;
      }
    } catch (e) {
      // GBK 解码失败
    }

    // 4. 尝试 Shift-JIS 解码（日文）
    try {
      final decoded = shiftJis.decode(bytes);
      // 简单验证：检查是否有乱码
      if (decoded.isNotEmpty && !decoded.contains('�')) {
        print('[TextPreview] 使用 Shift-JIS 编码');
        _detectedEncoding = 'Shift-JIS';
        return decoded;
      }
    } catch (e) {
      // Shift-JIS 解码失败
    }

    // 5. 最后尝试 Latin1（不会失败，但可能显示乱码）
    try {
      print('[TextPreview] 使用 Latin1 编码（降级处理）');
      _detectedEncoding = 'Latin1';
      return latin1.decode(bytes);
    } catch (e) {
      // 如果连 Latin1 都失败，返回错误提示
      _detectedEncoding = 'Unknown';
      return '文件编码无法识别，无法正确显示内容';
    }
  }

  /// 将字符串编码为字节数组
  /// 使用检测到的原始编码，保持文件编码一致性
  List<int> _encodeString(String content) {
    try {
      switch (_detectedEncoding) {
        case 'UTF-16LE':
          print('[TextPreview] 使用 UTF-16LE 编码保存（含 BOM）');
          // 转换为 UTF-16 码点
          final codeUnits = content.codeUnits;
          final bytes = <int>[0xFF, 0xFE]; // BOM
          // 小端序：低字节在前
          for (final code in codeUnits) {
            bytes.add(code & 0xFF); // 低字节
            bytes.add((code >> 8) & 0xFF); // 高字节
          }
          return bytes;
        case 'UTF-16BE':
          print('[TextPreview] 使用 UTF-16BE 编码保存（含 BOM）');
          // 转换为 UTF-16 码点
          final codeUnits = content.codeUnits;
          final bytes = <int>[0xFE, 0xFF]; // BOM
          // 大端序：高字节在前
          for (final code in codeUnits) {
            bytes.add((code >> 8) & 0xFF); // 高字节
            bytes.add(code & 0xFF); // 低字节
          }
          return bytes;
        case 'GBK':
          print('[TextPreview] 使用 GBK 编码保存');
          return gbk_bytes.encode(content);
        case 'Shift-JIS':
          print('[TextPreview] 使用 Shift-JIS 编码保存');
          return shiftJis.encode(content);
        case 'Latin1':
          print('[TextPreview] 使用 Latin1 编码保存');
          return latin1.encode(content);
        case 'UTF-8':
        default:
          // UTF-8 是最安全的默认选择
          print('[TextPreview] 使用 UTF-8 编码保存');
          return utf8.encode(content);
      }
    } catch (e) {
      // 编码失败时降级到 UTF-8
      print('[TextPreview] 编码失败，降级到 UTF-8: $e');
      return utf8.encode(content);
    }
  }

  void _showSaveOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('保存到本地'),
              subtitle: const Text('选择目录保存文件'),
              onTap: () {
                Navigator.pop(context);
                _saveToLocal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('保存到字幕库'),
              subtitle: const Text('保存到字幕库的“已保存”目录'),
              onTap: () {
                Navigator.pop(context);
                _saveToSubtitleLibrary();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToLocal() async {
    // 获取当前显示的内容（可能是编辑后的）
    final contentToSave = _getCurrentContent();
    if (contentToSave == null || contentToSave.isEmpty) {
      if (mounted) {
        SnackBarUtil.showWarning(context, '没有可保存的内容');
      }
      return;
    }

    try {
      // 选择保存目录
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return;

      // 生成文件名
      String fileName = widget.title;
      if (!fileName.contains('.')) {
        fileName = '$fileName.txt';
      }

      // 检查文件是否已存在，如果存在则添加序号
      String finalPath = path.join(directoryPath, fileName);
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final ext = path.extension(fileName);
        finalPath = path.join(directoryPath, '${nameWithoutExt}_$counter$ext');
        counter++;
      }

      // 写入文件
      final file = File(finalPath);
      // 使用原始编码保存，保持编码一致性
      final bytes = _encodeString(contentToSave);
      await file.writeAsBytes(bytes);

      if (mounted) {
        SnackBarUtil.showSuccess(context, '文件已保存到：$finalPath');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '保存失败: $e');
      }
    }
  }

  Future<void> _saveToSubtitleLibrary() async {
    // 获取当前显示的内容（可能是编辑后的）
    final contentToSave = _getCurrentContent();
    if (contentToSave == null || contentToSave.isEmpty) {
      if (mounted) {
        SnackBarUtil.showWarning(context, '没有可保存的内容');
      }
      return;
    }

    try {
      // 获取字幕库目录
      final libraryDir =
          await SubtitleLibraryService.getSubtitleLibraryDirectory();

      // 创建“已保存”目录
      final savedDir = Directory(path.join(libraryDir.path, '已保存'));
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
      widget.onSavedToLibrary?.call();

      // 等待下一帧再显示成功提示
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarUtil.showSuccess(context, '已保存到字幕库');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '保存失败: $e');
      }
    }
  }

  String? _getCurrentContent() {
    if (_showTranslation && _translatedContent != null) {
      return _isEditMode ? _translatedTextController.text : _translatedContent;
    } else {
      return _isEditMode ? _textController.text : _content;
    }
  }

  Future<void> _loadTextContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 优先检查是否是本地文件（file:// 协议）
      if (widget.textUrl.startsWith('file://')) {
        final localPath = widget.textUrl.substring(7); // 移除 'file://' 前缀
        final localFile = File(localPath);

        if (await localFile.exists()) {
          // 使用智能编码检测读取文件
          final content = await _readFileWithEncoding(localFile);
          setState(() {
            _content = content;
            _textController.text = content;
            _isLoading = false;
          });
          return;
        } else {
          setState(() {
            _errorMessage = '本地文件不存在';
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
      setState(() {
        _errorMessage = '加载文本失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _translateContent() async {
    if (_content == null || _content!.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _translationProgress = '准备翻译...';
    });

    try {
      final translationService = TranslationService();
      final translated = await translationService.translateLongText(
        _content!,
        onProgress: (current, total) {
          setState(() {
            _translationProgress = '翻译中 $current/$total';
          });
        },
      );

      setState(() {
        _translatedContent = translated;
        _translatedTextController.text = translated;
        _showTranslation = true;
        _isTranslating = false;
        _translationProgress = '';
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
        _translationProgress = '';
      });
      if (mounted) {
        SnackBarUtil.showError(context, '翻译失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScrollableAppBar(
        title: Text(widget.title),
        actions: [
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
              },
              tooltip: _isEditMode ? '预览模式' : '编辑模式',
            ),
          if (_content != null && _content!.isNotEmpty)
            IconButton(
              icon: _isTranslating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.g_translate,
                      color: _showTranslation
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
              onPressed: _isTranslating
                  ? null
                  : () {
                      if (_translatedContent != null) {
                        setState(() {
                          _showTranslation = !_showTranslation;
                        });
                      } else {
                        _translateContent();
                      }
                    },
              tooltip: _showTranslation ? '显示原文' : '翻译内容',
            ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showSaveOptions,
            tooltip: '保存',
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
              child: const Text('重试'),
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
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '编辑文本内容...',
                      ),
                    )
                  : SelectableText(
                      _showTranslation && _translatedContent != null
                          ? _translatedContent!
                          : _content ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
