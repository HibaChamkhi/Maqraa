import '../../../domain/achievement/models/achievement.dart';

/// Maps the streak/badge fields on users/{uid} <-> [Achievement].
class AchievementDto {
  static Achievement fromMap(Map<String, dynamic> map) {
    return Achievement(
      streakCount: (map['streakCount'] ?? 0) as int,
      lastCompletedDate: (map['lastCompletedDate'] ?? '') as String,
      badges: ((map['badges'] ?? const <dynamic>[]) as List)
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Only the streak-related fields, to merge into the user doc.
  static Map<String, dynamic> toMap(Achievement a) {
    return {
      'streakCount': a.streakCount,
      'lastCompletedDate': a.lastCompletedDate,
      'badges': a.badges,
    };
  }
}
