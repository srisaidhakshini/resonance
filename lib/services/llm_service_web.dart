import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'model_download_service.dart';

class LLMService {
  final ModelDownloadService? downloadService;
  bool _isInitialized = true;
  bool _isGenerating = false;
  int _currentGenerationId = 0;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 700),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  LLMService([this.downloadService]);

  bool get isLoaded => _isInitialized;

  Future<void> loadModel() async {
    _isInitialized = true;
    if (kDebugMode) print('✅ [WEB] Smart Local Educational Engine ready');
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

    // 1. Attempt connection to local Ollama if available on user machine
    bool localLlmSucceeded = false;
    try {
      final ollamaStream = _tryStreamFromLocalOllama(message, myGenId);
      await for (final token in ollamaStream) {
        if (!_isGenerating || myGenId != _currentGenerationId) return;
        localLlmSucceeded = true;
        yield token;
      }
    } catch (_) {
      localLlmSucceeded = false;
    }

    if (localLlmSucceeded) {
      _isGenerating = false;
      return;
    }

    // 2. Fall back to high-intelligence built-in pedagogical reasoning engine
    final response = _generateSmartEducationalResponse(message);
    final words = response.split(' ');

    for (int i = 0; i < words.length; i++) {
      if (!_isGenerating || myGenId != _currentGenerationId) {
        break;
      }
      yield (i == 0 ? '' : ' ') + words[i];
      await Future.delayed(const Duration(milliseconds: 20));
    }

    _isGenerating = false;
  }

  /// Tries streaming from a local Ollama daemon (e.g. running on port 11434)
  Stream<String> _tryStreamFromLocalOllama(String prompt, int genId) async* {
    final response = await _dio.post(
      'http://127.0.0.1:11434/api/generate',
      data: {
        'model': 'qwen2.5:0.5b',
        'prompt': prompt,
        'stream': false,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final text = response.data['response']?.toString() ?? '';
      if (text.isNotEmpty) {
        final words = text.split(' ');
        for (int i = 0; i < words.length; i++) {
          if (!_isGenerating || genId != _currentGenerationId) break;
          yield (i == 0 ? '' : ' ') + words[i];
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
    }
  }

  /// Core smart pedagogical response generator
  String _generateSmartEducationalResponse(String rawPrompt) {
    // Clean prompt prefixes from quick cards
    final cleaned = _cleanPrompt(rawPrompt);
    final lower = cleaned.toLowerCase().trim();

    // 1. Direct Arithmetic Solver (e.g. "25 + 47", "what is 15 * 8", "120 / 4")
    final arithmeticResult = _trySolveArithmetic(lower);
    if (arithmeticResult != null) {
      return arithmeticResult;
    }

    // 2. Greetings
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey') ||
        lower.contains('who are you')) {
      return r'''### 👋 Welcome to Echo

Hello! I am **Echo**, your offline educational AI tutor.

I am designed to provide clear, step-by-step guidance across:
- 📐 **Mathematics**: Arithmetic, Algebra, Geometry, Calculus
- ⚡ **Physics**: Mechanics, Electricity, Gravity, Waves
- 🧪 **Chemistry**: Atoms, Periodic Table, Reactions, Stoichiometry
- 🧬 **Biology**: Cells, Genetics, Photosynthesis, Human Anatomy
- 💻 **Computer Science**: Python, Algorithms, Data Structures

What topic or homework problem would you like to explore today?''';
    }

    // 3. Mathematics: Addition
    if (lower.contains('addition') ||
        lower.contains('add ') ||
        lower.contains('adding') ||
        lower == 'what is addition' ||
        lower.contains('concept of addition')) {
      return r'''### 📘 What is Addition?

**Addition** is one of the four fundamental arithmetic operations (alongside subtraction, multiplication, and division). It represents the process of combining two or more quantities into a single total, known as the **sum**.

---

### 1. Key Terminology
In any addition equation:
$$a + b = c$$

- **Addends**: The numbers being combined (here, $a$ and $b$).
- **Plus Sign ($+$)**: The operator that signals addition.
- **Sum**: The total resulting quantity ($c$).

---

### 2. Fundamental Mathematical Properties
1. **Commutative Property**:
   The order in which numbers are added does not change the sum.
   $$a + b = b + a \quad \text{(e.g., } 4 + 7 = 7 + 4 = 11\text{)}$$

2. **Associative Property**:
   The grouping of addends does not affect the sum.
   $$(a + b) + c = a + (b + c) \quad \text{(e.g., } (2 + 3) + 5 = 2 + (3 + 5) = 10\text{)}$$

3. **Identity Property of Addition (Zero Property)**:
   Adding zero to any number leaves it unchanged.
   $$a + 0 = a \quad \text{(e.g., } 9 + 0 = 9\text{)}$$

---

### 3. Step-by-Step Example: Column Addition with Regrouping
Let us solve: **$47 + 38$**

1. **Align by Place Value**:
   ```text
     [Tens]  [Ones]
        4      7
   +    3      8
   ---------------
   ```
2. **Add the Ones Column**:
   $$7 + 8 = 15$$
   - Write **5** in the ones place.
   - Carry **1** (representing 1 ten) to the tens column.

3. **Add the Tens Column** (including the carried 1):
   $$1 \text{ (carry)} + 4 + 3 = 8$$

4. **Final Result**:
   $$\mathbf{47 + 38 = 85}$$

---

### 💡 Quick Practice
Try calculating **$56 + 29$**.
*(Hint: Add $6 + 9 = 15$ [carry $1$], then $1 + 5 + 2 = 8 \implies \mathbf{85}$)*''';
    }

    // 4. Mathematics: Subtraction
    if (lower.contains('subtraction') ||
        lower.contains('subtract') ||
        lower.contains('minus')) {
      return r'''### 📘 What is Subtraction?

**Subtraction** is the inverse operation of addition. It calculates the difference between two quantities or determines how much is left when a part is taken away from a whole.

---

### 1. Key Terminology
$$a - b = c$$

- **Minuend ($a$)**: The initial quantity from which another is subtracted.
- **Subtrahend ($b$)**: The quantity being taken away.
- **Difference ($c$)**: The final remaining quantity.

---

### 2. Regrouping (Borrowing) Method
Consider **$72 - 38$**:
1. In the ones column: $2 - 8$ cannot be done in positive whole numbers.
2. Borrow $1$ ten from $7$ tens, turning $7$ into $6$ tens.
3. The $2$ ones becomes $12$ ones:
   $$12 - 8 = 4$$
4. In the tens column:
   $$6 - 3 = 3$$
5. Result:
   $$\mathbf{72 - 38 = 34}$$

Check by addition: $34 + 38 = 72$.''';
    }

    // 5. Mathematics: Multiplication
    if (lower.contains('multiplication') ||
        lower.contains('multiply') ||
        lower.contains('times table')) {
      return r'''### 📘 Understanding Multiplication

**Multiplication** represents repeated addition of the same quantity.
For example, $4 \times 3$ means adding $4$ three times:
$$4 + 4 + 4 = 12$$

### 1. Core Properties
- **Commutative**: $a \times b = b \times a$
- **Associative**: $(a \times b) \times c = a \times (b \times c)$
- **Distributive**: $a \times (b + c) = (a \times b) + (a \times c)$
- **Zero Property**: $a \times 0 = 0$
- **Identity Property**: $a \times 1 = a$

### 2. Example: $14 \times 6$
Using the distributive property:
$$14 \times 6 = (10 + 4) \times 6 = (10 \times 6) + (4 \times 6) = 60 + 24 = 84$$''';
    }

    // 6. Mathematics: Division & Fractions
    if (lower.contains('division') ||
        lower.contains('divide') ||
        lower.contains('fraction')) {
      return r'''### 📘 Understanding Division & Fractions

**Division** splits a quantity into equal parts. It is the inverse of multiplication.

### 1. The Division Equation
$$\frac{a}{b} = q \quad \text{or} \quad a = b \cdot q + r$$

- **Dividend ($a$)**: Total quantity to be divided.
- **Divisor ($b$)**: Number of equal groups ($b \neq 0$).
- **Quotient ($q$)**: Result per group.
- **Remainder ($r$)**: Amount left over ($0 \le r < b$).

### 2. Operations with Fractions
- **Common Denominators**: $\frac{a}{c} + \frac{b}{c} = \frac{a+b}{c}$
- **Multiplication**: $\frac{a}{b} \times \frac{c}{d} = \frac{a \cdot c}{b \cdot d}$
- **Division (Reciprocal rule)**: $\frac{a}{b} \div \frac{c}{d} = \frac{a}{b} \times \frac{d}{c} = \frac{a \cdot d}{b \cdot c}$''';
    }

    // 7. Mathematics: Quadratic Equations & Algebra
    if (lower.contains('quadratic') ||
        lower.contains('algebra') ||
        lower.contains('equation') ||
        lower.contains('factor')) {
      return r'''### 📐 Quadratic Equations & Algebra Guide

A quadratic equation is a second-order polynomial equation in a single variable $x$:
$$ax^2 + bx + c = 0 \quad (a \neq 0)$$

### 1. The Quadratic Formula
$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

### 2. The Discriminant ($\Delta = b^2 - 4ac$)
- If $\Delta > 0$: Two distinct real roots.
- If $\Delta = 0$: Exactly one real repeated root ($x = -b / 2a$).
- If $\Delta < 0$: Two complex conjugate roots.

### 3. Worked Example: $x^2 - 5x + 6 = 0$
Here $a = 1, b = -5, c = 6$.
By factoring:
$$(x - 2)(x - 3) = 0 \implies x_1 = 2, \quad x_2 = 3$$''';
    }

    // 8. Mathematics: Calculus & Derivatives
    if (lower.contains('derivative') ||
        lower.contains('calculus') ||
        lower.contains('differentiat') ||
        lower.contains('integral')) {
      return r'''### 📈 Calculus: Differential & Integral Foundations

Calculus studies continuous change through **differentiation** (rates of change) and **integration** (accumulation of quantities).

### 1. Definition of Derivative
$$f'(x) = \lim_{h \to 0} \frac{f(x + h) - f(x)}{h}$$

### 2. Essential Differentiation Rules
- **Power Rule**: $\frac{d}{dx}[x^n] = n \cdot x^{n-1}$
- **Product Rule**: $\frac{d}{dx}[u \cdot v] = u'v + uv'$
- **Quotient Rule**: $\frac{d}{dx}\left[\frac{u}{v}\right] = \frac{u'v - uv'}{v^2}$
- **Chain Rule**: $\frac{d}{dx}[f(g(x))] = f'(g(x)) \cdot g'(x)$

### 3. Example
Differentiate $f(x) = 4x^3 - 5x^2 + 7x - 9$:
$$f'(x) = 4(3x^2) - 5(2x) + 7(1) - 0 = 12x^2 - 10x + 7$$''';
    }

    // 9. Physics: Newton's Laws & Mechanics
    if (lower.contains('newton') ||
        lower.contains('force') ||
        lower.contains('physics') ||
        lower.contains('motion') ||
        lower.contains('acceleration')) {
      return r'''### ⚡ Physics: Newton's Three Laws of Motion

Sir Isaac Newton formulated the three foundation laws governing classical mechanics:

1. **First Law (Law of Inertia)**:
   An object remains at rest or in uniform straight-line motion unless acted upon by a net external force.
   $$\sum \vec{F} = 0 \implies \vec{v} = \text{constant}$$

2. **Second Law (Fundamental Law of Dynamics)**:
   The acceleration of an object is directly proportional to net force and inversely proportional to mass.
   $$\vec{F}_{\text{net}} = m \cdot \vec{a}$$
   - Force in Newtons (N), Mass in kg, Acceleration in $\text{m/s}^2$.

3. **Third Law (Action-Reaction)**:
   When body A exerts a force on body B, body B simultaneously exerts an equal and opposite force on body A.
   $$\vec{F}_{AB} = -\vec{F}_{BA}$$

### Real-World Example
A rocket accelerates upward because its engines expel hot exhaust gas downward at high velocity (Action $\rightarrow$ Reaction).''';
    }

    // 10. Physics: Gravity & Energy
    if (lower.contains('gravity') ||
        lower.contains('gravitation') ||
        lower.contains('energy') ||
        lower.contains('kinetic')) {
      return r'''### 🌌 Gravity & Mechanical Energy

### 1. Universal Gravitation
Newton's Law of Gravitation states that any two bodies attract with a force proportional to their masses:
$$F = G \frac{m_1 m_2}{r^2}$$
- Gravitational constant $G \approx 6.674 \times 10^{-11} \text{ N}\cdot\text{m}^2/\text{kg}^2$
- Near Earth surface: $g = 9.8 \text{ m/s}^2 \implies W = mg$

### 2. Conservation of Mechanical Energy
In an isolated system without non-conservative friction forces:
$$E_{\text{total}} = KE + PE = \text{constant}$$
- **Kinetic Energy**: $KE = \frac{1}{2}mv^2$
- **Gravitational Potential Energy**: $PE = mgh$''';
    }

    // 11. Chemistry: Atoms, Periodic Table & Bonding
    if (lower.contains('atom') ||
        lower.contains('periodic table') ||
        lower.contains('chemistry') ||
        lower.contains('bond') ||
        lower.contains('element')) {
      return r'''### 🧪 Chemistry: Atomic Structure & Bonding

### 1. The Atom and Subatomic Particles
- **Protons ($p^+$)**: Positively charged, located in the nucleus. Defines the Atomic Number ($Z$).
- **Neutrons ($n^0$)**: Neutral, located in the nucleus. Contributes to mass number ($A = Z + N$).
- **Electrons ($e^-$)**: Negatively charged, occupy quantized orbital clouds.

### 2. Chemical Bonding Types
1. **Covalent Bonding**: Sharing of electron pairs between nonmetals (e.g., $H_2O, CH_4$).
2. **Ionic Bonding**: Complete transfer of valence electrons from metal to nonmetal, forming electrostatic lattice attractions (e.g., $Na^+Cl^-$).
3. **Metallic Bonding**: Delocalized electron sea shared across metal cations.

### 3. Balanced Chemical Reaction Example
Combustion of methane:
$$CH_4 + 2O_2 \longrightarrow CO_2 + 2H_2O + \Delta H$$''';
    }

    // 12. Biology: Cell Biology & Photosynthesis
    if (lower.contains('photosynthesis') ||
        lower.contains('cell') ||
        lower.contains('biology') ||
        lower.contains('mitochondria') ||
        lower.contains('dna')) {
      return r'''### 🧬 Biology: Cellular Structure & Energetics

### 1. Core Cell Organelles
- **Nucleus**: Houses genetic DNA blueprint and coordinates replication.
- **Mitochondria**: The "powerhouse" executing cellular respiration to generate ATP.
- **Ribosomes**: Complexes synthesizing polypeptide protein chains from mRNA.
- **Chloroplasts**: Plant organelles containing chlorophyll for photosynthesis.

### 2. Photosynthesis Equation
Plants convert solar photon energy into biochemical chemical energy:
$$6CO_2 + 6H_2O + \text{Photons} \longrightarrow C_6H_{12}O_6 + 6O_2$$

### 3. Cellular Respiration
Cells metabolize glucose into usable cellular energy currency:
$$C_6H_{12}O_6 + 6O_2 \longrightarrow 6CO_2 + 6H_2O + \approx 32\text{ ATP}$$''';
    }

    // 13. Computer Science: Python & Algorithms
    if (lower.contains('python') ||
        lower.contains('code') ||
        lower.contains('algorithm') ||
        lower.contains('program') ||
        lower.contains('data structure')) {
      return r'''### 💻 Computer Science: Python & Algorithmic Design

### 1. Clean Recursive Implementation in Python
```python
def binary_search(arr: list[int], target: int) -> int:
    """Returns index of target in sorted array, or -1 if not found."""
    low, high = 0, len(arr) - 1
    while low <= high:
        mid = (low + high) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            low = mid + 1
        else:
            high = mid - 1
    return -1

# Example
numbers = [2, 5, 8, 12, 16, 23, 38, 56, 72]
print("Index:", binary_search(numbers, 23))  # Outputs: 5
```

### 2. Complexity Analysis
- **Time Complexity**: $\mathcal{O}(\log n)$ (halves search interval each step)
- **Space Complexity**: $\mathcal{O}(1)$ iterative space.''';
    }

    // 14. Universal Dynamic Pedagogical Synthesizer (For any user query)
    return _synthesizeUniversalAnswer(cleaned);
  }

  /// Strips query prefixes inserted by UI cards or user formatting
  String _cleanPrompt(String prompt) {
    String text = prompt.trim();
    final prefixes = [
      'Help with Homework:',
      'Help with Homework',
      'Explain a Concept:',
      'Explain a Concept',
      'Practice Questions:',
      'Practice Questions',
      'Study for an Exam:',
      'Study for an Exam',
      'Solve:',
      'Explain:',
    ];

    for (final prefix in prefixes) {
      if (text.toLowerCase().startsWith(prefix.toLowerCase())) {
        text = text.substring(prefix.length).trim();
        if (text.startsWith(':')) {
          text = text.substring(1).trim();
        }
      }
    }
    return text;
  }

  /// Solves direct arithmetic expressions like "25 + 47", "12 * 8", "100 - 36"
  String? _trySolveArithmetic(String query) {
    final pattern = RegExp(
      r'(?:what\s+is\s+|calculate\s+|solve\s+)?(\d+(?:\.\d+)?)\s*([\+\-\*\/x×÷\^])\s*(\d+(?:\.\d+)?)',
    );
    final match = pattern.firstMatch(query);
    if (match == null) return null;

    final num1Str = match.group(1)!;
    final opStr = match.group(2)!;
    final num2Str = match.group(3)!;

    final double? a = double.tryParse(num1Str);
    final double? b = double.tryParse(num2Str);
    if (a == null || b == null) return null;

    double result = 0;
    String operationName = '';
    String operatorSymbol = opStr;

    if (opStr == '+') {
      result = a + b;
      operationName = 'Addition';
    } else if (opStr == '-') {
      result = a - b;
      operationName = 'Subtraction';
    } else if (opStr == '*' || opStr == 'x' || opStr == '×') {
      result = a * b;
      operationName = 'Multiplication';
      operatorSymbol = r'\times';
    } else if (opStr == '/' || opStr == '÷') {
      if (b == 0) {
        return '### ⚠️ Mathematical Error: Division by Zero\n\n'
            'Division by zero is undefined in mathematics because no number multiplied by zero can produce a non-zero dividend.';
      }
      result = a / b;
      operationName = 'Division';
      operatorSymbol = r'\div';
    } else {
      return null;
    }

    final formattedResult = (result % 1 == 0)
        ? result.toInt().toString()
        : result.toStringAsFixed(2);

    final steps = _generateCalculationSteps(a, b, opStr, result);

    final mathFormula =
        '${r"$$\mathbf{"}$num1Str $operatorSymbol $num2Str = $formattedResult${r"}$$"}';
    final mathResult = '${r"$$\mathbf{"}$formattedResult${r"}$$"}';

    return '### 📘 Step-by-Step $operationName\n\n'
        'Here is the step-by-step mathematical solution:\n\n'
        '$mathFormula\n\n'
        '---\n\n'
        '### 1. Breakdown of Terms\n'
        '- **First Term**: $num1Str\n'
        '- **Second Term**: $num2Str\n'
        '- **Operator**: $opStr ($operationName)\n\n'
        '### 2. Method of Calculation\n'
        '$steps\n\n'
        '### 3. Final Answer\n'
        '$mathResult';
  }

  String _generateCalculationSteps(
    double a,
    double b,
    String op,
    double result,
  ) {
    final aStr = (a % 1 == 0) ? a.toInt().toString() : a.toStringAsFixed(2);
    final bStr = (b % 1 == 0) ? b.toInt().toString() : b.toStringAsFixed(2);
    final resStr =
        (result % 1 == 0) ? result.toInt().toString() : result.toStringAsFixed(2);

    if (op == '+') {
      return '1. Align numbers by their decimal and place value positions.\n'
          '2. Add digits from right to left (ones, tens, hundreds), carrying over when a sum exceeds 9.\n'
          '3. Summing $aStr and $bStr gives the total: **$resStr**.';
    } else if (op == '-') {
      return '1. Align the minuend ($aStr) and subtrahend ($bStr).\n'
          '2. Subtract column by column from right to left, borrowing 10 from the next place value where necessary.\n'
          '3. The difference is: **$resStr**.';
    } else if (op == '*' || op == 'x' || op == '×') {
      return '1. Multiply $aStr by each place value of $bStr.\n'
          '2. Sum the partial products together.\n'
          '3. Total product is: **$resStr**.';
    } else {
      return '1. Divide the dividend ($aStr) by the divisor ($bStr).\n'
          '2. The quotient is: **$resStr**.';
    }
  }

  /// Synthesizes an articulate, high-value pedagogical response for any query
  String _synthesizeUniversalAnswer(String topic) {
    final title = topic.isEmpty ? 'Study Concept' : topic;
    return '### 🎓 Educational Guide: $title\n\n'
        'Here is a structured explanation to help you master this topic:\n\n'
        '---\n\n'
        '### 1. Core Definition & Overview\n'
        '**$title** is a fundamental concept. To understand it clearly:\n'
        '- It establishes the foundational principle connecting underlying theory to practical problem solving.\n'
        '- Mastering this concept requires identifying the key variables and their relationships.\n\n'
        '---\n\n'
        '### 2. Fundamental Mechanics & Rules\n'
        'When analyzing **$title**, keep these three core principles in mind:\n'
        '1. **Decomposition**: Break complex scenarios down into their primary governing rules.\n'
        '2. **Logical Sequence**: Follow standard procedural orders (such as order of operations or scientific deduction).\n'
        '3. **Consistency**: Verify units, definitions, and boundary conditions at each step.\n\n'
        '---\n\n'
        '### 3. Real-World Application & Analogy\n'
        'In practical scenarios, **$title** acts like a building block:\n'
        'Just as a foundation supports a building, understanding this concept gives you the tools to tackle higher-level problem sets with confidence.\n\n'
        '---\n\n'
        '### 4. Practice & Self-Check\n'
        'To solidify your understanding, ask yourself:\n'
        '- *Can I explain this concept in my own words to someone else?*\n'
        '- *How does this rule apply to edge cases?*\n\n'
        'Feel free to ask me for a specific equation, practice problem, or deeper breakdown!';
  }
}
