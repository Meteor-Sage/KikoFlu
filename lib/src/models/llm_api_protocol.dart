enum LLMApiProtocol {
  chatCompletions(
    preferenceValue: 'chat_completions',
    endpointSuffix: '/chat/completions',
  ),
  responses(preferenceValue: 'responses', endpointSuffix: '/responses'),
  anthropic(preferenceValue: 'anthropic', endpointSuffix: '/messages');

  const LLMApiProtocol({
    required this.preferenceValue,
    required this.endpointSuffix,
  });

  final String preferenceValue;
  final String endpointSuffix;

  static LLMApiProtocol fromPreference(
    String? value, {
    required String apiUrl,
  }) {
    for (final protocol in values) {
      if (protocol.preferenceValue == value) return protocol;
    }

    final normalizedUrl = _withoutTrailingSlash(apiUrl);
    for (final protocol in values.reversed) {
      if (normalizedUrl.endsWith(protocol.endpointSuffix)) {
        return protocol;
      }
    }
    return chatCompletions;
  }

  static String baseUrlFrom(String apiUrl) {
    final normalizedUrl = _withoutTrailingSlash(apiUrl.trim());
    for (final protocol in values) {
      if (normalizedUrl.endsWith(protocol.endpointSuffix)) {
        return normalizedUrl.substring(
          0,
          normalizedUrl.length - protocol.endpointSuffix.length,
        );
      }
    }
    return normalizedUrl;
  }

  String resolveEndpoint(String baseUrl) {
    return '${baseUrlFrom(baseUrl)}$endpointSuffix';
  }

  static String _withoutTrailingSlash(String value) {
    var result = value;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
