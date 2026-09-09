import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../models/learning_course.dart';
import '../models/subject.dart';
import 'chat_provider.dart';
import 'course_progress_provider.dart';
import 'subject_provider.dart';
import 'user_profile_provider.dart';

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
  final int completedLevelsCount;
  final int totalLevelsCount;

  const SubjectProgress({
    required this.subject,
    required this.progress,
    required this.sessionCount,
    this.completedLevelsCount = 0,
    this.totalLevelsCount = 0,
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
  final courseProgress = ref.watch(courseProgressProvider);
  final userProfile = ref.watch(userProfileNotifierProvider);

  final List<ChatSession> sessions = chatBox.values.toList()
    ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  final contents = contentBox.values.toList();

  // 1. Calculate Real Consecutive Study Streak Days
  final activeDates = <DateTime>{};
  for (final s in sessions) {
    final d = s.lastUpdated;
    activeDates.add(DateTime(d.year, d.month, d.day));
  }
  for (final c in contents) {
    final d = c.createdAt;
    activeDates.add(DateTime(d.year, d.month, d.day));
  }

  int streak = 0;
  if (activeDates.isNotEmpty) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (activeDates.contains(today)) {
      streak = 1;
      var checkDate = yesterday;
      while (activeDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (activeDates.contains(yesterday)) {
      streak = 1;
      var checkDate = yesterday.subtract(const Duration(days: 1));
      while (activeDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      streak = 0;
    }
  }

  // 2. Total Sessions & Messages (Chat sessions + Completed course levels)
  int totalCompletedLevelsAcrossAllCourses = 0;
  for (final levels in courseProgress.completedLevels.values) {
    totalCompletedLevelsAcrossAllCourses += levels.length;
  }

  final totalSessions = sessions.length + totalCompletedLevelsAcrossAllCourses;
  int totalMessages = 0;
  for (final s in sessions) {
    totalMessages += s.messages.length;
  }

  // Helper keyword getter for intelligent domain matching
  List<String> getDomainKeywords(String subId, String subName) {
    final id = subId.toLowerCase();
    final name = subName.toLowerCase();

    if (id == 'math' || name.contains('math')) {
      return [
        'math', 'algebra', 'geometry', 'calculus', 'equation', 'quadratic',
        'polynomial', 'derivative', 'integral', 'triangle', 'theorem',
        'fraction', 'decimal', 'arithmetic', 'matrix', 'probability',
        'trigonometry', 'pythagor', 'logarithm', 'exponent', 'formula',
        'linear equation', 'functions', 'coordinates', 'numbers', 'solve for',
      ];
    } else if (id == 'science' || name.contains('science')) {
      return [
        'science', 'physics', 'chemistry', 'biology', 'photosynthesis',
        'newton', 'gravity', 'velocity', 'force', 'energy', 'atom',
        'molecule', 'cell', 'reaction', 'periodic table', 'electric',
        'circuit', 'ohm', 'acid', 'base', 'thermodynamics', 'light',
        'optics', 'magnet', 'dna', 'genetics', 'ecosystem', 'organism',
      ];
    } else if (id == 'english' || name.contains('english') || name.contains('lit')) {
      return [
        'english', 'grammar', 'essay', 'literature', 'novel', 'poem',
        'poetry', 'author', 'writing', 'paragraph', 'thesis', 'metaphor',
        'rhetoric', 'vocabulary', 'sentence', 'punctuation', 'analysis',
        'comprehension', 'theme', 'character', 'motif', 'narrative',
      ];
    } else if (id == 'social' || name.contains('social') || name.contains('history') || name.contains('civic') || name.contains('geo')) {
      return [
        'social studies', 'history', 'civics', 'geography', 'civilization',
        'constitution', 'democracy', 'government', 'revolution', 'treaty',
        'parliament', 'rights', 'duties', 'election', 'ancient', 'empire',
        'colonial', 'medieval', 'republic', 'war', 'culture', 'continent',
      ];
    }

    return name.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
  }

  bool isSessionForSubject(
    Subject subject,
    List<LearningCourse> courses,
    ChatSession session,
  ) {
    final sName = subject.name.toLowerCase().trim();
    final sId = subject.id.toLowerCase().trim();

    // 1. Explicit subject match on session
    if (session.subject != null && session.subject!.trim().isNotEmpty) {
      final sSubject = session.subject!.toLowerCase().trim();
      if (sSubject == sName || sSubject == sId || sName.contains(sSubject) || sSubject.contains(sName)) {
        return true;
      }
    }

    final titleLower = session.title.toLowerCase();
    if (titleLower.contains(sName) || titleLower.contains(sId)) return true;

    final keywords = getDomainKeywords(sId, sName);
    for (final kw in keywords) {
      if (titleLower.contains(kw)) return true;
    }

    for (final c in courses) {
      if (titleLower.contains(c.title.toLowerCase())) return true;
      for (final lvl in c.levels) {
        if (titleLower.contains(lvl.title.toLowerCase())) return true;
      }
    }

    // Check message contents
    for (final msg in session.messages) {
      final msgLower = msg.content.toLowerCase();
      if (msgLower.contains(sName)) return true;
      for (final kw in keywords) {
        if (msgLower.contains(kw)) return true;
      }
      for (final c in courses) {
        if (msgLower.contains(c.title.toLowerCase())) return true;
        for (final lvl in c.levels) {
          if (msgLower.contains(lvl.title.toLowerCase())) return true;
        }
      }
    }

    return false;
  }

  // 3. Subject Mastery
  final subjectMastery = <SubjectProgress>[];
  final completedLevelsList = <TopicItem>[];
  final inProgressLevelsList = <TopicItem>[];

  for (final subject in subjects) {
    final courses = CourseRepository.getCoursesForSubject(
      subject.name,
      grade: userProfile.grade,
      subjectId: subject.id,
    );

    int totalSubjectLevels = 0;
    int completedSubjectLevels = 0;

    for (final c in courses) {
      totalSubjectLevels += c.levels.length;
      final completedNums = courseProgress.completedLevels[c.id] ?? [];
      completedSubjectLevels += completedNums.length;

      // Track mastered levels for Completed Topics
      for (final lvlNum in completedNums) {
        final lvl = c.levels.firstWhere(
          (l) => l.levelNumber == lvlNum,
          orElse: () => c.levels.first,
        );
        completedLevelsList.add(TopicItem(
          id: '${c.id}_lvl_$lvlNum',
          title: lvl.title,
          subjectName: subject.name,
          date: DateTime.now(),
          status: 'Mastered',
          prompt: 'Let\'s review key concepts from "${lvl.title}" in ${subject.name}.',
        ));
      }

      // Track active uncompleted level for Study Focus
      final activeLevelNum = courseProgress.activeLevels[c.id] ??
          (completedNums.isEmpty ? 1 : (completedNums.last + 1).clamp(1, c.levels.length));
      if (!completedNums.contains(activeLevelNum) && activeLevelNum <= c.levels.length) {
        final activeLvl = c.levels.firstWhere(
          (l) => l.levelNumber == activeLevelNum,
          orElse: () => c.levels.first,
        );
        inProgressLevelsList.add(TopicItem(
          id: '${c.id}_lvl_$activeLevelNum',
          title: activeLvl.title,
          subjectName: subject.name,
          date: DateTime.now(),
          status: 'In Progress',
          prompt: 'Let\'s study "${activeLvl.title}" from ${c.title}. Can you explain the core concepts?',
        ));
      }
    }

    // Match sessions
    final matchedSessions = sessions.where((s) => isSessionForSubject(subject, courses, s)).toList();
    final engagedSessions = matchedSessions.where((s) => s.messages.length >= 2).length;
    final totalSubjectMessages = matchedSessions.fold<int>(0, (sum, s) => sum + s.messages.length);

    // Dynamic progress calculation:
    // Pure 0.0 when user hasn't studied or completed anything in this subject.
    // Course curriculum completion gives structured progression.
    // Practice conversations & doubt-clearing add real engagement mastery.
    double calculatedProgress = 0.0;
    if (totalSubjectLevels > 0) {
      final curriculumRatio = completedSubjectLevels / totalSubjectLevels;
      final practiceRatio = (engagedSessions * 0.06 + totalSubjectMessages * 0.005).clamp(0.0, 0.35);

      if (completedSubjectLevels == totalSubjectLevels) {
        calculatedProgress = 1.0;
      } else {
        calculatedProgress = (curriculumRatio * 0.75 + practiceRatio).clamp(0.0, 1.0);
      }
    } else {
      calculatedProgress = (engagedSessions * 0.1).clamp(0.0, 1.0);
    }

    final totalActivities = completedSubjectLevels + matchedSessions.length;

    subjectMastery.add(SubjectProgress(
      subject: subject,
      progress: calculatedProgress,
      sessionCount: totalActivities,
      completedLevelsCount: completedSubjectLevels,
      totalLevelsCount: totalSubjectLevels,
    ));
  }

  // 4. Completed Topics Count
  final completedTopicsCount = completedLevelsList.length +
      sessions.where((s) => s.messages.length >= 4).length +
      contents.length;

  // 5. Accuracy: dynamically derived from completion performance
  final totalWorkUnits = totalSessions + completedTopicsCount;
  final estimatedAccuracy = totalWorkUnits > 0
      ? ((completedTopicsCount / totalWorkUnits) * 100).round().clamp(0, 100)
      : 0;

  // 6. Recent Topics from actual sessions
  final recentTopics = <TopicItem>[];
  for (final s in sessions.take(6)) {
    String matchedSubject = s.subject ?? 'General';
    if (matchedSubject == 'General') {
      for (final sub in subjects) {
        final courses = CourseRepository.getCoursesForSubject(
          sub.name,
          grade: userProfile.grade,
          subjectId: sub.id,
        );
        if (isSessionForSubject(sub, courses, s)) {
          matchedSubject = sub.name;
          break;
        }
      }
    }
    final isMastered = s.messages.length >= 6;
    recentTopics.add(TopicItem(
      id: s.id,
      title: s.title,
      subjectName: matchedSubject,
      date: s.lastUpdated,
      status: isMastered ? 'Mastered' : 'In Progress',
      prompt: 'Let\'s review "${s.title}" and continue where we left off.',
    ));
  }

  // 7. Needs Practice & Mastered Lists
  // Needs practice: in-progress course levels + active sessions
  final needsPractice = <TopicItem>[
    ...inProgressLevelsList,
    ...recentTopics.where((t) => t.status != 'Mastered'),
  ];

  // Mastered topics: genuinely completed course levels + deep dive sessions
  final mastered = <TopicItem>[
    ...completedLevelsList,
    ...recentTopics.where((t) => t.status == 'Mastered'),
  ];

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
