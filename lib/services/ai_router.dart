import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ai_response.dart';
import 'internet_service.dart';
import 'gemini_service.dart';
import 'local_llm_service.dart';

/// Central AI Router that dynamically routes user prompts to either
/// Cloud Gemini API or On-Device Local SLM depending on internet reachability
/// and cloud service health.
class AIRouter {
  final InternetService _internetService;
  final GeminiService _geminiService;
  final LocalLLMService _localLLMService;

  AIRouter({
    required InternetService internetService,
    required GeminiService geminiService,
    required LocalLLMService localLLMService,
  })  : _internetService = internetService,
        _geminiService = geminiService,
        _localLLMService = localLLMService;

  /// Main routing method.
  /// Checks reachability and streams chunks tagged with active [AIProvider].
  Stream<AIResponseChunk> streamResponse(
    String message, {
    String? groundingContext,
  }) async* {
    final hasInternet = await _internetService.hasInternet();

    if (hasInternet) {
      bool isFirstChunk = true;
      bool geminiFailed = false;

      try {
        if (kDebugMode) {
          print('⚡ [AI_ROUTER] Internet reachability confirmed. Routing to Gemini API...');
        }

        final geminiStream = _geminiService.generateStream(
          message,
          groundingContext: groundingContext,
        );

        await for (final token in geminiStream) {
          yield AIResponseChunk(
            textDelta: token,
            provider: AIProvider.gemini,
            isFirstChunk: isFirstChunk,
          );
          isFirstChunk = false;
        }
        return;
      } catch (e) {
        geminiFailed = true;
        if (kDebugMode) {
          print('⚠️ [AI_ROUTER] Gemini API request failed: $e. Executing fallback to Local SLM...');
        }
      }

      if (geminiFailed) {
        yield* _streamFromLocal(message, groundingContext: groundingContext);
      }
    } else {
      if (kDebugMode) {
        print('📱 [AI_ROUTER] Device offline. Routing directly to Local SLM...');
      }
      yield* _streamFromLocal(message, groundingContext: groundingContext);
    }
  }

  Stream<AIResponseChunk> _streamFromLocal(
    String message, {
    String? groundingContext,
  }) async* {
    bool isFirstChunk = true;

    // Ensure local model is ready
    if (!_localLLMService.isLoaded) {
      await _localLLMService.loadModel();
    }

    final localStream = _localLLMService.generateStream(
      message,
      groundingContext: groundingContext,
    );

    await for (final token in localStream) {
      yield AIResponseChunk(
        textDelta: token,
        provider: AIProvider.local,
        isFirstChunk: isFirstChunk,
      );
      isFirstChunk = false;
    }
  }

  void cancelGeneration() {
    _localLLMService.cancelGeneration();
  }
}
