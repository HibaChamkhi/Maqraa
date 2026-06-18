// Exam domain models (US-20/21).
// Backed by `circles/{circleId}/exams/{examId}` and its `results` subcollection.

/// Kind of exam. Optional categorisation shown as a chip in the UI.
enum ExamType {
  juz, // اختبار جزء / نطاق
  periodic, // اختبار دوري / شهري
  half, // اختبار نصف القرآن
  full, // اختبار القرآن كاملًا
  certification, // إجازة / ختمة
  other; // عام

  String get arabicLabel {
    switch (this) {
      case ExamType.juz:
        return 'اختبار جزء';
      case ExamType.periodic:
        return 'اختبار دوري';
      case ExamType.half:
        return 'نصف القرآن';
      case ExamType.full:
        return 'القرآن كاملًا';
      case ExamType.certification:
        return 'إجازة / ختمة';
      case ExamType.other:
        return 'عام';
    }
  }

  String get storageKey => name;

  static ExamType fromKey(String? key) {
    return ExamType.values.firstWhere(
      (t) => t.name == key,
      orElse: () => ExamType.other,
    );
  }
}

/// A student's attendance state for an exam. Absent/excused are distinct from
/// a zero score (غائبة ≠ صفر).
enum ExamAttendance {
  present, // حاضرة (مرصودة)
  absent, // غائبة
  excused; // معذورة

  String get arabicLabel {
    switch (this) {
      case ExamAttendance.present:
        return 'حاضرة';
      case ExamAttendance.absent:
        return 'غائبة';
      case ExamAttendance.excused:
        return 'معذورة';
    }
  }

  String get storageKey => name;

  static ExamAttendance fromKey(String? key) {
    return ExamAttendance.values.firstWhere(
      (a) => a.name == key,
      orElse: () => ExamAttendance.present,
    );
  }
}

/// Verbal grade label derived from a score out of [total].
/// Returns '' when [total] is not positive.
String examGradeLabel(num score, num total) {
  if (total <= 0) return '';
  final pct = (score / total) * 100;
  if (pct >= 90) return 'ممتاز';
  if (pct >= 80) return 'جيد جدًا';
  if (pct >= 70) return 'جيد';
  if (pct >= 50) return 'مقبول';
  return 'راسب';
}

/// An exam document under circles/{circleId}/exams/{examId}.
class Exam {
  final String id;
  final String title;

  /// Free-text memorization range (e.g. "سورة البقرة 1-20").
  final String range;
  final DateTime date;
  final ExamType type;

  /// Full marks for the exam (denominator for grading).
  final num totalMarks;

  /// Minimum score to pass.
  final num passMark;

  /// When false, students cannot see their result yet (publish gate).
  final bool resultsPublished;

  const Exam({
    required this.id,
    required this.title,
    required this.range,
    required this.date,
    this.type = ExamType.other,
    this.totalMarks = 100,
    this.passMark = 50,
    this.resultsPublished = false,
  });

  Exam copyWith({
    String? title,
    String? range,
    DateTime? date,
    ExamType? type,
    num? totalMarks,
    num? passMark,
    bool? resultsPublished,
  }) {
    return Exam(
      id: id,
      title: title ?? this.title,
      range: range ?? this.range,
      date: date ?? this.date,
      type: type ?? this.type,
      totalMarks: totalMarks ?? this.totalMarks,
      passMark: passMark ?? this.passMark,
      resultsPublished: resultsPublished ?? this.resultsPublished,
    );
  }
}

/// A result document under circles/{circleId}/exams/{examId}/results/{uid}.
class ExamResult {
  final String uid;
  final String name;
  final num score;
  final ExamAttendance attendance;

  /// Optional teacher feedback note shown to the student after publishing.
  final String feedback;

  const ExamResult({
    required this.uid,
    required this.name,
    required this.score,
    this.attendance = ExamAttendance.present,
    this.feedback = '',
  });

  /// Whether this result counts as a pass, given the exam's [passMark].
  bool passed(num passMark) =>
      attendance == ExamAttendance.present && score >= passMark;

  ExamResult copyWith({
    String? name,
    num? score,
    ExamAttendance? attendance,
    String? feedback,
  }) {
    return ExamResult(
      uid: uid,
      name: name ?? this.name,
      score: score ?? this.score,
      attendance: attendance ?? this.attendance,
      feedback: feedback ?? this.feedback,
    );
  }
}
