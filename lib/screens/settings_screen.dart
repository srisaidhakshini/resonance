import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ui_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/offline_badge.dart';
import 'profile_setup_screen.dart';
import 'benchmark_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _tapCount = 0;
  Timer? _tapTimer;
  String _modelSizeDisplay = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateModelSize();
  }

  Future<void> _calculateModelSize() async {
    try {
      final downloadService = ref.read(modelDownloadServiceProvider);
      final display = await downloadService.getModelSizeDisplay();
      if (mounted) {
        setState(() {
          _modelSizeDisplay = display;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelSizeDisplay = '0MB Used';
        });
      }
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleKnowledgeBaseTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 2), () {
      _tapCount = 0;
    });
    if (_tapCount >= 5) {
      _tapCount = 0;
      _tapTimer?.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BenchmarkScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Offline Knowledge Base Card (5-tap easter egg for benchmarks)
            GestureDetector(
              onTap: _handleKnowledgeBaseTap,
              child: Container(
                width: double.infinity,
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
                        const OfflineBadge(isCompact: true),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.dns_rounded,
                            color: AppColors.lightTeal,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'On-Device AI Model',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 6,
                        backgroundColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightTeal),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _modelSizeDisplay,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTeal,
                          ),
                        ),
                        Text(
                          'Local Device Storage',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Echo runs completely on your phone using quantized GGUF weights. No network queries are dispatched.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 2. Profile Summary
            _buildSectionHeader('STUDENT PROFILE', isDark),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadii.cardRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: isDark ? AppShadows.darkCard : AppShadows.card,
              ),
              child: FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  final name = snapshot.data?.getString('user_name') ?? 'Student';
                  final grade = snapshot.data?.getString('user_grade') ?? '8';
                  final styleRaw = snapshot.data?.getString('user_teaching_style') ?? 'socratic';
                  final pacingRaw = snapshot.data?.getString('user_pacing_level') ?? 'stepByStep';

                  final styleDisplay = styleRaw == 'socratic'
                      ? 'Socratic'
                      : (styleRaw == 'direct' ? 'Direct' : 'Stories');
                  final pacingDisplay = pacingRaw == 'stepByStep' ? 'Step-by-step' : 'High-level';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      '$name • Class $grade',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Style: $styleDisplay • Pacing: $pacingDisplay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.lightTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.lightTeal,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(isEditMode: true),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // 3. Look & Feel
            _buildSectionHeader('APPEARANCE & ACCESSIBILITY', isDark),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
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
                children: [
                  // Theme Mode Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dark Theme',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                      Switch(
                        value: isDark,
                        activeTrackColor: AppColors.lightTeal.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.lightTeal,
                        onChanged: (_) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Text Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Text Size',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccent : AppColors.lightSecondary,
                          borderRadius: AppRadii.pillRadius,
                        ),
                        child: Text(
                          _getFontSizeLabel(fontSize),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Aa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.lightTeal,
                            inactiveTrackColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                            thumbColor: AppColors.lightTeal,
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          ),
                          child: Slider(
                            value: fontSize,
                            min: 0.8,
                            max: 1.2,
                            divisions: 2,
                            onChanged: (value) {
                              ref.read(fontSizeProvider.notifier).setFontSize(value);
                            },
                          ),
                        ),
                      ),
                      Text(
                        'Aa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 4. Destructive Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showClearDataDialog(context, ref, isDark),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.lightDestructive.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  foregroundColor: AppColors.lightDestructive,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Clear Chat History'),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'Pocket Tutor (Echo) • Offline Edition',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
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

  String _getFontSizeLabel(double size) {
    if (size <= 0.8) return 'Small';
    if (size >= 1.2) return 'Large';
    return 'Medium';
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        title: Text(
          'Clear Chat History?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete all your conversation history from local storage. Your AI models and learning profile will NOT be deleted.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(chatProvider.notifier).clearAllChats();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat history cleared'),
                    backgroundColor: AppColors.lightTeal,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightDestructive,
            ),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }
}
