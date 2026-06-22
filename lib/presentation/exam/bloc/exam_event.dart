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
  final ExamType type;
  final num totalMarks;
  final num passMark;

  const ExamScheduled({
    required this.circleId,
    required this.title,
    required this.range,
    required this.date,
    this.type = ExamType.other,
    this.totalMarks = 100,
    this.passMark = 50,
  });

  @override
  List<Object?> get props =>
      [circleId, title, range, date, type, totalMarks, passMark];
}

/// Teacher edits an existing exam.
class ExamUpdated extends ExamEvent {
  final String circleId;
  final String examId;
  final String title;
  final String range;
  final DateTime date;
  final ExamType type;
  final num totalMarks;
  final num passMark;

  const ExamUpdated({
    required this.circleId,
    required this.examId,
    required this.title,
    required this.range,
    required this.date,
    required this.type,
    required this.totalMarks,
    required this.passMark,
  });

  @override
  List<Object?> get props =>
      [circleId, examId, title, range, date, type, totalMarks, passMark];
}

/// Teacher deletes an exam.
class ExamDeleted extends ExamEvent {
  final String circleId;
  final String examId;

  const ExamDeleted({required this.circleId, required this.examId});

  @override
  List<Object?> get props => [circleId, examId];
}

/// Teacher toggles the publish gate for an exam's results.
class ExamPublishToggled extends ExamEvent {
  final String circleId;
  final String examId;
  final bool published;

  const ExamPublishToggled({
    required this.circleId,
    required this.examId,
    required this.published,
  });

  @override
  List<Object?> get props => [circleId, examId, published];
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
  final ExamAttendance attendance;
  final String feedback;
  final num? hifz;
  final num? tajweed;
  final num? fluency;

  const ExamResultRecorded({
    required this.circleId,
    required this.examId,
    required this.uid,
    required this.name,
    required this.score,
    this.attendance = ExamAttendance.present,
    this.feedback = '',
    this.hifz,
    this.tajweed,
    this.fluency,
  });

  @override
  List<Object?> get props => [
        circleId,
        examId,
        uid,
        name,
        score,
        attendance,
        feedback,
        hifz,
        tajweed,
        fluency
      ];
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
