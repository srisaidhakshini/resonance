import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo/models/chat_message.dart';
import 'package:echo/models/chat_session.dart';
import 'package:echo/models/content_chunk.dart';
import 'package:echo/models/study_content.dart';
import 'package:echo/providers/chat_provider.dart';
import 'package:echo/providers/course_progress_provider.dart';
import 'package:echo/providers/progress_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ChatMessageAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ChatSessionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ContentChunkAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StudyContentAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ContentSourceTypeAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Dynamic Progress Metrics Tests', () {
    test('Calculates real dynamic metrics from sessions and course progress', () async {
      final chatBox = await Hive.openBox<ChatSession>('test_chat_box_${DateTime.now().millisecondsSinceEpoch}');
      final contentBox = await Hive.openBox<StudyContent>('test_content_box_${DateTime.now().millisecondsSinceEpoch}');

      final container = ProviderContainer(
        overrides: [
          chatBoxProvider.overrideWithValue(chatBox),
          contentBoxProvider.overrideWithValue(contentBox),
        ],
      );

      // Initial state with 0 sessions
      var metrics = container.read(progressMetricsProvider);
      expect(metrics.studyStreakDays, 0);
      expect(metrics.totalSessions, 0);
      expect(metrics.totalMessages, 0);
      for (final sp in metrics.subjectMastery) {
        expect(sp.progress, 0.0);
      }

      // Add 1 chat session with 4 messages about Math
      final mathSession = ChatSession(
        id: 'session_1',
        title: 'Solving Linear Equations',
        messages: [
          ChatMessage(role: 'user', content: 'How do I solve 3x + 5 = 20?', timestamp: DateTime.now()),
          ChatMessage(role: 'assistant', content: 'Subtract 5 from both sides: 3x = 15, then divide by 3: x = 5.', timestamp: DateTime.now()),
          ChatMessage(role: 'user', content: 'Can we try another quadratic equation?', timestamp: DateTime.now()),
          ChatMessage(role: 'assistant', content: 'Sure! Let us look at x^2 - 4 = 0.', timestamp: DateTime.now()),
        ],
        lastUpdated: DateTime.now(),
        subject: 'Mathematics',
      );
      await chatBox.put(mathSession.id, mathSession);

      // Re-read metrics
      metrics = container.read(progressMetricsProvider);
      expect(metrics.studyStreakDays, 1);
      expect(metrics.totalSessions, 1);
      expect(metrics.totalMessages, 4);

      final mathProgress = metrics.subjectMastery.firstWhere((s) => s.subject.name == 'Mathematics');
      expect(mathProgress.progress, greaterThan(0.0));
      expect(mathProgress.sessionCount, greaterThan(0));

      // Subjects with no activity must remain strictly 0.0
      final englishProgress = metrics.subjectMastery.firstWhere((s) => s.subject.name == 'English');
      expect(englishProgress.progress, 0.0);
      expect(englishProgress.sessionCount, 0);

      // Complete a level in Algebra
      await container.read(courseProgressProvider.notifier).completeLevel('math_algebra', 1, totalLevels: 5);

      metrics = container.read(progressMetricsProvider);
      expect(metrics.totalSessions, 2); // 1 chat session + 1 completed level
      expect(metrics.masteredTopics.any((t) => t.title.contains('Variables') || t.title.contains('Expressions')), isTrue);

      container.dispose();
      await chatBox.close();
      await contentBox.close();
    });
  });
}
