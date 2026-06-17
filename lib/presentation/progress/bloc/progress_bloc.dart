import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/progress/models/progress_info.dart';
import '../../../domain/progress/repositories/progress_repository.dart';

part 'progress_event.dart';
part 'progress_state.dart';

@injectable
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepository progressRepository;

  ProgressBloc(this.progressRepository) : super(const ProgressState()) {
    on<LoadMyProgress>(_onLoadMyProgress);
    on<AddProgress>(_onAddProgress);
    on<LoadTodaySubmissions>(_onLoadTodaySubmissions);
  }

  Future<void> _onLoadMyProgress(LoadMyProgress event, Emitter<ProgressState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final info = await progressRepository.getMyProgress();
      emit(state.copyWith(status: UIStatus.success, progress: info));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAddProgress(AddProgress event, Emitter<ProgressState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final info = await progressRepository.addProgress(event.pages);
      emit(state.copyWith(status: UIStatus.success, progress: info));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onLoadTodaySubmissions(
      LoadTodaySubmissions event, Emitter<ProgressState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final list = await progressRepository.getTodaySubmissions(event.circleId);
      emit(state.copyWith(status: UIStatus.success, submissions: list));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
