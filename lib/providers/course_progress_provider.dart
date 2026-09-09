import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning_course.dart';

const String _kCourseProgressStorageKey = 'pocket_tutor_course_progress_v2';

class CourseProgressData {
  /// Map of courseId -> list of completed level numbers (e.g. [1, 2])
  final Map<String, List<int>> completedLevels;

  /// Map of courseId -> current active level number (defaults to lowest uncompleted, e.g. 3)
  final Map<String, int> activeLevels;

  /// ID of the course the user was most recently viewing/studying
  final String? lastActiveCourseId;

  const CourseProgressData({
    this.completedLevels = const {},
    this.activeLevels = const {},
    this.lastActiveCourseId,
  });

  CourseProgressData copyWith({
    Map<String, List<int>>? completedLevels,
    Map<String, int>? activeLevels,
    String? lastActiveCourseId,
  }) {
    return CourseProgressData(
      completedLevels: completedLevels ?? this.completedLevels,
      activeLevels: activeLevels ?? this.activeLevels,
      lastActiveCourseId: lastActiveCourseId ?? this.lastActiveCourseId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completedLevels': completedLevels,
      'activeLevels': activeLevels,
      'lastActiveCourseId': lastActiveCourseId,
    };
  }

  factory CourseProgressData.fromMap(Map<String, dynamic> map) {
    final rawCompleted = map['completedLevels'] as Map<String, dynamic>? ?? {};
    final completed = <String, List<int>>{};
    rawCompleted.forEach((k, v) {
      if (v is List) {
        completed[k] = v.map((e) => e as int).toList();
      }
    });

    final rawActive = map['activeLevels'] as Map<String, dynamic>? ?? {};
    final active = <String, int>{};
    rawActive.forEach((k, v) {
      if (v is int) {
        active[k] = v;
      }
    });

    return CourseProgressData(
      completedLevels: completed,
      activeLevels: active,
      lastActiveCourseId: map['lastActiveCourseId'] as String?,
    );
  }
}

class CourseProgressNotifier extends StateNotifier<CourseProgressData> {
  CourseProgressNotifier() : super(const CourseProgressData()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCourseProgressStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        state = CourseProgressData.fromMap(decoded);
      } else {
        // No saved progress yet: every level starts genuinely locked/untouched.
        // Progress is only ever set by the user actually completing a level.
        state = const CourseProgressData();
        await _saveProgress(state);
      }
    } catch (_) {}
  }

  Future<void> _saveProgress(CourseProgressData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCourseProgressStorageKey, json.encode(data.toMap()));
    } catch (_) {}
  }

  /// Completes [levelNumber] for [courseId] and dynamically unlocks the next level.
  Future<void> completeLevel(String courseId, int levelNumber, {int totalLevels = 5}) async {
    final currentCompleted = List<int>.from(state.completedLevels[courseId] ?? []);
    if (!currentCompleted.contains(levelNumber)) {
      currentCompleted.add(levelNumber);
      currentCompleted.sort();
    }

    // Advance active level to the next uncompleted level
    int nextActive = levelNumber + 1;
    while (currentCompleted.contains(nextActive) && nextActive <= totalLevels) {
      nextActive++;
    }
    if (nextActive > totalLevels) {
      nextActive = totalLevels; // all complete
    }

    final newCompletedMap = Map<String, List<int>>.from(state.completedLevels);
    newCompletedMap[courseId] = currentCompleted;

    final newActiveMap = Map<String, int>.from(state.activeLevels);
    newActiveMap[courseId] = nextActive;

    final updated = state.copyWith(
      completedLevels: newCompletedMap,
      activeLevels: newActiveMap,
      lastActiveCourseId: courseId,
    );

    state = updated;
    await _saveProgress(updated);
  }

  /// Sets the currently active course ID
  Future<void> setLastActiveCourse(String courseId) async {
    final updated = state.copyWith(lastActiveCourseId: courseId);
    state = updated;
    await _saveProgress(updated);
  }

  /// Gets the list of completed level numbers for a course
  List<int> getCompletedLevels(String courseId) {
    return state.completedLevels[courseId] ?? [];
  }

  /// Gets the active level number (1-based)
  int getActiveLevel(String courseId, {int totalLevels = 5}) {
    final stored = state.activeLevels[courseId];
    if (stored != null) return stored;
    final completed = getCompletedLevels(courseId);
    return completed.isEmpty ? 1 : (completed.last + 1).clamp(1, totalLevels);
  }

  /// Computes dynamic progress percentage [0..100]
  int getCourseProgressPercent(String courseId, int totalLevels) {
    if (totalLevels <= 0) return 0;
    final completedCount = getCompletedLevels(courseId).length;
    return ((completedCount / totalLevels) * 100).round().clamp(0, 100);
  }

  /// Computes dynamic subject-wide progress percentage [0..100]
  int getSubjectProgressPercent(List<LearningCourse> courses) {
    if (courses.isEmpty) return 0;
    int totalLevels = 0;
    int completedLevels = 0;
    for (final c in courses) {
      totalLevels += c.levels.length;
      completedLevels += getCompletedLevels(c.id).length;
    }
    if (totalLevels == 0) return 0;
    return ((completedLevels / totalLevels) * 100).round().clamp(0, 100);
  }
}

final courseProgressProvider =
    StateNotifierProvider<CourseProgressNotifier, CourseProgressData>((ref) {
  return CourseProgressNotifier();
});
