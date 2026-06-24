/// Broad grouping used by the notifications tabs/filters.
enum NotificationCategory { system, circles, homework, exams, alerts }

/// Kind of notification — drives the icon, colour and default title.
enum NotificationType {
  studentJoined,
  homework,
  circleUpcoming,
  report,
  adminMessage,
  prayer,
  exam,
  achievement,
  teacherMessage,
  attendance,
  general;

  NotificationCategory get category {
    switch (this) {
      case NotificationType.studentJoined:
      case NotificationType.circleUpcoming:
        return NotificationCategory.circles;
      case NotificationType.homework:
        return NotificationCategory.homework;
      case NotificationType.exam:
        return NotificationCategory.exams;
      case NotificationType.prayer:
      case NotificationType.achievement:
      case NotificationType.attendance:
        return NotificationCategory.alerts;
      case NotificationType.report:
      case NotificationType.adminMessage:
      case NotificationType.teacherMessage:
      case NotificationType.general:
        return NotificationCategory.system;
    }
  }

  static NotificationType fromName(String? value) =>
      NotificationType.values.where((t) => t.name == value).firstOrNull ??
      NotificationType.general;
}

/// A single notification stored under users/{uid}/notifications/{id}.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.general,
    this.read = false,
    this.createdAt,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}

/// User notification preferences (master switch + per-type + quiet hours),
/// persisted on users/{uid}.notificationSettings.
class NotificationSettings {
  final bool enabled;
  final Map<String, bool> types; // NotificationType.name -> on/off
  final String fromTime; // e.g. '08:00'
  final String toTime; // e.g. '22:00'

  const NotificationSettings({
    this.enabled = true,
    this.types = const {},
    this.fromTime = '08:00',
    this.toTime = '22:00',
  });

  bool typeEnabled(String key) => types[key] ?? true;

  NotificationSettings copyWith({
    bool? enabled,
    Map<String, bool>? types,
    String? fromTime,
    String? toTime,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      types: types ?? this.types,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }
}
