import '../models/exam.dart';

/// Exam contract (US-20/21).
/// Implemented with Cloud Firestore in the data layer.
abstract class ExamRepository {
  /// US-20: list a circle's exams.
  Future<List<Exam>> getExams(String circleId);

  /// US-20: teacher schedules an exam (title, range, date).
  Future<Exam> scheduleExam({
    required String circleId,
    required String title,
    required String range,
    required DateTime date,
  });

  /// US-21: teacher records / updates a student's score for an exam.
  Future<void> recordResult({
    required String circleId,
    required String examId,
    required String uid,
    required String name,
    required num score,
  });

  /// US-21: list all results of an exam (teacher view).
  Future<List<ExamResult>> getResults({
    required String circleId,
    required String examId,
  });

  /// US-21: a student views their own score for an exam (null if not graded).
  Future<ExamResult?> getMyResult({
    required String circleId,
    required String examId,
  });
}
