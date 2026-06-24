part of 'reminder_bloc.dart';

class ReminderState extends Equatable {
  final UIStatus status;
  final String message;

  /// Persisted daily-reminder settings (US-13).
  final ReminderSettings settings;

  const ReminderState({
    this.status = UIStatus.success,
    this.message = '',
    this.settings = const ReminderSettings(),
  });

  ReminderState copyWith({
    UIStatus? status,
    String? message,
    ReminderSettings? settings,
  }) {
    return ReminderState(
      status: status ?? this.status,
      message: message ?? this.message,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        status,
        message,
        settings.enabled,
        settings.hour,
        settings.minute,
      ];
}
