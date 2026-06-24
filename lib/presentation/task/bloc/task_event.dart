part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// US-08: load today's task for [uid].
class TaskTodayLoadRequested extends TaskEvent {
  final String circleId;
  final String uid;

  const TaskTodayLoadRequested({required this.circleId, required this.uid});

  @override
  List<Object?> get props => [circleId, uid];
}

/// US-09: record completion and ask [partnerId] to confirm.
class TaskConfirmationRequested extends TaskEvent {
  final String circleId;
  final String dateId;
  final DailyTask task;
  final String partnerId;

  const TaskConfirmationRequested({
    required this.circleId,
    required this.dateId,
    required this.task,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [circleId, dateId, task, partnerId];
}

/// US-10: load confirmations addressed to [partnerUid] for today.
class PendingConfirmationsLoadRequested extends TaskEvent {
  final String circleId;
  final String partnerUid;

  const PendingConfirmationsLoadRequested({
    required this.circleId,
    required this.partnerUid,
  });

  @override
  List<Object?> get props => [circleId, partnerUid];
}

/// US-10: confirm a peer's recitation.
class PeerTaskConfirmed extends TaskEvent {
  final String circleId;
  final String dateId;
  final String studentUid;

  const PeerTaskConfirmed({
    required this.circleId,
    required this.dateId,
    required this.studentUid,
  });

  @override
  List<Object?> get props => [circleId, dateId, studentUid];
}

/// US-35: load a student's assignments.
class AssignmentsLoadRequested extends TaskEvent {
  final String circleId;
  final String studentId;

  const AssignmentsLoadRequested({
    required this.circleId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [circleId, studentId];
}

/// US-35: teacher creates a per-student to-do.
class AssignmentCreateRequested extends TaskEvent {
  final String circleId;
  final Assignment assignment;

  const AssignmentCreateRequested({
    required this.circleId,
    required this.assignment,
  });

  @override
  List<Object?> get props => [circleId, assignment.id, assignment.studentId];
}

/// US-35: student marks an assignment done/undone.
class AssignmentDoneToggled extends TaskEvent {
  final String circleId;
  final String assignmentId;
  final bool done;

  const AssignmentDoneToggled({
    required this.circleId,
    required this.assignmentId,
    required this.done,
  });

  @override
  List<Object?> get props => [circleId, assignmentId, done];
}
