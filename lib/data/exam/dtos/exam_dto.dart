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
      type: ExamType.fromKey(map['type'] as String?),
      totalMarks: (map['totalMarks'] ?? 100) as num,
      passMark: (map['passMark'] ?? 50) as num,
      resultsPublished: (map['resultsPublished'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toMap(Exam exam) {
    return {
      'title': exam.title,
      'range': exam.range,
      'date': Timestamp.fromDate(exam.date),
      'type': exam.type.storageKey,
      'totalMarks': exam.totalMarks,
      'passMark': exam.passMark,
      'resultsPublished': exam.resultsPublished,
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
      attendance: ExamAttendance.fromKey(map['attendance'] as String?),
      feedback: (map['feedback'] ?? '') as String,
      hifz: map['hifz'] as num?,
      tajweed: map['tajweed'] as num?,
      fluency: map['fluency'] as num?,
    );
  }

  static Map<String, dynamic> toMap(ExamResult result) {
    return {
      'uid': result.uid,
      'name': result.name,
      'score': result.score,
      'attendance': result.attendance.storageKey,
      'feedback': result.feedback,
      'hifz': result.hifz,
      'tajweed': result.tajweed,
      'fluency': result.fluency,
    };
  }
}
