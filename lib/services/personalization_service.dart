import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Service responsible for managing explicit user profile preferences in local storage.
class PersonalizationService {
  static const String keyUserName = 'user_name';
  static const String keyUserGrade = 'user_grade';
  static const String keyTeachingStyle = 'user_teaching_style';
  static const String keyPacingLevel = 'user_pacing_level';
  static const String keyProfileCompleted = 'is_profile_completed';

  static PersonalizationService? _instance;
  PersonalizationService._();

  static PersonalizationService get instance {
    _instance ??= PersonalizationService._();
    return _instance!;
  }

  /// Loads the persisted [UserProfile], falling back to defaults if not yet configured.
  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(keyUserName) ?? 'Student';
    final grade = prefs.getString(keyUserGrade) ?? '8';
    final styleRaw = prefs.getString(keyTeachingStyle);
    final pacingRaw = prefs.getString(keyPacingLevel);

    return UserProfile(
      userName: name.trim().isEmpty ? 'Student' : name.trim(),
      grade: grade,
      teachingStyle: TeachingStyle.fromString(styleRaw),
      pacingLevel: PacingLevel.fromString(pacingRaw),
    );
  }

  /// Saves the complete [UserProfile] into [SharedPreferences].
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserName, profile.userName.trim());
    await prefs.setString(keyUserGrade, profile.grade);
    await prefs.setString(keyTeachingStyle, profile.teachingStyle.name);
    await prefs.setString(keyPacingLevel, profile.pacingLevel.name);
    await prefs.setBool(keyProfileCompleted, true);
  }

  /// Quick helper to check if onboarding profile setup has been finished.
  Future<bool> isProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyProfileCompleted) ?? false;
  }
}
