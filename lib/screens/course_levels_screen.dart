import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/learning_course.dart';
import '../providers/chat_provider.dart';
import '../providers/course_progress_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/ui_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/level_roadmap_painter.dart';

class CourseLevelsScreen extends ConsumerStatefulWidget {
  final LearningCourse initialCourse;
  final Function(String prompt)? onNavigateToChatWithPrompt;

  const CourseLevelsScreen({
    super.key,
    required this.initialCourse,
    this.onNavigateToChatWithPrompt,
  });

  @override
  ConsumerState<CourseLevelsScreen> createState() => _CourseLevelsScreenState();
}

class _CourseLevelsScreenState extends ConsumerState<CourseLevelsScreen> {
  late LearningCourse _currentCourse;
  late List<LearningCourse> _siblingCourses;

  @override
  void initState() {
    super.initState();
    _currentCourse = widget.initialCourse;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final grade = ref.read(userProfileNotifierProvider).grade;
      setState(() {
        _siblingCourses = CourseRepository.getCoursesForSubject(
          _currentCourse.subjectName,
          grade: grade,
          subjectId: _currentCourse.subjectId,
        );
      });
      ref.read(courseProgressProvider.notifier).setLastActiveCourse(_currentCourse.id);
    });
    _siblingCourses = CourseRepository.getCoursesForSubject(
      _currentCourse.subjectName,
      subjectId: _currentCourse.subjectId,
    );
  }

  void _switchCourse(LearningCourse course) {
    setState(() {
      _currentCourse = course;
    });
    ref.read(courseProgressProvider.notifier).setLastActiveCourse(course.id);
  }

  void _openLessonDetails(CourseLevel level) {
    if (level.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Complete the previous level to unlock "${level.title}".'),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1520) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2EBE9),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: level.isCompleted
                        ? const Color(0xFF00F5A0).withOpacity(0.15)
                        : (level.isActive
                            ? const Color(0xFF00F5A0).withOpacity(0.15)
                            : Colors.grey.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    level.code,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: level.isCompleted
                          ? const Color(0xFF00F5A0)
                          : (level.isActive ? const Color(0xFF00F5A0) : Colors.grey),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  level.duration,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              level.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              level.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            if (level.keyConcepts.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'KEY CONCEPTS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: level.keyConcepts.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '• $c',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startEchoLesson(level);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(
                      level.isCompleted ? 'Review with Echo' : 'Start with Echo',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : AppColors.lightTeal,
                      foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startLevelQuiz(level);
                    },
                    icon: const Icon(Icons.quiz_outlined, size: 16),
                    label: Text(
                      'Practice Quiz',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.lightTeal,
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.2) : AppColors.lightTeal,
                        width: 1.3,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!level.isCompleted)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(courseProgressProvider.notifier).completeLevel(
                          _currentCourse.id,
                          level.levelNumber,
                          totalLevels: _currentCourse.levels.length,
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Level ${level.levelNumber} Completed! Next level unlocked.'),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Mark Level Complete & Advance'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'Level Completed • Ready for Review or Retake',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
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

  void _startEchoLesson(CourseLevel level) {
    final prompt =
        'Teach me the topic "${level.title}" from ${_currentCourse.subjectName}: ${_currentCourse.title}. '
        'Explain step-by-step using clear analogies, key formulas, and test me with a sample problem!';

    if (widget.onNavigateToChatWithPrompt != null) {
      Navigator.pop(context);
      widget.onNavigateToChatWithPrompt!(prompt);
    } else {
      ref.read(chatProvider.notifier).startNewChat();
      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {'initialText': prompt},
      );
    }
  }

  void _startLevelQuiz(CourseLevel level) {
    ref.read(pendingQuizTopicProvider.notifier).state = level.quizTopic;
    ref.read(selectedNavIndexProvider.notifier).state = 2; // Jump to Practice Tab
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseProgressData = ref.watch(courseProgressProvider);
    final userProfile = ref.watch(userProfileNotifierProvider);
    final progressMetrics = ref.watch(progressMetricsProvider);

    final courseProgressNotifier = ref.read(courseProgressProvider.notifier);
    final completedLevels = courseProgressData.completedLevels[_currentCourse.id] ?? const <int>[];
    final activeLevelNum = courseProgressNotifier.getActiveLevel(
      _currentCourse.id,
      totalLevels: _currentCourse.levels.length,
    );
    final dynamicProgressPercent = courseProgressNotifier.getCourseProgressPercent(
      _currentCourse.id,
      _currentCourse.levels.length,
    );

    CourseLevel getDynamicLevel(int index) {
      if (index >= _currentCourse.levels.length) {
        return CourseLevel(
          levelNumber: index + 1,
          code: '0${index + 1} • LEVEL',
          title: 'Lesson ${index + 1}',
          description: '',
          status: LevelStatus.locked,
          stepProgress: 'Step 0 of 5',
          duration: '8 min',
          quizTopic: _currentCourse.title,
        );
      }
      final base = _currentCourse.levels[index];
      final isComp = completedLevels.contains(base.levelNumber);
      final isAct = !isComp && (base.levelNumber == activeLevelNum);
      final stat = isComp
          ? LevelStatus.completed
          : (isAct ? LevelStatus.active : LevelStatus.locked);
      return base.copyWith(status: stat);
    }

    final lvl1 = getDynamicLevel(0);
    final lvl2 = getDynamicLevel(1);
    final lvl3 = getDynamicLevel(2);
    final lvl4 = getDynamicLevel(3);
    final lvl5 = getDynamicLevel(4);

    final streak = progressMetrics.studyStreakDays;
    final streakText = streak > 0 ? '$streak Day${streak == 1 ? '' : 's'}' : '0 Days';
    final userInitial = userProfile.userName.trim().isNotEmpty
        ? userProfile.userName.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B11) : const Color(0xFFF9FBFA),
      body: Stack(
        children: [
          // Spirit ambient radial glows in dark mode
          if (isDark) ...[
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00F5A0).withOpacity(0.12),
                      const Color(0xFF00F5A0).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 350,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withOpacity(0.08),
                      const Color(0xFF0EA5E9).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(21),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Learn',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      // Dynamic Study Streak Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF00F5A0).withOpacity(0.12)
                              : const Color(0xFFD3F4EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00F5A0).withOpacity(0.25) : const Color(0xFFB5EAE1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              streakText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dynamic User Initial Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF0F262C),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            userInitial,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF5EEAD4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

            // Main Scrollable Area with generous bottom padding
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                child: Column(
                  children: [
                    // Course Header Card with dynamic progress ring
                    _buildCourseHeaderCard(isDark, dynamicProgressPercent),

                    const SizedBox(height: 14),

                    // Roadmap Skill Tree Area with responsive LayoutBuilder
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cx = w / 2;

                        final p1 = Offset(cx - 20, 50);
                        final p2 = Offset(cx + 70, 160);
                        final p3 = Offset(cx - 10, 280);
                        final p4 = Offset(cx - 75, 480);
                        final pBonus = Offset(cx + 65, 480);
                        final p5 = Offset(cx - 75, 610);

                        final nodePositions = [p1, p2, p3, p4, p5];

                        return SizedBox(
                          height: 690,
                          width: double.infinity,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Background Grid & Connecting Pipes
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: LevelRoadmapPainter(
                                    nodePositions: nodePositions,
                                    isDark: isDark,
                                  ),
                                ),
                              ),

                              // Node 1
                              _buildPositionedLevelNode(p1, lvl1, isDark),

                              // Node 2
                              _buildPositionedLevelNode(p2, lvl2, isDark),

                              // Node 3
                              _buildPositionedLevelNode(p3, lvl3, isDark),

                              // Node 4
                              _buildPositionedLevelNode(p4, lvl4, isDark),

                              // Adjacent Bonus Node: DAILY SPEED RUN (only when this level actually has one)
                              if (lvl4.hasBonus)
                                _buildPositionedBonusNode(pBonus),

                              // Node 5
                              _buildPositionedLevelNode(p5, lvl5, isDark),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
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

  // Positioned helper to guarantee the node icon box is strictly centered at pos.dx, pos.dy
  Widget _buildPositionedLevelNode(Offset pos, CourseLevel level, bool isDark) {
    final double boxRadius = level.isActive ? 33.0 : 31.0;
    const double slotWidth = 150.0;
    return Positioned(
      left: pos.dx - (slotWidth / 2),
      top: pos.dy - boxRadius,
      width: slotWidth,
      child: _buildNodeForLevel(level, isDark),
    );
  }

  Widget _buildPositionedBonusNode(Offset pos) {
    const double boxRadius = 29.0;
    const double slotWidth = 120.0;
    return Positioned(
      left: pos.dx - (slotWidth / 2),
      top: pos.dy - boxRadius,
      width: slotWidth,
      child: _buildDailySpeedRunNode(),
    );
  }

  // Helper to dynamically build each roadmap level node based on its computed status
  Widget _buildNodeForLevel(CourseLevel level, bool isDark) {
    if (level.isCompleted) {
      return _buildCompletedNode(
        code: level.code,
        onTap: () => _openLessonDetails(level),
      );
    } else if (level.isActive) {
      return _buildActiveNode(level);
    } else {
      return _buildLockedNode(
        title: '${level.code.split('•').first.trim()} • Locked',
        onTap: () => _openLessonDetails(level),
        isDark: isDark,
      );
    }
  }

  // Active Lesson Lightning Bolt Node
  Widget _buildActiveNode(CourseLevel level) {
    return GestureDetector(
      onTap: () => _openLessonDetails(level),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5A0), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F5A0).withOpacity(0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bolt_rounded,
                size: 34,
                color: Color(0xFF070B11),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.code,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFF00F5A0),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Course Header Card with Dropdown Switcher and Dynamic Circular Progress Ring
  Widget _buildCourseHeaderCard(bool isDark, int progressPercent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.055) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.09) : const Color(0xFFE2EBE9),
          width: 1.1,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subject badge tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentCourse.subjectName.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Course title with dropdown arrow
                PopupMenuButton<LearningCourse>(
                  initialValue: _currentCourse,
                  tooltip: 'Switch course',
                  onSelected: _switchCourse,
                  itemBuilder: (ctx) => _siblingCourses.map((c) {
                    final isSelected = c.id == _currentCourse.id;
                    return PopupMenuItem<LearningCourse>(
                      value: c,
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            size: 16,
                            color: isSelected ? const Color(0xFF00F5A0) : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _currentCourse.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentCourse.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Circular Progress Ring with dynamic percentage
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (progressPercent / 100.0).clamp(0.0, 1.0),
                  strokeWidth: 4.2,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE2E8F0),
                  color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$progressPercent%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Completed Level Node (Mint Rounded Node with Checkmark ✓)
  Widget _buildCompletedNode({required String code, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5A0), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.35),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 32,
                color: Color(0xFF070B11),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFF00F5A0),
            ),
          ),
        ],
      ),
    );
  }

  // Adjacent Bonus Node: DAILY SPEED RUN
  Widget _buildDailySpeedRunNode() {
    return GestureDetector(
      onTap: () {
        ref.read(pendingQuizTopicProvider.notifier).state =
            '${_currentCourse.title} Speed Run';
        ref.read(selectedNavIndexProvider.notifier).state = 2; // Jump to Practice Tab
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFF59E0B),
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 6),
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.flash_on_rounded,
                size: 28,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
                const SizedBox(width: 2),
                Text(
                  'DAILY SPEED RUN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Locked Node matching Image 2
  Widget _buildLockedNode({
    required String title,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE9F0EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD4E2DF),
                width: 1.1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.lock_rounded,
                size: 24,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
