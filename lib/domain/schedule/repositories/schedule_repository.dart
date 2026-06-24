import '../models/weekly_schedule.dart';

/// Weekly schedule contract (US-06 publish, US-07 view).
abstract class ScheduleRepository {
  /// Teacher publishes (creates/updates) a week's schedule.
  Future<void> publishSchedule({
    required String circleId,
    required WeeklySchedule schedule,
  });

  /// Loads the schedule for the given week, or null if none published.
  Future<WeeklySchedule?> getSchedule({
    required String circleId,
    required String weekId,
  });
}
