import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/learning_course.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../providers/chat_provider.dart';
import '../providers/course_progress_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_drawer.dart';
import 'course_levels_screen.dart';

class LearnScreen extends ConsumerWidget {
  final Function(String prompt)? onNavigateToChatWithPrompt;
  const LearnScreen({super.key, this.onNavigateToChatWithPrompt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(subjectNotifierProvider);
    final progressMetrics = ref.watch(progressMetricsProvider);
    final userProfile = ref.watch(userProfileNotifierProvider);
    final courseProgressData = ref.watch(courseProgressProvider);
    final courseProgressNotifier = ref.read(courseProgressProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => InkWell(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        borderRadius: BorderRadius.circular(22),
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
                    const SizedBox(width: 12),
                    Text(
                      'Learn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightForeground,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    // Add Subject Action Button
                    InkWell(
                      onTap: () => _showAddSubjectSheet(context, ref),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00F5A0).withOpacity(0.3) : AppColors.lightTeal.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 17,
                              color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Add Subject',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. DYNAMIC CONTINUE LEARNING SPOTLIGHT
                    _buildSectionHeader(context, 'CONTINUE LEARNING'),
                    const SizedBox(height: 10),
                    _buildDynamicContinueLearningCard(
                      context,
                      ref,
                      progressMetrics,
                      userProfile,
                      courseProgressData,
                      courseProgressNotifier,
                      subjects,
                    ),

                    const SizedBox(height: 28),

                    // 2. DYNAMIC SUBJECTS GRID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(context, 'YOUR SUBJECTS (${subjects.length})'),
                        InkWell(
                          onTap: () => _showAddSubjectSheet(context, ref),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.lightTeal),
                                const SizedBox(width: 4),
                                Text(
                                  'New',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lightTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDynamicSubjectsGrid(
                      context,
                      ref,
                      subjects,
                      userProfile,
                      courseProgressNotifier,
                    ),

                    const SizedBox(height: 28),

                    // 3. DYNAMIC RECENT TOPICS
                    _buildSectionHeader(context, 'RECENT STUDY SESSIONS'),
                    const SizedBox(height: 10),
                    _buildDynamicRecentTopics(context, ref, progressMetrics.recentTopics),

                    const SizedBox(height: 28),

                    // 4. RECOMMENDED PRACTICE
                    _buildSectionHeader(context, 'RECOMMENDED PRACTICE'),
                    const SizedBox(height: 10),
                    _buildDynamicRecommended(context, ref, subjects, userProfile),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
      ),
    );
  }

  Widget _buildDynamicContinueLearningCard(
    BuildContext context,
    WidgetRef ref,
    ProgressMetrics metrics,
    UserProfile userProfile,
    CourseProgressData courseProgressData,
    CourseProgressNotifier courseProgressNotifier,
    List<Subject> subjects,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Check if user has an active course
    final activeCourseId = courseProgressData.lastActiveCourseId ?? 'math_algebra';
    LearningCourse? activeCourse =
        CourseRepository.getCourseById(activeCourseId, grade: userProfile.grade);

    // Fallback if not found: first course of first subject
    if (activeCourse == null && subjects.isNotEmpty) {
      final courses = CourseRepository.getCoursesForSubject(
        subjects.first.name,
        grade: userProfile.grade,
        subjectId: subjects.first.id,
      );
      if (courses.isNotEmpty) {
        activeCourse = courses.first;
      }
    }

    if (activeCourse != null) {
      final activeLevelNum = courseProgressNotifier.getActiveLevel(
        activeCourse.id,
        totalLevels: activeCourse.levels.length,
      );
      final courseProgressPercent = courseProgressNotifier.getCourseProgressPercent(
        activeCourse.id,
        activeCourse.levels.length,
      );
      final activeLevel = activeCourse.levels.firstWhere(
        (l) => l.levelNumber == activeLevelNum,
        orElse: () => activeCourse!.levels.first,
      );

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.10) : AppColors.lightBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.25) : const Color(0xFF123B46).withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activeCourse.subjectName.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$courseProgressPercent% Complete • Level $activeLevelNum of ${activeCourse.levels.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${activeCourse.title} — ${activeLevel.title}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.lightForeground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              activeLevel.description.isNotEmpty ? activeLevel.description : activeCourse.subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseLevelsScreen(
                            initialCourse: activeCourse!,
                            onNavigateToChatWithPrompt: onNavigateToChatWithPrompt,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text('Resume Level $activeLevelNum'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : AppColors.lightTeal,
                      foregroundColor: isDark ? const Color(0xFF070B11) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _triggerPrompt(
                        ref,
                        context,
                        'Teach me "${activeLevel.title}" from ${activeCourse!.subjectName}: ${activeCourse.title} suitable for ${userProfile.grade}. Break it down with clear examples.',
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                    label: const Text('Echo Tutor'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.lightTeal,
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.18) : AppColors.lightTeal,
                        width: 1.2,
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
          ],
        ),
      );
    }

    // Fallback: If recent topics exist
    if (metrics.recentTopics.isNotEmpty) {
      final latest = metrics.recentTopics.first;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.featureRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    borderRadius: AppRadii.smRadius,
                  ),
                  child: Text(
                    latest.subjectName.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  latest.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              latest.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _triggerPrompt(ref, context, latest.prompt),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Resume Lesson with Echo'),
              ),
            ),
          ],
        ),
      );
    }

    // Dynamic clean empty/start state
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.featureRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.lightTeal, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Welcome, ${userProfile.userName} (${userProfile.grade})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a subject below to embark on interactive leveled courses, or ask Echo any question!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final subName = subjects.isNotEmpty ? subjects.first.name : 'Mathematics';
                _triggerPrompt(
                  ref,
                  context,
                  'Hello Echo! I am in ${userProfile.grade}. Can you introduce today\'s top study topic in $subName?',
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Ask Echo a Question'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSubjectsGrid(
    BuildContext context,
    WidgetRef ref,
    List<Subject> subjects,
    UserProfile userProfile,
    CourseProgressNotifier courseProgressNotifier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCards = subjects.length + 1; // +1 for "Add Subject" card

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: totalCards,
      itemBuilder: (context, index) {
        if (index == subjects.length) {
          // Add Subject Card
          return _buildAddSubjectCard(context, ref, isDark);
        }

        final sub = subjects[index];
        final courses = CourseRepository.getCoursesForSubject(
          sub.name,
          grade: userProfile.grade,
          subjectId: sub.id,
        );
        final masteryPercent = courseProgressNotifier.getSubjectProgressPercent(courses);

        return _buildSubjectCard(context, ref, sub, courses, masteryPercent, userProfile);
      },
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    WidgetRef ref,
    Subject sub,
    List<LearningCourse> courses,
    int masteryPercent,
    UserProfile userProfile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showSubjectCoursesSheet(context, ref, sub, courses, userProfile);
        },
        onLongPress: () {
          _showSubjectOptionsSheet(context, ref, sub);
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.15) : const Color(0xFF123B46).withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : sub.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      sub.icon,
                      size: 18,
                      color: isDark ? const Color(0xFF00F5A0) : sub.color,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showSubjectOptionsSheet(context, ref, sub),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: isDark ? Colors.white54 : AppColors.lightMutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${courses.length} Leveled Courses',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    masteryPercent > 0 ? '$masteryPercent% Mastery' : 'Ready to Start',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF00F5A0) : (masteryPercent > 0 ? const Color(0xFF0D9488) : AppColors.lightTeal),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddSubjectCard(BuildContext context, WidgetRef ref, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showAddSubjectSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
              style: BorderStyle.solid,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.10) : const Color(0xFF123B46).withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.07) : AppColors.lightCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : AppColors.lightBorder,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Subject',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Custom Topic',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicRecentTopics(BuildContext context, WidgetRef ref, List<TopicItem> topics) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (topics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.history_edu_rounded, size: 28, color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground),
            const SizedBox(height: 8),
            Text(
              'No study sessions recorded yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your topics and questions will appear here dynamically.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: topics.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.15) : const Color(0xFF123B46).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              t.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              t.subjectName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightTeal.withValues(alpha: 0.12),
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    t.status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ],
            ),
            onTap: () {
              _triggerPrompt(ref, context, t.prompt);
            },
          ),
        );
      }).toList(),
    );
  }

  void _showAddSubjectSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final availableIcons = [
      Icons.school_outlined,
      Icons.calculate_outlined,
      Icons.science_outlined,
      Icons.menu_book_rounded,
      Icons.public_rounded,
      Icons.code_rounded,
      Icons.palette_outlined,
      Icons.music_note_rounded,
      Icons.psychology_outlined,
      Icons.biotech_rounded,
    ];

    final availableColors = [
      AppColors.chart1,
      AppColors.chart2,
      AppColors.chart3,
      AppColors.chart4,
      AppColors.chart5,
      const Color(0xFF6B46C1),
      const Color(0xFF2B6CB0),
    ];

    int selectedIconIndex = 0;
    int selectedColorIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Subject',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g. Computer Science, World History',
                      border: OutlineInputBorder(borderRadius: AppRadii.buttonRadius),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description / Topics (optional)',
                      hintText: 'e.g. Algorithms, Data Structures',
                      border: OutlineInputBorder(borderRadius: AppRadii.buttonRadius),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Icon',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(availableIcons.length, (i) {
                      final isSelected = selectedIconIndex == i;
                      return InkWell(
                        onTap: () => setModalState(() => selectedIconIndex = i),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.darkAccent : AppColors.lightSecondary)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.lightTeal : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            availableIcons[i],
                            size: 20,
                            color: isSelected ? AppColors.lightTeal : (isDark ? AppColors.darkForeground : AppColors.lightForeground),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Color',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: List.generate(availableColors.length, (i) {
                      final isSelected = selectedColorIndex == i;
                      return InkWell(
                        onTap: () => setModalState(() => selectedColorIndex = i),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: availableColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: availableColors[i].withValues(alpha: 0.5), blurRadius: 6)]
                                : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        await ref.read(subjectNotifierProvider.notifier).addSubject(
                              name: name,
                              description: descController.text.trim(),
                              icon: availableIcons[selectedIconIndex],
                              color: availableColors[selectedColorIndex],
                            );

                        if (context.mounted) {
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added subject "$name"'),
                              backgroundColor: AppColors.lightTeal,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Subject'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubjectOptionsSheet(BuildContext context, WidgetRef ref, Subject sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? AppColors.darkForeground : AppColors.lightForeground),
                  title: Text('Study ${sub.name} with Echo'),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _triggerPrompt(ref, context, 'Let\'s start a study session on ${sub.name}.');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.lightDestructive),
                  title: Text('Delete Subject', style: TextStyle(color: AppColors.lightDestructive)),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    await ref.read(subjectNotifierProvider.notifier).deleteSubject(sub.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed subject "${sub.name}"')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerPrompt(WidgetRef ref, BuildContext context, String prompt) {
    if (onNavigateToChatWithPrompt != null) {
      onNavigateToChatWithPrompt!(prompt);
    } else {
      ref.read(chatProvider.notifier).startNewChat();
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'initialText': prompt,
          'autoSubmit': true,
        },
      );
    }
  }

  Widget _buildDynamicRecommended(
    BuildContext context,
    WidgetRef ref,
    List<Subject> subjects,
    UserProfile userProfile,
  ) {
    final firstSubjectName = subjects.isNotEmpty ? subjects.first.name : 'Mathematics';
    final secondSubjectName = subjects.length > 1 ? subjects[1].name : 'Science';

    return Row(
      children: [
        Expanded(
          child: _buildActionModuleCard(
            context,
            ref,
            icon: Icons.timer_outlined,
            title: '5-Min Active Recall',
            desc: '$firstSubjectName • ${userProfile.grade}',
            prompt: 'Give me a 5-question active recall multiple choice quiz on $firstSubjectName tailored for ${userProfile.grade}.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionModuleCard(
            context,
            ref,
            icon: Icons.lightbulb_outline_rounded,
            title: 'Concept Breakdown',
            desc: '$secondSubjectName • ${userProfile.grade}',
            prompt: 'Explain foundational concepts in $secondSubjectName tailored for ${userProfile.grade} step-by-step with analogies and real-world examples.',
          ),
        ),
      ],
    );
  }

  Widget _buildActionModuleCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String desc,
    required String prompt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _triggerPrompt(ref, context, prompt),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.055) : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
              width: 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectCoursesSheet(
    BuildContext context,
    WidgetRef ref,
    Subject sub,
    List<LearningCourse> courses,
    UserProfile userProfile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressNotifier = ref.read(courseProgressProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E1520) : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sub.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(sub.icon, size: 22, color: sub.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightForeground,
                          ),
                        ),
                        Text(
                          '${courses.length} Courses Available • ${userProfile.grade}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'CHOOSE A COURSE TO LEARN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final course = courses[i];
                    final dynamicProgress = progressNotifier.getCourseProgressPercent(course.id, course.levels.length);
                    final activeLvlNum = progressNotifier.getActiveLevel(
                      course.id,
                      totalLevels: course.levels.length,
                    );

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(modalContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseLevelsScreen(
                                initialCourse: course,
                                onNavigateToChatWithPrompt: onNavigateToChatWithPrompt,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.055) : const Color(0xFFF8FAFA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.09) : const Color(0xFFE2EBE9),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(course.icon, size: 22, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      course.subtitle,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightTeal.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${course.levels.length} Levels • Level $activeLvlNum',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$dynamicProgress% Complete',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(modalContext);
                    _triggerPrompt(
                      ref,
                      context,
                      'Help me study ${sub.name} for ${userProfile.grade}. Can you explain key concepts and give me a practice problem?',
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text('Or Ask Echo a question on ${sub.name}'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
