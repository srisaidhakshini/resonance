import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_drawer.dart';

class ProgressScreen extends ConsumerWidget {
  final Function(String prompt)? onNavigateToChatWithPrompt;
  const ProgressScreen({super.key, this.onNavigateToChatWithPrompt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = ref.watch(progressMetricsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Circular Back/Menu Button & Centered Title
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
                              width: 1.0,
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
                            color: isDark ? Colors.white : AppColors.lightForeground,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'My Progress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightForeground,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    // Balanced spacer on the right matching the circular button size
                    const SizedBox(width: 42),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isWide = width >= 840;
                    final horizontalPadding = width < 360 ? 14.0 : (isWide ? 24.0 : 18.0);

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isWide ? 1040 : 500),
                          child: isWide
                              ? _buildWideBody(context, ref, metrics, isDark)
                              : _buildCompactBody(context, ref, metrics, isDark),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Single stacked column (Mobile & narrow viewports)
  Widget _buildCompactBody(BuildContext context, WidgetRef ref, ProgressMetrics metrics, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connected Dual Glass Cards with Glowing Spirit Center Badge
        _buildConnectedCards(context, metrics, isDark),
        const SizedBox(height: 18),

        // High-Contrast Pill Action Button
        _buildActionButton(context, ref, isDark),
        const SizedBox(height: 28),

        // Subject Mastery Glass Card
        _buildSectionHeader('SUBJECT MASTERY', isDark),
        const SizedBox(height: 12),
        _buildSubjectMasteryCard(context, metrics, isDark),
        const SizedBox(height: 28),

        // Study Focus
        _buildSectionHeader('STUDY FOCUS', isDark),
        const SizedBox(height: 10),
        _buildDynamicNeedsPracticeSection(context, ref, metrics, isDark),
        const SizedBox(height: 28),

        // Completed Topics
        _buildSectionHeader('COMPLETED TOPICS', isDark),
        const SizedBox(height: 10),
        _buildDynamicMasteredSection(context, metrics, isDark),
        const SizedBox(height: 28),
      ],
    );
  }

  // Two-column dashboard (Tablets & Desktop)
  Widget _buildWideBody(BuildContext context, WidgetRef ref, ProgressMetrics metrics, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildConnectedCards(context, metrics, isDark),
                  const SizedBox(height: 18),
                  _buildActionButton(context, ref, isDark),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('SUBJECT MASTERY', isDark),
                  const SizedBox(height: 12),
                  _buildSubjectMasteryCard(context, metrics, isDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('STUDY FOCUS', isDark),
                  const SizedBox(height: 10),
                  _buildDynamicNeedsPracticeSection(context, ref, metrics, isDark),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('COMPLETED TOPICS', isDark),
                  const SizedBox(height: 10),
                  _buildDynamicMasteredSection(context, metrics, isDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightMutedForeground,
      ),
    );
  }

