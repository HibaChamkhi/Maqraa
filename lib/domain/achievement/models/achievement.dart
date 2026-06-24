/// Commitment streak & earned badges (US-24), persisted on
/// users/{uid}: { streakCount (int), lastCompletedDate (yyyy-MM-dd), badges: [string] }.
class Achievement {
  final int streakCount;

  /// Last day a task was completed, as 'yyyy-MM-dd' (empty if none yet).
  final String lastCompletedDate;

  /// Earned badge keys (see [Badge]).
  final List<String> badges;

  const Achievement({
    this.streakCount = 0,
    this.lastCompletedDate = '',
    this.badges = const [],
  });

  Achievement copyWith({
    int? streakCount,
    String? lastCompletedDate,
    List<String>? badges,
  }) {
    return Achievement(
      streakCount: streakCount ?? this.streakCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      badges: badges ?? this.badges,
    );
  }
}

/// Badge thresholds awarded by streak length. The [key] is what's stored in the
/// `badges` array; [arabicLabel] is for display.
enum Badge {
  starter(key: 'starter', threshold: 1),
  committed3(key: 'committed3', threshold: 3),
  week7(key: 'week7', threshold: 7),
  steady14(key: 'steady14', threshold: 14),
  month30(key: 'month30', threshold: 30),
  centurion100(key: 'centurion100', threshold: 100);

  final String key;
  final int threshold;

  const Badge({required this.key, required this.threshold});

  String get arabicLabel {
    switch (this) {
      case Badge.starter:
        return 'البداية';
      case Badge.committed3:
        return 'ملتزمة ٣ أيام';
      case Badge.week7:
        return 'أسبوع كامل';
      case Badge.steady14:
        return 'ثبات أسبوعين';
      case Badge.month30:
        return 'شهر متواصل';
      case Badge.centurion100:
        return 'مئة يوم';
    }
  }

  static Badge? fromKey(String key) =>
      Badge.values.where((b) => b.key == key).firstOrNull;

  /// All badge keys earned at or below [streak].
  static List<String> earnedFor(int streak) => Badge.values
      .where((b) => streak >= b.threshold)
      .map((b) => b.key)
      .toList();
}
