part of 'exam_bloc.dart';

class ExamState extends Equatable {
  final UIStatus status;
  final String message;

  /// Circle exams (US-20).
  final List<Exam> exams;

  /// Results of the currently viewed exam (US-21 teacher view).
  final List<ExamResult> results;

  /// The current student's own result for an exam (US-21 student view).
  final ExamResult? myResult;

  /// True after schedule/record succeeds (for feedback).
  final bool actionDone;

  const ExamState({
    this.status = UIStatus.loading,
    this.message = '',
    this.exams = const [],
    this.results = const [],
    this.myResult,
    this.actionDone = false,
  });

  ExamState copyWith({
    UIStatus? status,
    String? message,
    List<Exam>? exams,
    List<ExamResult>? results,
    ExamResult? myResult,
    bool clearMyResult = false,
    bool? actionDone,
  }) {
    return ExamState(
      status: status ?? this.status,
      message: message ?? this.message,
      exams: exams ?? this.exams,
      results: results ?? this.results,
      myResult: clearMyResult ? null : (myResult ?? this.myResult),
      actionDone: actionDone ?? this.actionDone,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, exams, results, myResult, actionDone];
}
