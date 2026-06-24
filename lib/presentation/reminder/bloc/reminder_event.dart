part of 'reminder_bloc.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class ReminderSettingsRequested extends ReminderEvent {
  const ReminderSettingsRequested();
}

class ReminderDailySaved extends ReminderEvent {
  final ReminderSettings settings;

  const ReminderDailySaved(this.settings);

  @override
  List<Object?> get props => [settings.enabled, settings.hour, settings.minute];
}

class ReminderExamScheduled extends ReminderEvent {
  final String examId;
  final String examTitle;
  final DateTime examTime;
  final Duration before;

  const ReminderExamScheduled({
    required this.examId,
    required this.examTitle,
    required this.examTime,
    this.before = const Duration(hours: 1),
  });

  @override
  List<Object?> get props => [examId, examTitle, examTime, before];
}
