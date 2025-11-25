import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/scrollable_appbar.dart';

class LLMSettingsScreen extends ConsumerStatefulWidget {
  const LLMSettingsScreen({super.key});

  @override
  ConsumerState<LLMSettingsScreen> createState() => _LLMSettingsScreenState();
}

class _LLMSettingsScreenState extends ConsumerState<LLMSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _apiUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _promptController;
  late double _concurrency;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(llmSettingsProvider);
    _apiUrlController = TextEditingController(text: settings.apiUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(text: settings.model);
    _promptController = TextEditingController(text: settings.prompt);
    _concurrency = settings.concurrency.toDouble();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = LLMSettings(
        apiUrl: _apiUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        model: _modelController.text.trim(),
        prompt: _promptController.text.trim(),
        concurrency: _concurrency.toInt(),
      );

      await ref.read(llmSettingsProvider.notifier).updateSettings(settings);

      if (mounted) {
        SnackBarUtil.showSuccess(context, '设置已保存');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScrollableAppBar(
        title: Text('LLM翻译设置', style: TextStyle(fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _apiUrlController,
                      decoration: const InputDecoration(
                        labelText: 'API 接口地址',
                        hintText: 'https://api.openai.com/v1/chat/completions',
                        helperText: 'OpenAI 兼容接口地址',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入 API 接口地址';
                        }
                        if (!value.startsWith('http')) {
                          return '请输入有效的 URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API Key',
                        hintText: 'sk-...',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入 API Key';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: '模型名称',
                        hintText: 'gpt-3.5-turbo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入模型名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('并发数', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              '${_concurrency.toInt()}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '同时进行的翻译请求数量，建议 3-5',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Slider(
                          value: _concurrency,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${_concurrency.toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _concurrency = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '提示词 (Prompt)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '由于系统采用分块翻译机制，请确保 Prompt 指令明确，要求只输出翻译结果，不包含任何解释。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _promptController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '输入系统提示词...',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入提示词';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        _promptController.text =
                            'You are a professional translator. Translate the following text into Simplified Chinese (zh-CN). Output ONLY the translated text without any explanations, notes, or markdown code blocks.';
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('恢复默认提示词'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
