import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/schedule/models/weekly_schedule.dart';
import '../../../domain/schedule/repositories/schedule_repository.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

@injectable
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository scheduleRepository;

  ScheduleBloc(this.scheduleRepository) : super(const ScheduleState()) {
    on<ScheduleLoadRequested>(_onLoad);
    on<SchedulePublishRequested>(_onPublish);
  }

  /// Saturday of the week containing [date], normalised to midnight.
  static DateTime weekStartOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // Dart weekday: Mon=1..Sun=7. Saturday=6.
    final diff = (d.weekday - DateTime.saturday) % 7;
    return d.subtract(Duration(days: diff));
  }

  static String weekIdOf(DateTime weekStart) {
    final m = weekStart.month.toString().padLeft(2, '0');
    final day = weekStart.day.toString().padLeft(2, '0');
    return '${weekStart.year}-$m-$day';
  }

  Future<void> _onLoad(
      ScheduleLoadRequested event, Emitter<ScheduleState> emit) async {
    final weekStart = weekStartOf(event.weekContaining ?? DateTime.now());
    final weekId = weekIdOf(weekStart);
    emit(state.copyWith(
        status: UIStatus.loading, weekStart: weekStart, weekId: weekId));
    try {
      final schedule = await scheduleRepository.getSchedule(
        circleId: event.circleId,
        weekId: weekId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        schedule: schedule,
        clearSchedule: schedule == null,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onPublish(
      SchedulePublishRequested event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final weekStart = weekStartOf(event.weekStart);
      final schedule = WeeklySchedule(
        weekId: weekIdOf(weekStart),
        weekStart: weekStart,
        days: event.days,
      );
      await scheduleRepository.publishSchedule(
        circleId: event.circleId,
        schedule: schedule,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        message: 'تم نشر الجدول بنجاح',
        schedule: schedule,
        weekStart: weekStart,
        weekId: schedule.weekId,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
