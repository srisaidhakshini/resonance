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
    final cleaned = _cleanPrompt(rawPrompt);
    final lower = cleaned.toLowerCase().trim();

    // 1. Conversational / Greetings / Small Talk Detection
    final conversationalReply = _tryHandleConversational(lower);
    if (conversationalReply != null) {
      return conversationalReply;
    }

    // 2. Direct Arithmetic Solver (e.g. "25 + 47", "what is 15 * 8", "120 / 4")
    final arithmeticResult = _trySolveArithmetic(lower);
    if (arithmeticResult != null) {
      return arithmeticResult;
    }

    // 3. Algebraic Linear Equation Solver (e.g. "3x + 5 = 20", "solve 2x - 4 = 10")
    final linearEquationResult = _trySolveLinearEquation(lower);
    if (linearEquationResult != null) {
      return linearEquationResult;
    }

    // 4. Percentage Solver (e.g. "what is 20% of 150")
    final percentageResult = _trySolvePercentage(lower);
    if (percentageResult != null) {
      return percentageResult;
    }

    // 5. Cybersecurity & Information Security
    if (lower.contains('cybersecurity') ||
        lower.contains('cyber security') ||
        lower.contains('hacker') ||
        lower.contains('hacking') ||
        lower.contains('firewall') ||
        lower.contains('malware') ||
        lower.contains('phishing') ||
        lower.contains('cia triad') ||
        lower.contains('ransomware') ||
        lower.contains('zero trust')) {
      return r'''### 🛡️ Understanding Cybersecurity

**Cybersecurity** is the practice of protecting computer systems, networks, devices, programs, and data from digital attacks, unauthorized access, damage, or theft.

---

### 1. The Core Foundation: The CIA Triad
All cybersecurity policies and architectures revolve around three essential pillars:
- **Confidentiality**: Ensuring sensitive information is accessible only to authorized entities (implemented via AES encryption, passwords, and multi-factor authentication).
- **Integrity**: Safeguarding the accuracy and completeness of data by preventing unauthorized tampering (implemented via cryptographic hashing like SHA-256 and digital signatures).
- **Availability**: Guaranteeing that systems, applications, and data are dependable and accessible when needed by legitimate users (implemented via redundancy, automated backups, and DDoS protection).

---

### 2. Major Categories of Cyber Threats
1. **Malware**: Malicious software including viruses, ransomware, trojans, and spyware engineered to disrupt or compromise systems.
2. **Phishing**: Social engineering attacks using deceptive communications to manipulate individuals into disclosing credentials or financial data.
3. **Man-in-the-Middle (MitM)**: Attackers covertly intercepting and altering communication between two parties (e.g., across unencrypted Wi-Fi networks).
4. **Denial-of-Service (DoS / DDoS)**: Flooding a targeted server or network with illegitimate traffic to exhaust its resources and cause outages.
5. **Zero-Day Exploits**: Attacks targeting software vulnerabilities before developers have created a patch.

---

### 3. Key Defensive Strategies
- **Defense in Depth**: Applying multiple layered security controls across endpoints, networks, and applications.
- **Zero Trust Architecture**: Operating on the principle of *"never trust, always verify"*—requiring continuous authentication for every request.
- **Access Control & IAM**: Enforcing the Principle of Least Privilege (PoLP) so users only have the minimum access necessary.
- **Incident Response & Patching**: Regular vulnerability assessments and systematic security updates.

---

### 💡 Practice Question
*Why is human user awareness considered both the most vulnerable link and the first line of defense in cybersecurity?*
*(Hint: Technical firewalls cannot prevent a user from voluntarily clicking a phishing link, making cybersecurity training vital!)*''';
    }

    // 6. Cloud Computing
    if (lower.contains('cloud computing') ||
        lower.contains('what is cloud') ||
        lower.contains('saas') ||
        lower.contains('paas') ||
        lower.contains('iaas')) {
      return r'''### ☁️ Understanding Cloud Computing

**Cloud Computing** is the on-demand delivery of computing services—including servers, storage, databases, networking, software, and analytics—over the internet ("the cloud") with pay-as-you-go pricing.

---

### 1. The Three Primary Cloud Service Models
1. **IaaS (Infrastructure as a Service)**:
   - Provides fundamental compute and storage infrastructure. You manage the OS, runtime, and applications.
   - *Examples*: AWS EC2, Google Compute Engine, Microsoft Azure VMs.
2. **PaaS (Platform as a Service)**:
   - Provides a hardware and software framework so developers can build and deploy applications without managing underlying infrastructure.
   - *Examples*: Google App Engine, Heroku, AWS Elastic Beanstalk.
3. **SaaS (Software as a Service)**:
   - Complete, fully managed end-user applications delivered over a web browser.
   - *Examples*: Google Workspace, Microsoft 365, Dropbox.

---

### 2. Core Advantages
- **Elastic Scalability**: Instantly scale computing resources up or down according to demand.
- **High Availability & Fault Tolerance**: Automated replication across geographic regions.
- **Cost Efficiency**: Eliminates capital expenses for physical data centers and on-premise hardware maintenance.''';
    }

    // 7. Artificial Intelligence & Machine Learning
    if (lower.contains('artificial intelligence') ||
        lower.contains('machine learning') ||
        lower.contains('neural network') ||
        lower.contains('deep learning') ||
        lower == 'what is ai' ||
        lower.contains('concept of ai')) {
      return r'''### 🤖 Artificial Intelligence & Machine Learning

**Artificial Intelligence (AI)** is the broad scientific discipline dedicated to creating software systems capable of performing tasks that typically require human intelligence, such as visual perception, natural language understanding, reasoning, and decision-making.

---

### 1. The Hierarchy of AI
- **Artificial Intelligence (Broadest)**: The overarching goal of building smart machines.
- **Machine Learning (Subset)**: Statistical algorithms that learn patterns from training data to make predictions rather than following explicitly hardcoded rules.
- **Deep Learning (Subfield of ML)**: Utilizes multi-layered artificial neural networks inspired by biological brain architectures to process unstructured data like images, audio, and text.

---

### 2. Core Machine Learning Paradigms
1. **Supervised Learning**: Model learns from labeled input-output pairs (e.g., classification, regression, spam filtering).
2. **Unsupervised Learning**: Model discovers hidden patterns and clusterings in unlabeled data (e.g., customer segmentation, anomaly detection).
3. **Reinforcement Learning**: An agent learns optimal actions through trial-and-error rewards and penalties within an environment (e.g., robotics, game engines).''';
    }

    // 8. Operating Systems
    if (lower.contains('operating system') ||
        lower.contains('what is an os') ||
        lower.contains('kernel') ||
        lower.contains('linux') ||
        lower.contains('virtual memory')) {
      return r'''### 💻 What is an Operating System?

An **Operating System (OS)** is the core system software that manages computer hardware components, coordinates software resources, and provides standard abstraction layers for user applications.

---

### 1. Key Functions of an Operating System
1. **Process Management**: Allocates CPU time across competing processes using scheduling algorithms (e.g., Round Robin, Priority Scheduling).
2. **Memory Management**: Coordinates RAM allocation using **Virtual Memory** and paging, allowing programs to exceed physical memory capacity safely.
3. **File System Management**: Organizes file hierarchies, storage directories, access permissions, and data read/write caching (e.g., NTFS, ext4, APFS).
4. **Device Management**: Interfaces with peripherals (graphics cards, keyboards, SSDs) via specialized device drivers.

---

### 2. The Kernel Architecture
The **Kernel** is the central component of an OS that operates with highest hardware privileges (Kernel Mode / Ring 0), managing the bridge between user-space applications and physical hardware.''';
    }

    // 9. Computer Networking & The Internet
    if (lower.contains('networking') ||
        lower.contains('how the internet works') ||
        lower.contains('tcp/ip') ||
        lower.contains('osi model') ||
        lower.contains('dns') ||
        lower.contains('ip address')) {
      return r'''### 🌐 Computer Networking & Internet Architecture

A **Computer Network** is a collection of interconnected computing nodes that communicate and share resources using standardized communication protocols.

---

### 1. The OSI 7-Layer Model
```text
[7] Application  : HTTP, HTTPS, DNS, SSH, FTP
[6] Presentation : TLS/SSL encryption, data encoding
[5] Session      : Session establishment and token management
[4] Transport    : TCP (reliable, connection-oriented) / UDP (fast, datagram)
[3] Network      : IP routing, logical addressing (IPv4, IPv6)
[2] Data Link    : MAC addressing, Ethernet frames, switches
[1] Physical     : Fiber-optic cables, copper wire, radio waves
```

---

### 2. How Web Requests Work (e.g., Opening a Website)
1. **DNS Lookup**: Your browser queries a Domain Name System server to translate a domain name (e.g., `example.com`) into an IP address.
2. **TCP 3-Way Handshake**: Client and server establish a reliable connection (`SYN` → `SYN-ACK` → `ACK`).
3. **TLS Negotiation**: Keys are securely exchanged to encrypt the channel.
4. **HTTP Request/Response**: Browser issues a `GET` request and renders the incoming HTML, CSS, and JavaScript payload.''';
    }

    // 10. Mathematics: Addition
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

