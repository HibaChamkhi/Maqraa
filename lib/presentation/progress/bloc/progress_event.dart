part of 'progress_bloc.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyProgress extends ProgressEvent {
  const LoadMyProgress();
}

class AddProgress extends ProgressEvent {
  final int pages;

  const AddProgress(this.pages);

  @override
  List<Object?> get props => [pages];
}

class LoadTodaySubmissions extends ProgressEvent {
  final String circleId;

  const LoadTodaySubmissions(this.circleId);

  @override
  List<Object?> get props => [circleId];
}
