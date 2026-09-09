import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_recommendation.dart';
import 'internet_service.dart';

/// Intelligent video recommendation service.
/// Fetches curated YouTube educational videos matching the student's doubt when online.
class VideoRecommendationService {
  static VideoRecommendationService? _instance;
  final InternetService _internetService;
  final Dio _dio;

  VideoRecommendationService({
    InternetService? internetService,
    Dio? dio,
  })  : _internetService = internetService ?? InternetService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  static VideoRecommendationService get instance {
    _instance ??= VideoRecommendationService();
    return _instance!;
  }

  /// Extracts clean educational search terms from chat messages and user doubts.
  static String extractCleanTopic(String doubt, {String? aiResponse}) {
    String clean = doubt
        .replaceAll(RegExp(r'^(help with homework:|explain a concept:|take a quiz on:|summarize:)', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(what is|can you explain|tell me about|how to solve|define)\s+', caseSensitive: false), '')
        .trim();

    if (clean.length > 60) {
      clean = clean.substring(0, 60);
    }

    if (clean.isEmpty && aiResponse != null && aiResponse.isNotEmpty) {
      // Pick the first line of the AI response as fallback topic
      clean = aiResponse.split('\n').first.replaceAll(RegExp(r'[#*`_]'), '').trim();
      if (clean.length > 50) clean = clean.substring(0, 50);
    }

    return clean.isEmpty ? 'Science & Math concepts' : clean;
  }

  /// Searches and retrieves video recommendations when online.
  /// If offline or if query yields no results, safely returns an empty list.
  Future<List<VideoRecommendation>> getRecommendations(
    String query, {
    int maxResults = 3,
  }) async {
    final hasNet = await _internetService.hasInternet();
    if (!hasNet) {
      if (kDebugMode) print('📴 [VIDEO_REC] Device offline. Skipping video recommendations.');
      return [];
    }

    try {
      final cleanTopic = extractCleanTopic(query);
      final searchQuery = Uri.encodeComponent('$cleanTopic animation lesson explanation');

      if (kIsWeb) {
        // In Web environment, route through our server proxy to avoid CORS
        final proxyUrl = '/api/youtube?q=$searchQuery&max=$maxResults';
        final resp = await _dio.get(proxyUrl);
        if (resp.statusCode == 200 && resp.data is List) {
          final list = (resp.data as List)
              .map((item) => VideoRecommendation.fromJson(item as Map<String, dynamic>))
              .toList();
          return list;
        }
      }

      // Direct YouTube Search parsing
      final ytUrl = 'https://www.youtube.com/results?search_query=$searchQuery';
      final response = await _dio.get(
        ytUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );

      final html = response.data.toString();
      final videos = <VideoRecommendation>[];

      // Parse JSON from ytInitialData
      final regExp = RegExp(r'var ytInitialData = ({.*?});</script>');
      final match = regExp.firstMatch(html);

      if (match != null) {
        try {
          final data = jsonDecode(match.group(1)!);
          final contents = data['contents']?['twoColumnSearchResultsRenderer']
              ?['primaryContents']?['sectionListRenderer']?['contents'] as List?;

          if (contents != null) {
            for (final section in contents) {
              final items = section['itemSectionRenderer']?['contents'] as List?;
              if (items != null) {
                for (final item in items) {
                  final vr = item['videoRenderer'];
                  if (vr != null && vr['videoId'] != null) {
                    final vid = vr['videoId'].toString();
                    final title = vr['title']?['runs']?[0]?['text']?.toString() ?? 'Learning Video';
                    final channel = vr['ownerText']?['runs']?[0]?['text']?.toString() ?? 'Educational Channel';
                    final duration = vr['lengthText']?['simpleText']?.toString() ?? '';
                    final thumb = 'https://img.youtube.com/vi/$vid/hqdefault.jpg';

                    videos.add(
                      VideoRecommendation(
                        id: vid,
                        title: title,
                        channel: channel,
                        thumbnail: thumb,
                        duration: duration,
                        url: 'https://www.youtube.com/watch?v=$vid',
                      ),
                    );

                    if (videos.length >= maxResults) return videos;
                  }
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ [VIDEO_REC] Failed parsing initial data: $e');
        }
      }

      // Regex fallback if structured initialData was absent
      if (videos.isEmpty) {
        final idMatches = RegExp(r'/watch\?v=([a-zA-Z0-9_-]{11})').allMatches(html);
        final seen = <String>{};
        for (final m in idMatches) {
          final vid = m.group(1)!;
          if (!seen.contains(vid)) {
            seen.add(vid);
            videos.add(
              VideoRecommendation(
                id: vid,
                title: '$cleanTopic (Video Lesson)',
                channel: 'YouTube Learning',
                thumbnail: 'https://img.youtube.com/vi/$vid/hqdefault.jpg',
                duration: '',
                url: 'https://www.youtube.com/watch?v=$vid',
              ),
            );
            if (videos.length >= maxResults) break;
          }
        }
      }

      return videos;
    } catch (e) {
      if (kDebugMode) print('⚠️ [VIDEO_REC] Error fetching video recommendations: $e');
      return [];
    }
  }

  /// Launch the video URL in external browser or YouTube app.
  static Future<bool> launchVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) print('❌ [VIDEO_REC] Could not launch video URL: $e');
      return false;
    }
  }
}