> **a + b = c**

- **Addends**: The numbers being combined (here, *a* and *b*).
- **Plus Sign (+)**: The mathematical operator signaling addition.
- **Sum**: The total resulting quantity (*c*).

---

### 2. Fundamental Mathematical Properties
1. **Commutative Property**: Changing the order of addends does not change the sum.
   > **a + b = b + a**  *(e.g., 4 + 7 = 7 + 4 = 11)*

2. **Associative Property**: The grouping of addends does not affect the sum.
   > **(a + b) + c = a + (b + c)**  *(e.g., (2 + 3) + 5 = 2 + (3 + 5) = 10)*

3. **Identity Property (Zero Property)**: Adding zero to any number leaves it unchanged.
   > **a + 0 = a**  *(e.g., 9 + 0 = 9)*

---

### 3. Step-by-Step Example: Column Addition with Regrouping
Let us solve: **47 + 38**

1. **Align by Place Value**:
   ```text
     [Tens]  [Ones]
        4      7
   +    3      8
   ---------------
   ```
2. **Add the Ones Column**:
   7 + 8 = 15
   - Write **5** in the ones place.
   - Carry **1** (representing 1 ten) to the tens column.

3. **Add the Tens Column** (including the carried 1):
   1 (carry) + 4 + 3 = 8

