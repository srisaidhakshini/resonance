import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'personalization_service.dart';
import 'prompt_builder.dart';

/// Cloud AI Service interacting with Google Gemini API.
class GeminiService {
  static const String _defaultApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const Duration defaultTimeout = Duration(seconds: 10);

  final Dio _dio;
  final String apiKey;

  GeminiService({
    String? apiKey,
    Dio? dio,
  })  : apiKey = apiKey ?? _defaultApiKey,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: defaultTimeout,
              ),
            );

  /// Streams generated content from Gemini 1.5 Flash.
  /// Throws Exception on network failure, timeout, or non-200 HTTP code.
  Stream<String> generateStream(
    String prompt, {
    String? groundingContext,
    Duration timeout = defaultTimeout,
  }) async* {
    final effectiveApiKey = apiKey.isNotEmpty ? apiKey : _defaultApiKey;

    if (effectiveApiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final userProfile = await PersonalizationService.instance.getUserProfile();
    final systemPrompt = PromptBuilder.buildSystemPrompt(profile: userProfile);
    final fullUserMessage = PromptBuilder.buildUserPrompt(
      prompt,
      groundingContext: groundingContext,
    );

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?alt=sse&key=$effectiveApiKey';

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemPrompt\n\n$fullUserMessage'},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.8,
        'maxOutputTokens': 1024,
      },
    };

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: jsonEncode(requestBody),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Content-Type': 'application/json'},
        ),
      ).timeout(timeout);

      final stream = response.data?.stream;
      if (stream == null) {
        throw Exception('Gemini returned an empty response stream.');
      }

      await for (final chunk in stream.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final jsonStr = chunk.substring(6).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

          try {
            final data = jsonDecode(jsonStr);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              if (content != null) {
                final parts = content['parts'] as List?;
                if (parts != null && parts.isNotEmpty) {
                  final text = parts[0]['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    yield text;
                  }
                }
              }
            }
          } catch (_) {
            // Ignore partial SSE chunk parse errors
          }
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [GEMINI] DioException: ${e.message} (Status: ${e.response?.statusCode})');
      }
      throw Exception('Gemini API request failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GEMINI] Exception: $e');
      }
      rethrow;
    }
  }
}
