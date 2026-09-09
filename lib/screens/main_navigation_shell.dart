import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/ui_provider.dart';
import '../providers/chat_provider.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'quiz_screen.dart';
import 'progress_screen.dart';
import 'profile_setup_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        ref.read(selectedNavIndexProvider.notifier).state = widget.initialIndex;
      }
    });
  }

  void _navigateToChatWithPrompt(String prompt) {
    ref.read(chatProvider.notifier).startNewChat();
    Navigator.of(context).pushNamed('/chat', arguments: {
      'initialText': prompt,
      'autoSubmit': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navIndex = ref.watch(selectedNavIndexProvider);

    final pages = [
      HomeScreen(onNavigateToChatWithPrompt: _navigateToChatWithPrompt),
      LearnScreen(onNavigateToChatWithPrompt: _navigateToChatWithPrompt),
      const QuizScreen(isTab: true),
      ProgressScreen(onNavigateToChatWithPrompt: _navigateToChatWithPrompt),
      const ProfileSetupScreen(isEditMode: true, isStandaloneTab: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: navIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF070B11) : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: isDark ? const Color(0xFF00F5A0).withOpacity(0.18) : AppColors.lightSecondary,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal)
                    : (isDark ? Colors.white.withOpacity(0.5) : AppColors.lightMutedForeground),
              );
            }),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: navIndex,
            onDestinationSelected: (index) {
              ref.read(selectedNavIndexProvider.notifier).state = index;
            },
            height: 60,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 20, color: isDark ? Colors.white.withOpacity(0.6) : null),
                selectedIcon: Icon(Icons.home_rounded, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal, size: 20),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, size: 20, color: isDark ? Colors.white.withOpacity(0.6) : null),
                selectedIcon: Icon(Icons.menu_book_rounded, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal, size: 20),
                label: 'Learn',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined, size: 20, color: isDark ? Colors.white.withOpacity(0.6) : null),
                selectedIcon: Icon(Icons.quiz_rounded, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal, size: 20),
                label: 'Practice',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined, size: 20, color: isDark ? Colors.white.withOpacity(0.6) : null),
                selectedIcon: Icon(Icons.insights_rounded, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal, size: 20),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 20, color: isDark ? Colors.white.withOpacity(0.6) : null),
                selectedIcon: Icon(Icons.person_rounded, color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal, size: 20),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
