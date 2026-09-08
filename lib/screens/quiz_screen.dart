import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';

class QuizScreen extends StatefulWidget {
  final QuizDeck? initialDeck;

  const QuizScreen({super.key, this.initialDeck});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizDeck> _allDecks;
  late QuizDeck _currentDeck;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasSubmitted = false;
  int _score = 0;
  String _selectedGrade = 'All';

  @override
  void initState() {
    super.initState();
    _allDecks = StudioPreTemplates.getSampleQuizzes();
    _currentDeck = widget.initialDeck ?? _allDecks.first;
    _initUserClass();
  }

  Future<void> _initUserClass() async {
    if (widget.initialDeck != null) return;
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    if (mounted) {
      setState(() {
        if (StudioPreTemplates.allGrades.contains(userGrade)) {
          _selectedGrade = userGrade;
          final matching = _allDecks.where((d) => d.gradeLevel == userGrade).toList();
          if (matching.isNotEmpty) {
            _currentDeck = matching.first;
          }
        }
      });
    }
  }

  void _openGenerateQuizDialog() {
    final theme = _currentDeck.theme;
    final topicCtrl = TextEditingController();
    String targetGrade = _selectedGrade == 'All' ? 'Class 10' : _selectedGrade;
    final quickTopics = [
      'Photosynthesis',
      'Quantum Mechanics',
      'Newton\'s Laws',
      'Wave Optics',
      'Calculus & Integrals',
      'Thermodynamics',
      'Genetics & DNA',
      'Chemical Bonding',
      'Periodic Table',
      'Human Heart & Circulation',
      'Trigonometry'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: theme.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Generate Custom Quiz',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter any STEM topic or choose a suggestion to generate active recall questions:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: topicCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Thermodynamics, Light Optics, Cell Division',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: Icon(Icons.search_rounded, color: theme.accent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickTopics.map((topic) {
                      return ActionChip(
                        label: Text(topic, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                        backgroundColor: theme.accent.withValues(alpha: 0.08),
                        side: BorderSide(color: theme.border),
                        onPressed: () {
                          setSheetState(() {
                            topicCtrl.text = topic;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text(
                        'Generate & Start Quiz',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final t = topicCtrl.text.trim();
                        if (t.isEmpty) return;
                        Navigator.pop(ctx);
                        _generateAndLoadQuiz(t, targetGrade);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _generateAndLoadQuiz(String topic, String grade) {
    final generatedDeck = QuizDeck(
      id: 'qz_gen_${DateTime.now().millisecondsSinceEpoch}',
      title: topic,
      subject: 'STEM Mastery',
      gradeLevel: grade,
      themeIndex: (_allDecks.length) % StudioPalettes.all.length,
      questions: [
        QuizQuestion(
          id: 'q_gen_1',
          question: 'What is the primary governing principle of $topic in $grade science?',
          options: [
            'Fundamental conservation laws and quantitative equilibrium',
            'Arbitrary conventions with no experimental basis',
            'Localized behavior observed strictly in closed vacuum chambers',
            'Hypothetical approximations discarded in modern curricula',
          ],
          correctOptionIndex: 0,
          explanation: '$topic relies directly on fundamental physical conservation laws and validated quantitative equations.',
        ),
        QuizQuestion(
          id: 'q_gen_2',
          question: 'When solving numerical problems related to $topic, which step is essential?',
          options: [
            'Omit dimensional units to speed up calculation',
            'Standardize all quantities to SI units and establish boundary conditions',
            'Assume ideal friction and infinite velocity',
            'Invert the final answer without algebraic verification',
          ],
          correctOptionIndex: 1,
          explanation: 'Accurate numerical mastery in $topic requires consistent SI units, identification of given parameters, and verifying edge limits.',
        ),
        QuizQuestion(
          id: 'q_gen_3',
          question: 'How is $topic typically applied in modern engineering or biological systems?',
          options: [
            'Optimizing thermodynamic efficiency and reaction kinetics',
            'Creating perpetual motion machines',
            'Eliminating electromagnetic radiation entirely',
            'Reversing chemical entropy spontaneously',
          ],
          correctOptionIndex: 0,
          explanation: 'Practical implementations of $topic center around maximizing energy efficiency and predicting reaction rates or mechanical equilibrium.',
        ),
        QuizQuestion(
          id: 'q_gen_4',
          question: 'Which common pitfall must students avoid when answering exam questions on $topic?',
          options: [
            'Writing down the formula before substituting values',
            'Confusing scalar quantities with vector directions or signs',
            'Checking answer magnitude against physical intuition',
            'Drawing a labeled free-body or reaction diagram',
          ],
          correctOptionIndex: 1,
          explanation: 'Sign conventions, vector resolution, and directional vectors are the most frequent source of errors in $topic examination problems.',
        ),
      ],
    );

    setState(() {
      _allDecks.insert(0, generatedDeck);
      _selectedGrade = grade;
      _switchDeck(generatedDeck);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Created new quiz: "$topic" ($grade)!'),
        backgroundColor: generatedDeck.theme.accent,
      ),
    );
  }

  List<QuizDeck> get _filteredDecks {
    if (_selectedGrade == 'All') return _allDecks;
    return _allDecks.where((d) => d.gradeLevel == _selectedGrade).toList();
  }

  void _switchDeck(QuizDeck deck) {
    setState(() {
      _currentDeck = deck;
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _hasSubmitted = false;
      _score = 0;
    });
  }

  void _selectOption(int index) {
    if (_hasSubmitted) return;
    setState(() => _selectedOptionIndex = index);
  }

  void _submitAnswer() {
    if (_selectedOptionIndex == null || _hasSubmitted) return;

    final question = _currentDeck.questions[_currentIndex];
    final isCorrect = _selectedOptionIndex == question.correctOptionIndex;

    setState(() {
      _hasSubmitted = true;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _currentDeck.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _hasSubmitted = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final total = _currentDeck.questions.length;
    final percentage = ((_score / total) * 100).toInt();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            percentage >= 70 ? '🏆 Fantastic Job!' : '📚 Good Practice!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score / $total Correct',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _currentDeck.theme.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy Score: $percentage%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _selectedOptionIndex = null;
                _hasSubmitted = false;
                _score = 0;
              });
            },
            child: Text(
              'Retake Quiz',
              style: GoogleFonts.plusJakartaSans(
                color: _currentDeck.theme.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentDeck.theme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentDeck.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = _currentDeck.questions[_currentIndex];
    final progress = (_currentIndex + 1) / _currentDeck.questions.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1A1C) : theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : theme.primaryText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Studio: Active Recall Quiz',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accent,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${_currentDeck.title} • ${_currentDeck.gradeLevel}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : theme.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Generate Custom Quiz',
            color: theme.accent,
            onPressed: _openGenerateQuizDialog,
          ),
          PopupMenuButton<QuizDeck>(
            icon: Icon(Icons.quiz_outlined, color: theme.accent),
            tooltip: 'Switch Quiz',
            onSelected: _switchDeck,
            itemBuilder: (context) => _filteredDecks.map((d) {
              final isSelected = d.id == _currentDeck.id;
              return PopupMenuItem<QuizDeck>(
                value: d,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 16,
                      color: isSelected ? theme.accent : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      d.gradeLevel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.accent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Grade Filter Chips Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: StudioPreTemplates.allGrades.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final grade = StudioPreTemplates.allGrades[i];
                  final isSelected = grade == _selectedGrade;
                  return FilterChip(
                    label: Text(
                      grade,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : theme.primaryText),
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: isDark ? const Color(0xFF1B2A2D) : theme.cardBackground,
                    selectedColor: theme.accent,
                    side: BorderSide(
                      color: isSelected ? theme.accent : (isDark ? Colors.white12 : theme.border),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (_) {
                      setState(() {
                        _selectedGrade = grade;
                        final filtered = _filteredDecks;
                        if (filtered.isNotEmpty && !filtered.any((d) => d.id == _currentDeck.id)) {
                          _switchDeck(filtered.first);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            // Visible Quiz Selector Chips Bar with "+ Generate" button
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filteredDecks.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    return InkWell(
                      onTap: _openGenerateQuizDialog,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.accent, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 14, color: theme.accent),
                            const SizedBox(width: 5),
                            Text(
                              '+ New Quiz',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: theme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final d = _filteredDecks[idx - 1];
                  final isCurrent = d.id == _currentDeck.id;
                  return InkWell(
                    onTap: () => _switchDeck(d),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.accent.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF162529) : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? theme.accent
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            width: isCurrent ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              d.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent
                                    ? theme.accent
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: theme.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${d.questions.length} Qs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Question Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUESTION ${_currentIndex + 1} OF ${_currentDeck.questions.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white60 : theme.secondaryText,
                        ),
                      ),
                      Text(
                        'Score: $_score',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: theme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                    ),
                  ),
                ],
              ),
            ),

            // Question Box & Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF162629) : theme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF233B3F) : theme.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      question.question,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : theme.primaryText,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option Tiles
                  ...List.generate(question.options.length, (optIdx) {
                    final optionText = question.options[optIdx];
                    final isSelected = _selectedOptionIndex == optIdx;
                    final isCorrect = optIdx == question.correctOptionIndex;

                    Color optBg = isDark ? const Color(0xFF142225) : Colors.white;
                    Color optBorder = isDark ? const Color(0xFF233B3F) : theme.border;
                    Color optText = isDark ? Colors.white : theme.primaryText;
                    IconData? optIcon;
                    Color? optIconColor;

                    if (_hasSubmitted) {
                      if (isCorrect) {
                        optBg = const Color(0xFFE8F5E9);
                        optBorder = const Color(0xFF4CAF50);
                        optText = const Color(0xFF1B5E20);
                        optIcon = Icons.check_circle_rounded;
                        optIconColor = const Color(0xFF4CAF50);
                      } else if (isSelected && !isCorrect) {
                        optBg = const Color(0xFFFFEBEE);
                        optBorder = const Color(0xFFEF5350);
                        optText = const Color(0xFFB71C1C);
                        optIcon = Icons.cancel_rounded;
                        optIconColor = const Color(0xFFEF5350);
                      }
                    } else if (isSelected) {
                      optBg = theme.accent.withValues(alpha: 0.1);
                      optBorder = theme.accent;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _selectOption(optIdx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: optBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: optBorder, width: isSelected ? 1.5 : 1.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected && !_hasSubmitted
                                      ? theme.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected && !_hasSubmitted
                                        ? theme.accent
                                        : Colors.grey[400]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected && !_hasSubmitted
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: optText,
                                  ),
                                ),
                              ),
                              if (optIcon != null) ...[
                                Icon(optIcon, color: optIconColor, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Explanation Card (Visible after submit)
                  if (_hasSubmitted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3236) : theme.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: theme.accent),
                              const SizedBox(width: 6),
                              Text(
                                'Explanation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            question.explanation,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                              color: isDark ? Colors.white70 : theme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Submit / Next Action
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedOptionIndex == null
                      ? null
                      : (_hasSubmitted ? _nextQuestion : _submitAnswer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    !_hasSubmitted
                        ? 'Check Answer'
                        : (_currentIndex == _currentDeck.questions.length - 1
                            ? 'See Final Results'
                            : 'Next Question →'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
