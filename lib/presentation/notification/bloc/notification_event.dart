part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationEvent {
  const NotificationsRequested();
}

class NotificationReadMarked extends NotificationEvent {
  final String id;
  const NotificationReadMarked(this.id);

  @override
  List<Object?> get props => [id];
}

class NotificationsAllReadMarked extends NotificationEvent {
  const NotificationsAllReadMarked();
}

class NotificationSettingsRequested extends NotificationEvent {
  const NotificationSettingsRequested();
}

class NotificationSettingsSaved extends NotificationEvent {
  final NotificationSettings settings;
  const NotificationSettingsSaved(this.settings);

  @override
  List<Object?> get props => [settings];
}
