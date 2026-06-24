part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

/// US-07: load the schedule for the week containing [weekContaining] (default: now).
class ScheduleLoadRequested extends ScheduleEvent {
  final String circleId;
  final DateTime? weekContaining;

  const ScheduleLoadRequested({required this.circleId, this.weekContaining});

  @override
  List<Object?> get props => [circleId, weekContaining];
}

/// US-06: teacher publishes a week's day-by-day ranges.
class SchedulePublishRequested extends ScheduleEvent {
  final String circleId;
  final DateTime weekStart;
  final Map<String, String> days;

  const SchedulePublishRequested({
    required this.circleId,
    required this.weekStart,
    required this.days,
  });

  @override
  List<Object?> get props => [circleId, weekStart, days];
}
