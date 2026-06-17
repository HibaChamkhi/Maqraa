import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/exam/models/exam.dart';
import '../../dtos/exam_dto.dart';

/// Firestore-backed exam & results data source (US-20/21).
@injectable
class ExamRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  ExamRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> _exams(String circleId) =>
      firestore.collection('circles').doc(circleId).collection('exams');

  CollectionReference<Map<String, dynamic>> _results(
    String circleId,
    String examId,
  ) =>
      _exams(circleId).doc(examId).collection('results');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  // --- US-20 ---

  Future<List<Exam>> getExams(String circleId) async {
    final query = await _exams(circleId).orderBy('date').get();
    return query.docs
        .map((d) => ExamDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  Future<Exam> scheduleExam({
    required String circleId,
    required String title,
    required String range,
    required DateTime date,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedRange = range.trim();
    if (trimmedTitle.isEmpty) {
      throw BadRequestException(message: 'عنوان الاختبار مطلوب');
    }
    if (trimmedRange.isEmpty) {
      throw BadRequestException(message: 'نطاق الاختبار مطلوب');
    }
    final docRef = _exams(circleId).doc();
    final exam = Exam(
      id: docRef.id,
      title: trimmedTitle,
      range: trimmedRange,
      date: date,
    );
    await docRef.set(ExamDto.toMap(exam));
    return exam;
  }

  // --- US-21 ---

  Future<void> recordResult({
    required String circleId,
    required String examId,
    required String uid,
    required String name,
    required num score,
  }) async {
    if (score < 0) {
      throw BadRequestException(message: 'الدرجة غير صالحة');
    }
    await _results(circleId, examId).doc(uid).set(
          ExamResultDto.toMap(
            ExamResult(uid: uid, name: name, score: score),
          ),
        );
  }

  Future<List<ExamResult>> getResults({
    required String circleId,
    required String examId,
  }) async {
    final query = await _results(circleId, examId).get();
    return query.docs
        .map((d) => ExamResultDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  Future<ExamResult?> getMyResult({
    required String circleId,
    required String examId,
  }) async {
    final doc = await _results(circleId, examId).doc(_uid).get();
    if (!doc.exists) return null;
    return ExamResultDto.fromMap(doc.id, doc.data()!);
  }
}
