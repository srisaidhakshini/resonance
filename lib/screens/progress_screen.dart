import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(
                        Icons.menu_rounded,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                      tooltip: 'Menu',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
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
                    // 1. DYNAMIC STATS OVERVIEW
                    _buildStatsOverview(context, metrics),

                    const SizedBox(height: 28),

                    // 2. DYNAMIC SUBJECT MASTERY
                    _buildSectionHeader(context, 'SUBJECT MASTERY'),
                    const SizedBox(height: 12),
                    _buildSubjectMasteryCard(context, metrics),

                    const SizedBox(height: 28),

                    // 3. DYNAMIC RECENT FOCUS & PRACTICE
                    _buildSectionHeader(context, 'STUDY FOCUS'),
                    const SizedBox(height: 10),
                    _buildDynamicNeedsPracticeSection(context, ref, metrics),

                    const SizedBox(height: 28),

                    // 4. DYNAMIC MASTERED SESSIONS
                    _buildSectionHeader(context, 'COMPLETED TOPICS'),
                    const SizedBox(height: 10),
                    _buildDynamicMasteredSection(context, metrics),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildStatsOverview(BuildContext context, ProgressMetrics metrics) {
    final streakText = metrics.studyStreakDays > 0 ? '${metrics.studyStreakDays} Day${metrics.studyStreakDays > 1 ? 's' : ''}' : '0 Days';
    final topicsText = '${metrics.totalSessions} Session${metrics.totalSessions == 1 ? '' : 's'}';
    final accuracyText = metrics.totalMessages > 0 ? '${metrics.totalMessages} Msg' : '0 Msg';

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            icon: '🔥',
            value: streakText,
            label: 'Study Streak',
            color: AppColors.chart4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            context,
            icon: '📚',
            value: topicsText,
            label: 'Study History',
            color: AppColors.lightTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            context,
            icon: '💬',
            value: accuracyText,
            label: 'Interactions',
            color: AppColors.chart3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMasteryCard(BuildContext context, ProgressMetrics metrics) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (metrics.subjectMastery.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Text(
            'No subjects added yet.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
      ),
      child: Column(
        children: metrics.subjectMastery.map((item) {
          final progress = item.progress;
          final color = item.subject.color;
          final percent = (progress * 100).toInt();

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
                        Icon(item.subject.icon, size: 16, color: color),
                        const SizedBox(width: 8),
                        Text(
                          item.subject.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.sessionCount > 0 ? '$percent%' : '0%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : 0.05,
                    minHeight: 6,
                    backgroundColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDynamicNeedsPracticeSection(BuildContext context, WidgetRef ref, ProgressMetrics metrics) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topics = metrics.needsPracticeTopics;

    if (topics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.lightTeal, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All study topics are on track. Start a new session in the Learn tab to explore new concepts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
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
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightTeal.withValues(alpha: 0.12),
                  borderRadius: AppRadii.smRadius,
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.lightTeal,
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
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.subjectName} • In Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  _triggerPrompt(ref, context, t.prompt);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Review'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicMasteredSection(BuildContext context, ProgressMetrics metrics) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mastered = metrics.masteredTopics;

    if (mastered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: AppColors.lightTeal, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete in-depth study sessions with Echo to see your mastered topics here.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: mastered.map((m) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.lightTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    m.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  m.subjectName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
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
        arguments: {'initialText': prompt},
      );
    }
  }
}
