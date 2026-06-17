part of 'schedule_bloc.dart';

class ScheduleState extends Equatable {
  final UIStatus status;
  final String message;
  final WeeklySchedule? schedule;
  final DateTime? weekStart;
  final String? weekId;

  const ScheduleState({
    this.status = UIStatus.success,
    this.message = '',
    this.schedule,
    this.weekStart,
    this.weekId,
  });

  ScheduleState copyWith({
    UIStatus? status,
    String? message,
    WeeklySchedule? schedule,
    bool clearSchedule = false,
    DateTime? weekStart,
    String? weekId,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      message: message ?? this.message,
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      weekStart: weekStart ?? this.weekStart,
      weekId: weekId ?? this.weekId,
    );
  }

  @override
  List<Object?> get props => [status, message, schedule, weekStart, weekId];
}
