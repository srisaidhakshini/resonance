import '../models/chat_message.dart';
import '../models/content_chunk.dart';
import '../models/studio_items.dart';
import '../models/study_content.dart';
import 'llm_service.dart';
import 'prompt_builder.dart';

/// Turns ingested content or a chat conversation into a short kinetic
/// typography video script by prompting the on-device LLM for a small
/// number of title+bullets+narration segments, then parsing its (often
/// imperfect) structured text output defensively.
///
/// Unlike [ChatToStudioGenerator]'s siblings, this generator actually calls
/// the LLM rather than deriving content with regex/templates - so every
/// public entry point falls back to a deterministic template on failure
/// (model not loaded, empty/garbled output) instead of surfacing an error.
class VideoScriptGenerator {
  static const int _maxSourceChars = 1400;
  static const int _minSegmentsForSuccess = 2;
  static const int _maxSegments = 6;

  /// Generates a video script summarizing an active chat conversation.
  static Future<KineticVideoScript> generateFromChat(
    List<ChatMessage> messages,
    LLMService llmService,
  ) async {
    final topic = _detectChatTopic(messages);
    final sourceText = _buildChatSourceText(messages);
    return _generate(topic: topic, sourceText: sourceText, llmService: llmService);
  }

  /// Generates a video script summarizing an ingested study document.
  static Future<KineticVideoScript> generateFromStudyContent(
    StudyContent content,
    LLMService llmService,
  ) async {
    final sourceText = _buildDocumentSourceText(content);
    return _generate(topic: content.title, sourceText: sourceText, llmService: llmService);
  }

  static String _detectChatTopic(List<ChatMessage> messages) {
    for (final m in messages.reversed) {
      if (m.role == 'user' && m.content.trim().isNotEmpty) {
        var title = m.content.trim().split(RegExp(r'[\n.?!]')).first.trim();
        if (title.length > 48) title = '${title.substring(0, 46)}...';
        return title.isEmpty ? 'Study Session Recap' : title;
      }
    }
    return 'Study Session Recap';
  }

