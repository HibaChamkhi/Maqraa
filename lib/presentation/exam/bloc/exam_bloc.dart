import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/util/notify.dart';
import '../../../domain/exam/models/exam.dart';
import '../../../domain/exam/repositories/exam_repository.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../../domain/reminder/repositories/reminder_repository.dart';

part 'exam_event.dart';
part 'exam_state.dart';

@injectable
class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository examRepository;

  ExamBloc(this.examRepository) : super(const ExamState()) {
    on<ExamsRequested>(_onLoad);
    on<ExamScheduled>(_onSchedule);
    on<ExamUpdated>(_onUpdate);
    on<ExamDeleted>(_onDelete);
    on<ExamPublishToggled>(_onPublishToggled);
    on<ExamResultsRequested>(_onResults);
    on<ExamResultRecorded>(_onRecord);
    on<ExamMyResultRequested>(_onMyResult);
  }

  /// Schedule (or reschedule) a local reminder for an exam. Best-effort — a
  /// missing notification permission must never fail the exam write.
  Future<void> _syncReminder({
    required String examId,
    required String title,
    required DateTime date,
  }) async {
    try {
      await getIt<ReminderRepository>().scheduleExamReminder(
          examId: examId, examTitle: title, examTime: date);
    } catch (_) {/* ignore */}
  }

  Future<void> _cancelReminder(String examId) async {
    try {
      await getIt<ReminderRepository>().cancelExamReminder(examId);
    } catch (_) {/* ignore */}
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
      final exam = await examRepository.scheduleExam(
        circleId: event.circleId,
        title: event.title,
        range: event.range,
        date: event.date,
        type: event.type,
        totalMarks: event.totalMarks,
        passMark: event.passMark,
      );
      await _syncReminder(
          examId: exam.id, title: exam.title, date: exam.date);
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

  Future<void> _onUpdate(ExamUpdated event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await examRepository.updateExam(
        circleId: event.circleId,
        examId: event.examId,
        title: event.title,
        range: event.range,
        date: event.date,
        type: event.type,
        totalMarks: event.totalMarks,
        passMark: event.passMark,
      );
      await _syncReminder(
          examId: event.examId, title: event.title, date: event.date);
      final exams = await examRepository.getExams(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        exams: exams,
        message: 'تم تعديل الاختبار',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onDelete(ExamDeleted event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await examRepository.deleteExam(
        circleId: event.circleId,
        examId: event.examId,
      );
      await _cancelReminder(event.examId);
      final exams = await examRepository.getExams(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        exams: exams,
        message: 'تم حذف الاختبار',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onPublishToggled(
      ExamPublishToggled event, Emitter<ExamState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await examRepository.setResultsPublished(
        circleId: event.circleId,
        examId: event.examId,
        published: event.published,
      );
      if (event.published) {
        await notifyCircleStudents(
          circleId: event.circleId,
          title: 'نتيجة اختبار جاهزة',
          body: 'ظهرت نتيجة اختبار جديد — تفقّدي قسم الاختبارات',
          type: NotificationType.exam,
        );
      }
      emit(state.copyWith(
        status: UIStatus.success,
        message: event.published ? 'تم نشر النتائج' : 'تم إخفاء النتائج',
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
        attendance: event.attendance,
        feedback: event.feedback,
        hifz: event.hifz,
        tajweed: event.tajweed,
        fluency: event.fluency,
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
