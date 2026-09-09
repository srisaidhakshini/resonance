import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/teaching_style_template.dart';
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
    String effectiveApiKey = apiKey.isNotEmpty ? apiKey : _defaultApiKey;

    if (effectiveApiKey.isEmpty && kIsWeb) {
      try {
        final resp = await _dio.get('/api/config');
        if (resp.statusCode == 200 && resp.data is Map) {
          final k = resp.data['geminiApiKey']?.toString();
          if (k != null && k.isNotEmpty) {
            effectiveApiKey = k;
          }
        }
      } catch (_) {}
    }

    if (effectiveApiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final userProfile = await PersonalizationService.instance.getUserProfile();
    final systemPrompt = PromptBuilder.buildSystemPrompt(profile: userProfile);
    final styleTemplate = TeachingStyleTemplate.fromStyle(userProfile.teachingStyle);
    final fullUserMessage = PromptBuilder.buildUserPrompt(
      prompt,
      groundingContext: groundingContext,
    );

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?alt=sse&key=$effectiveApiKey';

    // Build conversational turns including pedagogical few-shot examples
    final contentsList = <Map<String, dynamic>>[];

    // Inject few-shot turns to strongly condition Gemini on the chosen Teaching Style
    for (final ex in styleTemplate.fewShotExamples.take(1)) {
      contentsList.add({
        'role': ex.role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': ex.content},
        ],
      });
    }

    // Add current user prompt
    contentsList.add({
      'role': 'user',
      'parts': [
        {'text': fullUserMessage},
      ],
    });

    final requestBody = {
      'systemInstruction': {
        'role': 'user',
        'parts': [
          {
            'text': '$systemPrompt\n\n'
                'IMPORTANT PERSONALIZATION MANDATE:\n'
                '- The student name is "${userProfile.userName}", in Class ${userProfile.grade}.\n'
                '- Teaching Style: ${userProfile.teachingStyle.displayName}.\n'
                '- Pacing: ${userProfile.pacingLevel.displayName}.\n'
                '- Always adapt all explanations to this grade level and strictly follow the teaching style.'
          },
        ],
      },
      'contents': contentsList,
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
