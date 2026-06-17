import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/schedule/models/weekly_schedule.dart';

/// Maps the `circles/{circleId}/schedules/{weekId}` document <-> [WeeklySchedule].
class WeeklyScheduleDto {
  static WeeklySchedule fromMap(String weekId, Map<String, dynamic> map) {
    final rawDays = (map['days'] as Map<String, dynamic>?) ?? const {};
    final days = <String, String>{
      for (final entry in rawDays.entries)
        entry.key: (entry.value ?? '').toString(),
    };
    return WeeklySchedule(
      weekId: weekId,
      weekStart: (map['weekStart'] as Timestamp?)?.toDate() ??
          DateTime.tryParse(weekId) ??
          DateTime.now(),
      days: days,
      publishedAt: (map['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(WeeklySchedule schedule) {
    return {
      'weekStart': Timestamp.fromDate(schedule.weekStart),
      'days': schedule.days,
      'publishedAt': FieldValue.serverTimestamp(),
    };
  }
}
