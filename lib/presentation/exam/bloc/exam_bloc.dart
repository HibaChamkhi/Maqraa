import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';

part 'exam_event.dart';
part 'exam_state.dart';

@injectable
class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository examRepository;

  ExamBloc(this.examRepository) : super(const ExamState()) {
    on<ExamsRequested>(_onLoad);
    on<ExamScheduled>(_onSchedule);
    on<ExamResultsRequested>(_onResults);
    on<ExamResultRecorded>(_onRecord);
    on<ExamMyResultRequested>(_onMyResult);
  }

  Future<void> _onLoad(ExamsRequested event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      final exams = await examRepository.getExams(event.circleId);
      emit(state.copyWith(status: UIStatus.success, exams: exams));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onSchedule(
      ExamScheduled event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await examRepository.scheduleExam(
        circleId: event.circleId,
        title: event.title,
        range: event.range,
        date: event.date,
      );
      final exams = await examRepository.getExams(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        exams: exams,
        message: 'تم جدولة الاختبار',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onResults(
      ExamResultsRequested event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final results = await examRepository.getResults(
        circleId: event.circleId,
        examId: event.examId,
      );
      emit(state.copyWith(status: UIStatus.success, results: results));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onRecord(
      ExamResultRecorded event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await examRepository.recordResult(
        circleId: event.circleId,
        examId: event.examId,
        uid: event.uid,
        name: event.name,
        score: event.score,
      );
      final results = await examRepository.getResults(
        circleId: event.circleId,
        examId: event.examId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        results: results,
        message: 'تم تسجيل الدرجة',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMyResult(
      ExamMyResultRequested event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final result = await examRepository.getMyResult(
        circleId: event.circleId,
        examId: event.examId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        myResult: result,
        clearMyResult: result == null,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