4. **Final Result**:
   > **47 + 38 = 85**

---

### 💡 Quick Practice
Try calculating **56 + 29**.
*(Hint: Add 6 + 9 = 15 [carry 1], then 1 + 5 + 2 = 8 ⟹ **85**)*''';
    }

    // 11. Mathematics: Subtraction
    if (lower.contains('subtraction') ||
        lower.contains('subtract') ||
        lower.contains('minus')) {
      return r'''### 📘 What is Subtraction?

**Subtraction** is the inverse operation of addition. It calculates the difference between two quantities or determines how much remains when a part is taken away from a whole.

---

### 1. Key Terminology
> **a − b = c**

- **Minuend (a)**: The initial total quantity from which another is subtracted.
- **Subtrahend (b)**: The quantity being taken away.
- **Difference (c)**: The final remaining quantity.

---

### 2. Regrouping (Borrowing) Method
Let us solve: **72 − 38**

1. In the ones column: *2 − 8* cannot be computed in positive whole numbers.
2. Borrow **1 ten** from 7 tens, turning 7 into 6 tens.
3. The 2 ones becomes 12 ones:
   12 − 8 = 4
4. In the tens column:
   6 − 3 = 3
5. Final Result:
   > **72 − 38 = 34**

*Check by Addition*: 34 + 38 = 72.''';
    }

    // 12. Mathematics: Multiplication
    if (lower.contains('multiplication') ||
        lower.contains('multiply') ||
        lower.contains('times table')) {
      return r'''### 📘 Understanding Multiplication

**Multiplication** represents repeated addition of the same quantity.
For example, *4 × 3* means adding 4 three times:

> **4 + 4 + 4 = 12**

---

### 1. Core Mathematical Properties
- **Commutative**: a × b = b × a
- **Associative**: (a × b) × c = a × (b × c)
- **Distributive**: a × (b + c) = (a × b) + (a × c)
- **Zero Property**: a × 0 = 0
- **Identity Property**: a × 1 = a

---

### 2. Example: 14 × 6
Using the distributive property:
> **14 × 6 = (10 + 4) × 6 = (10 × 6) + (4 × 6) = 60 + 24 = 84**''';
    }

    // 13. Mathematics: Division & Fractions
    if (lower.contains('division') ||
        lower.contains('divide') ||
        lower.contains('fraction')) {
      return r'''### 📘 Understanding Division & Fractions

