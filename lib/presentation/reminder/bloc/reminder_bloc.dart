import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/reminder/models/reminder_settings.dart';
import '../../../domain/reminder/repositories/reminder_repository.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

@injectable
class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository reminderRepository;

  ReminderBloc(this.reminderRepository) : super(const ReminderState()) {
    on<ReminderSettingsRequested>(_onLoad);
    on<ReminderDailySaved>(_onSaveDaily);
    on<ReminderExamScheduled>(_onScheduleExam);
  }

  Future<void> _onLoad(
      ReminderSettingsRequested event, Emitter<ReminderState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final settings = await reminderRepository.getSettings();
      emit(state.copyWith(status: UIStatus.success, settings: settings));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onSaveDaily(
      ReminderDailySaved event, Emitter<ReminderState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await reminderRepository.saveDailyReminder(event.settings);
      emit(state.copyWith(
        status: UIStatus.success,
        settings: event.settings,
        message: event.settings.enabled
            ? 'تم ضبط التذكير اليومي'
            : 'تم إيقاف التذكير اليومي',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onScheduleExam(
      ReminderExamScheduled event, Emitter<ReminderState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await reminderRepository.scheduleExamReminder(
        examId: event.examId,
        examTitle: event.examTitle,
        examTime: event.examTime,
        before: event.before,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        message: 'تم ضبط تذكير الاختبار',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
