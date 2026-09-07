/// Represents the teaching pedagogy style chosen by or adapted for the student.
enum TeachingStyle {
  socratic,
  direct,
  storytelling;

  String get displayName {
    switch (this) {
      case TeachingStyle.socratic:
        return 'Socratic (Guiding)';
      case TeachingStyle.direct:
        return 'Direct & Clear';
      case TeachingStyle.storytelling:
        return 'Stories & Analogies';
    }
  }

  String get description {
    switch (this) {
      case TeachingStyle.socratic:
        return 'Asks guiding questions to help you discover answers yourself';
      case TeachingStyle.direct:
        return 'Direct, concise explanations with clear formulas and steps';
      case TeachingStyle.storytelling:
        return 'Explains abstract ideas using memorable stories and analogies';
    }
  }

  static TeachingStyle fromString(String? val) {
    if (val == null) return TeachingStyle.socratic;
    return TeachingStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TeachingStyle.socratic,
    );
  }
}

/// Represents the explanation pacing and detail preference.
enum PacingLevel {
  stepByStep,
  highLevel;

  String get displayName {
    switch (this) {
      case PacingLevel.stepByStep:
        return 'Step-by-step (Detailed)';
      case PacingLevel.highLevel:
        return 'High-level (Summary)';
    }
  }

  String get description {
    switch (this) {
      case PacingLevel.stepByStep:
        return 'Breaks every concept down into bite-sized sequential steps';
      case PacingLevel.highLevel:
        return 'Delivers quick summaries and the big picture first';
    }
  }

  static PacingLevel fromString(String? val) {
    if (val == null) return PacingLevel.stepByStep;
    return PacingLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PacingLevel.stepByStep,
    );
  }
}

/// Explicit profile preferences set by the student.
class UserProfile {
  final String userName;
  final String grade;
  final TeachingStyle teachingStyle;
  final PacingLevel pacingLevel;

  const UserProfile({
    required this.userName,
    required this.grade,
    required this.teachingStyle,
    required this.pacingLevel,
  });

  factory UserProfile.defaults() {
    return const UserProfile(
      userName: 'Student',
      grade: '8',
      teachingStyle: TeachingStyle.socratic,
      pacingLevel: PacingLevel.stepByStep,
    );
  }

  UserProfile copyWith({
    String? userName,
    String? grade,
    TeachingStyle? teachingStyle,
    PacingLevel? pacingLevel,
  }) {
    return UserProfile(
      userName: userName ?? this.userName,
      grade: grade ?? this.grade,
      teachingStyle: teachingStyle ?? this.teachingStyle,
      pacingLevel: pacingLevel ?? this.pacingLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'grade': grade,
      'teachingStyle': teachingStyle.name,
      'pacingLevel': pacingLevel.name,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userName: json['userName'] as String? ?? 'Student',
      grade: json['grade'] as String? ?? '8',
      teachingStyle: TeachingStyle.fromString(json['teachingStyle'] as String?),
      pacingLevel: PacingLevel.fromString(json['pacingLevel'] as String?),
    );
  }
}
