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
    ExamType type = ExamType.other,
    num totalMarks = 100,
    num passMark = 50,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedRange = range.trim();
    if (trimmedTitle.isEmpty) {
      throw BadRequestException(message: 'عنوان الاختبار مطلوب');
    }
    if (trimmedRange.isEmpty) {
      throw BadRequestException(message: 'نطاق الاختبار مطلوب');
    }
    if (totalMarks <= 0) {
      throw BadRequestException(message: 'الدرجة الكاملة غير صالحة');
    }
    if (passMark < 0 || passMark > totalMarks) {
      throw BadRequestException(message: 'درجة النجاح غير صالحة');
    }
    final docRef = _exams(circleId).doc();
    final exam = Exam(
      id: docRef.id,
      title: trimmedTitle,
      range: trimmedRange,
      date: date,
      type: type,
      totalMarks: totalMarks,
      passMark: passMark,
      resultsPublished: false,
    );
    await docRef.set(ExamDto.toMap(exam));
    return exam;
  }

  Future<void> updateExam({
    required String circleId,
    required String examId,
    required String title,
    required String range,
    required DateTime date,
    required ExamType type,
    required num totalMarks,
    required num passMark,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedRange = range.trim();
    if (trimmedTitle.isEmpty) {
      throw BadRequestException(message: 'عنوان الاختبار مطلوب');
    }
    if (trimmedRange.isEmpty) {
      throw BadRequestException(message: 'نطاق الاختبار مطلوب');
    }
    if (totalMarks <= 0) {
      throw BadRequestException(message: 'الدرجة الكاملة غير صالحة');
    }
    if (passMark < 0 || passMark > totalMarks) {
      throw BadRequestException(message: 'درجة النجاح غير صالحة');
    }
    await _exams(circleId).doc(examId).update({
      'title': trimmedTitle,
      'range': trimmedRange,
      'date': Timestamp.fromDate(date),
      'type': type.storageKey,
      'totalMarks': totalMarks,
      'passMark': passMark,
    });
  }

  Future<void> deleteExam({
    required String circleId,
    required String examId,
  }) async {
    final results = await _results(circleId, examId).get();
    final batch = firestore.batch();
    for (final doc in results.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_exams(circleId).doc(examId));
    await batch.commit();
  }

  Future<void> setResultsPublished({
    required String circleId,
    required String examId,
    required bool published,
  }) async {
    await _exams(circleId).doc(examId).update({'resultsPublished': published});
  }

  // --- US-21 ---

  Future<void> recordResult({
    required String circleId,
    required String examId,
    required String uid,
    required String name,
    required num score,
    ExamAttendance attendance = ExamAttendance.present,
    String feedback = '',
  }) async {
    if (score < 0) {
      throw BadRequestException(message: 'الدرجة غير صالحة');
    }
    // Absent/excused students keep a zero score regardless of input.
    final effectiveScore =
        attendance == ExamAttendance.present ? score : 0;
    await _results(circleId, examId).doc(uid).set(
          ExamResultDto.toMap(
            ExamResult(
              uid: uid,
              name: name,
              score: effectiveScore,
              attendance: attendance,
              feedback: feedback.trim(),
            ),
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
