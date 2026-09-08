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
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                  // Brand & Logo
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          borderRadius: AppRadii.smRadius,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.lightTeal,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Echo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                    ],
                  ),

                  // Theme Mode Toggle (Light/Dark) & Profile Avatar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? const Color(0xFFFBBF24) : AppColors.lightPrimary,
                            size: 18,
                          ),
                        ),
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/profile_setup'),
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                          child: Icon(
                            Icons.person_rounded,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            size: 18,
                          ),
                        ),
                        tooltip: 'Profile',
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
                              '$greeting, $name 👋',
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
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.featureRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
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
                  color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.lightTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ask Echo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  'On-Device AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
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
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your subjects...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.buttonRadius,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.buttonRadius,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.buttonRadius,
                      borderSide: const BorderSide(color: AppColors.lightTeal, width: 1.5),
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
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                borderRadius: AppRadii.buttonRadius,
                child: InkWell(
                  borderRadius: AppRadii.buttonRadius,
                  onTap: () {
                    final text = _askEchoController.text.trim();
                    _triggerPrompt(text.isNotEmpty ? text : 'Explain what we are studying next.');
                    _askEchoController.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: isDark ? AppColors.darkPrimaryForeground : AppColors.lightPrimaryForeground,
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
          borderRadius: AppRadii.cardRadius,
          onTap: () {
            _triggerPrompt(latest.prompt);
          },
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      latest.subjectName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTeal,
                      ),
                    ),
                    Text(
                      latest.status,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  latest.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded, size: 16, color: AppColors.lightTeal),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to resume study session with Echo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined, size: 20, color: AppColors.lightTeal),
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
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask any question above or choose a quick action.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
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
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF132B30), const Color(0xFF0F1E22)]
                  : [const Color(0xFFE6F7F5), const Color(0xFFF0FDFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: const Color(0xFF14B8A6).withValues(alpha: isDark ? 0.35 : 0.45),
              width: 1.2,
            ),
            boxShadow: [
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Color(0xFF0D9488),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Live Voice Call Tutor',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ELEVENLABS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D9488),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Solve doubts back-and-forth via live call or Twilio dial',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Call',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
        'desc': 'ElevenLabs + Twilio doubts',
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
        borderRadius: AppRadii.cardRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                      borderRadius: AppRadii.smRadius,
                    ),
                    child: Icon(icon, size: 18, color: AppColors.lightTeal),
                  ),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTeal,
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
        arguments: {'initialText': prompt},
      );
    }
  }
}
