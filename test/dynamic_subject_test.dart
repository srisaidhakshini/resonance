import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo/models/subject.dart';
import 'package:echo/providers/subject_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subject Model and Provider Tests', () {
    test('Subject serialization and deserialization', () {
      final subject = Subject(
        id: 'test_sub_1',
        name: 'Computer Science',
        description: 'Algorithms and Python',
        iconCodePoint: Icons.code.codePoint,
        colorValue: 0xFF159A8C,
        createdAt: DateTime(2026, 9, 8),
      );

      final map = subject.toMap();
      final restored = Subject.fromMap(map);

      expect(restored.id, 'test_sub_1');
      expect(restored.name, 'Computer Science');
      expect(restored.description, 'Algorithms and Python');
      expect(restored.iconCodePoint, Icons.code.codePoint);
      expect(restored.colorValue, 0xFF159A8C);
    });

    test('SubjectNotifier adds and removes subjects dynamically', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = SubjectNotifier();

      // Initial defaults
      expect(notifier.state.length, greaterThanOrEqualTo(4));
      final initialCount = notifier.state.length;

      // Add custom subject
      final added = await notifier.addSubject(
        name: 'Robotics & AI',
        description: 'Sensors and Machine Learning',
        icon: Icons.biotech,
        color: const Color(0xFF6B46C1),
      );

      expect(notifier.state.length, initialCount + 1);
      expect(notifier.state.any((s) => s.id == added.id), isTrue);

      // Delete subject
      await notifier.deleteSubject(added.id);
      expect(notifier.state.length, initialCount);
      expect(notifier.state.any((s) => s.id == added.id), isFalse);
    });
  });
}
