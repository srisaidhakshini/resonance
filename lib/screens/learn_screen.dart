import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subject.dart';
import '../providers/chat_provider.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/subject_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class LearnScreen extends ConsumerWidget {
  final Function(String prompt)? onNavigateToChatWithPrompt;
  const LearnScreen({super.key, this.onNavigateToChatWithPrompt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(subjectNotifierProvider);
    final progressMetrics = ref.watch(progressMetricsProvider);
    final contents = ref.watch(contentNotifierProvider);

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
                    'Learn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                    ),
                  ),
                  const Spacer(),
                  // Add Subject Action Button
                  TextButton.icon(
                    onPressed: () => _showAddSubjectSheet(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Subject'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightTeal,
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
                    _buildDynamicContinueLearningCard(context, ref, progressMetrics, contents),

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
                    _buildDynamicSubjectsGrid(context, ref, subjects, progressMetrics),

                    const SizedBox(height: 28),

                    // 3. DYNAMIC RECENT TOPICS
                    _buildSectionHeader(context, 'RECENT STUDY SESSIONS'),
                    const SizedBox(height: 10),
                    _buildDynamicRecentTopics(context, ref, progressMetrics.recentTopics),

                    const SizedBox(height: 28),

                    // 4. RECOMMENDED PRACTICE
                    _buildSectionHeader(context, 'RECOMMENDED PRACTICE'),
                    const SizedBox(height: 10),
                    _buildDynamicRecommended(context, ref, subjects),

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

  Widget _buildDynamicContinueLearningCard(
    BuildContext context,
    WidgetRef ref,
    ProgressMetrics metrics,
    List<dynamic> contents,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline_rounded, size: 14, color: AppColors.lightTeal),
                    const SizedBox(width: 4),
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

    // Empty state when no sessions yet
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
                'Start Your First Study Session',
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
            'Ask Echo any question, pick a subject below, or attach your study materials to get tailored explanations.',
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
                _triggerPrompt(ref, context, 'Hello Echo! What topic should we study today?');
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
    ProgressMetrics metrics,
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
        final mastery = metrics.subjectMastery.firstWhere(
          (m) => m.subject.id == sub.id,
          orElse: () => SubjectProgress(subject: sub, progress: 0, sessionCount: 0),
        );
        return _buildSubjectCard(context, ref, sub, mastery.sessionCount);
      },
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    WidgetRef ref,
    Subject sub,
    int sessionCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.cardRadius,
        onTap: () {
          _triggerPrompt(
            ref,
            context,
            'Help me study ${sub.name}. Can you explain key concepts and give me a practice problem?',
          );
        },
        onLongPress: () {
          _showSubjectOptionsSheet(context, ref, sub);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sub.color.withValues(alpha: 0.12),
                      borderRadius: AppRadii.smRadius,
                    ),
                    child: Icon(sub.icon, size: 18, color: sub.color),
                  ),
                  InkWell(
                    onTap: () => _showSubjectOptionsSheet(context, ref, sub),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
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
                      color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub.description.isNotEmpty ? sub.description : 'Study concepts & notes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Text(
                sessionCount > 0 ? '$sessionCount Study Sessions' : 'Ready to Study',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTeal,
                ),
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
        borderRadius: AppRadii.cardRadius,
        onTap: () => _showAddSubjectSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: const Icon(Icons.add_rounded, size: 20, color: AppColors.lightTeal),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Subject',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
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
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
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

  Widget _buildDynamicRecommended(BuildContext context, WidgetRef ref, List<Subject> subjects) {
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
            desc: '$firstSubjectName Quiz • 5 MCQs',
            prompt: 'Give me a 5-question active recall multiple choice quiz on $firstSubjectName.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionModuleCard(
            context,
            ref,
            icon: Icons.lightbulb_outline_rounded,
            title: 'Concept Breakdown',
            desc: '$secondSubjectName Concepts',
            prompt: 'Explain fundamental concepts in $secondSubjectName in simple, step-by-step terms with real-world examples.',
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
        borderRadius: AppRadii.cardRadius,
        onTap: () => _triggerPrompt(ref, context, prompt),
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.lightTeal),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
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
        arguments: {'initialText': prompt},
      );
    }
  }
}
