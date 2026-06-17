import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/exam/models/exam.dart';

/// Maps `circles/{circleId}/exams/{examId}` <-> [Exam].
class ExamDto {
  static Exam fromMap(String id, Map<String, dynamic> map) {
    return Exam(
      id: id,
      title: (map['title'] ?? '') as String,
      range: (map['range'] ?? '') as String,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(Exam exam) {
    return {
      'title': exam.title,
      'range': exam.range,
      'date': Timestamp.fromDate(exam.date),
    };
  }
}

/// Maps `circles/{circleId}/exams/{examId}/results/{uid}` <-> [ExamResult].
class ExamResultDto {
  static ExamResult fromMap(String uid, Map<String, dynamic> map) {
    return ExamResult(
      uid: uid,
      name: (map['name'] ?? '') as String,
      score: (map['score'] ?? 0) as num,
    );
  }

  static Map<String, dynamic> toMap(ExamResult result) {
    return {
      'uid': result.uid,
      'name': result.name,
      'score': result.score,
    };
  }
}
