/// Weekly homework («الواجب الأسبوعي») for ONE حلقة.
/// Stored at `circles/{circleId}/homework/{weekId}` where weekId is the
/// yyyy-MM-dd of the week's Saturday.

/// One day's plan: the assignment (الواجب), its type, and notes (ملاحظات).
class DayPlan {
  final String wajib;
  final String notes;
  final String type; // تسميع / إملاء / مراجعة (or empty)
  const DayPlan({this.wajib = '', this.notes = '', this.type = ''});

  bool get isEmpty => wajib.trim().isEmpty && notes.trim().isEmpty;

  Map<String, dynamic> toMap() =>
      {'wajib': wajib, 'notes': notes, 'type': type};
  static DayPlan fromMap(Map<String, dynamic> m) => DayPlan(
        wajib: (m['wajib'] ?? '') as String,
        notes: (m['notes'] ?? '') as String,
        type: (m['type'] ?? '') as String,
      );
}

/// Available واجب types.
const kWajibTypes = ['تسميع', 'إملاء', 'مراجعة'];

class WeeklyHomework {
  final String weekId;
  final DateTime weekStart;
  final Map<String, DayPlan> days; // dayCode -> plan
  const WeeklyHomework({
    required this.weekId,
    required this.weekStart,
    this.days = const {},
  });

  /// Saturday → Friday.
  static const dayOrder = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];

  static const dayLabels = {
    'sat': 'السبت',
    'sun': 'الأحد',
    'mon': 'الإثنين',
    'tue': 'الثلاثاء',
    'wed': 'الأربعاء',
    'thu': 'الخميس',
    'fri': 'الجمعة',
  };

  /// The Saturday that starts the week containing [d].
  static DateTime weekStartOf(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    final daysSinceSat = (midnight.weekday - DateTime.saturday + 7) % 7;
    return midnight.subtract(Duration(days: daysSinceSat));
  }

  DateTime dateOf(String code) =>
      weekStart.add(Duration(days: dayOrder.indexOf(code)));

  DayPlan planOf(String code) => days[code] ?? const DayPlan();
}

/// One student's completion for a week. Stored at
/// `circles/{circleId}/homework/{weekId}/completions/{studentUid}`.
class HomeworkCompletion {
  final String uid;
  final String name;
  final Set<String> doneDays; // codes done
  final Map<String, String> partners; // dayCode -> partner name
  const HomeworkCompletion({
    required this.uid,
    this.name = '',
    this.doneDays = const {},
    this.partners = const {},
  });

  bool isDone(String code) => doneDays.contains(code);
}
