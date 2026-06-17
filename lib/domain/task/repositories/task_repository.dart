import '../models/assignment.dart';
import '../models/daily_task.dart';

/// Daily homework + per-student assignments contract (US-08..US-10, US-35).
abstract class TaskRepository {
  // --- Daily tasks ---

  /// US-08: the student's task for a given day, or null if none.
  Future<DailyTask?> getTaskForDay({
    required String circleId,
    required String dateId,
    required String uid,
  });

  /// US-09: student records completion and requests partner confirmation.
  /// Sets status to pending and stores [partnerId] so the partner is notified.
  Future<void> requestConfirmation({
    required String circleId,
    required String dateId,
    required DailyTask task,
    required String partnerId,
  });

  /// US-10: partner confirms a peer's recitation → partnerConfirmed=true, status=done.
  Future<void> confirmTask({
    required String circleId,
    required String dateId,
    required String studentUid,
  });

  /// US-10: tasks for [dateId] where partnerId == [partnerUid] and not yet confirmed.
  Future<List<DailyTask>> getPendingConfirmations({
    required String circleId,
    required String dateId,
    required String partnerUid,
  });

  /// US-12: all of today's tasks in the circle (for the teacher dashboard).
  Future<List<DailyTask>> getTasksForDay({
    required String circleId,
    required String dateId,
  });

  // --- Assignments (US-35) ---

  /// Teacher creates a per-student to-do.
  Future<void> createAssignment({
    required String circleId,
    required Assignment assignment,
  });

  /// Assignments for one student.
  Future<List<Assignment>> getAssignmentsForStudent({
    required String circleId,
    required String studentId,
  });

  /// Student marks an assignment done/undone.
  Future<void> setAssignmentDone({
    required String circleId,
    required String assignmentId,
    required bool done,
  });
}