  static String _buildChatSourceText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final m in messages.reversed) {
      if (m.role != 'user' && m.content.trim().isNotEmpty && m.content.trim() != '...') {
        buffer.writeln(m.content.trim());
        if (buffer.length >= _maxSourceChars) break;
      }
    }
    final text = buffer.toString().trim();
    return text.length > _maxSourceChars ? text.substring(0, _maxSourceChars) : text;
  }

  static String _buildDocumentSourceText(StudyContent content) {
    final buffer = StringBuffer();
    final ordered = List<ContentChunk>.from(content.chunks)..sort((a, b) => a.index.compareTo(b.index));
    for (final chunk in ordered) {
      if (buffer.length >= _maxSourceChars) break;
      buffer.writeln(chunk.text.trim());
    }
    final text = buffer.toString().trim();
    return text.length > _maxSourceChars ? text.substring(0, _maxSourceChars) : text;
  }

  static Future<KineticVideoScript> _generate({
    required String topic,
    required String sourceText,
    required LLMService llmService,
  }) async {
    if (sourceText.trim().isEmpty) {
      return _fallbackScript(topic);
    }

    try {
      // Deliberately NOT streamResponse: that method wraps input as a Q&A
      // "answer this question using the reference material" turn, injects
      // the tutor persona + a style few-shot example, and permanently logs
      // both sides into the user's real chat history - all of which fight
      // a plain reformatting task and reportedly caused the model to ignore
      // the requested format and fall back to the same generic template
      // every time. generateStructuredContent is a stateless, persona-free
      // one-shot call built specifically for this.
      const systemPrompt =
          'You are a formatting engine with no persona. You never ask '
          'questions, never add commentary, and never refuse. You output '
          'ONLY the exact plain-text format requested - nothing before or '
          'after it.';

      final userPrompt =
          'Study material:\n"""\n$sourceText\n"""\n\n'
          'Task: turn the study material above into a short video script of '
          '4 to 6 segments for a student. Output ONLY plain text in exactly '
          'this format, with no extra words:\n\n'
          '### SEGMENT 1\n'
          'TITLE: <short headline, under 6 words>\n'
          'BULLET: <short phrase>\n'
          'BULLET: <short phrase>\n'
          'BULLET: <short phrase, optional>\n'
          'NARRATION: <1-2 spoken sentences explaining this segment>\n'
          '### SEGMENT 2\n'
          '...continue the same pattern for each segment.';

      final response = await llmService.generateStructuredContent(
        systemPrompt,
        PromptBuilder.sanitizeForPrompt(userPrompt),
      );

      final segments = _parseSegments(response);
      if (segments.length < _minSegmentsForSuccess) {
        return _fallbackScript(topic);
      }

      return KineticVideoScript(
        id: 'video_gen_${DateTime.now().millisecondsSinceEpoch}',
        title: topic,
        topic: topic,
        gradeLevel: 'From Content',
        themeIndex: topic.length % StudioPalettes.all.length,
        segments: segments,
      );
    } catch (_) {
      return _fallbackScript(topic);
    }
  }

  /// Tolerant parser for the LLM's plain-text segment format. A 1.5B model
  /// will not always follow the format exactly, so this: splits on the
  /// "### SEGMENT" marker, pulls TITLE/BULLET/NARRATION lines by prefix
  /// regardless of ordering or extra chatter, skips segments missing a
  /// title or narration, and drops a trailing segment cut short by
  /// truncated generation instead of failing outright.
  static List<VideoSegment> _parseSegments(String raw) {
    final blocks = raw.split(RegExp(r'#{1,3}\s*SEGMENT\s*\d*', caseSensitive: false));
    final segments = <VideoSegment>[];

    for (final block in blocks) {
      if (block.trim().isEmpty) continue;

      String? title;
      String? narration;
      final bullets = <String>[];

      for (final line in block.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final titleMatch = RegExp(r'^TITLE\s*:\s*(.+)$', caseSensitive: false).firstMatch(trimmed);
        final bulletMatch = RegExp(r'^BULLET\s*:\s*(.+)$', caseSensitive: false).firstMatch(trimmed);
        final narrationMatch = RegExp(r'^NARRATION\s*:\s*(.+)$', caseSensitive: false).firstMatch(trimmed);

        if (titleMatch != null) {
          title = titleMatch.group(1)!.trim();
        } else if (bulletMatch != null) {
          final bullet = bulletMatch.group(1)!.trim();
          if (bullet.isNotEmpty) bullets.add(bullet);
        } else if (narrationMatch != null) {
          narration = narrationMatch.group(1)!.trim();
        }
      }

      if (title != null && title.isNotEmpty && narration != null && narration.isNotEmpty && bullets.isNotEmpty) {
        segments.add(
          VideoSegment(
            segmentNumber: segments.length + 1,
            title: title,
            bulletPoints: bullets.take(4).toList(),
            narration: narration,
          ),
        );
      }

      if (segments.length >= _maxSegments) break;
    }

    return segments;
  }

  static KineticVideoScript _fallbackScript(String topic) {
    return KineticVideoScript(
      id: 'video_fallback_${DateTime.now().millisecondsSinceEpoch}',
      title: topic,
      topic: topic,
      gradeLevel: 'From Content',
      themeIndex: topic.length % StudioPalettes.all.length,
      segments: [
        VideoSegment(
          segmentNumber: 1,
          title: topic,
          bulletPoints: const [
            'Core concepts synthesized from your material',
            'A quick recap of the key ideas',
          ],
          narration: "Here's a quick recap of $topic, covering the core ideas from your material.",
        ),
        const VideoSegment(
          segmentNumber: 2,
          title: 'Why It Matters',
          bulletPoints: [
            'Connects to related concepts',
            'Useful for exam-style questions',
          ],
          narration: 'Understanding this well makes it easier to connect related ideas and answer exam-style questions with confidence.',
        ),
      ],
    );
  }
}
