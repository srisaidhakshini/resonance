import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';

class SlideDeckScreen extends StatefulWidget {
  final SlideDeck? initialDeck;

  const SlideDeckScreen({super.key, this.initialDeck});

  @override
  State<SlideDeckScreen> createState() => _SlideDeckScreenState();
}

class _SlideDeckScreenState extends State<SlideDeckScreen> {
  late List<SlideDeck> _decks;
  late SlideDeck _currentDeck;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedGrade = 'All';

  @override
  void initState() {
    super.initState();
    _decks = StudioPreTemplates.getSampleDecks();
    _currentDeck = widget.initialDeck ?? _decks.first;
    _initUserClass();
  }

  Future<void> _initUserClass() async {
    if (widget.initialDeck != null) return;
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    if (mounted) {
      setState(() {
        if (StudioPreTemplates.allGrades.contains(userGrade)) {
          _selectedGrade = userGrade;
          final matching = _decks.where((d) => d.gradeLevel == userGrade).toList();
          if (matching.isNotEmpty) {
            _currentDeck = matching.first;
            _currentPage = 0;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<SlideDeck> get _filteredDecks {
    if (_selectedGrade == 'All') return _decks;
    return _decks.where((d) => d.gradeLevel == _selectedGrade).toList();
  }

  void _switchDeck(SlideDeck deck) {
    setState(() {
      _currentDeck = deck;
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentDeck.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              'Studio: Slide Deck',
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
          // Deck Switcher Menu
          PopupMenuButton<SlideDeck>(
            icon: Icon(Icons.layers_outlined, color: theme.accent),
            tooltip: 'Choose Slide Deck',
            onSelected: _switchDeck,
            itemBuilder: (context) => _filteredDecks.map((d) {
              final isSelected = d.id == _currentDeck.id;
              return PopupMenuItem<SlideDeck>(
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
                                '${d.slides.length} slides',
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
            // Deck progress header & indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SLIDE ${_currentPage + 1} OF ${_currentDeck.slides.length}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.white70 : theme.secondaryText,
                    ),
                  ),
                  Row(
                    children: List.generate(_currentDeck.slides.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? theme.accent : theme.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Main Slide PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _currentDeck.slides.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final slide = _currentDeck.slides[index];
                  return _buildSlideCard(slide, theme, isDark);
                },
              ),
            ),

            // Bottom Navigation Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  OutlinedButton.icon(
                    onPressed: _currentPage > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'Prev',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.accent,
                      side: BorderSide(color: theme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),

                  // Next Button
                  ElevatedButton.icon(
                    onPressed: _currentPage < _currentDeck.slides.length - 1
                        ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      _currentPage == _currentDeck.slides.length - 1 ? 'Finished' : 'Next',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildSlideCard(SlideItem slide, StudioTheme theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(24),
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
          // Slide number chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Slide ${slide.slideNumber}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Slide Title
          Text(
            slide.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : theme.primaryText,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            slide.subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : theme.secondaryText,
            ),
          ),
          const Divider(height: 32, thickness: 1),

          // Bullet Points
          Expanded(
            child: ListView.separated(
              itemCount: slide.bulletPoints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final pt = slide.bulletPoints[idx];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        pt,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: isDark ? Colors.white70 : theme.primaryText,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Formula / Code box if present
          if (slide.codeOrFormula != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.accent.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  slide.codeOrFormula!,
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          // Key Takeaway callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2E32) : theme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF2C494E) : theme.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 18, color: theme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slide.keyTakeaway,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : theme.primaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
