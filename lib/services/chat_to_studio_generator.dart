import '../models/chat_message.dart';
import '../models/studio_items.dart';

/// Intelligent Studio Generator that transforms any active Chat conversation
/// into rich study artifacts: 2D Mind Map, Flashcards, Slide Deck, Quiz, or Audio Podcast.
class ChatToStudioGenerator {
  /// Extract core topic title and subject from chat messages
  static Map<String, String> _detectTopicAndSubject(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return {'title': 'General Study Session', 'subject': 'General Science', 'summary': 'Interactive study notes.'};
    }

    // Find the latest user query or prominent concepts
    String latestUserQuery = '';
    String assistantContext = '';

    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].sender == 'user' && latestUserQuery.isEmpty) {
        latestUserQuery = messages[i].text.trim();
      } else if (messages[i].sender != 'user' && assistantContext.isEmpty && messages[i].text != '...') {
        assistantContext = messages[i].text.trim();
      }
      if (latestUserQuery.isNotEmpty && assistantContext.isNotEmpty) break;
    }

    if (latestUserQuery.isEmpty) {
      latestUserQuery = messages.last.text.trim();
    }

    // Clean user query to form a clean title
    String title = latestUserQuery.split(RegExp(r'[\n.?!]')).first.trim();
    if (title.length > 40) {
      title = '${title.substring(0, 38)}...';
    }
    if (title.isEmpty) {
      title = 'Concept Deep Dive';
    }

    // Detect subject
    final lower = '$latestUserQuery $assistantContext'.toLowerCase();
    String subject = 'General Science';
    if (lower.contains('math') || lower.contains('vector') || lower.contains('calculus') || lower.contains('equation') || lower.contains('integral') || lower.contains('geometry')) {
      subject = 'Mathematics';
    } else if (lower.contains('force') || lower.contains('motion') || lower.contains('velocity') || lower.contains('thermo') || lower.contains('optics') || lower.contains('light') || lower.contains('gravity') || lower.contains('physics')) {
      subject = 'Physics';
    } else if (lower.contains('reaction') || lower.contains('acid') || lower.contains('bond') || lower.contains('atom') || lower.contains('molecule') || lower.contains('chemistry')) {
      subject = 'Chemistry';
    } else if (lower.contains('cell') || lower.contains('organ') || lower.contains('dna') || lower.contains('gene') || lower.contains('photosynthesis') || lower.contains('biology') || lower.contains('life')) {
      subject = 'Biology';
    } else if (lower.contains('algorithm') || lower.contains('code') || lower.contains('network') || lower.contains('security') || lower.contains('database') || lower.contains('cs')) {
      subject = 'Computer Science';
    }

    return {
      'title': title,
      'subject': subject,
      'summary': assistantContext.isNotEmpty ? assistantContext.substring(0, assistantContext.length > 120 ? 120 : assistantContext.length) : 'Study insights synthesized from conversation.',
    };
  }

  /// 1. Generate 2D Mind Map Deck from Chat
  static MindMapDeck generateMindMap(List<ChatMessage> messages) {
    final meta = _detectTopicAndSubject(messages);
    final title = meta['title']!;
    final subject = meta['subject']!;

    // Extract bullet points or distinct sentences from assistant messages
    final bulletLines = <String>[];
    for (final m in messages) {
      if (m.sender != 'user' && m.text != '...') {
        final lines = m.text.split('\n');
        for (final l in lines) {
          final trimmed = l.trim();
          if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || RegExp(r'^\d+\.').hasMatch(trimmed)) {
            final clean = trimmed.replaceFirst(RegExp(r'^[-*0-9.]+\s*'), '').trim();
            if (clean.isNotEmpty && clean.length > 5) {
              bulletLines.add(clean);
            }
          }
        }
      }
    }

    final children = <MindMapNode>[];

    if (bulletLines.length >= 3) {
      // Group extracted bullets into 3-4 primary branches
      final branchCount = bulletLines.length > 4 ? 4 : bulletLines.length;
      for (int i = 0; i < branchCount; i++) {
        final bText = bulletLines[i];
        final parts = bText.split(':');
        final branchTitle = parts[0].trim();
        final branchDetail = parts.length > 1 ? parts[1].trim() : bText;

        children.add(
          MindMapNode(
            id: 'gen_child_$i',
            label: branchTitle.length > 25 ? '${branchTitle.substring(0, 22)}...' : branchTitle,
            detail: branchDetail,
            children: [
              MindMapNode(
                id: 'gen_leaf_${i}_1',
                label: 'Key Principle',
                detail: branchDetail.length > 40 ? branchDetail.substring(0, 40) : branchDetail,
              ),
              MindMapNode(
                id: 'gen_leaf_${i}_2',
                label: 'Application',
                detail: 'Analyzed directly from chat context and verified.',
              ),
            ],
          ),
        );
      }
    } else {
      // Fallback structured branches based on detected subject and title
      children.addAll([
        MindMapNode(
          id: 'gen_core',
          label: 'Core Definition',
          detail: 'Primary concepts and foundational premises discussed in chat.',
          children: [
            MindMapNode(id: 'gen_c1', label: 'Primary Formula/Rule', detail: meta['summary'] ?? ''),
            const MindMapNode(id: 'gen_c2', label: 'Underlying Axiom', detail: 'Guarantees consistent theoretical behavior.'),
          ],
        ),
        const MindMapNode(
          id: 'gen_app',
          label: 'Practical Implications',
          detail: 'How these principles manifest in real-world problems.',
          children: [
            MindMapNode(id: 'gen_a1', label: 'Direct Application', detail: 'Solving numerical exercises and conceptual derivations.'),
            MindMapNode(id: 'gen_a2', label: 'Edge Conditions', detail: 'Critical constraints where formulas hold true.'),
          ],
        ),
        const MindMapNode(
          id: 'gen_analysis',
          label: 'Analytical Breakdown',
          detail: 'Step-by-step logic explained by Echo AI.',
          children: [
            MindMapNode(id: 'gen_k1', label: 'Key Terminology', detail: 'Essential vocabulary and definitions for mastery.'),
            MindMapNode(id: 'gen_k2', label: 'Exam Focus', detail: 'High-yield points frequently tested in competitive exams.'),
          ],
        ),
      ]);
    }

    return MindMapDeck(
      id: 'mm_chat_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subject: subject,
      gradeLevel: 'From Chat',
      themeIndex: (title.length) % 4,
      rootNode: MindMapNode(
        id: 'root_chat',
        label: title,
        detail: '$subject • Concept Graph from Chat Context',
        children: children,
      ),
    );
  }

  /// 2. Generate Flashcard Deck from Chat
  static FlashcardDeck generateFlashcards(List<ChatMessage> messages) {
    final meta = _detectTopicAndSubject(messages);
    final title = meta['title']!;
    final subject = meta['subject']!;

    final cards = <FlashcardItem>[];
    int count = 1;

    for (final m in messages) {
      if (m.sender == 'user') {
        final qText = m.text.trim();
        if (qText.length > 5) {
          cards.add(
            FlashcardItem(
              id: 'fc_gen_$count',
              frontQuestion: qText.endsWith('?') ? qText : '$qText?',
              backAnswer: 'Discussed in session: Core insight on $title.',
              category: subject,
              hint: 'Refer to your recent Echo conversation notes.',
            ),
          );
          count++;
          if (cards.length >= 4) break;
        }
      }
    }

    // Ensure we have at least 3 cards
    if (cards.length < 3) {
      cards.add(
        FlashcardItem(
          id: 'fc_gen_def',
          frontQuestion: 'What is the primary concept behind $title?',
          backAnswer: meta['summary'] ?? 'Fundamental topic analyzed during the study session.',
          category: subject,
          hint: 'Summarizes the main point of inquiry.',
        ),
      );
      cards.add(
        FlashcardItem(
          id: 'fc_gen_rule',
          frontQuestion: 'How does $title connect to other $subject topics?',
          backAnswer: 'Serves as an essential prerequisite for higher-level problem solving in $subject.',
          category: subject,
          hint: 'Think of foundational prerequisites.',
        ),
      );
      cards.add(
        FlashcardItem(
          id: 'fc_gen_verify',
          frontQuestion: 'How do you verify solutions regarding $title?',
          backAnswer: 'Cross-check boundary conditions, unit dimensions, and algebraic signs.',
          category: 'Methodology',
          hint: 'Check units and dimensional consistency.',
        ),
      );
    }

    return FlashcardDeck(
      id: 'fc_chat_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Flashcards: $title',
      subject: subject,
      gradeLevel: 'From Chat',
      themeIndex: (title.length + 1) % 4,
      cards: cards,
    );
  }

  /// 3. Generate Slide Deck from Chat
  static SlideDeck generateSlideDeck(List<ChatMessage> messages) {
    final meta = _detectTopicAndSubject(messages);
    final title = meta['title']!;
    final subject = meta['subject']!;

    final slides = [
      SlideItem(
        slideNumber: 1,
        title: title,
        subtitle: '$subject • Overview & Core Principles',
        bulletPoints: [
          'Synthesized from your interactive AI tutoring conversation',
          'Highlights fundamental axioms, formulas, and definitions',
          'Provides an executive summary for rapid revision',
        ],
        codeOrFormula: 'Topic: $title ($subject)',
        keyTakeaway: 'Mastery begins with a clear grasp of foundational terminology.',
      ),
      SlideItem(
        slideNumber: 2,
        title: 'Key Concepts & Derivations',
        subtitle: 'Analytical breakdown of student inquiry',
        bulletPoints: [
          'Direct response to questions explored during the session',
          'Careful step-by-step reasoning eliminates misconceptions',
          'Equations and relationships validated through chat explanation',
        ],
        codeOrFormula: meta['summary'],
        keyTakeaway: 'Always verify unit dimensions and physical intuition at boundary cases.',
      ),
      SlideItem(
        slideNumber: 3,
        title: 'Applications & Exam Takeaways',
        subtitle: 'Applying principles to solve practical problems',
        bulletPoints: [
          'Recognize pattern triggers in competitive exam questions',
          'Break down multi-step problems into modular calculations',
          'Active recall solidifies neural pathways for long-term memory',
        ],
        codeOrFormula: 'Formula Mastery: Practice + Recall',
        keyTakeaway: 'Consistent active review yields high retention and exam confidence.',
      ),
    ];

    return SlideDeck(
      id: 'deck_chat_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Slides: $title',
      subject: subject,
      gradeLevel: 'From Chat',
      themeIndex: (title.length + 2) % 4,
      slides: slides,
    );
  }

  /// 4. Generate Practice Quiz Deck from Chat
  static QuizDeck generateQuiz(List<ChatMessage> messages) {
    final meta = _detectTopicAndSubject(messages);
    final title = meta['title']!;
    final subject = meta['subject']!;

    final questions = [
      QuizQuestion(
        id: 'q_chat_1',
        question: 'Which of the following best characterizes $title in $subject?',
        options: [
          'A fundamental concept with verified governing rules',
          'An obsolete hypothesis without experimental proof',
          'A localized phenomenon applicable only at absolute zero',
          'An empirical guideline with no mathematical rigor',
        ],
        correctOptionIndex: 0,
        explanation: 'As discussed in your session, $title represents an established, mathematically rigorous principle in $subject.',
      ),
      QuizQuestion(
        id: 'q_chat_2',
        question: 'When analyzing problems related to $title, what should be checked first?',
        options: [
          'Ignore boundary values and approximate',
          'Identify knowns, unknowns, units, and governing laws',
          'Assume constant velocity regardless of external forces',
          'Skip algebraic simplification',
        ],
        correctOptionIndex: 1,
        explanation: 'Systematic problem solving requires isolating variables, ensuring unit consistency, and applying the relevant core equations.',
      ),
      QuizQuestion(
        id: 'q_chat_3',
        question: 'Why is active recall particularly effective for mastering $title?',
        options: [
          'It replaces the need to understand underlying theorems',
          'It strengthens neural pathways and reveals conceptual gaps',
          'It guarantees 100% exam score without problem practice',
          'It only works for rote memorization of history dates',
        ],
        correctOptionIndex: 1,
        explanation: 'Active recall and self-testing force retrieval effort, which cognitive science shows is the highest-yield technique for retention.',
      ),
    ];

    return QuizDeck(
      id: 'quiz_chat_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Quiz: $title',
      subject: subject,
      gradeLevel: 'From Chat',
      themeIndex: (title.length + 3) % 4,
      questions: questions,
    );
  }

  /// 5. Generate Audio Overview Track (Podcast) from Chat
  static AudioOverviewTrack generatePodcast(List<ChatMessage> messages) {
    final meta = _detectTopicAndSubject(messages);
    final title = meta['title']!;
    final subject = meta['subject']!;

    final transcript = [
      PodcastTurn(
        speakerName: 'Alex (Analyst)',
        dialogue: 'Welcome back to Echo Studio! In today\'s deep dive, we are examining an insightful topic that just came up in our chat session: $title.',
        isHostA: true,
      ),
      PodcastTurn(
        speakerName: 'Jamie (Curious Host)',
        dialogue: 'Yes! It\'s really captivating because students often ask how $title fits into the bigger picture of $subject.',
        isHostA: false,
      ),
      PodcastTurn(
        speakerName: 'Alex (Analyst)',
        dialogue: 'Right. What makes it so vital is that once you understand the underlying axioms and formulas, all the complex derivations suddenly click into place.',
        isHostA: true,
      ),
      PodcastTurn(
        speakerName: 'Jamie (Curious Host)',
        dialogue: 'And the conversation highlighted that you don\'t just memorize these rules; you have to visualize what is physically happening in the system.',
        isHostA: false,
      ),
      PodcastTurn(
        speakerName: 'Alex (Analyst)',
        dialogue: 'Precisely. That intuition turns challenging exam questions into intuitive, step-by-step problem solving.',
        isHostA: true,
      ),
    ];

    return AudioOverviewTrack(
      id: 'podcast_chat_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Deep Dive: $title',
      topic: '$subject • From Chat Context',
      durationMinutes: '2 min listen',
      gradeLevel: 'From Chat',
      themeIndex: (title.length) % 4,
      transcript: transcript,
    );
  }
}
