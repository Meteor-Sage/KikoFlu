import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/translation_service.dart';
import '../utils/snackbar_util.dart';
import '../widgets/settings_section.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptController.text.isEmpty) {
      _fillDefaultPrompt();
    }
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
      final prompt = _promptController.text.trim();
      final settings = LLMSettings(
        apiUrl: _apiUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        model: _modelController.text.trim(),
        prompt: TranslationService.isGeneratedDefaultLLMPrompt(prompt)
            ? ''
            : prompt,
        concurrency: _concurrency.toInt(),
      );

      await ref.read(llmSettingsProvider.notifier).updateSettings(settings);

      if (mounted) {
        SnackBarUtil.showSuccess(context, S.of(context).settingsSaved);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _fillDefaultPrompt() async {
    final prompt =
        await TranslationService().getDefaultLLMPromptForCurrentLocale();
    if (!mounted || _promptController.text.isNotEmpty) return;
    _promptController.text = prompt;
  }

  Future<void> _restoreDefaultPrompt() async {
    _promptController.text =
        await TranslationService().getDefaultLLMPromptForCurrentLocale();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: S.of(context).llmTranslationSettings,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SettingsSectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _apiUrlController,
                      decoration: InputDecoration(
                        labelText: S.of(context).apiEndpointUrl,
                        hintText: 'https://api.openai.com/v1/chat/completions',
                        helperText: S.of(context).openaiCompatibleEndpoint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).pleaseEnterApiUrl;
                        }
                        if (!value.startsWith('http')) {
                          return S.of(context).pleaseEnterValidUrl;
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
                          return S.of(context).pleaseEnterApiKey;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: S.of(context).modelName,
                        hintText: 'gpt-3.5-turbo',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).pleaseEnterModelName;
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
                            Text(S.of(context).concurrencyCount,
                                style: const TextStyle(fontSize: 16)),
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
                        Text(
                          S.of(context).concurrencyDescription,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
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
            SettingsSectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).promptSection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).promptDescription,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _promptController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: S.of(context).enterSystemPrompt,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).pleaseEnterPrompt;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _restoreDefaultPrompt,
                      icon: const Icon(Icons.restore),
                      label: Text(S.of(context).restoreDefaultPrompt),
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
                label: Text(S.of(context).saveSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
