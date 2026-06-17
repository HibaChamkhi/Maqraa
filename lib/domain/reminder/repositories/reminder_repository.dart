import '../models/reminder_settings.dart';

/// Reminder scheduling contract (US-13 daily, US-15 exam).
abstract class ReminderRepository {
  /// Current persisted daily-reminder settings.
  Future<ReminderSettings> getSettings();

  /// US-13: persist + (re)schedule (or cancel) the daily reminder.
  Future<void> saveDailyReminder(ReminderSettings settings);

  /// US-15: schedule a one-off reminder a given duration before [examTime].
  Future<void> scheduleExamReminder({
    required String examId,
    required String examTitle,
    required DateTime examTime,
    Duration before = const Duration(hours: 1),
  });

  /// Cancel a previously scheduled exam reminder.
  Future<void> cancelExamReminder(String examId);
}
