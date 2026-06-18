import '../models/app_notification.dart';

/// Notifications feed + per-user notification preferences.
abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? recipientId,
  });
  Future<NotificationSettings> getSettings();
  Future<void> saveSettings(NotificationSettings settings);
}
