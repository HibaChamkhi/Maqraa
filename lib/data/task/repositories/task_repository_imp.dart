import 'package:injectable/injectable.dart';

import '../../../domain/task/models/assignment.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../../domain/task/repositories/task_repository.dart';
import '../data_sources/remote/task_data_source.dart';

@Injectable(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DailyTask?> getTaskForDay({
    required String circleId,
    required String dateId,
    required String uid,
  }) {
    return remoteDataSource.getTaskForDay(
      circleId: circleId,
      dateId: dateId,
      uid: uid,
    );
  }

  @override
  Future<void> requestConfirmation({
    required String circleId,
    required String dateId,
    required DailyTask task,
    required String partnerId,
  }) {
    return remoteDataSource.requestConfirmation(
      circleId: circleId,
      dateId: dateId,
      task: task,
      partnerId: partnerId,
    );
  }

  @override
  Future<void> confirmTask({
    required String circleId,
    required String dateId,
    required String studentUid,
  }) {
    return remoteDataSource.confirmTask(
      circleId: circleId,
      dateId: dateId,
      studentUid: studentUid,
    );
  }

  @override
  Future<List<DailyTask>> getPendingConfirmations({
    required String circleId,
    required String dateId,
    required String partnerUid,
  }) {
    return remoteDataSource.getPendingConfirmations(
      circleId: circleId,
      dateId: dateId,
      partnerUid: partnerUid,
    );
  }

  @override
  Future<List<DailyTask>> getTasksForDay({
    required String circleId,
    required String dateId,
  }) {
    return remoteDataSource.getTasksForDay(circleId: circleId, dateId: dateId);
  }

  @override
  Future<void> createAssignment({
    required String circleId,
    required Assignment assignment,
  }) {
    return remoteDataSource.createAssignment(
      circleId: circleId,
      assignment: assignment,
    );
  }

  @override
  Future<List<Assignment>> getAssignmentsForStudent({
    required String circleId,
    required String studentId,
  }) {
    return remoteDataSource.getAssignmentsForStudent(
      circleId: circleId,
      studentId: studentId,
    );
  }

  @override
  Future<void> setAssignmentDone({
    required String circleId,
    required String assignmentId,
    required bool done,
  }) {
    return remoteDataSource.setAssignmentDone(
      circleId: circleId,
      assignmentId: assignmentId,
      done: done,
    );
  }
}
