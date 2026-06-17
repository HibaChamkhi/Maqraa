/// A teacher's per-student to-do assignment (US-35).
///
/// Stored at `circles/{circleId}/assignments/{assignmentId}`.
class Assignment {
  final String id;
  final String studentId;
  final String studentName;
  final String title;
  final DateTime date;
  final bool done;

  const Assignment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.date,
    this.done = false,
  });

  Assignment copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? title,
    DateTime? date,
    bool? done,
  }) {
    return Assignment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      title: title ?? this.title,
      date: date ?? this.date,
      done: done ?? this.done,
    );
  }
}
