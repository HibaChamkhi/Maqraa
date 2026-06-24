part of 'progress_bloc.dart';

class ProgressState extends Equatable {
  final UIStatus status;
  final String message;
  final ProgressInfo? progress;
  final List<StudentSubmission> submissions;

  const ProgressState({
    this.status = UIStatus.success,
    this.message = '',
    this.progress,
    this.submissions = const [],
  });

  ProgressState copyWith({
    UIStatus? status,
    String? message,
    ProgressInfo? progress,
    List<StudentSubmission>? submissions,
  }) {
    return ProgressState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      submissions: submissions ?? this.submissions,
    );
  }

  @override
  List<Object?> get props => [status, message, progress, submissions];
}
