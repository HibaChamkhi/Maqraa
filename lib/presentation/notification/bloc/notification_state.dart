part of 'notification_bloc.dart';

class NotificationState extends Equatable {
  final UIStatus status;
  final String message;
  final List<AppNotification> notifications;
  final NotificationSettings settings;

  const NotificationState({
    this.status = UIStatus.loading,
    this.message = '',
    this.notifications = const [],
    this.settings = const NotificationSettings(),
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  NotificationState copyWith({
    UIStatus? status,
    String? message,
    List<AppNotification>? notifications,
    NotificationSettings? settings,
  }) {
    return NotificationState(
      status: status ?? this.status,
      message: message ?? this.message,
      notifications: notifications ?? this.notifications,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [status, message, notifications, settings];
}
