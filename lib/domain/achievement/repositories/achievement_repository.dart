import '../models/achievement.dart';

/// Streak & badge contract (US-24).
abstract class AchievementRepository {
  /// Current streak/badge state of the signed-in user.
  Future<Achievement> getAchievement();

  /// Register a task completion for today. Increments the streak for a
  /// consecutive day, resets it after a gap, awards any newly earned badges,
  /// and is idempotent for the same day. Returns the updated [Achievement].
  Future<Achievement> registerCompletion();
}
