import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/task/models/assignment.dart';
import '../../../../domain/task/models/daily_task.dart';
import '../../dtos/assignment_dto.dart';
import '../../dtos/daily_task_dto.dart';

/// Firestore-backed daily tasks + assignments data source.
@injectable
class TaskRemoteDataSource {
  final FirebaseFirestore firestore;

  TaskRemoteDataSource({required this.firestore});

  CollectionReference<Map<String, dynamic>> _students(
          String circleId, String dateId) =>
      firestore
          .collection('circles')
          .doc(circleId)
          .collection('tasks')
          .doc(dateId)
          .collection('students');

  CollectionReference<Map<String, dynamic>> _assignments(String circleId) =>
      firestore.collection('circles').doc(circleId).collection('assignments');

  // --- Daily tasks ---

  Future<DailyTask?> getTaskForDay({
    required String circleId,
    required String dateId,
    required String uid,
  }) async {
    try {
      final doc = await _students(circleId, dateId).doc(uid).get();
      if (!doc.exists) return null;
      return DailyTaskDto.fromMap(dateId, doc.data()!);
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تحميل مهمة اليوم');
    }
  }

  Future<void> requestConfirmation({
    required String circleId,
    required String dateId,
    required DailyTask task,
    required String partnerId,
  }) async {
    try {
      final updated = task.copyWith(
        status: TaskStatus.pending,
        partnerConfirmed: false,
        partnerId: partnerId,
      );
      await _students(circleId, dateId)
          .doc(task.uid)
          .set(DailyTaskDto.toMap(updated), SetOptions(merge: true));
    } catch (e) {
      throw BadRequestException(message: 'تعذّر إرسال طلب التأكيد');
    }
  }

  Future<void> confirmTask({
    required String circleId,
    required String dateId,
    required String studentUid,
  }) async {
    try {
      await _students(circleId, dateId).doc(studentUid).update({
        'partnerConfirmed': true,
        'status': TaskStatus.done.name,
      });
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تأكيد التسميع');
    }
  }

  Future<List<DailyTask>> getPendingConfirmations({
    required String circleId,
    required String dateId,
    required String partnerUid,
  }) async {
    try {
      final snap = await _students(circleId, dateId)
          .where('partnerId', isEqualTo: partnerUid)
          .where('partnerConfirmed', isEqualTo: false)
          .get();
      return snap.docs
          .map((d) => DailyTaskDto.fromMap(dateId, d.data()))
          .toList();
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تحميل طلبات التأكيد');
    }
  }

  Future<List<DailyTask>> getTasksForDay({
    required String circleId,
    required String dateId,
  }) async {
    try {
      final snap = await _students(circleId, dateId).get();
      return snap.docs
          .map((d) => DailyTaskDto.fromMap(dateId, d.data()))
          .toList();
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تحميل تسليمات اليوم');
    }
  }

  // --- Assignments ---

  Future<void> createAssignment({
    required String circleId,
    required Assignment assignment,
  }) async {
    try {
      await _assignments(circleId).add(AssignmentDto.toMap(assignment));
    } catch (e) {
      throw BadRequestException(message: 'تعذّر إنشاء التكليف');
    }
  }

  Future<List<Assignment>> getAssignmentsForStudent({
    required String circleId,
    required String studentId,
  }) async {
    try {
      final snap = await _assignments(circleId)
          .where('studentId', isEqualTo: studentId)
          .get();
      final list = snap.docs
          .map((d) => AssignmentDto.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تحميل التكاليف');
    }
  }

  Future<void> setAssignmentDone({
    required String circleId,
    required String assignmentId,
    required bool done,
  }) async {
    try {
      await _assignments(circleId).doc(assignmentId).update({'done': done});
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تحديث التكليف');
    }
  }
}
