/// Daily-task reminder settings (US-13), persisted locally.
class ReminderSettings {
  /// Whether the daily reminder is enabled.
  final bool enabled;

  /// Hour of day (0-23) the reminder fires.
  final int hour;

  /// Minute of hour (0-59) the reminder fires.
  final int minute;

  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
