import 'package:flutter_test/flutter_test.dart';
import 'package:echo/models/learning_course.dart';
import 'package:echo/providers/course_progress_provider.dart';

void main() {
  group('Learning Course and Level Roadmap Tests', () {
    test('Mathematics subject returns rich courses including Algebra & Functions', () {
      final mathCourses = CourseRepository.getCoursesForSubject('Mathematics');
      expect(mathCourses.isNotEmpty, isTrue);

      final algebra = mathCourses.firstWhere((c) => c.title.contains('Algebra'));
      expect(algebra.subjectName, 'Mathematics');
      expect(algebra.levels.length, 5);

      // Check level structures matching Image 2
      expect(algebra.levels[0].code, '01 • FOUNDATIONS');
      expect(algebra.levels[0].isCompleted, isTrue);

      expect(algebra.levels[1].code, '02 • BASICS');
      expect(algebra.levels[1].isCompleted, isTrue);

      expect(algebra.levels[2].title, 'Solving Linear Equations');
      expect(algebra.levels[2].isActive, isTrue);
      expect(algebra.levels[2].stepProgress, contains('Step 3 of 5'));
      expect(algebra.levels[2].duration, contains('8 min'));

      expect(algebra.levels[3].code, contains('COORDINATE MAPS'));
      expect(algebra.levels[3].hasBonus, isTrue);
      expect(algebra.levels[3].bonusTitle, 'DAILY SPEED RUN');

      expect(algebra.levels[4].isLocked, isTrue);
    });

    test('Science subject returns Physics, Chemistry, Biology courses with 5 levels', () {
      final sciCourses = CourseRepository.getCoursesForSubject('Science');
      expect(sciCourses.length, greaterThanOrEqualTo(3));

      final titles = sciCourses.map((c) => c.title).toList();
      expect(titles.contains('Physics'), isTrue);
      expect(titles.contains('Chemistry'), isTrue);
      expect(titles.contains('Biology'), isTrue);

      for (final c in sciCourses) {
        expect(c.levels.length, 5);
        expect(c.completedLevelsCount, greaterThan(0));
        expect(c.activeLevel != null, isTrue);
      }
    });

    test('English and Social Studies return valid courses and levels', () {
      final engCourses = CourseRepository.getCoursesForSubject('English');
      expect(engCourses.isNotEmpty, isTrue);
      expect(engCourses.first.levels.length, 5);

      final socCourses = CourseRepository.getCoursesForSubject('Social Studies');
      expect(socCourses.isNotEmpty, isTrue);
      expect(socCourses.any((c) => c.title.contains('History')), isTrue);
      expect(socCourses.any((c) => c.title.contains('Geography')), isTrue);
      expect(socCourses.any((c) => c.title.contains('Civics')), isTrue);
    });

    test('Custom user-added subjects generate structured courses and levels', () {
      final customCourses = CourseRepository.getCoursesForSubject('Robotics & AI', subjectId: 'robotics_1');
      expect(customCourses.isNotEmpty, isTrue);
      expect(customCourses.first.title, 'Robotics & AI Essentials');
      expect(customCourses.first.levels.length, 5);
      expect(customCourses.first.levels[0].isCompleted, isTrue);
      expect(customCourses.first.levels[2].isActive, isTrue);
      expect(customCourses.first.levels[4].isLocked, isTrue);
    });

    test('getAllCourses and getCourseById look up predefined courses correctly', () {
      final all = CourseRepository.getAllCourses();
      expect(all.length, greaterThanOrEqualTo(8));

      final algebra = CourseRepository.getCourseById('math_algebra');
      expect(algebra, isNotNull);
      expect(algebra!.title, contains('Algebra'));

      final nonExistent = CourseRepository.getCourseById('non_existent_course_id');
      expect(nonExistent, isNull);
    });
  });

  group('CourseProgressNotifier Dynamic Logic Tests', () {
    test('CourseProgressData serialization and copyWith', () {
      const data = CourseProgressData(
        completedLevels: {'math_algebra': [1, 2]},
        activeLevels: {'math_algebra': 3},
        lastActiveCourseId: 'math_algebra',
      );

      final map = data.toMap();
      final fromMap = CourseProgressData.fromMap(map);
      expect(fromMap.completedLevels['math_algebra'], [1, 2]);
      expect(fromMap.activeLevels['math_algebra'], 3);
      expect(fromMap.lastActiveCourseId, 'math_algebra');

      final copied = data.copyWith(lastActiveCourseId: 'sci_physics');
      expect(copied.lastActiveCourseId, 'sci_physics');
      expect(copied.completedLevels['math_algebra'], [1, 2]);
    });
  });
}
