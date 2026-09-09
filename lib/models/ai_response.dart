enum AIProvider {
  gemini,
  local,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.gemini:
        return 'Gemini AI';
      case AIProvider.local:
        return 'Offline AI';
    }
  }

  String get iconSymbol {
    switch (this) {
      case AIProvider.gemini:
        return '⚡';
      case AIProvider.local:
        return '📱';
    }
  }
}

/// Represents a single streamed token/chunk from the active AI provider.
class AIResponseChunk {
  final String textDelta;
  final AIProvider provider;
  final bool isFirstChunk;

  AIResponseChunk({
    required this.textDelta,
    required this.provider,
    this.isFirstChunk = false,
  });
}

/// Represents a completed single-shot response from an AI provider.
class AIResponse {
  final String text;
  final AIProvider provider;

  AIResponse({
    required this.text,
    required this.provider,
  });
}
