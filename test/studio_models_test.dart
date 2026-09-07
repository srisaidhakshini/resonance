import 'package:flutter_test/flutter_test.dart';
import 'package:echo/models/studio_items.dart';
import 'package:echo/models/chat_message.dart';
import 'package:echo/services/chat_to_studio_generator.dart';

void main() {
  group('Studio Models & Palettes Tests', () {
    test('Palettes contain all 4 minimalist themes with valid colors', () {
      expect(StudioPalettes.all.length, 4);
      for (final p in StudioPalettes.all) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.background, isNotNull);
        expect(p.cardBackground, isNotNull);
        expect(p.accent, isNotNull);
      }
    });

    test('Pre-built Slide Decks have valid content and STEM formulas', () {
      final decks = StudioPreTemplates.getSampleDecks();
      expect(decks.isNotEmpty, isTrue);

      final deck3d = decks.firstWhere((d) => d.id == 'deck_3d_geometry');
      expect(deck3d.title, contains('3D Geometry'));
      expect(deck3d.slides.length, greaterThanOrEqualTo(3));
      expect(deck3d.slides.any((s) => s.codeOrFormula != null), isTrue);
      expect(deck3d.theme.name, 'Lavender Mist');
    });

    test('Pre-built Flashcards can toggle mastery count', () {
      final decks = StudioPreTemplates.getSampleFlashcards();
      expect(decks.isNotEmpty, isTrue);

      final physicsDeck = decks.firstWhere((d) => d.id == 'fc_physics');
      expect(physicsDeck.cards.length, greaterThanOrEqualTo(3));
      expect(physicsDeck.masteredCount, 0);

      physicsDeck.cards[0].isMastered = true;
      expect(physicsDeck.masteredCount, 1);
    });

    test('Pre-built Quizzes have valid questions, options and explanations', () {
      final quizzes = StudioPreTemplates.getSampleQuizzes();
      expect(quizzes.isNotEmpty, isTrue);

      for (final q in quizzes) {
        expect(q.questions.length, greaterThanOrEqualTo(3));
        for (final question in q.questions) {
          expect(question.options.length, greaterThanOrEqualTo(2));
          expect(question.correctOptionIndex, lessThan(question.options.length));
          expect(question.explanation.isNotEmpty, isTrue);
        }
      }
    });

    test('Pre-built Audio Overview tracks have dual-speaker podcast turns', () {
      final tracks = StudioPreTemplates.getSamplePodcasts();
      expect(tracks.isNotEmpty, isTrue);

      final podcast = tracks.first;
      expect(podcast.transcript.length, greaterThanOrEqualTo(4));
      expect(podcast.transcript.any((t) => t.isHostA), isTrue);
      expect(podcast.transcript.any((t) => !t.isHostA), isTrue);
    });

    test('Pre-built Mind Maps have hierarchical tree structure', () {
      final mindMaps = StudioPreTemplates.getSampleMindMaps();
      expect(mindMaps.isNotEmpty, isTrue);

      final mm3d = mindMaps.firstWhere((m) => m.id == 'mm_3d_geometry');
      expect(mm3d.rootNode.label, '3D Coordinate Space');
      expect(mm3d.rootNode.children.length, greaterThanOrEqualTo(3));
      expect(mm3d.rootNode.children.any((c) => c.children.isNotEmpty), isTrue);
    });

    test('ChatToStudioGenerator creates all 5 artifacts from chat messages', () {
      final messages = [
        ChatMessage(
          role: 'user',
          content: 'Can you explain the Laws of Motion and how momentum works in Physics?',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          role: 'assistant',
          content: 'Newton’s Laws of Motion:\n- First Law: Inertia governs objects at rest or uniform motion.\n- Second Law: Force equals mass times acceleration (F = ma).\n- Third Law: Every action has an equal and opposite reaction.\nMomentum (p = mv) is always conserved in isolated systems.',
          timestamp: DateTime.now(),
        ),
      ];

      final mindMap = ChatToStudioGenerator.generateMindMap(messages);
      expect(mindMap.rootNode.children.isNotEmpty, isTrue);
      expect(mindMap.subject, 'Physics');

      final flashcards = ChatToStudioGenerator.generateFlashcards(messages);
      expect(flashcards.cards.length, greaterThanOrEqualTo(3));

      final slides = ChatToStudioGenerator.generateSlideDeck(messages);
      expect(slides.slides.length, greaterThanOrEqualTo(3));

      final quiz = ChatToStudioGenerator.generateQuiz(messages);
      expect(quiz.questions.length, greaterThanOrEqualTo(3));

      final podcast = ChatToStudioGenerator.generatePodcast(messages);
      expect(podcast.transcript.length, greaterThanOrEqualTo(4));
      expect(podcast.transcript.any((t) => t.isHostA), isTrue);
      expect(podcast.transcript.any((t) => !t.isHostA), isTrue);
    });
  });
}