  // Connected Dual Glass Cards with Overlapping Glowing Spirit Connector
  Widget _buildConnectedCards(BuildContext context, ProgressMetrics metrics, bool isDark) {
    final streak = metrics.studyStreakDays;
    final sessions = metrics.totalSessions;
    final messages = metrics.totalMessages;

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            // Top Card: Study Streak
            _buildGlassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPillBadge(
                        isDark: isDark,
                        icon: Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: isDark ? Colors.white : const Color(0xFFF97316),
                        ),
                        label: 'Study Streak',
                      ),
                      _buildSubtlePill(
                        isDark: isDark,
                        label: streak > 0 ? 'Active' : 'Start Today',
                        color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Giant Center Value with flanking pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildMiniPill('Daily', isDark),
                      Text(
                        '$streak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightForeground,
                          letterSpacing: -1.0,
                        ),
                      ),
                      _buildMiniPill(streak > 0 ? '${streak}d' : '0d', isDark),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Bottom Balance/Status text
                  Text(
                    streak > 0
                        ? 'Active Streak: $streak Day${streak > 1 ? 's' : ''}'
                        : 'No active streak yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withOpacity(0.50) : AppColors.lightMutedForeground,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Bottom Card: Study History & Interactions
            _buildGlassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPillBadge(
                        isDark: isDark,
                        icon: Icon(
                          Icons.auto_stories_rounded,
                          size: 13,
                          color: isDark ? Colors.white : const Color(0xFF0284C7),
                        ),
                        label: 'Study History',
                      ),
                      _buildSubtlePill(
                        isDark: isDark,
                        label: '$messages Msg',
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Giant Center Value with flanking pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildMiniPill('Sessions', isDark),
                      Text(
                        '$sessions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightForeground,
                          letterSpacing: -1.0,
                        ),
                      ),
                      _buildMiniPill('$messages Msg', isDark),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Bottom Balance/Status text
                  Text(
                    '$sessions Study Session${sessions == 1 ? '' : 's'} • $messages Interactions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withOpacity(0.50) : AppColors.lightMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Floating Glowing Spirit Connector
        Positioned(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34D399),
                  Color(0xFF00F5A0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F5A0).withOpacity(isDark ? 0.55 : 0.40),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: isDark ? const Color(0xFF070B11) : Colors.white,
                width: 3.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.swap_vert_rounded,
                color: Color(0xFF04281B),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Frosted Glassmorphism Card Container
  Widget _buildGlassCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.10) : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.25) : const Color(0xFF123B46).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // Pill badge with single-color icon and label
  Widget _buildPillBadge({required Widget icon, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.12) : Colors.white,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightForeground,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: isDark ? Colors.white.withOpacity(0.40) : AppColors.lightMutedForeground,
          ),
        ],
      ),
    );
  }

  // Subtle Pill (e.g. Active/Status indicator)
  Widget _buildSubtlePill({required String label, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.20 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Mini Pill (e.g. Daily / Sessions / d pills)
  Widget _buildMiniPill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white.withOpacity(0.85) : AppColors.lightForeground,
        ),
      ),
    );
  }

  // High-Contrast Action Button
  Widget _buildActionButton(BuildContext context, WidgetRef ref, bool isDark) {
    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).startNewChat();
        Navigator.pushNamed(context, '/chat');
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? Colors.white : AppColors.lightPrimary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.white.withOpacity(0.14) : AppColors.lightPrimary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Start Study Session',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF070B11) : Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  // Subject Mastery Glass Card
  Widget _buildSubjectMasteryCard(BuildContext context, ProgressMetrics metrics, bool isDark) {
    if (metrics.subjectMastery.isEmpty) {
      return _buildGlassCard(
        isDark: isDark,
        child: Center(
          child: Text(
            'No subjects added yet.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white.withOpacity(0.5) : AppColors.lightMutedForeground,
            ),
          ),
        ),
      );
    }

    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: metrics.subjectMastery.map((item) {
          final progress = item.progress;
          final percent = (progress * 100).toInt();
          final color = item.subject.color;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.18),
                            border: Border.all(
                              color: color.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Icon(item.subject.icon, size: 14, color: color),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.subject.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.lightForeground,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$percent%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: percent > 0
                            ? (isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal)
                            : (isDark ? Colors.white.withOpacity(0.4) : AppColors.lightMutedForeground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.07) : AppColors.lightMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 0
                          ? (isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal)
                          : color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Dynamic Needs Practice Section (Study Focus)
  Widget _buildDynamicNeedsPracticeSection(BuildContext context, WidgetRef ref, ProgressMetrics metrics, bool isDark) {
    final topics = metrics.needsPracticeTopics;

    if (topics.isEmpty) {
      return _buildGlassCard(
        isDark: isDark,
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All study topics are on track. Start a new session in the Learn tab to explore new concepts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightMutedForeground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: topics.take(3).map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF123B46).withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF00F5A0).withOpacity(0.14)
                      : AppColors.lightSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.lightForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.subjectName} • In Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white.withOpacity(0.50) : AppColors.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _triggerPrompt(ref, context, t.prompt);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Review',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF070B11) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Dynamic Mastered Section (Completed Topics)
  Widget _buildDynamicMasteredSection(BuildContext context, ProgressMetrics metrics, bool isDark) {
    final mastered = metrics.masteredTopics;

    if (mastered.isEmpty) {
      return _buildGlassCard(
        isDark: isDark,
        child: Row(
          children: [
            Icon(
              Icons.school_outlined,
              color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete in-depth study sessions with Echo to see your mastered topics here.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightMutedForeground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: mastered.map((m) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    m.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  m.subjectName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? Colors.white.withOpacity(0.50) : AppColors.lightMutedForeground,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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
}
