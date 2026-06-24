import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/notification/models/app_notification.dart';

/// Maps users/{uid}/notifications/{id} <-> [AppNotification].
class NotificationDto {
  static AppNotification fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      type: NotificationType.fromName(map['type'] as String?),
      read: (map['read'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(AppNotification n) {
    return {
      'title': n.title,
      'body': n.body,
      'type': n.type.name,
      'read': n.read,
      'createdAt': n.createdAt != null
          ? Timestamp.fromDate(n.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Maps the notificationSettings map on a user doc <-> [NotificationSettings].
class NotificationSettingsDto {
  static NotificationSettings fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationSettings();
    final rawTypes = (map['types'] as Map<String, dynamic>?) ?? const {};
    return NotificationSettings(
      enabled: (map['enabled'] ?? true) as bool,
      types: rawTypes.map((k, v) => MapEntry(k, v == true)),
      fromTime: (map['fromTime'] ?? '08:00') as String,
      toTime: (map['toTime'] ?? '22:00') as String,
    );
  }

  static Map<String, dynamic> toMap(NotificationSettings s) {
    return {
      'enabled': s.enabled,
      'types': s.types,
      'fromTime': s.fromTime,
      'toTime': s.toTime,
    };
  }
}
