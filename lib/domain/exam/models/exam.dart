// Exam domain models (US-20/21).
// Backed by `circles/{circleId}/exams/{examId}` and its `results` subcollection.

/// An exam document under circles/{circleId}/exams/{examId}.
class Exam {
  final String id;
  final String title;

  /// Free-text memorization range (e.g. "سورة البقرة 1-20").
  final String range;
  final DateTime date;

  const Exam({
    required this.id,
    required this.title,
    required this.range,
    required this.date,
  });

  Exam copyWith({
    String? title,
    String? range,
    DateTime? date,
  }) {
    return Exam(
      id: id,
      title: title ?? this.title,
      range: range ?? this.range,
      date: date ?? this.date,
    );
  }
}

/// A result document under circles/{circleId}/exams/{examId}/results/{uid}.
class ExamResult {
  final String uid;
  final String name;
  final num score;

  const ExamResult({
    required this.uid,
    required this.name,
    required this.score,
  });

  ExamResult copyWith({
    String? name,
    num? score,
  }) {
    return ExamResult(
      uid: uid,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}
