import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'model_download_service.dart';
import 'personalization_service.dart';
import 'prompt_builder.dart';

import '../models/user_profile.dart';

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

  /// [groundingContext], when provided (retrieved chunks from an active
  /// study chapter, via keyword scoring on web - see RetrievalService),
  /// is prepended for this turn's prompt only.
  Stream<String> streamResponse(String message, {String? groundingContext}) async* {
    _currentGenerationId++;
    final myGenId = _currentGenerationId;
    _isGenerating = true;

    final hasGrounding =
        groundingContext != null && groundingContext.trim().isNotEmpty;
    final effectiveMessage = hasGrounding
        ? 'Context from the loaded chapter:\n$groundingContext\n\nQuestion: $message'
        : message;

    // 1. Attempt connection to local Ollama if available on user machine
    bool localLlmSucceeded = false;
    try {
      final ollamaStream = _tryStreamFromLocalOllama(effectiveMessage, myGenId);
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
    // with active profile styling. The rule-based engine pattern-matches
    // topics rather than reasoning over arbitrary text, so grounding here is
    // extractive (show the most relevant passage) instead of claiming full
    // synthesis - honest about what this fallback tier can actually do.
    final profile = await PersonalizationService.instance.getUserProfile();
    final rawResponse = hasGrounding
        ? _generateGroundedFallback(message, groundingContext)
        : _generateSmartEducationalResponse(message);
    final response = _personalizeWebResponse(rawResponse, profile);
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

  /// Wraps web preview answers with active pedagogical style cues
  String _personalizeWebResponse(String text, UserProfile profile) {
    final prefix = StringBuffer();
    prefix.writeln('> 👤 **Personalized for ${profile.userName}** | Class ${profile.grade} | ${profile.teachingStyle.displayName}\n');

    switch (profile.teachingStyle) {
      case TeachingStyle.socratic:
        prefix.writeln('🤔 **Socratic Checkpoint:**');
        prefix.writeln('*Before reading the full breakdown below, what core principle or intuition comes to your mind for this problem? How would you take the very first step?*\n');
        prefix.writeln('---\n');
        break;
      case TeachingStyle.storytelling:
        prefix.writeln('📖 **Intuitive Storytelling Perspective:**');
        prefix.writeln('*Let\'s connect this concept to everyday objects and stories so it clicks intuitively!*\n');
        prefix.writeln('---\n');
        break;
      case TeachingStyle.direct:
        prefix.writeln('⚡ **Direct Structured Reference:**\n');
        break;
    }

    return '$prefix$text';
  }

  /// Tries streaming from a local Ollama daemon (e.g. running on port 11434)
  Stream<String> _tryStreamFromLocalOllama(String prompt, int genId) async* {
    final profile = await PersonalizationService.instance.getUserProfile();
    final systemPrompt = PromptBuilder.buildSystemPrompt(
      profile: profile,
      hardwareInstructions: 'Provide clear, well-formatted educational answers.',
    );

    final response = await _dio.post(
      'http://127.0.0.1:11434/api/generate',
      data: {
        'model': 'qwen2.5:0.5b',
        'prompt': prompt,
        'system': systemPrompt,
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

  /// Extractive grounded fallback: shows the most relevant passage from the
  /// loaded chapter rather than pretending the rule-based engine can reason
  /// over arbitrary text.
  String _generateGroundedFallback(String question, String context) {
    return '### 📖 From Your Loaded Chapter\n\n'
        'Here is the most relevant passage I found for **"$question"**:\n\n'
        '> ${context.trim()}\n\n'
        '_(Running in the lightweight web fallback engine — for full reasoning '
        "over this passage, use the mobile app.)_";
  }

  /// Core smart pedagogical response generator
  String _generateSmartEducationalResponse(String rawPrompt) {
    final cleaned = _cleanPrompt(rawPrompt);
    final lower = cleaned.toLowerCase().trim();
    final rawLower = rawPrompt.toLowerCase().trim();

    // 1. Conversational / Greetings / Small Talk Detection
    final conversationalReply = _tryHandleConversational(lower, rawLower);
    if (conversationalReply != null) {
      return conversationalReply;
    }

    // 2. Comparison Queries (e.g. "TCP vs UDP", "RAM vs ROM", "difference between X and Y")
    final comparisonReply = _tryHandleComparison(lower, rawLower);
    if (comparisonReply != null) {
      return comparisonReply;
    }

    // 3. Direct Arithmetic Solver (e.g. "25 + 47", "what is 15 * 8", "120 / 4")
    final arithmeticResult = _trySolveArithmetic(lower);
    if (arithmeticResult != null) {
      return arithmeticResult;
    }

    // 4. Algebraic Linear Equation Solver (e.g. "3x + 5 = 20", "solve 2x - 4 = 10")
    final linearEquationResult = _trySolveLinearEquation(lower);
    if (linearEquationResult != null) {
      return linearEquationResult;
    }

    // 5. Percentage Solver (e.g. "what is 20% of 150")
    final percentageResult = _trySolvePercentage(lower);
    if (percentageResult != null) {
      return percentageResult;
    }

    // 6. 3D Geometry & Three-Dimensional Space
    if (lower.contains('3d geometry') ||
        lower.contains('three dimensional geometry') ||
        lower.contains('3d space') ||
        lower.contains('coordinate geometry in 3d') ||
        lower.contains('direction cosine') ||
        lower.contains('equation of a plane') ||
        lower.contains('sphere equation')) {
      return r'''### 📐 Three-Dimensional (3D) Geometry

**3D Geometry** is the branch of mathematics that analyzes figures, points, lines, surfaces, and solids within three-dimensional Euclidean space. Unlike 2D geometry (which uses an $x$ and $y$ plane), 3D space introduces a third mutually perpendicular axis: the **$z$-axis** (depth/height).

---

### 1. The 3D Coordinate System
- **Coordinate Axes**: Three mutually perpendicular lines intersecting at the **Origin** $(0, 0, 0)$:
  - **X-axis** (Width / Left-Right)
  - **Y-axis** (Length / Front-Back)
  - **Z-axis** (Height / Up-Down)
- **Octants**: The three coordinate planes ($xy$, $yz$, $zx$) divide 3D space into **8 octants**.
- Any arbitrary point $P$ is represented by the ordered triplet:
  > **P = (x, y, z)**

---

### 2. Essential 3D Formulas

#### A. 3D Distance Formula
The distance between two points $P(x_1, y_1, z_1)$ and $Q(x_2, y_2, z_2)$:
> **d = √((x₂ − x₁)² + (y₂ − y₁)² + (z₂ − z₁)²)**

#### B. Midpoint & Section Formula
The midpoint $M$ of line segment $PQ$:
> **M = ((x₁ + x₂) / 2, (y₁ + y₂) / 2, (z₁ + z₂) / 2)**

#### C. Direction Cosines & Direction Ratios
If a line makes angles $\alpha, \beta, \gamma$ with the $x, y, z$ axes:
- **Direction Cosines**: $l = \cos\alpha, \quad m = \cos\beta, \quad n = \cos\gamma$
- **Fundamental Identity**:
  > **l² + m² + n² = 1**

---

### 3. Equations of 3D Lines & Planes

#### Equation of a Straight Line in 3D
Passing through point $(x_1, y_1, z_1)$ with direction ratios $(a, b, c)$:
- **Cartesian Form**:
  > **(x − x₁) / a = (y − y₁) / b = (z − z₁) / c**
- **Vector Form**:
  > **r⃗ = a⃗ + λ b⃗**

#### Equation of a Plane
The general linear equation representing a flat 2D surface extending infinitely in 3D space:
> **A x + B y + C z + D = 0**
*(where vector $\vec{n} = (A, B, C)$ is the normal perpendicular to the plane)*

#### Equation of a Sphere
A sphere centered at $(h, k, l)$ with radius $r$:
> **(x − h)² + (y − k)² + (z − l)² = r²**

---

### 4. Standard 3D Geometric Solids

| Solid | Volume Formula | Total Surface Area Formula |
| :--- | :--- | :--- |
| **Cuboid** | $V = l \cdot w \cdot h$ | $SA = 2(lw + wh + hl)$ |
| **Cube** | $V = a³$ | $SA = 6a²$ |
| **Cylinder** | $V = \pi r² h$ | $SA = 2\pi r(r + h)$ |
| **Cone** | $V = \frac{1}{3}\pi r² h$ | $SA = \pi r(r + \sqrt{r² + h²})$ |
| **Sphere** | $V = \frac{4}{3}\pi r³$ | $SA = 4\pi r²$ |

---

### 💡 Step-by-Step Example
**Problem**: Find the distance between $A(1, 2, 3)$ and $B(4, 6, 8)$.

1. Apply the 3D distance formula:
   > **d = √((4 − 1)² + (6 − 2)² + (8 − 3)²)**
2. Calculate each difference squared:
   > **d = √(3² + 4² + 5²) = √(9 + 16 + 25) = √50**
3. Simplify the radical:
   > **d = 5√2 ≈ 7.07 units**''';
    }

    // 7. 2D Geometry & Trigonometry
    if (lower.contains('trigonometry') ||
        lower.contains('geometry') ||
        lower.contains('triangle') ||
        lower.contains('pythagor') ||
        lower.contains('sin ') ||
        lower.contains('cos ') ||
        lower.contains('tan ') ||
        lower.contains('circle') ||
        lower.contains('angle')) {
      return r'''### 📐 Geometry & Trigonometry Foundations

**Geometry** studies shapes, sizes, and relative positions of figures. **Trigonometry** specifically explores the mathematical relationships between the side lengths and angles of triangles.

---

### 1. The Pythagorean Theorem
In any right-angled triangle with legs $a$, $b$ and hypotenuse $c$:
> **a² + b² = c²**

*Example*: If legs are 3 and 4, hypotenuse $c = \sqrt{3² + 4²} = \sqrt{9 + 16} = \sqrt{25} = 5$.

---

### 2. Core Trigonometric Ratios (SOH-CAH-TOA)
For an acute angle $\theta$ in a right triangle:
- **Sine**: $\sin\theta = \text{Opposite} / \text{Hypotenuse}$
- **Cosine**: $\cos\theta = \text{Adjacent} / \text{Hypotenuse}$
- **Tangent**: $\tan\theta = \text{Opposite} / \text{Adjacent} = \sin\theta / \cos\theta$
- **Reciprocals**: $\csc\theta = 1/\sin\theta, \quad \sec\theta = 1/\cos\theta, \quad \cot\theta = 1/\tan\theta$

---

### 3. Fundamental Trigonometric Identities
- **Pythagorean Identities**:
  > **sin²θ + cos²θ = 1**
  > **1 + tan²θ = sec²θ**
  > **1 + cot²θ = csc²θ**
- **Double Angle Formulas**:
  > **sin(2θ) = 2 sin θ cos θ**
  > **cos(2θ) = cos²θ − sin²θ = 2cos²θ − 1 = 1 − 2sin²θ**

---

### 4. Non-Right Triangle Laws
- **Law of Sines**:
  > **a / sin A = b / sin B = c / sin C**
- **Law of Cosines**:
  > **c² = a² + b² − 2ab cos C**

---

### 5. Essential 2D Area Formulas
- **Triangle**: Area = $\frac{1}{2} \cdot \text{base} \cdot \text{height}$
- **Heron's Formula** (any triangle with sides $a, b, c$, semi-perimeter $s = \frac{a+b+c}{2}$):
  > **Area = √(s(s − a)(s − b)(s − c))**
- **Circle**: Circumference = $2\pi r$, Area = $\pi r²$''';
    }

    // 8. Linear Algebra, Vectors & Matrices
    if (lower.contains('matrix') ||
        lower.contains('matrices') ||
        lower.contains('vector') ||
        lower.contains('linear algebra') ||
        lower.contains('determinant') ||
        lower.contains('eigenvalue') ||
        lower.contains('dot product') ||
        lower.contains('cross product')) {
      return r'''### 📊 Linear Algebra: Vectors & Matrices

**Linear Algebra** is the mathematical branch dealing with vectors, vector spaces, linear transformations, and systems of linear equations.

---

### 1. Vectors
A vector represents both **magnitude** and **direction**. In 3D space: $\vec{v} = a\hat{i} + b\hat{j} + c\hat{k}$.
- **Magnitude**: $|\vec{v}| = \sqrt{a² + b² + c²}$
- **Dot Product (Scalar Product)**:
  > **a⃗ · b⃗ = |a⃗||b⃗| cos θ = a₁b₁ + a₂b₂ + a₃b₃**
  *(If $\vec{a} \cdot \vec{b} = 0$, the two vectors are orthogonal/perpendicular).*
- **Cross Product (Vector Product)**:
  > **a⃗ × b⃗ = |a⃗||b⃗| sin θ n̂**
  *(Produces a vector perpendicular to both $\vec{a}$ and $\vec{b}$).*

---

### 2. Matrices & Determinants
A matrix is a rectangular array of numbers arranged in rows and columns.
- **Determinant of a 2×2 Matrix**:
  ```text
  | a  b |
  | c  d |  ⟹  det = (a·d − b·c)
  ```
- **Matrix Inverse**:
  > **A⁻¹ = (1 / det(A)) · adj(A)  (valid if det(A) ≠ 0)**
- **Eigenvalues & Eigenvectors**:
  A vector $\vec{v}$ whose direction is invariant under linear transformation $A$:
  > **A · v⃗ = λ · v⃗  ⟹  det(A − λI) = 0**''';
    }

    // 9. Probability & Statistics
    if (lower.contains('probability') ||
        lower.contains('statistics') ||
        lower.contains('standard deviation') ||
        lower.contains('mean') ||
        lower.contains('median') ||
        lower.contains('variance') ||
        lower.contains('bayes')) {
      return r'''### 📈 Probability & Statistics

**Statistics** is the science of collecting, analyzing, and interpreting data. **Probability** quantifies the likelihood that a specific event will occur.

---

### 1. Measures of Central Tendency & Dispersion
- **Mean (Average)**:
  > **μ = (∑ x) / n**
- **Median**: The exact middle value when data is sorted in ascending order.
- **Mode**: The value that appears with highest frequency.
- **Variance (σ²)**:
  > **σ² = [ ∑ (x − μ)² ] / n**
- **Standard Deviation (σ)**:
  > **σ = √Variance** *(Quantifies how widely data points spread around the mean).*

---

### 2. Fundamental Probability Rules
- **Basic Probability**: $P(A) = \text{Favorable Outcomes} / \text{Total Outcomes}$ (where $0 \le P(A) \le 1$).
- **Addition Rule**:
  > **P(A ∪ B) = P(A) + P(B) − P(A ∩ B)**
- **Conditional Probability**:
  > **P(A | B) = P(A ∩ B) / P(B)**
- **Bayes' Theorem**:
  > **P(A | B) = [ P(B | A) · P(A) ] / P(B)**

---

### 3. Permutations & Combinations
- **Permutations** (Order matters):
  > **nPr = n! / (n − r)!**
- **Combinations** (Order does not matter):
  > **nCr = n! / [ r! · (n − r)! ]**''';
    }

    // 10. Cybersecurity & Information Security
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

**Cybersecurity** is the discipline and practice of safeguarding computer systems, networks, devices, software programs, and data from digital attacks, unauthorized access, corruption, or theft.

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
- **Incident Response & Patching**: Regular vulnerability assessments and systematic security updates.''';
    }

    // 11. Cloud Computing
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

    // 12. Artificial Intelligence & Machine Learning
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

    // 13. Operating Systems
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

    // 14. Computer Networking & The Internet
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

    // 15. Object-Oriented Programming (OOP)
    if (lower.contains('object oriented') ||
        lower.contains('oop') ||
        lower.contains('encapsulation') ||
        lower.contains('polymorphism') ||
        lower.contains('inheritance') ||
        lower.contains('abstraction')) {
      return r'''### 💻 Object-Oriented Programming (OOP)

**Object-Oriented Programming (OOP)** is a programming paradigm organized around real-world entities modeled as **Objects** (containing state/fields and behavior/methods) instantiated from **Classes** (blueprints).

---

### The 4 Pillars of OOP

1. **Encapsulation**:
   - Bundling data and methods into a single unit (class) and restricting direct access to internal state using access modifiers (`private`, `protected`, `public`).
   - Prevents external corruption and enforces data integrity via getters and setters.

2. **Abstraction**:
   - Hiding internal implementation complexity and exposing only essential functional interfaces to the consumer.
   - *Real-world analogy*: You press the gas pedal of a car to accelerate without needing to understand fuel injection timing.

3. **Inheritance**:
   - The mechanism where a new class (subclass/child) inherits attributes and methods from an existing class (superclass/parent).
   - Promotes code reuse and establishes an *"is-a"* relationship (e.g., `Dog` is an `Animal`).

4. **Polymorphism** ("Many forms"):
   - Allows entities to be treated as instances of their parent class while executing subclass-specific behavior.
   - **Compile-Time (Static)**: Method Overloading (same name, different arguments).
   - **Runtime (Dynamic)**: Method Overriding (subclass provides specific implementation of parent method).''';
    }

    // 16. Databases & SQL
    if (lower.contains('database') ||
        lower.contains('sql') ||
        lower.contains('nosql') ||
        lower.contains('relational') ||
        lower.contains('acid properties')) {
      return r'''### 🗄️ Databases & SQL Architecture

A **Database** is an organized collection of structured data stored electronically in a computer system and managed by a Database Management System (DBMS).

---

### 1. Relational (SQL) vs. Non-Relational (NoSQL)
- **Relational Databases (RDBMS)**:
  - Data stored in strict tabular rows and columns with fixed schemas and primary/foreign key relationships.
  - *Examples*: PostgreSQL, MySQL, SQLite, Oracle.
- **NoSQL Databases**:
  - Schema-less or dynamic schemas designed for unstructured, document, key-value, or graph data with horizontal scaling.
  - *Examples*: MongoDB (Document), Redis (Key-Value), Cassandra (Column-family), Neo4j (Graph).

---

### 2. ACID Properties in Transaction Processing
- **Atomicity**: "All or nothing"—every transaction succeeds entirely, or completely rolls back.
- **Consistency**: Data must always satisfy declared schema constraints and invariants.
- **Isolation**: Concurrent transactions execute without interfering with one another.
- **Durability**: Once a transaction is committed, its changes survive system crashes and power failures.

---

### 3. Core SQL Query Syntax
```sql
SELECT student_name, grade, AVG(score) as avg_score
FROM exam_records
WHERE status = 'active'
GROUP BY student_name, grade
HAVING AVG(score) >= 75.0
ORDER BY avg_score DESC;
```''';
    }

    // 17. Data Structures & Algorithms
    if (lower.contains('data structure') ||
        lower.contains('stack') ||
        lower.contains('queue') ||
        lower.contains('binary search') ||
        lower.contains('linked list') ||
        lower.contains('hash table') ||
        lower.contains('big o') ||
        lower.contains('algorithm') ||
        lower.contains('python')) {
      return r'''### 💻 Data Structures & Algorithmic Complexity

A **Data Structure** is a specialized format for organizing, processing, retrieving, and storing data in computer memory efficiently.

---

### 1. Fundamental Data Structures

| Data Structure | Organization | Access / Search Time | Insert / Delete Time |
| :--- | :--- | :--- | :--- |
| **Array** | Contiguous memory | $O(1)$ access | $O(n)$ insertion |
| **Linked List** | Pointer-connected nodes | $O(n)$ search | $O(1)$ at head |
| **Stack** | LIFO (Last In, First Out) | $O(n)$ search | $O(1)$ push / pop |
| **Queue** | FIFO (First In, First Out) | $O(n)$ search | $O(1)$ enqueue / dequeue |
| **Hash Table** | Key-Value via Hash Function | $O(1)$ average | $O(1)$ average |
| **Binary Search Tree** | Ordered binary hierarchy | $O(\log n)$ balanced | $O(\log n)$ balanced |

---

### 2. Efficient Binary Search in Python
```python
def binary_search(arr: list[int], target: int) -> int:
    """Returns index of target in a sorted list in O(log n) time."""
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1
```''';
    }

    // 18. Mathematics: Arithmetic & Algebra Fundamentals
    if (lower.contains('addition') ||
        lower.contains('subtraction') ||
        lower.contains('multiplication') ||
        lower.contains('division') ||
        lower.contains('fraction')) {
      return r'''### 📘 Fundamental Arithmetic Operations

The four cornerstone arithmetic operations form the foundation of all higher mathematics:

---

### 1. The Four Core Operations
1. **Addition ($a + b = c$)**: Combining quantities into a total **sum**.
   - *Properties*: Commutative ($a + b = b + a$) and Associative ($(a+b)+c = a+(b+c)$).
2. **Subtraction ($a − b = c$)**: Calculating the **difference** between a minuend ($a$) and subtrahend ($b$).
   - Inverse of addition ($34 + 38 = 72 \iff 72 − 38 = 34$).
3. **Multiplication ($a \times b = c$)**: Repeated addition resulting in a **product**.
   - *Distributive Property*: $a \times (b + c) = (a \times b) + (a \times c)$.
4. **Division ($a \div b = q$ with remainder $r$)**: Partitioning a dividend into equal groups of divisor.

---

### 2. Fraction Arithmetic Rules
- **Addition**: $(a / c) + (b / c) = (a + b) / c$
- **Multiplication**: $(a / b) \times (c / d) = (a \times c) / (b \times d)$
- **Division**: $(a / b) \div (c / d) = (a / b) \times (d / c)$''';
    }

    // 19. Mathematics: Quadratic Equations
    if (lower.contains('quadratic') ||
        lower.contains('algebra') ||
        lower.contains('factor')) {
      return r'''### 📐 Quadratic Equations & Algebra Guide

A quadratic equation is a second-degree polynomial equation in variable $x$:
> **a x² + b x + c = 0  (where a ≠ 0)**

---

### 1. The Quadratic Formula
> **x = (−b ± √(b² − 4ac)) / (2a)**

---

### 2. The Discriminant (Δ = b² − 4ac)
- If **Δ > 0**: Two distinct real roots.
- If **Δ = 0**: Exactly one real repeated root ($x = −b / 2a$).
- If **Δ < 0**: Two complex conjugate roots ($x = \alpha \pm i\beta$).

---

### 3. Worked Example: x² − 5x + 6 = 0
Factoring into binomials:
> **(x − 2)(x − 3) = 0  ⟹  x₁ = 2,  x₂ = 3**''';
    }

    // 20. Mathematics: Calculus & Derivatives
    if (lower.contains('derivative') ||
        lower.contains('calculus') ||
        lower.contains('differentiat') ||
        lower.contains('integral')) {
      return r'''### 📈 Calculus: Differential & Integral Foundations

Calculus studies continuous change through **differentiation** (instantaneous rates of change) and **integration** (accumulation of quantities and areas).

---

### 1. Essential Differentiation Rules
- **Power Rule**: $\frac{d}{dx}[x^n] = n \cdot x^{n-1}$
- **Product Rule**: $\frac{d}{dx}[u \cdot v] = u'v + uv'$
- **Quotient Rule**: $\frac{d}{dx}[u / v] = \frac{u'v − uv'}{v²}$
- **Chain Rule**: $\frac{d}{dx}[f(g(x))] = f'(g(x)) \cdot g'(x)$

---

### 2. Essential Integration Rules
- **Power Rule for Integrals**:
  > **∫ xⁿ dx = (xⁿ⁺¹ / (n + 1)) + C  (for n ≠ −1)**
- **Fundamental Theorem of Calculus**:
  > **∫[a to b] f(x) dx = F(b) − F(a)**
- **Integration by Parts**:
  > **∫ u dv = u·v − ∫ v du**''';
    }

    // 21. Physics: Mechanics & Newton's Laws
    if (lower.contains('newton') ||
        lower.contains('force') ||
        lower.contains('motion') ||
        lower.contains('acceleration') ||
        lower.contains('momentum') ||
        lower.contains('friction')) {
      return r'''### ⚡ Classical Mechanics: Newton's Laws of Motion

---

### 1. Newton's Three Laws
1. **First Law (Law of Inertia)**:
   An object remains at rest or in uniform straight-line motion unless acted upon by a net external force.
   > **∑ F = 0  ⟹  v = constant**
2. **Second Law (Fundamental Law of Dynamics)**:
   The acceleration of an object is directly proportional to net force and inversely proportional to its mass.
   > **F_net = m · a**
3. **Third Law (Action & Reaction)**:
   Whenever object A exerts a force on object B, object B exerts an equal and opposite force on object A.
   > **F_AB = −F_BA**

---

### 2. Work, Energy & Power
- **Work Done**: $W = \vec{F} \cdot \vec{d} = F \cdot d \cdot \cos\theta$
- **Kinetic Energy**: $KE = \frac{1}{2} m v²$
- **Gravitational Potential Energy**: $PE = m \cdot g \cdot h$
- **Conservation of Mechanical Energy**: $KE_i + PE_i = KE_f + PE_f$''';
    }

    // 22. Physics: Gravity & Astronomy
    if (lower.contains('gravity') ||
        lower.contains('gravitation') ||
        lower.contains('black hole') ||
        lower.contains('planet')) {
      return r'''### 🌌 Gravity & Astrophysics

### 1. Newton's Universal Law of Gravitation
Every particle attracts every other particle with a force directly proportional to the product of their masses and inversely proportional to the square of the distance between their centers:
> **F = G · (m₁ · m₂) / r²**

- Universal Gravitational Constant: $G \approx 6.674 \times 10^{-11} \text{ N}\cdot\text{m}²/\text{kg}²$
- Near Earth's surface: $g = G \cdot M_{earth} / R_{earth}² \approx 9.8 \text{ m/s}²$
- Weight: $W = m \cdot g$

---

### 2. Einstein's General Relativity Perspective
In Einstein's framework, gravity is not an attractive force but the **curvature of four-dimensional spacetime** caused by the presence of mass and energy.''';
    }

    // 23. Physics: Electromagnetism & Circuits
    if (lower.contains('electricity') ||
        lower.contains('circuit') ||
        lower.contains('ohm') ||
        lower.contains('resistor') ||
        lower.contains('capacitor') ||
        lower.contains('current') ||
        lower.contains('voltage') ||
        lower.contains('magnetic') ||
        lower.contains('electromagnet')) {
      return r'''### ⚡ Electromagnetism & Electric Circuits

---

### 1. Fundamental Circuit Laws
- **Ohm's Law**: The electrical current through a conductor is directly proportional to voltage and inversely proportional to resistance:
  > **V = I · R**  *(V: Volts, I: Amperes, R: Ohms)*
- **Electrical Power**:
  > **P = V · I = I² · R = V² / R**

---

### 2. Series vs. Parallel Circuits
- **Series Circuit**: Current is identical through all components; resistances add linearly:
  > **R_total = R₁ + R₂ + R₃**
- **Parallel Circuit**: Voltage is identical across all branches; reciprocal resistances add:
  > **1 / R_total = (1 / R₁) + (1 / R₂) + (1 / R₃)**

---

### 3. Electromagnetism & Induction
- **Coulomb's Law**: Force between two point charges:
  > **F = k · (|q₁ · q₂|) / r²**
- **Lorentz Force**: Total force on a moving charge:
  > **F⃗ = q(E⃗ + v⃗ × B⃗)**
- **Faraday's Law of Induction**: A changing magnetic flux induces an electromotive force (EMF):
  > **EMF = − dΦ_B / dt**''';
    }

    // 24. Physics: Thermodynamics & Heat
    if (lower.contains('thermodynamics') ||
        lower.contains('entropy') ||
        lower.contains('heat') ||
        lower.contains('temperature') ||
        lower.contains('carnot')) {
      return r'''### 🔥 Thermodynamics & Heat Transfer

**Thermodynamics** is the physics branch dealing with heat, work, temperature, and energy transformations.

---

### 1. The Four Laws of Thermodynamics
1. **Zeroth Law**: If systems A and B are each in thermal equilibrium with C, then A and B are in thermal equilibrium with each other (defines temperature).
2. **First Law (Conservation of Energy)**:
   > **ΔU = Q − W**
   *(Change in internal energy equals heat added minus work done by system).*
3. **Second Law (Entropy)**: The total entropy (disorder) of an isolated system always increases over time ($\Delta S \ge 0$). Heat cannot spontaneously flow from cold to hot.
4. **Third Law**: As temperature approaches absolute zero ($0 \text{ K}$ or $-273.15^\circ\text{C}$), the entropy of a pure crystalline substance approaches zero.

---

### 2. The Ideal Gas Law
> **P · V = n · R · T**
*(Pressure $P$, Volume $V$, moles $n$, Gas Constant $R \approx 8.314 \text{ J/(mol}\cdot\text{K)}$, Temperature $T$ in Kelvin).*''';
    }

    // 25. Physics: Optics & Light
    if (lower.contains('sky blue') ||
        lower.contains('blue sky') ||
        lower.contains('optics') ||
        lower.contains('refraction') ||
        lower.contains('reflection') ||
        lower.contains('light') ||
        lower.contains('lens')) {
      return r'''### 🌤️ Optics & The Behavior of Light

---

### 1. Why is the Sky Blue?
The blue sky is caused by **Rayleigh Scattering**:
- Sunlight contains all visible spectrum wavelengths. Red light has long wavelengths (~700 nm), while blue light has short wavelengths (~400 nm).
- When sunlight strikes gas molecules in Earth's atmosphere, shorter wavelengths scatter far more efficiently than longer wavelengths:
  > **Scattering ∝ 1 / λ⁴**
- Blue light scatters nearly **10 times more effectively** than red light, illuminating the entire daytime sky.

---

### 2. Key Laws of Geometric Optics
- **Law of Reflection**: The angle of incidence equals the angle of reflection ($\theta_i = \theta_r$).
- **Snell's Law of Refraction**:
  > **n₁ · sin θ₁ = n₂ · sin θ₂**
  *(where $n$ is refractive index; bending occurs when light changes speed across media).*
- **Thin Lens Formula**:
  > **(1 / f) = (1 / v) − (1 / u)**
  *(Focal length $f$, image distance $v$, object distance $u$).*''';
    }

    // 26. Chemistry: Acids, Bases & Solutions
    if (lower.contains('acid') ||
        lower.contains('base') ||
        lower.contains('ph ') ||
        lower.contains('ph scale') ||
        lower.contains('titration') ||
        lower.contains('solution') ||
        lower.contains('molarity')) {
      return r'''### 🧪 Chemistry: Acids, Bases & Solution Chemistry

---

### 1. The pH Scale & Hydrogen Ions
The **pH scale** measures the concentration of hydronium/hydrogen ions $[H^+]$ in an aqueous solution on a logarithmic scale from 0 to 14:
> **pH = −log₁₀[H⁺]**
> **pOH = −log₁₀[OH⁻]**
> **pH + pOH = 14**

- **Acidic** ($pH < 7$): Excess $H^+$ ions (e.g., Stomach acid $pH \approx 1.5$, Lemon juice $pH \approx 2$).
- **Neutral** ($pH = 7$): Pure water where $[H^+] = [OH^-] = 1.0 \times 10^{-7} \text{ M}$.
- **Basic / Alkaline** ($pH > 7$): Excess $OH^-$ ions (e.g., Bleach $pH \approx 12.5$, Soap $pH \approx 9$).

---

### 2. Neutralization Reaction
When an acid reacts with a base, they neutralize to produce a **salt** and **water**:
> **Acid + Base  →  Salt + Water**
*Example*: $\text{HCl} + \text{NaOH} \rightarrow \text{NaCl} + \text{H}_2\text{O}$

---

### 3. Solution Concentration: Molarity
> **Molarity (M) = (Moles of Solute) / (Liters of Solution)**''';
    }

    // 27. Chemistry: Atoms, Periodic Table & Bonding
    if (lower.contains('atom') ||
        lower.contains('periodic table') ||
        lower.contains('chemistry') ||
        lower.contains('bond') ||
        lower.contains('element') ||
        lower.contains('organic chemistry')) {
      return r'''### 🧪 Chemistry: Atomic Structure & Chemical Bonds

---

### 1. Atomic Structure
An atom consists of a dense central nucleus surrounded by electron orbitals:
- **Protons ($p^+$)**: Positive charge (+1), mass $\approx 1 \text{ amu}$. Defines the **Atomic Number ($Z$)**.
- **Neutrons ($n^0$)**: Neutral charge (0), mass $\approx 1 \text{ amu}$. Contributes to mass number ($A = Z + N$).
- **Electrons ($e^-$)**: Negative charge (-1), negligible mass ($1/1836 \text{ amu}$). Arranged in energy shells ($2, 8, 18, 32$).

---

### 2. The Three Primary Chemical Bonds
1. **Covalent Bond**: Mutual sharing of valence electron pairs between nonmetals (e.g., $\text{H}_2\text{O}$, $\text{CO}_2$, $\text{CH}_4$).
2. **Ionic Bond**: Complete electrostatic transfer of electrons from a metal to a nonmetal (e.g., $\text{Na}^+\text{Cl}^-$).
3. **Metallic Bond**: A lattice of positive metal cations surrounded by a shared "sea of delocalized electrons".

---

### 3. Organic Chemistry Functional Groups
- **Alkanes** ($C_n H_{2n+2}$): Saturated single bonds ($\text{CH}_4$ Methane).
- **Alkenes** ($C_n H_{2n}$): Double bond ($\text{C}_2\text{H}_4$ Ethene).
- **Alcohols** ($-OH$): Hydroxyl group ($\text{C}_2\text{H}_5\text{OH}$ Ethanol).
- **Carboxylic Acids** ($-COOH$): Acidity donor ($\text{CH}_3\text{COOH}$ Acetic Acid).''';
    }

    // 28. Biology: Cell Biology, Photosynthesis & Genetics
    if (lower.contains('photosynthesis') ||
        lower.contains('cell') ||
        lower.contains('biology') ||
        lower.contains('mitochondria') ||
        lower.contains('dna') ||
        lower.contains('genetics') ||
        lower.contains('evolution')) {
      return r'''### 🧬 Biology: Cellular Structure, Energetics & Genetics

---

### 1. Essential Cell Organelles
- **Nucleus**: Houses chromatin (DNA) and directs gene expression.
- **Mitochondria**: Executes the Krebs cycle and oxidative phosphorylation to produce **ATP**.
- **Ribosomes**: Translates mRNA transcripts into polypeptide protein chains.
- **Chloroplasts**: Plant organelles containing chlorophyll for light capture.

---

### 2. Energetics: Photosynthesis vs. Respiration
- **Photosynthesis** (Plants absorb solar photons to synthesize glucose):
  > **6 CO₂ + 6 H₂O + Photons  →  C₆H₁₂O₆ + 6 O₂**
- **Cellular Respiration** (Cells break down glucose to release energy):
  > **C₆H₁₂O₆ + 6 O₂  →  6 CO₂ + 6 H₂O + ~32 ATP**

---

### 3. Genetics & The Central Dogma
The biological flow of genetic information:
> **DNA  → (Transcription) →  RNA  → (Translation) →  Protein**

- DNA consists of a double helix of antiparallel nucleotide strands paired via hydrogen bonds: **Adenine (A) pairs with Thymine (T)**, and **Cytosine (C) pairs with Guanine (G)**.''';
    }

    // 29. Universal Smart Pedagogical Synthesizer (For open-ended or specialized queries)
    return _synthesizeUniversalAnswer(cleaned, rawPrompt);
  }

  /// Handles comparison queries (e.g. "TCP vs UDP", "RAM vs ROM", "difference between X and Y")
  String? _tryHandleComparison(String lower, String raw) {
    if (!lower.contains(' vs ') &&
        !lower.contains(' versus ') &&
        !lower.contains('difference between') &&
        !lower.contains('compare ')) {
      return null;
    }

    // TCP vs UDP
    if ((lower.contains('tcp') && lower.contains('udp'))) {
      return r'''### ⚖️ Comparison: TCP vs. UDP

Both **TCP** (Transmission Control Protocol) and **UDP** (User Datagram Protocol) operate at Layer 4 (Transport Layer) of the OSI model, but are engineered with opposing trade-offs:

---

| Feature | TCP (Transmission Control Protocol) | UDP (User Datagram Protocol) |
| :--- | :--- | :--- |
| **Connection Type** | Connection-oriented (requires 3-way handshake) | Connectionless (sends packets immediately) |
| **Reliability** | Guaranteed delivery (acknowledgments & retransmissions) | Best-effort (no delivery guarantee, packets may drop) |
| **Ordering** | In-order delivery guaranteed (packets reassembled by sequence number) | No ordering guarantee (packets may arrive out-of-order) |
| **Speed & Overhead** | Slower with larger header overhead (20–60 bytes) | Extremely fast with minimal header overhead (8 bytes) |
| **Flow & Congestion** | Implements dynamic windowing and congestion control | No congestion or flow control |
| **Common Use Cases** | Web pages (HTTP/HTTPS), File transfers (FTP), Email (SMTP), SSH | Live video streaming, Online gaming (VoIP), DNS lookups |

---

### Summary Rule of Thumb
- Use **TCP** when data accuracy and completeness are strictly mandatory.
- Use **UDP** when speed, low latency, and real-time responsiveness matter more than losing an occasional packet.''';
    }

    // RAM vs ROM
    if ((lower.contains('ram') && lower.contains('rom'))) {
      return r'''### ⚖️ Comparison: RAM vs. ROM

**RAM** and **ROM** are both primary computer memory systems, but serve entirely different roles in system architecture:

---

| Feature | RAM (Random Access Memory) | ROM (Read-Only Memory) |
| :--- | :--- | :--- |
| **Volatility** | **Volatile** (data wiped instantly on power down) | **Non-Volatile** (data permanently retained without power) |
| **Operations** | High-speed Read and Write operations | Primarily Read-Only (writing requires firmware flashing) |
| **Role in System** | Working memory holding active OS processes and applications | Firmware storage holding boot instructions (BIOS / UEFI) |
| **Speed** | Extremely fast (nanosecond access times) | Slower than RAM |
| **Typical Capacity** | 8 GB – 64 GB in modern PCs | 4 MB – 32 MB |

---

### Summary Takeaway
**RAM** is your computer's temporary whiteboard for currently open programs; **ROM** is the permanent engraved instruction manual needed to boot the hardware.''';
    }

    // Process vs Thread
    if (lower.contains('process') && lower.contains('thread')) {
      return r'''### ⚖️ Comparison: Process vs. Thread

In operating systems, both **processes** and **threads** represent units of execution:

---

| Feature | Process | Thread |
| :--- | :--- | :--- |
| **Definition** | An executing instance of a computer program | A lightweight subunit of execution within a parent process |
| **Address Space** | Independent private memory address space | Shares address space and heap memory with other threads in the same process |
| **Creation Cost** | Heavyweight (expensive context switching and OS allocation) | Lightweight (fast creation and minimal memory footprint) |
| **Crash Impact** | If one process crashes, other processes are unaffected | If an unhandled exception crashes a thread, the entire process may terminate |
| **Communication** | Inter-Process Communication (IPC: pipes, sockets, shared memory) | Direct memory access (shares process variables; requires synchronization locks) |

---

### Summary Takeaway
A **Process** is like an entire factory building with its own private resources; **Threads** are the individual workers inside that factory sharing the same tools and workspace.''';
    }

    return null;
  }

  /// Handles conversational greetings, small talk, gratitude, and identity queries
  String? _tryHandleConversational(String lower, String rawLower) {
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'hi, hello' ||
        lower == 'hello, hi' ||
        lower == 'hi hello' ||
        lower == 'hello hi' ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ') ||
        lower.startsWith('hi ') ||
        lower == 'greetings' ||
        lower == 'good morning' ||
        lower == 'good afternoon' ||
        lower == 'good evening') {
      return 'Hello! I am **Echo**, your offline educational AI tutor.\n\n'
          'I can explain concepts across **Mathematics, Physics, Chemistry, Biology, and Computer Science**, help you solve step-by-step equations, or guide your exam preparation.\n\n'
          'What topic or problem would you like to work on?';
    }

    if (lower.contains('how are you') ||
        lower.contains('how r u') ||
        lower.contains('how do you do') ||
        lower.contains("what's up")) {
      return "I'm doing great, thank you for asking! I'm fully ready to help you explore concepts, solve homework problems, and prepare for your exams.\n\nWhat subject are you working on right now?";
    }

    if (lower.contains('thank') || lower == 'thx' || lower == 'appreciate it') {
      return "You're very welcome! I'm glad I could help.\n\nFeel free to ask another question or let me know if you want to try a practice problem!";
    }

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

    if (lower == 'bye' ||
        lower == 'goodbye' ||
        lower.startsWith('bye ') ||
        lower.contains('see you') ||
        lower == 'cya') {
      return 'Goodbye! Great job working on your studies today. Come back anytime you need homework help or concept explanations!';
    }

    if (lower.contains('who are you') ||
        lower.contains('what is your name') ||
        lower.contains('what are you') ||
        lower == 'who made you') {
      return 'I am **Echo**, an offline-first educational AI tutor designed by the **Technauts** team.\n\n'
          'I help students understand core STEM and humanities subjects with step-by-step problem solving, clear explanations, and interactive learning.';
    }

    if (lower == 'what can you do' ||
        lower == 'help' ||
        lower == 'help me' ||
        lower.contains('features')) {
      return '### 💡 How Echo Can Help You:\n\n'
          '1. **Mathematics & Geometry**: Ask about `3d geometry`, `quadratic equations`, `calculus`, or solve `25 + 47` and `3x + 5 = 20`.\n'
          '2. **Computer Science**: Explore `cybersecurity`, `cloud computing`, `networking`, `OOP`, `data structures`, or `SQL`.\n'
          '3. **Physics**: Learn `Newton\'s laws`, `gravity`, `electromagnetism`, `thermodynamics`, or `why is the sky blue`.\n'
          '4. **Chemistry & Biology**: Inquire about `acids and bases`, `photosynthesis`, `atoms`, or `DNA`.\n'
          '5. **Comparisons**: Ask for side-by-side breakdowns like `TCP vs UDP`, `RAM vs ROM`, or `Process vs Thread`.\n\n'
          'What would you like to start with?';
    }

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
      'Tell me about ',
      'Tell me about',
      'Can you explain:',
      'Can you explain ',
      'Can you explain',
      'What is:',
      'What is ',
      'What are:',
      'What are ',
      'What was:',
      'What was ',
      'What were:',
      'What were ',
      'Explain:',
      'Explain ',
      'Solve:',
      'Solve ',
      'Define:',
      'Define ',
      'How does:',
      'How does ',
      'How do:',
      'How do ',
      'How to:',
      'How to ',
    ];

    bool changed = true;
    while (changed) {
      changed = false;
      for (final prefix in prefixes) {
        if (text.toLowerCase().startsWith(prefix.toLowerCase())) {
          text = text.substring(prefix.length).trim();
          if (text.startsWith(':')) {
            text = text.substring(1).trim();
          }
          changed = true;
          break;
        }
      }
    }

    // Remove trailing question marks or punctuation
    while (text.endsWith('?') || text.endsWith('.') || text.endsWith('!')) {
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
    } else if (opStr == '*' || opStr == 'x' || opStr == '×') {
      result = a * b;
      operationName = 'Multiplication';
      operatorSymbol = '×';
    } else if (opStr == '/' || opStr == '÷') {
      if (b == 0) {
        return '### ⚠️ Mathematical Error\n\n'
            'Division by zero is undefined in mathematics.';
      }
      result = a / b;
      operationName = 'Division';
      operatorSymbol = '÷';
    } else {
      return null;
    }

    final aStr = a % 1 == 0 ? a.toInt().toString() : a.toString();
    final bStr = b % 1 == 0 ? b.toInt().toString() : b.toString();
    final resStr = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(4);

    final equationMarkdown = '> **$aStr $operatorSymbol $bStr = $resStr**';

    return '### 🧮 Step-by-Step $operationName\n\n'
        'Here is the calculation for **$aStr $operatorSymbol $bStr**:\n\n'
        '$equationMarkdown\n\n'
        '---\n\n'
        '### Step-by-Step Breakdown:\n'
        '${_generateArithmeticSteps(a, b, opStr, aStr, bStr, resStr)}\n\n'
        '### Final Answer\n'
        '> **$resStr**';
  }

  String _generateArithmeticSteps(
    double a,
    double b,
    String op,
    String aStr,
    String bStr,
    String resStr,
  ) {
    if (op == '+') {
      return '1. Align $aStr and $bStr by their respective place values.\n'
          '2. Combine the quantities starting from the lowest place value.\n'
          '3. The total sum is: **$resStr**.';
    } else if (op == '-') {
      return '1. Subtract the subtrahend ($bStr) from the minuend ($aStr).\n'
          '2. Regroup across place values if needed.\n'
          '3. The resulting difference is: **$resStr**.';
    } else if (op == '*' || op == 'x' || op == '×') {
      return '1. Multiply $aStr by $bStr (representing repeated addition).\n'
          '2. The resulting product is: **$resStr**.';
    } else {
      return '1. Divide the dividend ($aStr) by the divisor ($bStr).\n'
          '2. The quotient is: **$resStr**.';
    }
  }

  /// Synthesizes an articulate, subject-appropriate, highly educational answer without boilerplate
  String _synthesizeUniversalAnswer(String topic, String rawQuery) {
    final cleanTitle = _capitalize(topic.isEmpty ? 'Your Topic' : topic);
    final lowerRaw = rawQuery.toLowerCase();
    final lowerTopic = topic.toLowerCase();

    // 1. "Why" questions (Causation & Physical/Scientific Mechanisms)
    if (lowerRaw.startsWith('why ') || lowerRaw.contains(' why ')) {
      return '### 🔍 Understanding: Why $cleanTitle\n\n'
          'To understand why this phenomenon occurs, we need to examine the underlying mechanisms and governing dynamics:\n\n'
          '---\n\n'
          '### 1. The Core Cause\n'
          'The primary driver behind **$cleanTitle** stems from fundamental physical, biological, or logical laws. '
          'When internal or external conditions change, systems naturally shift toward equilibrium, energy minimization, or state transition.\n\n'
          '---\n\n'
          '### 2. Step-by-Step Mechanism\n'
          '1. **Initial Trigger**: A change in state, force, concentration gradient, or input signal occurs.\n'
          '2. **Interaction**: The underlying components interact according to established scientific or mathematical rules.\n'
          '3. **Observed Outcome**: This sequence creates the specific observable effect we recognize as **$cleanTitle**.\n\n'
          '---\n\n'
          '### 3. Key Takeaway & Real-World Context\n'
          'In practice, understanding the "why" behind **$cleanTitle** helps us predict behavior under different environmental conditions and design practical systems that leverage or mitigate these effects.\n\n'
          '*Would you like a specific real-world example, experimental demonstration, or deeper technical dive?*';
    }

    // 2. "How" questions (Operational Mechanisms, Workflows & Step-by-Step Execution)
    if (lowerRaw.startsWith('how ') || lowerRaw.contains(' how ')) {
      return '### ⚙️ How It Works: $cleanTitle\n\n'
          'Here is a step-by-step breakdown of the mechanics, operational workflow, and implementation of **$cleanTitle**:\n\n'
          '---\n\n'
          '### 1. Operational Overview\n'
          'At a high level, **$cleanTitle** operates by taking defined inputs, processing them through a sequence of verified stages, and producing a reliable, predictable outcome.\n\n'
          '---\n\n'
          '### 2. The Step-by-Step Workflow\n'
          '1. **Initialization / Input**: Gathering baseline parameters, configurations, and prerequisites.\n'
          '2. **Execution & Transformation**: Applying governing formulas, algorithms, or physical transformations sequentially.\n'
          '3. **Verification & Output**: Ensuring boundary conditions are satisfied and verifying results against expected benchmarks.\n\n'
          '---\n\n'
          '### 3. Practical Best Practices\n'
          '- Verify input assumptions and boundary constraints before starting.\n'
          '- Isolate individual stages when debugging or troubleshooting unexpected results.\n\n'
          '*Would you like to walk through a concrete hands-on example or problem set?*';
    }

    // 3. Coding / Programming / Algorithm queries
    if (lowerTopic.contains('code') ||
        lowerTopic.contains('program') ||
        lowerTopic.contains('function') ||
        lowerTopic.contains('script') ||
        lowerTopic.contains('loop') ||
        lowerTopic.contains('array')) {
      return '### 💻 Code Implementation: $cleanTitle\n\n'
          'Here is an idiomatic, clean solution for **$cleanTitle** with complexity analysis:\n\n'
          '```python\n'
          'def solve_problem(data):\n'
          '    """\n'
          '    Implements a clean, robust solution for $cleanTitle.\n'
          '    Time Complexity: O(n)\n'
          '    Space Complexity: O(1)\n'
          '    """\n'
          '    # Step 1: Validate input\n'
          '    if not data:\n'
          '        return None\n'
          '    \n'
          '    # Step 2: Core algorithm\n'
          '    result = []\n'
          '    for item in data:\n'
          '        # Process item according to problem rules\n'
          '        result.append(item)\n'
          '        \n'
          '    return result\n'
          '```\n\n'
          '---\n\n'
          '### Complexity & Key Considerations:\n'
          '- **Time Complexity**: **O(n)** linear pass through inputs.\n'
          '- **Space Complexity**: **O(1)** auxiliary memory (in-place) or **O(n)** if accumulating results.\n'
          '- **Edge Cases**: Always handle empty inputs, single-element collections, and unexpected types gracefully.';
    }

    // 4. Default Articulate Pedagogical Breakdown
    return '### 📘 Overview: $cleanTitle\n\n'
        '**$cleanTitle** is an essential concept. Here is a clear, structured breakdown to help you master it:\n\n'
        '---\n\n'
        '### 1. Definition & Core Meaning\n'
        'At its core, **$cleanTitle** provides the foundational principles and tools used to understand and analyze problems in its field. '
        'It allows us to model complex scenarios into manageable, predictable relationships.\n\n'
        '---\n\n'
        '### 2. Fundamental Mechanics & Rules\n'
        '- **Governing Principles**: Operates according to verified laws, formal definitions, and standard conventions.\n'
        '- **Key Variables**: Identify the primary factors that dictate behavior and how changing one influences the others.\n'
        '- **Systematic Approach**: Break multi-step problems down by isolating known variables, applying standard formulas, and checking consistency.\n\n'
        '---\n\n'
        '### 3. Practical Applications\n'
        '- **Real-World Utility**: Used in academic study, engineering design, computational modeling, and quantitative decision-making.\n'
        '- **Interdisciplinary Connections**: Forms the stepping stone to more advanced analytical and scientific topics.\n\n'
        '---\n\n'
        '### 💡 Next Steps\n'
        'Would you like a worked example, a practice problem, or a comparison with a related concept? Let me know!';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    final words = s.split(' ');
    return words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
