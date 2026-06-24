import 'package:injectable/injectable.dart';

import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../data_sources/remote/exam_data_source.dart';

@Injectable(as: ExamRepository)
class ExamRepositoryImpl implements ExamRepository {
  final ExamRemoteDataSource remoteDataSource;

  ExamRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Exam>> getExams(String circleId) =>
      remoteDataSource.getExams(circleId);

  @override
  Future<Exam> scheduleExam({
    required String circleId,
    required String title,
    required String range,
    required DateTime date,
    ExamType type = ExamType.other,
    num totalMarks = 100,
    num passMark = 50,
  }) =>
      remoteDataSource.scheduleExam(
        circleId: circleId,
        title: title,
        range: range,
        date: date,
        type: type,
        totalMarks: totalMarks,
        passMark: passMark,
      );

  @override
  Future<void> updateExam({
    required String circleId,
    required String examId,
    required String title,
    required String range,
    required DateTime date,
    required ExamType type,
    required num totalMarks,
    required num passMark,
  }) =>
      remoteDataSource.updateExam(
        circleId: circleId,
        examId: examId,
        title: title,
        range: range,
        date: date,
        type: type,
        totalMarks: totalMarks,
        passMark: passMark,
      );

  @override
  Future<void> deleteExam({
    required String circleId,
    required String examId,
  }) =>
      remoteDataSource.deleteExam(circleId: circleId, examId: examId);

  @override
  Future<void> setResultsPublished({
    required String circleId,
    required String examId,
    required bool published,
  }) =>
      remoteDataSource.setResultsPublished(
        circleId: circleId,
        examId: examId,
        published: published,
      );

  @override
  Future<void> recordResult({
    required String circleId,
    required String examId,
    required String uid,
    required String name,
    required num score,
    ExamAttendance attendance = ExamAttendance.present,
    String feedback = '',
    num? hifz,
    num? tajweed,
    num? fluency,
  }) =>
      remoteDataSource.recordResult(
        circleId: circleId,
        examId: examId,
        uid: uid,
        name: name,
        score: score,
        attendance: attendance,
        feedback: feedback,
        hifz: hifz,
        tajweed: tajweed,
        fluency: fluency,
      );

  @override
  Future<List<ExamResult>> getResults({
    required String circleId,
    required String examId,
  }) =>
      remoteDataSource.getResults(circleId: circleId, examId: examId);

  @override
  Future<ExamResult?> getMyResult({
    required String circleId,
    required String examId,
  }) =>
      remoteDataSource.getMyResult(circleId: circleId, examId: examId);
}
