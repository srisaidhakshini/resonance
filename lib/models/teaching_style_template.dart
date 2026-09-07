import 'user_profile.dart';

/// A pair of simulated user and assistant turns used for few-shot prompt injection.
class StyleExampleMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const StyleExampleMessage({
    required this.role,
    required this.content,
  });
}

/// Abstract contract for pedagogical teaching style templates.
abstract class TeachingStyleTemplate {
  TeachingStyle get style;

  /// System instructions defining tone, questioning philosophy, and method.
  String get systemInstructions;

  /// Concrete few-shot conversational turns to condition small on-device models.
  List<StyleExampleMessage> get fewShotExamples;

  /// Factory dispatcher to obtain the appropriate template.
  static TeachingStyleTemplate fromStyle(TeachingStyle style) {
    switch (style) {
      case TeachingStyle.socratic:
        return SocraticStyleTemplate();
      case TeachingStyle.direct:
        return DirectStyleTemplate();
      case TeachingStyle.storytelling:
        return StorytellingStyleTemplate();
    }
  }
}

/// Socratic Style: Prompts the student to discover the answers via inquiry and scaffolding.
class SocraticStyleTemplate implements TeachingStyleTemplate {
  @override
  TeachingStyle get style => TeachingStyle.socratic;

  @override
  String get systemInstructions => '''PEDAGOGICAL TEACHING STYLE: SOCRATIC & GUIDING
- NEVER give the final answer right away on reasoning problems.
- Ask guiding questions, provide gentle hints, and break problems into smaller steps.
- Encourage the student to think through each sub-step.
- Validate good thinking and gently redirect misconceptions.''';

  @override
  List<StyleExampleMessage> get fewShotExamples => const [
        StyleExampleMessage(
          role: 'user',
          content: 'What is 15 ÷ 3?',
        ),
        StyleExampleMessage(
          role: 'assistant',
          content:
              'Great question! Let\'s think about this together: Imagine you have 15 apples and want to share them equally among 3 friends. How many apples would each friend get? What number times 3 equals 15?',
        ),
        StyleExampleMessage(
          role: 'user',
          content: 'Why is the sky blue?',
        ),
        StyleExampleMessage(
          role: 'assistant',
          content:
              'Notice how sunlight looks white, but it actually contains all colors of the rainbow. When that sunlight hits the Earth\'s atmosphere, which type of light do you think scatters more: long red waves or short blue waves?',
        ),
      ];
}

/// Direct Style: Delivers concise, structured facts, definitions, and formulas immediately.
class DirectStyleTemplate implements TeachingStyleTemplate {
  @override
  TeachingStyle get style => TeachingStyle.direct;

  @override
  String get systemInstructions => '''PEDAGOGICAL TEACHING STYLE: DIRECT & STRUCTURED
- Give the exact answer, definition, or solution immediately and clearly.
- State relevant formulas or rules first, followed by clear step-by-step calculations.
- Use bold headers, bullet points, and concise language.
- Avoid unnecessary rhetoric or delaying the core answer.''';

  @override
  List<StyleExampleMessage> get fewShotExamples => const [
        StyleExampleMessage(
          role: 'user',
          content: 'What is 15 ÷ 3?',
        ),
        StyleExampleMessage(
          role: 'assistant',
          content: '''**Answer:** 5

**Calculation:**
- Division problem: \$15 \\div 3\$
- Since \$3 \\times 5 = 15\$, the quotient is **5**.''',
        ),
        StyleExampleMessage(
          role: 'user',
          content: 'Why is the sky blue?',
        ),
        StyleExampleMessage(
          role: 'assistant',
          content: '''The sky appears blue due to **Rayleigh scattering**.

- **Mechanism:** Sunlight reaches Earth's atmosphere and is scattered in all directions by gases and particles.
- **Wavelength:** Blue light travels as smaller, shorter waves than other colors and is scattered much more strongly than red or yellow light.
- **Result:** Our eyes perceive this scattered blue light across the sky.''',
        ),
      ];
}

/// Storytelling Style: Uses narrative, relatable characters, and tangible analogies.
class StorytellingStyleTemplate implements TeachingStyleTemplate {
  @override
  TeachingStyle get style => TeachingStyle.storytelling;

  @override
  String get systemInstructions => '''PEDAGOGICAL TEACHING STYLE: STORIES & INTUITIVE ANALOGIES
- Introduce concepts through vivid, relatable analogies and short mini-stories.
- Connect abstract math, science, or history ideas to everyday objects and experiences.
- Keep the narrative engaging and imaginative while maintaining academic accuracy.''';

  @override
  List<StyleExampleMessage> get fewShotExamples => const [
        StyleExampleMessage(
          role: 'user',
          content: 'What is 15 ÷ 3?',
        ),
        StyleExampleMessage(
          role: 'assistant',
          content:
              'Imagine you run a bakery and just baked 15 warm chocolate chip cookies! 🍪 Three hungry travelers knock on your door asking to share them fairly. You place one cookie on plate 1, one on plate 2, one on plate 3... and keep going until all 15 are shared. Each traveler gets **5 cookies**!',
        ),
        StyleExampleMessage(
          role: 'user',
          content: 'Why is the sky blue?',
        ),
        StyleExampleMessage(
          role: 'assistant',
          content:
              'Picture sunlight as a parade of runners wearing different colored jerseys. Red and orange runners are wearing heavy boots and march straight through without bumping into anything. But the blue runners are bouncy acrobats wearing springy shoes! When they hit the atmosphere\'s tiny air molecules, they bounce and ricochet in every direction across the atmosphere. When you look up, you\'re seeing all those bouncing blue acrobats lighting up the day!',
        ),
      ];
}
