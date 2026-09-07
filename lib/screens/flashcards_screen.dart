import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';

class FlashcardsScreen extends StatefulWidget {
  final FlashcardDeck? initialDeck;

  const FlashcardsScreen({super.key, this.initialDeck});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> with SingleTickerProviderStateMixin {
  late List<FlashcardDeck> _decks;
  late FlashcardDeck _currentDeck;
  int _currentIndex = 0;
  bool _showBack = false;
  bool _showHint = false;
  String _selectedGrade = 'All';

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _decks = StudioPreTemplates.getSampleFlashcards();
    _currentDeck = widget.initialDeck ?? _decks.first;

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  List<FlashcardDeck> get _filteredDecks {
    if (_selectedGrade == 'All') return _decks;
    return _decks.where((d) => d.gradeLevel == _selectedGrade).toList();
  }

  void _flipCard() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _showBack = !_showBack;
      _showHint = false;
    });
  }

  void _nextCard({required bool mastered}) {
    setState(() {
      _currentDeck.cards[_currentIndex].isMastered = mastered;
      if (_currentIndex < _currentDeck.cards.length - 1) {
        _currentIndex++;
        _showBack = false;
        _showHint = false;
        _flipController.reset();
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showBack = false;
        _showHint = false;
        _flipController.reset();
      });
    }
  }

  void _switchDeck(FlashcardDeck deck) {
    setState(() {
      _currentDeck = deck;
      _currentIndex = 0;
      _showBack = false;
      _showHint = false;
      _flipController.reset();
    });
  }

  void _showCompletionDialog() {
    final masteredCount = _currentDeck.masteredCount;
    final total = _currentDeck.cards.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _currentDeck.theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Deck Finished! 🎉',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: _currentDeck.theme.primaryText,
          ),
        ),
        content: Text(
          'You mastered $masteredCount of $total cards in ${_currentDeck.title}!',
          style: GoogleFonts.plusJakartaSans(
            color: _currentDeck.theme.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _showBack = false;
                _showHint = false;
                _flipController.reset();
                for (final c in _currentDeck.cards) {
                  c.isMastered = false;
                }
              });
            },
            child: Text(
              'Practice Again',
              style: GoogleFonts.plusJakartaSans(
                color: _currentDeck.theme.accent,
                fontWeight: FontWeight.w600,
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentDeck.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _currentDeck.cards[_currentIndex];
    final progress = (_currentIndex + 1) / _currentDeck.cards.length;

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
              'Studio: Flashcards',
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
          PopupMenuButton<FlashcardDeck>(
            icon: Icon(Icons.style_outlined, color: theme.accent),
            tooltip: 'Switch Deck',
            onSelected: _switchDeck,
            itemBuilder: (context) => _filteredDecks.map((d) {
              final isSelected = d.id == _currentDeck.id;
              return PopupMenuItem<FlashcardDeck>(
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
            // Visible Deck Selector Chips Bar
            if (_filteredDecks.length > 1)
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredDecks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final d = _filteredDecks[idx];
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
                                '${d.cards.length}',
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
            // Progress tracker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CARD ${_currentIndex + 1} OF ${_currentDeck.cards.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white60 : theme.secondaryText,
                        ),
                      ),
                      Text(
                        'Mastered: ${_currentDeck.masteredCount}',
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

            // Interactive Flip Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      final isUnder = angle > math.pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateY(angle),
                        child: isUnder
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _buildBackCard(card, theme, isDark),
                              )
                            : _buildFrontCard(card, theme, isDark),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom Action Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  // Previous Card
                  IconButton.outlined(
                    onPressed: _currentIndex > 0 ? _previousCard : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.accent,
                      side: BorderSide(color: theme.border),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Still Learning / Need Review
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _nextCard(mastered: false),
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(
                        'Review',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD95C5C),
                        side: const BorderSide(color: Color(0xFFF3C0C0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Mastered / Got it
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _nextCard(mastered: true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        'Got It!',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontCard(FlashcardItem card, StudioTheme theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162629) : theme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF233B3F) : theme.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.category.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to flip',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              card.frontQuestion,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : theme.primaryText,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          if (card.hint.isNotEmpty) ...[
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showHint = !_showHint),
                icon: Icon(
                  _showHint ? Icons.visibility_off_outlined : Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: theme.accent,
                ),
                label: Text(
                  _showHint ? card.hint : 'Need a hint?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackCard(FlashcardItem card, StudioTheme theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132B2E) : theme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.4),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ANSWER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to flip back',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              card.backAnswer,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : theme.primaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Did you recall this correctly?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white60 : theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
