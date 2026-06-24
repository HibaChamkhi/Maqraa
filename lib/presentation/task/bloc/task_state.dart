part of 'task_bloc.dart';

class TaskState extends Equatable {
  final UIStatus status;
  final String message;
  final String dateId;
  final DailyTask? todayTask;
  final List<DailyTask> pendingConfirmations;
  final List<Assignment> assignments;

  const TaskState({
    this.status = UIStatus.success,
    this.message = '',
    this.dateId = '',
    this.todayTask,
    this.pendingConfirmations = const [],
    this.assignments = const [],
  });

  TaskState copyWith({
    UIStatus? status,
    String? message,
    String? dateId,
    DailyTask? todayTask,
    bool clearTodayTask = false,
    List<DailyTask>? pendingConfirmations,
    List<Assignment>? assignments,
  }) {
    return TaskState(
      status: status ?? this.status,
      message: message ?? this.message,
      dateId: dateId ?? this.dateId,
      todayTask: clearTodayTask ? null : (todayTask ?? this.todayTask),
      pendingConfirmations: pendingConfirmations ?? this.pendingConfirmations,
      assignments: assignments ?? this.assignments,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, dateId, todayTask, pendingConfirmations, assignments];
}
