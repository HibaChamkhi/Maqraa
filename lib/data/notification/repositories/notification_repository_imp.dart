import '../../../domain/notification/models/app_notification.dart';
import '../../../domain/notification/repositories/notification_repository.dart';
import '../data_sources/remote/notification_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AppNotification>> getNotifications() =>
      remoteDataSource.getNotifications();

  @override
  Future<void> markRead(String id) => remoteDataSource.markRead(id);

  @override
  Future<void> markAllRead() => remoteDataSource.markAllRead();

  @override
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? recipientId,
  }) =>
      remoteDataSource.createNotification(
        title: title,
        body: body,
        type: type,
        recipientId: recipientId,
      );

  @override
  Future<NotificationSettings> getSettings() => remoteDataSource.getSettings();

  @override
  Future<void> saveSettings(NotificationSettings settings) =>
      remoteDataSource.saveSettings(settings);
}
