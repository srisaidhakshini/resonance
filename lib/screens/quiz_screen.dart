import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';
import '../providers/ui_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/mascot_widget.dart';
import 'profile_setup_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final QuizDeck? initialDeck;
  /// True when hosted as a persistent bottom-nav tab (shows a menu/drawer
  /// icon and reacts to [pendingQuizTopicProvider]) instead of a pushed
  /// route (which shows a back button).
  final bool isTab;

  const QuizScreen({super.key, this.initialDeck, this.isTab = false});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late List<QuizDeck> _allDecks;
  late QuizDeck _currentDeck;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasSubmitted = false;
  int _score = 0;
  String? _activeGrade;
  String _selectedSubject = 'All';
  MascotState _mascotState = MascotState.idle;

  @override
  void initState() {
    super.initState();
    _allDecks = StudioPreTemplates.getSampleQuizzes();
    _currentDeck = widget.initialDeck ?? _allDecks.first;
    _initUserClass();
  }

  Future<void> _initUserClass() async {
    if (widget.initialDeck != null) {
      _activeGrade = widget.initialDeck!.gradeLevel;
      _selectedSubject = widget.initialDeck!.subject;
      return;
    }
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    if (mounted) {
      setState(() {
        _activeGrade = userGrade;
        _selectedSubject = 'All';
        final matching = _allDecks.where((d) => d.gradeLevel == userGrade).toList();
        if (matching.isNotEmpty) {
          _currentDeck = matching.first;
        }
      });
    }
  }

  void _navigateToProfile() {
    if (widget.isTab) {
      // In persistent bottom navigation shell: jump directly to Profile tab
      ref.read(selectedNavIndexProvider.notifier).state = 5;
    } else {
      // Pushed modal or route: push ProfileSetupScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(isEditMode: true),
        ),
      ).then((_) {
        if (mounted) {
          final p = ref.read(userProfileNotifierProvider);
          final g = formatGrade(p.grade);
          if (_activeGrade != g) {
            setState(() {
              _activeGrade = g;
              _selectedSubject = 'All';
              final matching = _allDecks.where((d) => d.gradeLevel == g).toList();
              if (matching.isNotEmpty) {
                _switchDeck(matching.first);
              }
            });
          }
        }
      });
    }
  }

  void _openGenerateQuizDialog() {
    final theme = _currentDeck.theme;
    final topicCtrl = TextEditingController();
    final targetGrade = _activeGrade ?? 'Class 10';

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
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1520) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
              ),
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
                          color: isDark ? const Color(0xFF00F5A0).withOpacity(0.14) : AppColors.lightSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: isDark ? const Color(0xFF00F5A0) : theme.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Generate Custom Quiz',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : theme.primaryText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : AppColors.lightMutedForeground),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Topic or Concept',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: topicCtrl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.lightForeground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., Electromagnetic Induction, Mitosis...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : AppColors.lightMutedForeground,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.06) : AppColors.lightInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF00F5A0) : theme.accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Popular Topics for $targetGrade',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickTopics.map((topic) {
                      return ActionChip(
                        label: Text(topic, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : theme.cardBackground,
                        side: BorderSide(color: isDark ? Colors.white12 : theme.border),
                        onPressed: () {
                          topicCtrl.text = topic;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final topic = topicCtrl.text.trim();
                        if (topic.isEmpty) return;
                        Navigator.pop(ctx);
                        _generateAndLoadQuiz(topic, targetGrade);
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text(
                        'Generate Quiz',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF00F5A0) : theme.accent,
                        foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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
    final currentThemeIndex = _currentDeck.themeIndex;
    final generatedDeck = QuizDeck(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: topic,
      subject: _selectedSubject == 'All' ? 'Science' : _selectedSubject,
      gradeLevel: grade,
      themeIndex: currentThemeIndex,
      questions: [
        QuizQuestion(
          id: 'q_gen_1',
          question: 'What is the primary governing principle of $topic at the $grade curriculum level?',
          options: [
            'Fundamental conservation laws and core mechanistic principles',
            'Arbitrary empirical observations with zero theoretical backing',
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
      _switchDeck(generatedDeck);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Created new quiz: "$topic" ($grade)!'),
        backgroundColor: generatedDeck.theme.accent,
      ),
    );
  }

  List<QuizDeck> get _gradeDecks {
    final grade = _activeGrade ?? 'Class 10';
    final list = _allDecks.where((d) => d.gradeLevel == grade).toList();
    if (list.isEmpty) {
      return _allDecks.where((d) => d.gradeLevel == 'Class 10').toList();
    }
    return list;
  }

  List<String> get _availableSubjects {
    final subjects = <String>['All'];
    for (final deck in _gradeDecks) {
      final s = deck.subject.trim();
      if (s.isNotEmpty && !subjects.contains(s)) {
        subjects.add(s);
      }
    }
    return subjects;
  }

  List<QuizDeck> get _filteredDecks {
    final list = _gradeDecks;
    if (_selectedSubject == 'All') return list;
    final subjectMatches = list.where((d) => d.subject == _selectedSubject).toList();
    return subjectMatches.isNotEmpty ? subjectMatches : list;
  }

  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      final filtered = _filteredDecks;
      if (filtered.isNotEmpty && !filtered.any((d) => d.id == _currentDeck.id)) {
        _switchDeck(filtered.first);
      }
    });
  }

  IconData _getSubjectIcon(String subject) {
    final lower = subject.toLowerCase();
    if (lower == 'all') return Icons.grid_view_rounded;
    if (lower.contains('physic')) return Icons.bolt_rounded;
    if (lower.contains('chem')) return Icons.science_outlined;
    if (lower.contains('bio')) return Icons.biotech_rounded;
    if (lower.contains('math')) return Icons.calculate_outlined;
    if (lower.contains('comp') || lower.contains('cs')) return Icons.computer_rounded;
    if (lower.contains('social') || lower.contains('history') || lower.contains('geo')) return Icons.public_rounded;
    if (lower.contains('eng')) return Icons.menu_book_rounded;
    return Icons.school_outlined;
  }

  String _cleanQuizTitle(String title) {
    var cleaned = title
        .replaceFirst(RegExp(r'^(?:Class|Grade)\s*\d+[\s:\-–]*', caseSensitive: false), '')
        .trim();
    cleaned = cleaned
        .replaceFirst(RegExp(r'^(?:Physics|Chemistry|Biology|Mathematics|Math|Computer\s*Science|CS|Science(?:\s*&\s*Math)?)[\s:\-–]+', caseSensitive: false), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : title;
  }

  void _switchDeck(QuizDeck deck) {
    setState(() {
      _currentDeck = deck;
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _hasSubmitted = false;
      _score = 0;
      _mascotState = MascotState.idle;
    });
  }

  void _selectOption(int index) {
    if (_hasSubmitted) return;
    setState(() {
      _selectedOptionIndex = index;
      _mascotState = MascotState.thinking;
    });
  }

  void _submitAnswer() {
    if (_selectedOptionIndex == null || _hasSubmitted) return;

    final isCorrect = _selectedOptionIndex == _currentDeck.questions[_currentIndex].correctOptionIndex;

    setState(() {
      _hasSubmitted = true;
      if (isCorrect) _score++;
      _mascotState = isCorrect ? MascotState.correct : MascotState.wrong;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _currentDeck.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _hasSubmitted = false;
        _mascotState = MascotState.idle;
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1520) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
            ),
          ),
          title: Center(
            child: Text(
              percentage >= 70 ? '🏆 Fantastic Job!' : '📚 Good Practice!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: isDark ? Colors.white : AppColors.lightForeground,
              ),
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
                  color: isDark ? const Color(0xFF00F5A0) : _currentDeck.theme.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accuracy Score: $percentage%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey[600],
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
                  _mascotState = MascotState.idle;
                });
              },
              child: Text(
                'Retake Quiz',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? const Color(0xFF00F5A0) : _currentDeck.theme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (!widget.isTab) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : _currentDeck.theme.accent,
                foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.isTab ? 'Done' : 'Back to Home'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileNotifierProvider);
    final profileGrade = formatGrade(userProfile.grade);

    if (_activeGrade != profileGrade && widget.initialDeck == null) {
      _activeGrade = profileGrade;
      _selectedSubject = 'All';
      final matching = _allDecks.where((d) => d.gradeLevel == profileGrade).toList();
      if (matching.isNotEmpty) {
        _currentDeck = matching.first;
        _currentIndex = 0;
        _selectedOptionIndex = null;
        _hasSubmitted = false;
        _score = 0;
        _mascotState = MascotState.idle;
      }
    }

    if (widget.isTab) {
      ref.listen<String?>(pendingQuizTopicProvider, (previous, topic) {
        if (topic != null && topic.trim().isNotEmpty) {
          ref.read(pendingQuizTopicProvider.notifier).state = null;
          final cleanTopic = topic.replaceAll(RegExp(r'[:\s]+$'), '').trim();
          _generateAndLoadQuiz(cleanTopic, _activeGrade ?? 'Class 10');
        }
      });
    }

    final theme = _currentDeck.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = _currentDeck.questions[_currentIndex];
    final progress = (_currentIndex + 1) / _currentDeck.questions.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: widget.isTab ? const AppDrawer() : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: widget.isTab
              ? Builder(
                  builder: (context) => Center(
                    child: InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.menu_rounded,
                          size: 20,
                          color: isDark ? Colors.white : AppColors.lightForeground,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(21),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
                          width: 1,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark ? Colors.white : AppColors.lightForeground,
                      ),
                    ),
                  ),
                ),
        ),
        title: Text(
          _activeGrade ?? profileGrade,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.lightForeground,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconButton(
              icon: Icon(Icons.auto_awesome_rounded, size: 18, color: isDark ? const Color(0xFF00F5A0) : theme.accent),
              tooltip: 'Generate Custom Quiz',
              onPressed: _openGenerateQuizDialog,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: PopupMenuButton<QuizDeck>(
              icon: Icon(Icons.quiz_outlined, size: 18, color: isDark ? const Color(0xFF00F5A0) : theme.accent),
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
                        color: isSelected ? (isDark ? const Color(0xFF00F5A0) : theme.accent) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _cleanQuizTitle(d.title),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        d.subject,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF00F5A0) : theme.accent,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconButton(
              icon: Icon(Icons.person_outline_rounded, size: 18, color: isDark ? const Color(0xFF00F5A0) : theme.accent),
              tooltip: 'Profile',
              onPressed: _navigateToProfile,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Subject Switcher Bar for that particular grade
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableSubjects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final subject = _availableSubjects[i];
                    final isSelected = subject == _selectedSubject;
                    return FilterChip(
                      avatar: Icon(
                        _getSubjectIcon(subject),
                        size: 14,
                        color: isSelected ? Colors.white : (isDark ? const Color(0xFF00F5A0) : theme.accent),
                      ),
                      label: Text(
                        subject,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : theme.primaryText),
                        ),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
                      selectedColor: isDark ? const Color(0xFF00F5A0) : theme.accent,
                      side: BorderSide(
                        color: isSelected ? (isDark ? const Color(0xFF00F5A0) : theme.accent) : (isDark ? Colors.white12 : AppColors.lightBorder),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (_) => _selectSubject(subject),
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
                            color: (isDark ? const Color(0xFF00F5A0) : theme.accent).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF00F5A0) : theme.accent, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 14, color: isDark ? const Color(0xFF00F5A0) : theme.accent),
                              const SizedBox(width: 5),
                              Text(
                                '+ New Quiz',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF00F5A0) : theme.accent,
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
                              ? (isDark ? const Color(0xFF00F5A0).withOpacity(0.18) : theme.accent.withOpacity(0.14))
                              : (isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? (isDark ? const Color(0xFF00F5A0) : theme.accent)
                                : (isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder),
                            width: isCurrent ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _cleanQuizTitle(d.title),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent
                                    ? (isDark ? const Color(0xFF00F5A0) : theme.accent)
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF00F5A0) : theme.accent).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${d.questions.length} Qs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF00F5A0) : theme.accent,
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

              // Mascot Reaction Panel
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    MascotWidget(
                      key: ValueKey('${_currentDeck.id}_$_currentIndex'),
                      state: _mascotState,
                      size: 92,
                      onReactionComplete: () {},
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey(_mascotState),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: (_mascotState == MascotState.correct
                                    ? const Color(0xFF4CAF50)
                                    : _mascotState == MascotState.wrong
                                        ? const Color(0xFFEF5350)
                                        : (isDark ? const Color(0xFF00F5A0) : theme.accent))
                                .withOpacity(isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            switch (_mascotState) {
                              MascotState.idle => "I'll be here — take your time!",
                              MascotState.thinking => "Hmm, are you sure about that?",
                              MascotState.correct => "Yes! Nailed it! 🎉",
                              MascotState.wrong => "Oops, not quite — check the explanation!",
                            },
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : theme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            color: isDark ? const Color(0xFF00F5A0) : theme.accent,
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
                        backgroundColor: isDark ? Colors.white.withOpacity(0.08) : theme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF00F5A0) : theme.accent),
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
                        color: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.10) : AppColors.lightBorder,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.20) : const Color(0xFF123B46).withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
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

                      Color optBg = isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.92);
                      Color optBorder = isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder;
                      Color optText = isDark ? Colors.white : theme.primaryText;
                      IconData? optIcon;
                      Color? optIconColor;

                      if (_hasSubmitted) {
                        if (isCorrect) {
                          optBg = isDark ? const Color(0xFF00F5A0).withOpacity(0.15) : const Color(0xFFE8F5E9);
                          optBorder = const Color(0xFF00F5A0);
                          optText = isDark ? const Color(0xFF00F5A0) : const Color(0xFF1B5E20);
                          optIcon = Icons.check_circle_rounded;
                          optIconColor = const Color(0xFF00F5A0);
                        } else if (isSelected && !isCorrect) {
                          optBg = const Color(0xFFEF5350).withOpacity(0.15);
                          optBorder = const Color(0xFFEF5350);
                          optText = isDark ? const Color(0xFFF87171) : const Color(0xFFB71C1C);
                          optIcon = Icons.cancel_rounded;
                          optIconColor = const Color(0xFFEF5350);
                        }
                      } else if (isSelected) {
                        optBg = isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : theme.accent.withOpacity(0.1);
                        optBorder = isDark ? const Color(0xFF00F5A0) : theme.accent;
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
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.10) : const Color(0xFF123B46).withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected && !_hasSubmitted
                                        ? (isDark ? const Color(0xFF00F5A0) : theme.accent)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected && !_hasSubmitted
                                          ? (isDark ? const Color(0xFF00F5A0) : theme.accent)
                                          : (isDark ? Colors.white30 : Colors.grey[400]!),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + optIdx),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected && !_hasSubmitted
                                            ? (isDark ? const Color(0xFF070B11) : Colors.white)
                                            : (isDark ? Colors.white60 : Colors.grey[600]),
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
                          color: isDark ? Colors.white.withOpacity(0.055) : theme.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF00F5A0).withOpacity(0.3) : theme.accent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: isDark ? const Color(0xFF00F5A0) : theme.accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Explanation',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF00F5A0) : theme.accent,
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
                      backgroundColor: isDark ? Colors.white : theme.accent,
                      foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
