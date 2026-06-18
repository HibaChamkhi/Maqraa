import '../models/exam.dart';

/// Exam contract (US-20/21).
/// Implemented with Cloud Firestore in the data layer.
abstract class ExamRepository {
  /// US-20: list a circle's exams.
  Future<List<Exam>> getExams(String circleId);

  /// US-20: teacher schedules an exam (title, range, date, type, marks).
  Future<Exam> scheduleExam({
    required String circleId,
    required String title,
    required String range,
    required DateTime date,
    ExamType type,
    num totalMarks,
    num passMark,
  });

  /// US-20: teacher edits an existing exam's details.
  Future<void> updateExam({
    required String circleId,
    required String examId,
    required String title,
    required String range,
    required DateTime date,
    required ExamType type,
    required num totalMarks,
    required num passMark,
  });

  /// Teacher deletes an exam (and its results).
  Future<void> deleteExam({
    required String circleId,
    required String examId,
  });

  /// Publish gate: show/hide results to students.
  Future<void> setResultsPublished({
    required String circleId,
    required String examId,
    required bool published,
  });

  /// US-21: teacher records / updates a student's result for an exam.
  Future<void> recordResult({
    required String circleId,
    required String examId,
    required String uid,
    required String name,
    required num score,
    ExamAttendance attendance,
    String feedback,
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