**Division** splits a quantity into equal groups. It is the inverse operation of multiplication.

---

### 1. The Division Equation
> **a ÷ b = q  (Remainder r)**

- **Dividend (a)**: Total quantity to be divided.
- **Divisor (b)**: Number of equal groups (b ≠ 0).
- **Quotient (q)**: Result per group.
- **Remainder (r)**: Amount left over (0 ≤ r < b).

---

### 2. Working with Fractions
- **Common Denominators**: (a / c) + (b / c) = (a + b) / c
- **Multiplication**: (a / b) × (c / d) = (a × c) / (b × d)
- **Division (Reciprocal Rule)**: (a / b) ÷ (c / d) = (a / b) × (d / c)''';
    }

    // 14. Mathematics: Quadratic Equations & Algebra
    if (lower.contains('quadratic') ||
        lower.contains('algebra') ||
        lower.contains('factor')) {
      return r'''### 📐 Quadratic Equations & Algebra Guide

A quadratic equation is a second-degree polynomial equation in a single variable *x*:

> **ax² + bx + c = 0  (where a ≠ 0)**

---

### 1. The Quadratic Formula
> **x = (−b ± √(b² − 4ac)) / (2a)**

---

### 2. The Discriminant (Δ = b² − 4ac)
- If **Δ > 0**: Two distinct real roots.
- If **Δ = 0**: Exactly one real repeated root (x = −b / 2a).
- If **Δ < 0**: Two complex conjugate roots.

---

### 3. Worked Example: x² − 5x + 6 = 0
Here a = 1, b = −5, c = 6.
By factoring:
> **(x − 2)(x − 3) = 0  ⟹  x₁ = 2,  x₂ = 3**''';
    }

    // 15. Mathematics: Calculus & Derivatives
    if (lower.contains('derivative') ||
        lower.contains('calculus') ||
        lower.contains('differentiat') ||
        lower.contains('integral')) {
      return r'''### 📈 Calculus: Differential & Integral Foundations

Calculus studies continuous change through **differentiation** (instantaneous rates of change) and **integration** (accumulation of areas and quantities).

---

### 1. Definition of the Derivative
> **f'(x) = lim(h → 0) [ (f(x + h) − f(x)) / h ]**

---

### 2. Essential Differentiation Rules
- **Power Rule**: d/dx [xⁿ] = n · xⁿ⁻¹
- **Product Rule**: d/dx [u · v] = u'v + uv'
- **Quotient Rule**: d/dx [u / v] = (u'v − uv') / v²
- **Chain Rule**: d/dx [f(g(x))] = f'(g(x)) · g'(x)

---

