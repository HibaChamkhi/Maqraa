import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../../domain/notification/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc(this.repository) : super(const NotificationState()) {
    on<NotificationsRequested>(_onLoad);
    on<NotificationReadMarked>(_onMarkRead);
    on<NotificationsAllReadMarked>(_onMarkAllRead);
    on<NotificationSettingsRequested>(_onLoadSettings);
    on<NotificationSettingsSaved>(_onSaveSettings);
  }

  Future<void> _onLoad(
      NotificationsRequested event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final list = await repository.getNotifications();
      emit(state.copyWith(status: UIStatus.success, notifications: list));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMarkRead(
      NotificationReadMarked event, Emitter<NotificationState> emit) async {
    // Optimistic update.
    emit(state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == event.id ? n.copyWith(read: true) : n)
          .toList(),
    ));
    try {
      await repository.markRead(event.id);
    } on Exception {
      // Ignore — the list will reconcile on next load.
    }
  }

  Future<void> _onMarkAllRead(
      NotificationsAllReadMarked event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(read: true)).toList(),
    ));
    try {
      await repository.markAllRead();
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onLoadSettings(NotificationSettingsRequested event,
      Emitter<NotificationState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final s = await repository.getSettings();
      emit(state.copyWith(status: UIStatus.success, settings: s));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onSaveSettings(NotificationSettingsSaved event,
      Emitter<NotificationState> emit) async {
    emit(state.copyWith(settings: event.settings));
    try {
      await repository.saveSettings(event.settings);
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
