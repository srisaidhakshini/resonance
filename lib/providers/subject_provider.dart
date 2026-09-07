import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

const String _kSubjectsStorageKey = 'pocket_tutor_user_subjects_v1';

final List<Subject> _kDefaultSubjects = [
  Subject(
    id: 'math',
    name: 'Mathematics',
    description: 'Algebra, Geometry, Calculus',
    iconCodePoint: Icons.calculate_outlined.codePoint,
    colorValue: AppColors.chart1.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
  ),
  Subject(
    id: 'science',
    name: 'Science',
    description: 'Physics, Chemistry, Biology',
    iconCodePoint: Icons.science_outlined.codePoint,
    colorValue: AppColors.chart3.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
  ),
  Subject(
    id: 'english',
    name: 'English',
    description: 'Grammar, Writing, Literature',
    iconCodePoint: Icons.menu_book_rounded.codePoint,
    colorValue: AppColors.chart4.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
  ),
  Subject(
    id: 'social',
    name: 'Social Studies',
    description: 'History, Civics, Geography',
    iconCodePoint: Icons.public_rounded.codePoint,
    colorValue: AppColors.chart5.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
  ),
];

class SubjectNotifier extends StateNotifier<List<Subject>> {
  SubjectNotifier() : super(_kDefaultSubjects) {
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSubjectsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        final loaded = decoded
            .map((item) => Subject.fromMap(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) {
          state = loaded;
          return;
        }
      }
      // If not stored yet, save default list
      await _saveSubjects(state);
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  Future<void> _saveSubjects(List<Subject> subjects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = subjects.map((s) => s.toMap()).toList();
      await prefs.setString(_kSubjectsStorageKey, json.encode(mapped));
    } catch (e) {
      debugPrint('Error saving subjects: $e');
    }
  }

  Future<Subject> addSubject({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    final newSubject = Subject(
      id: const Uuid().v4(),
      name: name.trim(),
      description: description.trim(),
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
    );

    final updated = [...state, newSubject];
    state = updated;
    await _saveSubjects(updated);
    return newSubject;
  }

  Future<void> deleteSubject(String id) async {
    final updated = state.where((s) => s.id != id).toList();
    state = updated;
    await _saveSubjects(updated);
  }

  Future<void> updateSubject(Subject subject) async {
    final updated = state.map((s) => s.id == subject.id ? subject : s).toList();
    state = updated;
    await _saveSubjects(updated);
  }
}

final subjectNotifierProvider =
    StateNotifierProvider<SubjectNotifier, List<Subject>>((ref) {
  return SubjectNotifier();
});
