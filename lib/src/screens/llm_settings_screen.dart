import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../models/llm_api_protocol.dart';
import '../providers/settings_provider.dart';
import '../services/translation_service.dart';
import '../widgets/settings_section.dart';

class LLMSettingsScreen extends ConsumerStatefulWidget {
  const LLMSettingsScreen({super.key});

  @override
  ConsumerState<LLMSettingsScreen> createState() => _LLMSettingsScreenState();
}

class _LLMSettingsScreenState extends ConsumerState<LLMSettingsScreen> {
  late TextEditingController _apiUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _promptController;
  late LLMSettingsNotifier _settingsNotifier;
  late LLMApiProtocol _apiProtocol;
  late double _concurrency;
  Timer? _saveTimer;
  Future<void>? _saveFuture;
  LLMSettings? _pendingSettings;
  bool _syncingSettings = false;
  bool _hasLocalChanges = false;
  final Set<String> _dirtyFields = <String>{};

  static const _apiUrlField = 'apiUrl';
  static const _apiKeyField = 'apiKey';
  static const _modelField = 'model';
  static const _promptField = 'prompt';
  static const _protocolField = 'protocol';
  static const _concurrencyField = 'concurrency';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(llmSettingsProvider);
    _apiUrlController = TextEditingController(text: settings.apiUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(text: settings.model);
    _promptController = TextEditingController(text: settings.prompt);
    _settingsNotifier = ref.read(llmSettingsProvider.notifier);
    _apiProtocol = settings.apiProtocol;
    _concurrency = settings.concurrency.toDouble();

    _apiUrlController.addListener(() => _handleTextChanged(_apiUrlField));
    _apiKeyController.addListener(() => _handleTextChanged(_apiKeyField));
    _modelController.addListener(() => _handleTextChanged(_modelField));
    _promptController.addListener(() => _handleTextChanged(_promptField));

    ref.listenManual<LLMSettings>(llmSettingsProvider, (previous, next) {
      if (!mounted) return;
      if (_hasLocalChanges) {
        if (_settingsNotifier.isLoaded && _saveFuture == null) {
          _scheduleSave();
        }
        return;
      }
      setState(() => _applySettings(next));
    });
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
    _saveTimer?.cancel();
    if (_hasLocalChanges) {
      _queueSettingsForSave();
    }
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _applySettings(LLMSettings settings) {
    _syncingSettings = true;
    if (!_dirtyFields.contains(_apiUrlField)) {
      _apiUrlController.text = settings.apiUrl;
    }
    if (!_dirtyFields.contains(_apiKeyField)) {
      _apiKeyController.text = settings.apiKey;
    }
    if (!_dirtyFields.contains(_modelField)) {
      _modelController.text = settings.model;
    }
    if (!_dirtyFields.contains(_promptField) && settings.prompt.isNotEmpty) {
      _promptController.text = settings.prompt;
    }
    if (!_dirtyFields.contains(_protocolField)) {
      _apiProtocol = settings.apiProtocol;
    }
    if (!_dirtyFields.contains(_concurrencyField)) {
      _concurrency = settings.concurrency.toDouble();
    }
    _syncingSettings = false;
  }

  void _handleTextChanged(String field) {
    if (_syncingSettings) return;
    _dirtyFields.add(field);
    _scheduleSave();
  }

  void _scheduleSave() {
    _hasLocalChanges = true;
    if (!_settingsNotifier.isLoaded) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 450),
      _queueSettingsForSave,
    );
  }

  LLMSettings _buildSettings() {
    final prompt = _promptController.text.trim();
    return LLMSettings(
      apiUrl: _apiUrlController.text.trim(),
      apiProtocol: _apiProtocol,
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      prompt: TranslationService.isGeneratedDefaultLLMPrompt(prompt)
          ? ''
          : prompt,
      concurrency: _concurrency.toInt(),
    );
  }

  void _queueSettingsForSave() {
    _saveTimer?.cancel();
    _pendingSettings = _buildSettings();
    _saveFuture ??= _drainSaveQueue();
  }

  Future<void> _drainSaveQueue() async {
    while (_pendingSettings != null) {
      final settings = _pendingSettings!;
      _pendingSettings = null;
      await _settingsNotifier.updateSettings(settings);
    }
    _saveFuture = null;
    _hasLocalChanges = false;
    _dirtyFields.clear();
  }

  Future<void> _fillDefaultPrompt() async {
    final prompt = await TranslationService()
        .getDefaultLLMPromptForCurrentLocale();
    if (!mounted || _promptController.text.isNotEmpty) return;
    _syncingSettings = true;
    _promptController.text = prompt;
    _syncingSettings = false;
  }

  Future<void> _restoreDefaultPrompt() async {
    final prompt = await TranslationService()
        .getDefaultLLMPromptForCurrentLocale();
    if (!mounted) return;
    _promptController.text = prompt;
  }

  String _protocolLabel(BuildContext context, LLMApiProtocol protocol) {
    switch (protocol) {
      case LLMApiProtocol.chatCompletions:
        return S.of(context).chatCompletionsProtocol;
      case LLMApiProtocol.responses:
        return S.of(context).responsesProtocol;
      case LLMApiProtocol.anthropic:
        return S.of(context).anthropicProtocol;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: S.of(context).llmTranslationSettings,
      body: Form(
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: S.of(context).apiBaseUrl,
                        hintText: _apiProtocol == LLMApiProtocol.anthropic
                            ? 'https://api.anthropic.com/v1'
                            : 'https://api.openai.com/v1',
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
                    DropdownButtonFormField<LLMApiProtocol>(
                      key: ValueKey(_apiProtocol),
                      initialValue: _apiProtocol,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: S.of(context).apiProtocol,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final protocol in LLMApiProtocol.values)
                          DropdownMenuItem(
                            value: protocol,
                            child: Text(_protocolLabel(context, protocol)),
                          ),
                      ],
                      onChanged: (protocol) {
                        if (protocol == null || protocol == _apiProtocol) {
                          return;
                        }
                        setState(() => _apiProtocol = protocol);
                        _dirtyFields.add(_protocolField);
                        _scheduleSave();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiKeyController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            Text(
                              S.of(context).concurrencyCount,
                              style: const TextStyle(fontSize: 16),
                            ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                            _dirtyFields.add(_concurrencyField);
                            _scheduleSave();
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
          ],
        ),
      ),
    );
  }
}