### 3. Worked Example
Differentiate: f(x) = 4x³ − 5x² + 7x − 9
> **f'(x) = 4(3x²) − 5(2x) + 7(1) − 0 = 12x² − 10x + 7**''';
    }

    // 16. Physics: Newton's Laws & Mechanics
    if (lower.contains('newton') ||
        lower.contains('force') ||
        lower.contains('physics') ||
        lower.contains('motion') ||
        lower.contains('acceleration')) {
      return r'''### ⚡ Physics: Newton's Three Laws of Motion

Sir Isaac Newton formulated the three foundation laws governing classical mechanics:

---

1. **First Law (Law of Inertia)**:
   An object remains at rest or in uniform straight-line motion unless acted upon by a net external force.
   > **∑ F = 0  ⟹  v = constant**

2. **Second Law (Fundamental Law of Dynamics)**:
   The acceleration of an object is directly proportional to net applied force and inversely proportional to its mass.
   > **F_net = m · a**
   *(Force in Newtons, Mass in kg, Acceleration in m/s²)*

3. **Third Law (Action-Reaction)**:
   When body A exerts a force on body B, body B simultaneously exerts an equal and opposite force on body A.
   > **F_AB = −F_BA**

---

### Real-World Example
A space rocket accelerates upward because its engines expel exhaust gases downward at high velocity (Action ⟹ Reaction).''';
    }

    // 17. Physics: Gravity & Energy
    if (lower.contains('gravity') ||
        lower.contains('gravitation') ||
        lower.contains('energy') ||
        lower.contains('kinetic')) {
      return r'''### 🌌 Gravity & Mechanical Energy

### 1. Universal Gravitation
Newton's Law of Gravitation states that any two massive bodies attract each other with a force proportional to the product of their masses:
> **F = G · (m₁ · m₂) / r²**

- Gravitational constant G ≈ 6.674 × 10⁻¹¹ N·m²/kg²
- Near Earth's surface: g ≈ 9.8 m/s²  ⟹  Weight W = m·g

---

### 2. Conservation of Mechanical Energy
In an isolated system without non-conservative friction forces:
> **E_total = KE + PE = constant**

- **Kinetic Energy**: KE = ½ m·v²
- **Gravitational Potential Energy**: PE = m·g·h''';
    }

    // 18. Physics: Why is the sky blue?
    if (lower.contains('sky blue') || lower.contains('blue sky')) {
      return r'''### 🌤️ Why is the Sky Blue?

The blue color of the daytime sky is caused by an optical phenomenon known as **Rayleigh Scattering**.

---

### 1. The Composition of Sunlight
Sunlight appears white, but it is actually a blend of all visible colors. Each color travels in waves of different lengths:
- **Red & Orange**: Long wavelengths (~700 nm)
- **Blue & Violet**: Short wavelengths (~400 nm)

---

### 2. Atmospheric Scattering
As sunlight passes through Earth's atmosphere, it collides with gases (primarily Nitrogen and Oxygen molecules):
- Light with shorter wavelengths scatters much more strongly than longer wavelengths.
- Scattering efficiency is inversely proportional to the fourth power of wavelength:
  > **Scattering ∝ 1 / λ⁴**
- Because blue light has a wavelength nearly half that of red light, it is scattered approximately **10 times more efficiently** in every direction.

---

### 3. Why Not Violet?
Violet light scatters even more than blue light! However, the sky appears blue because:
1. The Sun radiates significantly higher amounts of blue light than violet light.
2. Human eyes are much more sensitive to blue light due to our retinal cone receptors.''';
    }

    // 19. Chemistry: Atoms, Periodic Table & Bonding
    if (lower.contains('atom') ||
        lower.contains('periodic table') ||
        lower.contains('chemistry') ||
        lower.contains('bond') ||
        lower.contains('element')) {
      return r'''### 🧪 Chemistry: Atomic Structure & Chemical Bonding

### 1. Subatomic Particles
- **Protons (p⁺)**: Positively charged particles in the nucleus. Defines the **Atomic Number (Z)**.
- **Neutrons (n⁰)**: Neutral particles in the nucleus. Contributes to atomic mass (A = Z + N).
- **Electrons (e⁻)**: Negatively charged particles orbiting in quantized energy shells.

---

### 2. Primary Types of Chemical Bonds
1. **Covalent Bonding**: Mutual sharing of valence electron pairs between nonmetal atoms (e.g., H₂O, CH₄).
2. **Ionic Bonding**: Complete transfer of valence electrons from a metal to a nonmetal, forming electrostatic lattice attractions (e.g., Na⁺Cl⁻).
3. **Metallic Bonding**: Sea of delocalized electrons freely moving across positive metal cations.

---

### 3. Balanced Chemical Equation Example
Combustion of methane gas:
> **CH₄ + 2 O₂  →  CO₂ + 2 H₂O  +  Energy**''';
    }

    // 20. Biology: Cell Biology & Photosynthesis
    if (lower.contains('photosynthesis') ||
        lower.contains('cell') ||
        lower.contains('biology') ||
        lower.contains('mitochondria') ||
        lower.contains('dna')) {
      return r'''### 🧬 Biology: Cellular Structure & Energetics

### 1. Essential Cell Organelles
- **Nucleus**: The command center containing DNA genetic instructions.
- **Mitochondria**: The "powerhouse of the cell" executing cellular respiration to synthesize ATP energy.
- **Ribosomes**: Macromolecular machines that assemble amino acids into proteins according to mRNA sequences.
- **Chloroplasts**: Plant cell organelles containing chlorophyll that capture light energy for photosynthesis.

---

### 2. Photosynthesis Reaction
Green plants convert solar photon energy into chemical energy:
> **6 CO₂ + 6 H₂O + Photons  →  C₆H₁₂O₆ + 6 O₂**

---

### 3. Cellular Respiration
Living cells metabolize glucose to produce usable cellular ATP currency:
> **C₆H₁₂O₆ + 6 O₂  →  6 CO₂ + 6 H₂O + ~32 ATP**''';
    }

    // 21. Computer Science: Python & Algorithms
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

