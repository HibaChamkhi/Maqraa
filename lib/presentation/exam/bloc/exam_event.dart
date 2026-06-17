part of 'exam_bloc.dart';

abstract class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => [];
}

/// US-20: load a circle's exams.
class ExamsRequested extends ExamEvent {
  final String circleId;

  const ExamsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// US-20: teacher schedules an exam.
class ExamScheduled extends ExamEvent {
  final String circleId;
  final String title;
  final String range;
  final DateTime date;

  const ExamScheduled({
    required this.circleId,
    required this.title,
    required this.range,
    required this.date,
  });

  @override
  List<Object?> get props => [circleId, title, range, date];
}

/// US-21: load all results of an exam (teacher view).
class ExamResultsRequested extends ExamEvent {
  final String circleId;
  final String examId;

  const ExamResultsRequested({
    required this.circleId,
    required this.examId,
  });

  @override
  List<Object?> get props => [circleId, examId];
}

/// US-21: teacher records / updates a student's score.
class ExamResultRecorded extends ExamEvent {
  final String circleId;
  final String examId;
  final String uid;
  final String name;
  final num score;

  const ExamResultRecorded({
    required this.circleId,
    required this.examId,
    required this.uid,
    required this.name,
    required this.score,
  });

  @override
  List<Object?> get props => [circleId, examId, uid, name, score];
}

/// US-21: a student requests their own score for an exam.
class ExamMyResultRequested extends ExamEvent {
  final String circleId;
  final String examId;

  const ExamMyResultRequested({
    required this.circleId,
    required this.examId,
  });

  @override
  List<Object?> get props => [circleId, examId];
}
