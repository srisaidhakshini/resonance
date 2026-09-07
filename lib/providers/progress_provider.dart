import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../models/subject.dart';
import 'chat_provider.dart';
import 'subject_provider.dart';

class ProgressMetrics {
  final int studyStreakDays;
  final int totalSessions;
  final int totalMessages;
  final int completedTopicsCount;
  final int estimatedAccuracy;
  final List<SubjectProgress> subjectMastery;
  final List<TopicItem> recentTopics;
  final List<TopicItem> needsPracticeTopics;
  final List<TopicItem> masteredTopics;

  const ProgressMetrics({
    required this.studyStreakDays,
    required this.totalSessions,
    required this.totalMessages,
    required this.completedTopicsCount,
    required this.estimatedAccuracy,
    required this.subjectMastery,
    required this.recentTopics,
    required this.needsPracticeTopics,
    required this.masteredTopics,
  });
}

class SubjectProgress {
  final Subject subject;
  final double progress;
  final int sessionCount;

  const SubjectProgress({
    required this.subject,
    required this.progress,
    required this.sessionCount,
  });
}

class TopicItem {
  final String id;
  final String title;
  final String subjectName;
  final DateTime date;
  final String status;
  final String prompt;

  const TopicItem({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.date,
    required this.status,
    required this.prompt,
  });
}

final progressMetricsProvider = Provider<ProgressMetrics>((ref) {
  final chatBox = ref.watch(chatBoxProvider);
  final contentBox = ref.watch(contentBoxProvider);
  final subjects = ref.watch(subjectNotifierProvider);

  final List<ChatSession> sessions = chatBox.values.toList()
    ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  final contents = contentBox.values.toList();

  // 1. Calculate Streak Days
  int streak = 0;
  if (sessions.isNotEmpty) {
    final activeDates = <String>{};
    for (final s in sessions) {
      final d = s.lastUpdated;
      activeDates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
    streak = activeDates.length;
  }

  // 2. Total Sessions & Messages
  final totalSessions = sessions.length;
  int totalMessages = 0;
  for (final s in sessions) {
    totalMessages += s.messages.length;
  }

  // 3. Completed Topics
  final completedTopicsCount = sessions.where((s) => s.messages.length >= 2).length + contents.length;

  // 4. Accuracy
  final estimatedAccuracy = totalSessions > 0 ? (75 + (completedTopicsCount * 2)).clamp(70, 98) : 0;

  // 5. Subject Mastery
  final subjectMastery = <SubjectProgress>[];
  for (final subject in subjects) {
    final sName = subject.name.toLowerCase();
    int count = 0;
    for (final s in sessions) {
      if ((s.subject != null && s.subject!.toLowerCase() == sName) ||
          s.title.toLowerCase().contains(sName) ||
          s.messages.any((m) => m.content.toLowerCase().contains(sName))) {
        count++;
      }
    }
    for (final c in contents) {
      if (c.title.toLowerCase().contains(sName)) {
        count += 2;
      }
    }
    final progress = count > 0 ? (count * 0.2).clamp(0.15, 1.0) : 0.0;
    subjectMastery.add(SubjectProgress(
      subject: subject,
      progress: progress,
      sessionCount: count,
    ));
  }

  // 6. Recent Topics from actual sessions
  final recentTopics = <TopicItem>[];
  for (final s in sessions.take(6)) {
    String matchedSubject = s.subject ?? 'General';
    if (matchedSubject == 'General') {
      for (final sub in subjects) {
        if (s.title.toLowerCase().contains(sub.name.toLowerCase())) {
          matchedSubject = sub.name;
          break;
        }
      }
    }
    recentTopics.add(TopicItem(
      id: s.id,
      title: s.title,
      subjectName: matchedSubject,
      date: s.lastUpdated,
      status: s.messages.length > 4 ? 'Mastered' : 'In Progress',
      prompt: 'Let\'s review "${s.title}" and continue where we left off.',
    ));
  }

  // 7. Needs Practice & Mastered
  final needsPractice = recentTopics.where((t) => t.status != 'Mastered').toList();
  final mastered = recentTopics.where((t) => t.status == 'Mastered').toList();

  return ProgressMetrics(
    studyStreakDays: streak,
    totalSessions: totalSessions,
    totalMessages: totalMessages,
    completedTopicsCount: completedTopicsCount,
    estimatedAccuracy: estimatedAccuracy,
    subjectMastery: subjectMastery,
    recentTopics: recentTopics,
    needsPracticeTopics: needsPractice,
    masteredTopics: mastered,
  );
});
