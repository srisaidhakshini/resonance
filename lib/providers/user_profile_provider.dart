import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/personalization_service.dart';

/// Helper to standardize user grade string into "Class X" format.
String formatGrade(String? rawGrade) {
  if (rawGrade == null) return 'Class 8';
  final g = rawGrade.trim();
  if (g.isEmpty) return 'Class 8';
  if (g.startsWith('Class ')) return g;
  if (RegExp(r'^\d+$').hasMatch(g)) return 'Class $g';
  return g;
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile.defaults()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await PersonalizationService.instance.getUserProfile();
    state = profile;
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    state = newProfile;
    await PersonalizationService.instance.saveUserProfile(newProfile);
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
