import '../models/user_profile.dart';
import '../models/teaching_style_template.dart';

/// Representation of a conversation message turn for prompt assembly.
class PromptMessage {
  final String role; // 'system', 'user', or 'assistant'
  final String content;

  const PromptMessage({required this.role, required this.content});
}

/// Orchestrates the dynamic composition of inference prompts by merging:
/// 1. Hardware constraints (from ModelConfig)
/// 2. Explicit user profile (Name, Grade, Pacing)
/// 3. Pedagogical style guidelines & few-shot examples (TeachingStyleTemplate)
/// 4. Conversation history & latest query
class PromptBuilder {
  /// Builds the personalized system prompt block.
  static String buildSystemPrompt({
    required UserProfile profile,
    required String hardwareInstructions,
  }) {
    final styleTemplate = TeachingStyleTemplate.fromStyle(profile.teachingStyle);

    final pacingInstruction = profile.pacingLevel == PacingLevel.stepByStep
        ? '- **Pacing:** Break concepts and calculations down step-by-step into digestible, bite-sized components.'
        : '- **Pacing:** Give a direct high-level summary and big-picture overview first before expanding.';

    return '''You are Echo, a dedicated and friendly offline AI tutor for ${profile.userName}.
The student is in **Class/Grade ${profile.grade}**.

ADAPTABILITY & TONE:
- Tailor all vocabulary, explanations, and complexity specifically for a Class ${profile.grade} student.
$pacingInstruction
- For Math and Science, format formulas clearly using LaTeX (e.g. \$x^2\$) and show working steps.

${styleTemplate.systemInstructions}

HARDWARE & SYSTEM CONSTRAINTS:
$hardwareInstructions''';
  }

  /// Assembles the complete ChatML formatted prompt buffer ready for llama.cpp / local SLM.
  static String buildChatMLPrompt({
    required UserProfile profile,
    required String hardwareInstructions,
    required List<PromptMessage> history,
    required String currentMessage,
    bool includeFewShot = true,
  }) {
    final buffer = StringBuffer();

    // 1. Dynamic System Prompt
    final systemPrompt = buildSystemPrompt(
      profile: profile,
      hardwareInstructions: hardwareInstructions,
    );
    buffer.write('<|im_start|>system\n$systemPrompt<|im_end|>\n');

    // 2. Few-shot Style Examples (Conditioning for small SLMs)
    // Only inject if conversation is fresh (e.g. history is empty or short) to save context budget
    if (includeFewShot && history.length <= 2) {
      final styleTemplate =
          TeachingStyleTemplate.fromStyle(profile.teachingStyle);
      for (final example in styleTemplate.fewShotExamples.take(1)) {
        buffer.write('<|im_start|>${example.role}\n${example.content}<|im_end|>\n');
      }
    }

    // 3. Prior Chat History Turns
    for (final msg in history) {
      if (msg.content.trim().isEmpty || msg.role == 'system') continue;
      buffer.write('<|im_start|>${msg.role}\n${msg.content}<|im_end|>\n');
    }

    // 4. Current User Turn & Assistant Trigger
    buffer.write('<|im_start|>user\n$currentMessage<|im_end|>\n');
    buffer.write('<|im_start|>assistant\n');

    return buffer.toString();
  }
}
