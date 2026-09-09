import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'slide_deck_screen.dart';
import 'flashcards_screen.dart';
import 'audio_overview_screen.dart';
import 'quiz_screen.dart';
import 'mind_map_screen.dart';
import 'video_overview_screen.dart';
import '../widgets/call_launch_sheet.dart';

import '../widgets/ambient_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(String prompt)? onNavigateToChatWithPrompt;
  const HomeScreen({super.key, this.onNavigateToChatWithPrompt});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _askEchoController = TextEditingController();

  @override
  void dispose() {
    _askEchoController.dispose();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = ref.watch(progressMetricsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const AppDrawer(),
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Bar Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                    // Brand & Logo
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF00F5A0).withOpacity(0.16) : AppColors.lightSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Echo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightForeground,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),

                    // Theme Mode Toggle (Light/Dark) & Profile Avatar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
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
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: isDark ? const Color(0xFFFBBF24) : AppColors.lightPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, '/profile_setup'),
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
                              Icons.person_rounded,
                              color: isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    FutureBuilder<SharedPreferences>(
                      future: SharedPreferences.getInstance(),
                      builder: (context, snapshot) {
                        final name = snapshot.data?.getString('user_name') ?? 'Student';
                        final greeting = _getTimeGreeting();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting, $name',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What are we learning today?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 3. ASK ECHO PROMINENT AI CARD
                    _buildAskEchoCard(context, isDark),

                    const SizedBox(height: 16),

                    // 3.5 ELEVENLABS & TWILIO VOICE CALL BANNER
                    _buildElevenLabsVoiceCallBanner(context, isDark),

                    const SizedBox(height: 24),

                    // 4. CONTINUE LEARNING
                    _buildSectionHeader(context, 'CONTINUE LEARNING', isDark),
                    const SizedBox(height: 10),
                    _buildDynamicContinueLearningCard(context, isDark, metrics),

                    const SizedBox(height: 24),

                    // 5. NOTEBOOKLM STUDIO & QUICK ACTIONS
                    _buildSectionHeader(context, 'STUDIO & QUICK STUDY ACTIONS', isDark),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context, isDark),

                    const SizedBox(height: 48),
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

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
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

  Widget _buildAskEchoCard(BuildContext context, bool isDark) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF00F5A0).withOpacity(0.16) : AppColors.lightSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ask Echo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightForeground,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightMuted,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  'On-Device AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF00F5A0) : AppColors.lightMutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search-like Prompt Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _askEchoController,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : AppColors.lightForeground,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your subjects...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white.withOpacity(0.4) : AppColors.lightMutedForeground,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : AppColors.lightInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _triggerPrompt(value);
                      _askEchoController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final text = _askEchoController.text.trim();
                    _triggerPrompt(text.isNotEmpty ? text : 'Explain what we are studying next.');
                    _askEchoController.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: isDark ? const Color(0xFF070B11) : AppColors.lightPrimaryForeground,
                      size: 20,
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

  Widget _buildDynamicContinueLearningCard(BuildContext context, bool isDark, ProgressMetrics metrics) {
    if (metrics.recentTopics.isNotEmpty) {
      final latest = metrics.recentTopics.first;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            _triggerPrompt(latest.prompt);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00F5A0).withOpacity(0.15) : AppColors.lightSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        latest.subjectName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                        ),
                      ),
                    ),
                    Text(
                      latest.status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.lightForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  latest.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.play_circle_fill_rounded, size: 16, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to resume study session with Echo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white.withOpacity(0.50) : AppColors.lightMutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.055) : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.10) : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.20) : const Color(0xFF123B46).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF00F5A0).withOpacity(0.16) : AppColors.lightSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_outlined, size: 20, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No study sessions yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask any question above or choose a quick action.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white.withOpacity(0.5) : AppColors.lightMutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevenLabsVoiceCallBanner(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => CallLaunchSheet.show(context),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.055) : null,
            gradient: isDark
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFE6F7F5), Color(0xFFF0FDFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF00F5A0).withOpacity(0.35) : const Color(0xFF14B8A6).withOpacity(0.45),
              width: 1.2,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F5A0).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF00F5A0).withOpacity(0.16) : const Color(0xFF0D9488).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: isDark ? const Color(0xFF00F5A0) : const Color(0xFF0D9488),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Live Voice Call Tutor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Solve doubts back-and-forth via live call or Twilio dial',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? Colors.white.withOpacity(0.55) : AppColors.lightMutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_rounded, size: 13, color: isDark ? const Color(0xFF070B11) : Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Call',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF070B11) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    final actions = [
      {
        'icon': Icons.phone_in_talk_rounded,
        'title': 'Voice Call',
        'desc': 'Real-time AI voice tutor',
        'tag': 'AI CALL',
        'onTap': () => CallLaunchSheet.show(context),
      },
      {
        'icon': Icons.slideshow_rounded,
        'title': 'Slide Decks',
        'desc': 'Interactive STEM slides',
        'tag': 'STUDIO',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SlideDeckScreen()),
        ),
      },
      {
        'icon': Icons.style_outlined,
        'title': 'Flashcards',
        'desc': '3D flip & spaced repetition',
        'tag': 'STUDIO',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FlashcardsScreen()),
        ),
      },
      {
        'icon': Icons.podcasts_rounded,
        'title': 'Audio Overview',
        'desc': '2-Host conversational podcast',
        'tag': 'AI AUDIO',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AudioOverviewScreen()),
        ),
      },
      {
        'icon': Icons.quiz_outlined,
        'title': 'Take a Quiz',
        'desc': 'Active recall & explanations',
        'tag': 'STUDIO',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        ),
      },
      {
        'icon': Icons.movie_filter_outlined,
        'title': 'Video Overview',
        'desc': 'Kinetic typography recap, narrated',
        'tag': 'AI VIDEO',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VideoOverviewScreen()),
        ),
      },
      {
        'icon': Icons.account_tree_outlined,
        'title': 'Mind Map',
        'desc': 'Concept tree & hierarchy',
        'tag': 'GRAPH',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MindMapScreen()),
        ),
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Study Report',
        'desc': 'Executive brief & takeaways',
        'tag': 'SUMMARY',
        'onTap': () => _triggerPrompt('Generate a comprehensive study report and structured briefing on: '),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return _buildActionCard(
          context,
          isDark: isDark,
          icon: a['icon'] as IconData,
          title: a['title'] as String,
          desc: a['desc'] as String,
          tag: a['tag'] as String?,
          onTap: a['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String desc,
    String? tag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
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
                      color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal),
                  ),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00F5A0).withOpacity(0.15) : AppColors.lightTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      fontSize: 10.5,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerPrompt(String prompt) {
    if (widget.onNavigateToChatWithPrompt != null) {
      widget.onNavigateToChatWithPrompt!(prompt);
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
