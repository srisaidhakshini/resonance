import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'chat_screen.dart';
import 'progress_screen.dart';
import 'profile_setup_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToChatWithPrompt(String prompt) {
    setState(() {
      _currentIndex = 2; // Switch to Ask / Chat Tab
    });

    // If prompt is ready to submit, or if it's a prefix
    if (prompt.endsWith(': ') || prompt.endsWith('for: ')) {
      // Start new chat and set initial text
      ref.read(chatProvider.notifier).startNewChat();
    } else {
      ref.read(chatProvider.notifier).startNewChat();
      ref.read(chatProvider.notifier).addMessage(prompt, 'user');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      HomeScreen(onNavigateToChatWithPrompt: _navigateToChatWithPrompt),
      LearnScreen(onNavigateToChatWithPrompt: _navigateToChatWithPrompt),
      const ChatScreen(showBottomNav: true),
      ProgressScreen(onNavigateToChatWithPrompt: _navigateToChatWithPrompt),
      const ProfileSetupScreen(isEditMode: true, isStandaloneTab: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 20),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.lightTeal, size: 20),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, size: 20),
              selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.lightTeal, size: 20),
              label: 'Learn',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, size: 20),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: AppColors.lightTeal, size: 20),
              label: 'Ask',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined, size: 20),
              selectedIcon: Icon(Icons.insights_rounded, color: AppColors.lightTeal, size: 20),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, size: 20),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.lightTeal, size: 20),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
