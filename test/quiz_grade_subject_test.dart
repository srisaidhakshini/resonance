import 'package:flutter_test/flutter_test.dart';
import 'package:echo/models/studio_items.dart';
import 'package:echo/models/user_profile.dart';
import 'package:echo/providers/user_profile_provider.dart';

void main() {
  group('Grade Formatting & UserProfileProvider Tests', () {
    test('formatGrade standardizes numbers and strings', () {
      expect(formatGrade('8'), 'Class 8');
      expect(formatGrade('10'), 'Class 10');
      expect(formatGrade('Class 12'), 'Class 12');
      expect(formatGrade(''), 'Class 8');
      expect(formatGrade(null), 'Class 8');
      expect(formatGrade('1'), 'Class 1');
      expect(formatGrade('6'), 'Class 6');
    });

    test('UserProfile copyWith updates grade correctly', () {
      final initial = UserProfile.defaults();
      expect(initial.grade, '8');

      final updated = initial.copyWith(grade: '10');
      expect(updated.grade, '10');
      expect(formatGrade(updated.grade), 'Class 10');
    });
  });

  group('Grade-Restricted Quizzes & Subject Switching Tests', () {
    final allDecks = StudioPreTemplates.getSampleQuizzes();

    test('All sample quizzes have non-empty gradeLevel and subject', () {
      expect(allDecks.isNotEmpty, isTrue);
      for (final deck in allDecks) {
        expect(deck.gradeLevel.isNotEmpty, isTrue);
        expect(deck.subject.isNotEmpty, isTrue);
        expect(deck.questions.isNotEmpty, isTrue);
        for (final q in deck.questions) {
          expect(q.question.isNotEmpty, isTrue);
          expect(q.options.isNotEmpty, isTrue);
          expect(q.correctOptionIndex, inInclusiveRange(0, q.options.length - 1));
        }
      }
    });

    test('Class 8 quizzes contain only Class 8 questions and multiple subjects', () {
      final class8Decks = allDecks.where((d) => d.gradeLevel == 'Class 8').toList();
      expect(class8Decks.isNotEmpty, isTrue);
      for (final d in class8Decks) {
        expect(d.gradeLevel, 'Class 8');
      }

      final subjects = class8Decks.map((d) => d.subject).toSet();
      expect(subjects.contains('Biology'), isTrue);
      expect(subjects.contains('Physics'), isTrue);
      expect(subjects.contains('Chemistry'), isTrue);
      expect(subjects.contains('Mathematics'), isTrue);

      // Switching to Physics filters strictly to Physics
      final physicsDecks = class8Decks.where((d) => d.subject == 'Physics').toList();
      expect(physicsDecks.isNotEmpty, isTrue);
      expect(physicsDecks.first.title, contains('Force'));
    });

    test('Class 10 quizzes contain only Class 10 questions and multiple subjects', () {
      final class10Decks = allDecks.where((d) => d.gradeLevel == 'Class 10').toList();
      expect(class10Decks.isNotEmpty, isTrue);
      for (final d in class10Decks) {
        expect(d.gradeLevel, 'Class 10');
      }

      final subjects = class10Decks.map((d) => d.subject).toSet();
      expect(subjects.contains('Physics'), isTrue);
      expect(subjects.contains('Chemistry'), isTrue);
      expect(subjects.contains('Mathematics'), isTrue);
      expect(subjects.contains('Biology'), isTrue);

      // Verify no Class 8 questions leak into Class 10
      expect(class10Decks.any((d) => d.id == 'qz_c8_micro'), isFalse);
    });

    test('Grades 1 through 7 each have valid sample quizzes and subjects', () {
      for (int g = 1; g <= 7; g++) {
        final gradeKey = 'Class $g';
        final decks = allDecks.where((d) => d.gradeLevel == gradeKey).toList();
        expect(decks.isNotEmpty, isTrue, reason: 'Expected quizzes for $gradeKey');
        final subjects = decks.map((d) => d.subject).toSet();
        expect(subjects.length, greaterThanOrEqualTo(2), reason: 'Expected multiple subjects for $gradeKey');
      }
    });

    test('Simulating Profile Grade Change switches available quizzes and subjects', () {
      // Step 1: User is Class 8
      String activeGrade = formatGrade('8');
      var visibleDecks = allDecks.where((d) => d.gradeLevel == activeGrade).toList();
      expect(visibleDecks.every((d) => d.gradeLevel == 'Class 8'), isTrue);

      // Step 2: User switches subject to 'Mathematics'
      String selectedSubject = 'Mathematics';
      var filtered = visibleDecks.where((d) => d.subject == selectedSubject).toList();
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.every((d) => d.subject == 'Mathematics' && d.gradeLevel == 'Class 8'), isTrue);

      // Step 3: User changes grade in Profile to '12'
      activeGrade = formatGrade('12');
      selectedSubject = 'All';
      visibleDecks = allDecks.where((d) => d.gradeLevel == activeGrade).toList();
      expect(visibleDecks.every((d) => d.gradeLevel == 'Class 12'), isTrue);
      expect(visibleDecks.any((d) => d.gradeLevel == 'Class 8'), isFalse);

      // Step 4: User switches subject to 'Computer Science'
      selectedSubject = 'Computer Science';
      filtered = visibleDecks.where((d) => d.subject == selectedSubject).toList();
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.first.title, contains('Cybersecurity'));
    });

    test('Quiz titles do not start with Class or Grade prefixes', () {
      for (final d in allDecks) {
        expect(
          d.title.startsWith(RegExp(r'^(?:Class|Grade)\s*\d+', caseSensitive: false)),
          isFalse,
          reason: 'Quiz title "${d.title}" should not start with Class or Grade',
        );
      }
    });
  });
}
