import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds a topic that should be turned into a Practice quiz as soon as the
// Practice tab is shown (set by quick-action cards on Home/Learn/Progress).
final pendingQuizTopicProvider = StateProvider<String?>((ref) => null);

// Controls the active bottom navigation tab in MainNavigationShell (0: Home, 1: Learn, 2: Practice, 3: Progress, 4: Profile)
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);


// Font Size Provider: 0.8 (Small), 1.0 (Medium), 1.2 (Large)
final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>((ref) {
  return FontSizeNotifier();
});

class FontSizeNotifier extends StateNotifier<double> {
  FontSizeNotifier() : super(1.0) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getDouble('app_font_scale');
    if (savedSize != null) {
      state = savedSize;
    }
  }

  Future<void> setFontSize(double size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_font_scale', size);
  }
}