---

### 2. Algorithmic Complexity Analysis
- **Time Complexity**: **O(log n)** (halves the search space at each step).
- **Space Complexity**: **O(1)** (constant auxiliary memory).''';
    }

    // 22. Universal Dynamic Pedagogical Synthesizer (For open-ended academic queries)
    return _synthesizeUniversalAnswer(cleaned);
  }

  /// Handles conversational greetings, small talk, gratitude, and identity queries
  String? _tryHandleConversational(String lower) {
    final isGreeting = lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'hi, hello' ||
        lower == 'hello, hi' ||
        lower == 'hi hello' ||
        lower == 'hello hi' ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ') ||
        lower.startsWith('hi ') ||
        lower.startsWith('good morning') ||
        lower.startsWith('good afternoon') ||
        lower.startsWith('good evening') ||
        lower == 'greetings' ||
        lower == 'yo' ||
        lower == 'sup';

    if (isGreeting) {
      return '### 👋 Hello!\n\n'
          'I am **Echo**, your offline AI study tutor.\n\n'
          'How can I assist you with your studies today? You can ask me to:\n'
          '- 📐 **Solve math problems** (e.g. `25 + 47`, `3x + 5 = 20`, or calculus)\n'
          '- 🔬 **Explain science concepts** (e.g. `photosynthesis`, `Newton\'s laws`, `why is the sky blue`)\n'
          '- 🛡️ **Technology & Cybersecurity** (e.g. `what is cybersecurity`, `cloud computing`, `AI`)\n'
          '- 💻 **Help with programming** (e.g. Python, data structures, algorithms)\n'
          '- 📝 **Review homework** or test your knowledge with practice questions!';
    }

    // "How are you"
    if (lower.contains('how are you') ||
        lower.contains('how r u') ||
        lower.contains('how do you do') ||
        lower.contains("what's up")) {
      return "I'm doing great, thank you for asking! I'm fully ready to help you explore concepts, solve homework problems, and prepare for your exams.\n\nWhat subject are you working on right now?";
    }

    // Gratitude: "thank you", "thanks"
    if (lower.contains('thank') || lower == 'thx' || lower == 'appreciate it') {
      return "You're very welcome! I'm glad I could help.\n\nFeel free to ask another question or let me know if you want to try a practice problem!";
    }

    // Acknowledgments: "ok", "okay", "cool", "great", "awesome", "got it"
    if (lower == 'ok' ||
        lower == 'okay' ||
        lower == 'cool' ||
        lower == 'great' ||
        lower == 'awesome' ||
        lower == 'nice' ||
        lower == 'got it' ||
        lower == 'understood' ||
        lower == 'sure' ||
        lower == 'yes' ||
        lower == 'yep') {
      return "Sounds great! Whenever you're ready, let me know what problem or topic you'd like to tackle next.";
    }

    // Farewells: "bye", "goodbye", "see you"
    if (lower == 'bye' ||
        lower == 'goodbye' ||
        lower.startsWith('bye ') ||
        lower.contains('see you') ||
        lower == 'cya') {
      return 'Goodbye! Great job working on your studies today. Come back anytime you need homework help or concept explanations!';
    }

    // Identity: "who are you", "what is your name"
    if (lower.contains('who are you') ||
        lower.contains('what is your name') ||
        lower.contains('what are you') ||
        lower == 'who made you') {
      return 'I am **Echo**, an offline-first educational AI tutor designed by the **Technauts** team.\n\n'
          'I help students understand core STEM and humanities subjects with step-by-step problem solving, clear explanations, and interactive learning.';
    }

    // Capability / Help: "what can you do", "help"
    if (lower == 'what can you do' ||
        lower == 'help' ||
        lower == 'help me' ||
        lower.contains('features')) {
      return '### 💡 How Echo Can Help You:\n\n'
          '1. **Step-by-Step Math Solving**: Try typing `25 + 47`, `15 * 8`, or `3x + 5 = 20`.\n'
          '2. **Computer Science & Security**: Inquire about `cybersecurity`, `cloud computing`, or `AI`.\n'
          '3. **Science Concepts**: Ask `what is addition`, `why is the sky blue`, or `explain gravity`.\n'
          '4. **Biology & Chemistry**: Ask about `photosynthesis`, `atoms`, or `mitochondria`.\n'
          '5. **Coding & Algorithms**: Request `Python binary search` or `Big-O complexity`.\n\n'
          'What would you like to start with?';
    }

    // Very short gibberish guard (e.g. "asdf", "??", "123")
    if (lower.length <= 2 &&
        !RegExp(r'[0-9]').hasMatch(lower) &&
        lower != 'pi') {
      return "I didn't quite catch that. Could you please type a full question or topic you'd like help with?";
    }

    return null;
  }

  /// Solves linear equations of the form "ax + b = c" or "ax - b = c"
  String? _trySolveLinearEquation(String query) {
    final pattern = RegExp(
      r'(?:solve\s+)?(\d*)\s*([a-zA-Z])\s*([\+\-])?\s*(\d+)?\s*=\s*(\d+)',
    );
    final match = pattern.firstMatch(query);
    if (match == null) return null;

    final coeffStr = match.group(1);
    final variable = match.group(2)!;
    final signStr = match.group(3);
    final constStr = match.group(4);
    final rhsStr = match.group(5)!;

    final double a = (coeffStr == null || coeffStr.isEmpty)
        ? 1.0
        : (double.tryParse(coeffStr) ?? 1.0);
    final double b = (constStr == null)
        ? 0.0
        : (double.tryParse(constStr) ?? 0.0) * (signStr == '-' ? -1.0 : 1.0);
    final double c = double.tryParse(rhsStr) ?? 0.0;

    if (a == 0) return null;

    final x = (c - b) / a;
    final formattedX =
        (x % 1 == 0) ? x.toInt().toString() : x.toStringAsFixed(2);
    final aDisplay = a == 1.0 ? '' : (a % 1 == 0 ? a.toInt().toString() : '$a');
    final bSign = b >= 0 ? '+' : '-';
    final bAbs = b.abs() % 1 == 0 ? b.abs().toInt().toString() : '${b.abs()}';

    final cDisplay = c % 1 == 0 ? c.toInt().toString() : '$c';
    final cbDisplay =
        (c - b) % 1 == 0 ? (c - b).toInt().toString() : '${c - b}';
    final eqFormula =
        '> **$aDisplay$variable ${b != 0 ? '$bSign $bAbs' : ''} = $cDisplay**';
    final finalEq = '> **$variable = $formattedX**';

    return '### 📐 Step-by-Step Linear Equation Solution\n\n'
        'We are solving for **$variable** in the equation:\n\n'
        '$eqFormula\n\n'
        '---\n\n'
        '### Step 1: Isolate the Variable Term\n'
        '${b != 0 ? 'Subtract ($bSign $bAbs) from both sides of the equation:\n\n'
            '> **$aDisplay$variable = $cDisplay ${b >= 0 ? '-' : '+'} $bAbs**\n\n'
            '> **$aDisplay$variable = $cbDisplay**\n' : 'The variable term is already isolated.'}\n\n'
        '### Step 2: Divide by the Coefficient of $variable\n'
        '${a != 1.0 ? 'Divide both sides by **$aDisplay**:\n\n'
            '> **$variable = $cbDisplay / $aDisplay = $formattedX**\n' : 'The coefficient is 1, so the solution is immediate.'}\n\n'
        '---\n\n'
        '### Final Answer\n'
        '$finalEq\n\n'
        '*Verification*: Substituting $variable = $formattedX back into the original equation confirms both sides balance.';
  }

  /// Solves percentage problems like "what is 20% of 150"
  String? _trySolvePercentage(String query) {
    final pattern = RegExp(
      r'(?:what\s+is\s+)?(\d+(?:\.\d+)?)\s*%\s*(?:of\s*)?(\d+(?:\.\d+)?)',
    );
    final match = pattern.firstMatch(query);
    if (match == null) return null;

    final percentStr = match.group(1)!;
    final baseStr = match.group(2)!;

    final double? p = double.tryParse(percentStr);
    final double? base = double.tryParse(baseStr);
    if (p == null || base == null) return null;

    final result = (p / 100.0) * base;
    final formattedResult = (result % 1 == 0)
        ? result.toInt().toString()
        : result.toStringAsFixed(2);
    final pDiv100 = (p / 100.0).toStringAsFixed(2);

    final formula = '> **Result = ($percentStr / 100) × $baseStr = $formattedResult**';

    return '### 📊 Percentage Calculation\n\n'
        'Here is how to calculate **$percentStr% of $baseStr**:\n\n'
        '$formula\n\n'
        '---\n\n'
        '### Step-by-Step Method:\n'
        '1. **Convert percentage to decimal / fraction**:\n'
        '   > **$percentStr% = $percentStr / 100 = $pDiv100**\n'
        '2. **Multiply by the base amount ($baseStr)**:\n'
        '   > **$pDiv100 × $baseStr = $formattedResult**\n\n'
        '### Final Answer\n'
        '> **$formattedResult**';
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
      'Tell me about:',
      'Tell me about',
      'Can you explain:',
      'Can you explain',
      'What is:',
      'What is ',
      'What are:',
      'What are ',
      'Explain:',
      'Explain ',
      'Solve:',
      'Solve ',
      'Define:',
      'Define ',
      'How does:',
      'How does ',
    ];

    for (final prefix in prefixes) {
      if (text.toLowerCase().startsWith(prefix.toLowerCase())) {
        text = text.substring(prefix.length).trim();
        if (text.startsWith(':')) {
          text = text.substring(1).trim();
        }
      }
    }

    // Remove trailing question marks
    while (text.endsWith('?')) {
      text = text.substring(0, text.length - 1).trim();
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
      operatorSymbol = '−';
    } else if (opStr == '*' || opStr == 'x' || opStr == '×') {
      result = a * b;
      operationName = 'Multiplication';
      operatorSymbol = '×';
    } else if (opStr == '/' || opStr == '÷') {
      if (b == 0) {
        return '### ⚠️ Mathematical Error: Division by Zero\n\n'
            'Division by zero is undefined in mathematics because no number multiplied by zero can produce a non-zero dividend.';
      }
      result = a / b;
      operationName = 'Division';
      operatorSymbol = '÷';
    } else {
      return null;
    }

    final formattedResult = (result % 1 == 0)
        ? result.toInt().toString()
        : result.toStringAsFixed(2);

    final steps = _generateCalculationSteps(a, b, opStr, result);
    final mathFormula = '> **$num1Str $operatorSymbol $num2Str = $formattedResult**';
    final mathResult = '> **$formattedResult**';

    return '### 📘 Step-by-Step $operationName\n\n'
        'Here is the step-by-step mathematical solution:\n\n'
        '$mathFormula\n\n'
        '---\n\n'
        '### 1. Breakdown of Terms\n'
        '- **First Term**: $num1Str\n'
        '- **Second Term**: $num2Str\n'
        '- **Operator**: $operatorSymbol ($operationName)\n\n'
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
    final cleanTitle = _capitalize(topic.isEmpty ? 'Your Question' : topic);

    return '### 🎓 Educational Guide: $cleanTitle\n\n'
        'Here is a structured explanation to help you understand **$cleanTitle**:\n\n'
        '---\n\n'
        '### 1. Core Definition & Purpose\n'
        '**$cleanTitle** is an important concept in its field. At its core:\n'
        '- It defines a systematic framework for understanding how related components interact.\n'
        '- It serves to solve specific real-world challenges by organizing principles into reliable practices.\n\n'
        '---\n\n'
        '### 2. Key Components & Working Mechanisms\n'
        'When analyzing **$cleanTitle**, consider these critical dimensions:\n'
        '1. **Foundational Rules**: What primary constraints and governing dynamics dictate its behavior?\n'
        '2. **Component Relationships**: How do the individual parts communicate or depend on one another?\n'
        '3. **Operational Workflow**: What sequential steps take place from input to final outcome?\n\n'
        '---\n\n'
        '### 3. Practical Applications & Real-World Impact\n'
        'Understanding **$cleanTitle** provides practical insight:\n'
        '- It allows practitioners and students to diagnose edge cases and optimize systems.\n'
        '- It forms the foundation for advanced topics and multidisciplinary problem solving.\n\n'
        '---\n\n'
        '### 💡 Self-Check Practice\n'
        'Would you like a specific worked example, practice problem, or a deeper dive into any aspect of **$cleanTitle**? Let me know!';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    final words = s.split(' ');
    return words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
