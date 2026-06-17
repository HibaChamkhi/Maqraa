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
  }) =>
      remoteDataSource.scheduleExam(
        circleId: circleId,
        title: title,
        range: range,
        date: date,
      );

  @override
  Future<void> recordResult({
    required String circleId,
    required String examId,
    required String uid,
    required String name,
    required num score,
  }) =>
      remoteDataSource.recordResult(
        circleId: circleId,
        examId: examId,
        uid: uid,
        name: name,
        score: score,
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
