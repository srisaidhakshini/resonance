import 'dart:async';
import 'package:flutter/foundation.dart';
import 'model_download_service.dart';

class LLMService {
  final ModelDownloadService? downloadService;
  bool _isInitialized = true;
  bool _isGenerating = false;
  int _currentGenerationId = 0;

  LLMService([this.downloadService]);

  bool get isLoaded => _isInitialized;

  Future<void> loadModel() async {
    _isInitialized = true;
    if (kDebugMode) print('✅ [WEB] LLM Service ready');
  }

  void cancelGeneration() {
    _isGenerating = false;
    _currentGenerationId++;
    if (kDebugMode) print('🛑 [WEB] Generation cancelled');
  }

  Future<void> resetContext() async {
    _isGenerating = false;
    if (kDebugMode) print('🔄 [WEB] Context reset');
  }

  Future<void> reloadLlamaContext() async {
    _isGenerating = false;
  }

  void removeLastUserAndAssistantMessage() {}

  void removeLastAssistantMessage() {}

  Future<void> unloadModel() async {
    _isGenerating = false;
  }

  Stream<String> streamResponse(String message) async* {
    _currentGenerationId++;
    final myGenId = _currentGenerationId;
    _isGenerating = true;

    final response = _generateEducationalResponse(message);
    final words = response.split(' ');

    for (int i = 0; i < words.length; i++) {
      if (!_isGenerating || myGenId != _currentGenerationId) {
        break;
      }
      yield (i == 0 ? '' : ' ') + words[i];
      await Future.delayed(const Duration(milliseconds: 35));
    }

    _isGenerating = false;
  }

  String _generateEducationalResponse(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('hello') || lower.contains('hi ') || lower == 'hi') {
      return 'Hello! I am **Mobileshiksha**, your offline educational assistant.\n\nHow can I help you with your studies today? You can ask me questions about **Mathematics**, **Physics**, **Chemistry**, **History**, or **Computer Science**!';
    }

    if (lower.contains('derivative') || lower.contains('calculus') || lower.contains('math')) {
      return 'Here is a step-by-step mathematical explanation:\n\n'
          '### Derivative of a Function\n'
          'By the power rule of differentiation:\n'
          r'$$\frac{d}{dx}[x^n] = n \cdot x^{n-1}$$'
          '\n\n'
          '**Example:**\n'
          r"If we differentiate $f(x) = 3x^4 + 5x^2 - 7$:"
          '\n'
          r"$$f'(x) = 3 \cdot 4x^3 + 5 \cdot 2x = 12x^3 + 10x$$"
          '\n\n'
          'Let me know if you would like to solve a specific equation!';
    }

    if (lower.contains('newton') || lower.contains('force') || lower.contains('gravity') || lower.contains('physics')) {
      return "### Newton's Laws of Motion\n\n"
          '1. **First Law (Law of Inertia):** An object will remain at rest or move at a constant velocity unless acted upon by an external net force.\n\n'
          '2. **Second Law (Fundamental Law of Dynamics):** The rate of change of momentum of a body is directly proportional to the applied force:\n'
          r'$$\vec{F} = m \cdot \vec{a}$$'
          '\n\n'
          '3. **Third Law (Action-Reaction):** For every action, there is an equal and opposite reaction:\n'
          r'$$\vec{F}_{AB} = -\vec{F}_{BA}$$';
    }

    if (lower.contains('python') || lower.contains('code') || lower.contains('program')) {
      return '### Python Educational Example\n\n'
          'Here is a simple Python function to demonstrate recursion with factorial calculation:\n\n'
          '```python\n'
          'def factorial(n: int) -> int:\n'
          '    """Calculates n! recursively."""\n'
          '    if n <= 1:\n'
          '        return 1\n'
          '    return n * factorial(n - 1)\n\n'
          '# Example usage\n'
          'print("Factorial of 5 is:", factorial(5))  # Output: 120\n'
          '```\n\n'
          r'Time Complexity: $\mathcal{O}(n)$'
          '\n'
          r'Space Complexity: $\mathcal{O}(n)$ (call stack).';
    }

    return '### Educational Guide & Explanation\n\n'
        'Thank you for asking about: **$prompt**.\n\n'
        'Here are the core concepts to understand:\n\n'
        '1. **Fundamental Concept:** Break down the problem into fundamental principles.\n'
        '2. **Key Insight:** Ensure all terms and definitions are clearly distinguished.\n'
        '3. **Practical Application:** Connect the theoretical rule to real-world problem solving.\n\n'
        'Feel free to ask follow-up questions or request specific practice problems!';
  }
}
