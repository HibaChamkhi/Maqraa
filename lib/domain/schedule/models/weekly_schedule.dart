/// A weekly memorization schedule (US-06 / US-07).
///
/// Stored at `circles/{circleId}/schedules/{weekId}` where `weekId` is the
/// ISO date (yyyy-MM-dd) of the week's start (Saturday in the Hijri working
/// week used by الحلقات).
class WeeklySchedule {
  /// ISO date of the week start, also the Firestore document id.
  final String weekId;

  /// First day of the week (Saturday).
  final DateTime weekStart;

  /// Range per day keyed by the short day code: sat, sun, mon, tue, wed, thu, fri.
  final Map<String, String> days;

  /// When the teacher published this schedule (null = draft / not published).
  final DateTime? publishedAt;

  const WeeklySchedule({
    required this.weekId,
    required this.weekStart,
    required this.days,
    this.publishedAt,
  });

  /// Ordered day codes for a memorization week (Saturday → Friday).
  static const List<String> dayOrder = [
    'sat',
    'sun',
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
  ];

  /// Arabic label for a day code.
  static String arabicDay(String code) {
    switch (code) {
      case 'sat':
        return 'السبت';
      case 'sun':
        return 'الأحد';
      case 'mon':
        return 'الإثنين';
      case 'tue':
        return 'الثلاثاء';
      case 'wed':
        return 'الأربعاء';
      case 'thu':
        return 'الخميس';
      case 'fri':
        return 'الجمعة';
      default:
        return code;
    }
  }

  WeeklySchedule copyWith({
    String? weekId,
    DateTime? weekStart,
    Map<String, String>? days,
    DateTime? publishedAt,
  }) {
    return WeeklySchedule(
      weekId: weekId ?? this.weekId,
      weekStart: weekStart ?? this.weekStart,
      days: days ?? this.days,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
