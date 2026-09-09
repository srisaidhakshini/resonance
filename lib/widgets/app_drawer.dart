import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/chat_session.dart';
import '../theme/app_theme.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_setup_screen.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);
    final currentSessionId = ref.watch(currentSessionIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter sessions based on search
    final filteredSessions = sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Group sessions
    final now = DateTime.now();
    final today = <ChatSession>[];
    final yesterday = <ChatSession>[];
    final previousDays = <ChatSession>[];

    for (var session in filteredSessions) {
      final diff = now.difference(session.lastUpdated).inDays;
      if (diff == 0 && session.lastUpdated.day == now.day) {
        today.add(session);
      } else if (diff == 1 || (diff == 0 && session.lastUpdated.day != now.day)) {
        yesterday.add(session);
      } else {
        previousDays.add(session);
      }
    }

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF070B11) : AppColors.lightBackground,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header & Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Echo Study History',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.lightCard,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // New Chat Button
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Start New Study Session',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.lightForeground,
                      ),
                    ),
                    onTap: () {
                      ref.read(chatProvider.notifier).startNewChat();
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  // Study Materials Item
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Study Materials',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.lightForeground,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/library');
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 2. Chat List
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No study history yet' : 'No matching sessions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      children: [
                        if (today.isNotEmpty)
                          _buildSection(context, 'Today', today, currentSessionId, isDark),
                        if (yesterday.isNotEmpty)
                          _buildSection(context, 'Yesterday', yesterday, currentSessionId, isDark),
                        if (previousDays.isNotEmpty)
                          _buildSection(context, 'Previous Days', previousDays, currentSessionId, isDark),
                      ],
                    ),
            ),

            const Divider(height: 1),

            // 3. Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E1520) : AppColors.lightCard,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSetupScreen(isEditMode: true),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF00F5A0).withOpacity(0.25) : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FutureBuilder<SharedPreferences>(
                            future: SharedPreferences.getInstance(),
                            builder: (context, snapshot) {
                              final name = snapshot.data?.getString('user_name') ?? 'Student';
                              return Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? const Color(0xFFFBBF24) : AppColors.lightMutedForeground,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<ChatSession> sessions,
    String? currentId,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...sessions.map(
            (session) => _buildSessionTile(session, currentId == session.id, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(ChatSession session, bool isSelected, bool isDark) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.lightDestructive,
          borderRadius: AppRadii.smRadius,
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
            title: Text(
              'Delete Conversation',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Are you sure you want to delete this study session from local history?',
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.lightDestructive),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(chatProvider.notifier).deleteSession(session.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00F5A0).withOpacity(0.12) : AppColors.lightSecondary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected && isDark
              ? Border.all(color: const Color(0xFF00F5A0).withOpacity(0.25), width: 1)
              : null,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 16,
            color: isSelected ? (isDark ? const Color(0xFF00F5A0) : AppColors.lightTeal) : (isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground),
          ),
          title: Text(
            session.title.isEmpty ? 'Untitled Study Session' : session.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? (isDark ? const Color(0xFF00F5A0) : AppColors.lightPrimary)
                  : (isDark ? Colors.white : AppColors.lightForeground),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            ref.read(chatProvider.notifier).loadSession(session.id);
            Navigator.pop(context);
            if (ModalRoute.of(context)?.settings.name != '/chat') {
              Navigator.pushNamed(context, '/chat');
            }
          },
        ),
      ),
    );
  }
}
