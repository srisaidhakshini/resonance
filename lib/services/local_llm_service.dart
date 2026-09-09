import 'dart:async';
import 'llm_service.dart';

/// Wrapper service around the on-device Local SLM engine (`llama_cpp_dart`).
class LocalLLMService {
  final LLMService _llmService;

  LocalLLMService(this._llmService);

  bool get isLoaded => _llmService.isLoaded;

  Future<void> loadModel() async {
    await _llmService.loadModel();
  }

  /// Delegates streaming inference to the on-device local engine.
  Stream<String> generateStream(
    String prompt, {
    String? groundingContext,
  }) {
    return _llmService.streamResponse(
      prompt,
      groundingContext: groundingContext,
    );
  }

  void cancelGeneration() {
    _llmService.cancelGeneration();
  }
}
