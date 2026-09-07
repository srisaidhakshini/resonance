import 'package:flutter_test/flutter_test.dart';
import 'package:echo/models/user_profile.dart';
import 'package:echo/models/teaching_style_template.dart';
import 'package:echo/services/prompt_builder.dart';

void main() {
  group('UserProfile Tests', () {
    test('Defaults are correctly configured', () {
      final profile = UserProfile.defaults();
      expect(profile.userName, equals('Student'));
      expect(profile.grade, equals('8'));
      expect(profile.teachingStyle, equals(TeachingStyle.socratic));
      expect(profile.pacingLevel, equals(PacingLevel.stepByStep));
    });

    test('Serialization and Deserialization round-trip', () {
      const profile = UserProfile(
        userName: 'Aarav',
        grade: '5',
        teachingStyle: TeachingStyle.storytelling,
        pacingLevel: PacingLevel.highLevel,
      );

      final json = profile.toJson();
      final reconstructed = UserProfile.fromJson(json);

      expect(reconstructed.userName, equals('Aarav'));
      expect(reconstructed.grade, equals('5'));
      expect(reconstructed.teachingStyle, equals(TeachingStyle.storytelling));
      expect(reconstructed.pacingLevel, equals(PacingLevel.highLevel));
    });
  });

  group('TeachingStyleTemplate Tests', () {
    test('Socratic template contains guiding instructions and examples', () {
      final template = TeachingStyleTemplate.fromStyle(TeachingStyle.socratic);
      expect(template.systemInstructions, contains('SOCRATIC'));
      expect(template.systemInstructions, contains('NEVER give the final answer right away'));
      expect(template.fewShotExamples.isNotEmpty, isTrue);
    });

    test('Direct template contains structured instructions and formulas', () {
      final template = TeachingStyleTemplate.fromStyle(TeachingStyle.direct);
      expect(template.systemInstructions, contains('DIRECT'));
      expect(template.fewShotExamples.isNotEmpty, isTrue);
    });

    test('Storytelling template contains narrative instructions', () {
      final template = TeachingStyleTemplate.fromStyle(TeachingStyle.storytelling);
      expect(template.systemInstructions, contains('STORIES'));
      expect(template.fewShotExamples.isNotEmpty, isTrue);
    });
  });

  group('PromptBuilder Tests', () {
    test('buildSystemPrompt injects name, grade, pacing, and style', () {
      const profile = UserProfile(
        userName: 'Priya',
        grade: '10',
        teachingStyle: TeachingStyle.socratic,
        pacingLevel: PacingLevel.stepByStep,
      );

      final prompt = PromptBuilder.buildSystemPrompt(
        profile: profile,
        hardwareInstructions: 'Keep answers concise.',
      );

      expect(prompt, contains('Priya'));
      expect(prompt, contains('Class/Grade 10'));
      expect(prompt, contains('SOCRATIC & GUIDING'));
      expect(prompt, contains('step-by-step'));
      expect(prompt, contains('Keep answers concise.'));
    });

    test('buildChatMLPrompt injects few-shot examples on fresh session', () {
      const profile = UserProfile(
        userName: 'Rahul',
        grade: '7',
        teachingStyle: TeachingStyle.direct,
        pacingLevel: PacingLevel.highLevel,
      );

      final chatML = PromptBuilder.buildChatMLPrompt(
        profile: profile,
        hardwareInstructions: 'Use bullet points.',
        history: [],
        currentMessage: 'What is photosynthesis?',
        includeFewShot: true,
      );

      // Verify ChatML delimiters
      expect(chatML, contains('<|im_start|>system\n'));
      expect(chatML, contains('<|im_end|>\n'));
      expect(chatML, contains('Rahul'));
      expect(chatML, contains('Class/Grade 7'));

      // Verify few-shot example was injected
      expect(chatML, contains('<|im_start|>user\nWhat is 15 ÷ 3?<|im_end|>\n'));

      // Verify current query and assistant trigger
      expect(chatML, contains('<|im_start|>user\nWhat is photosynthesis?<|im_end|>\n<|im_start|>assistant\n'));
    });
  });
}
