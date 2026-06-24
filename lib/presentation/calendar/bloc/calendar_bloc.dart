import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../core/util/notify.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../../domain/session/models/session.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

@injectable
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository calendarRepository;

  CalendarBloc(this.calendarRepository) : super(const CalendarState()) {
    on<CalendarSessionsRequested>(_onLoad);
    on<CalendarSessionAdded>(_onAdd);
    on<CalendarRecurringSessionsAdded>(_onAddRecurring);
    on<CalendarSessionUpdated>(_onUpdate);
    on<CalendarSessionDeleted>(_onDelete);
    on<CalendarSeriesDeleted>(_onDeleteSeries);
  }

  Future<void> _onLoad(
      CalendarSessionsRequested event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      final sessions = await calendarRepository.getSessions(event.circleId);
      emit(state.copyWith(status: UIStatus.success, sessions: sessions));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAdd(
      CalendarSessionAdded event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await calendarRepository.addSession(
        circleId: event.circleId,
        title: event.title,
        scheduledAt: event.scheduledAt,
        durationMinutes: event.durationMinutes,
        type: event.type,
        link: event.link,
      );
      await notifyCircleStudents(
        circleId: event.circleId,
        title: 'جلسة جديدة',
        body: 'أضافت المعلّمة جلسة جديدة إلى الجدول',
        type: NotificationType.circleUpcoming,
      );
      final sessions = await calendarRepository.getSessions(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        sessions: sessions,
        message: 'تمت إضافة الجلسة',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAddRecurring(
      CalendarRecurringSessionsAdded event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(
        status: UIStatus.loading, message: '', actionDone: false));
    try {
      await calendarRepository.addRecurringSessions(
        circleId: event.circleId,
        title: event.title,
        type: event.type,
        durationMinutes: event.durationMinutes,
        occurrences: event.occurrences,
        link: event.link,
      );
      await notifyCircleStudents(
        circleId: event.circleId,
        title: 'جدول الجلسات',
        body: 'حدّثت المعلّمة جدول جلسات الحلقة',
        type: NotificationType.circleUpcoming,
      );
      final sessions = await calendarRepository.getSessions(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        sessions: sessions,
        message: 'تمت إضافة الجلسات',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onUpdate(
      CalendarSessionUpdated event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await calendarRepository.updateSession(
        circleId: event.circleId,
        sessionId: event.sessionId,
        title: event.title,
        scheduledAt: event.scheduledAt,
        durationMinutes: event.durationMinutes,
        type: event.type,
        link: event.link,
      );
      await notifyCircleStudents(
        circleId: event.circleId,
        title: 'تعديل جلسة',
        body: 'تم تعديل موعد إحدى جلسات الحلقة — تفقّدي الجدول',
        type: NotificationType.circleUpcoming,
      );
      final sessions = await calendarRepository.getSessions(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        sessions: sessions,
        message: 'تم تعديل الجلسة',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onDelete(
      CalendarSessionDeleted event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await calendarRepository.deleteSession(
        circleId: event.circleId,
        sessionId: event.sessionId,
      );
      await notifyCircleStudents(
        circleId: event.circleId,
        title: 'إلغاء جلسة',
        body: 'أُلغيت إحدى جلسات الحلقة',
        type: NotificationType.circleUpcoming,
      );
      final sessions = await calendarRepository.getSessions(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        sessions: sessions,
        message: 'تم حذف الجلسة',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onDeleteSeries(
      CalendarSeriesDeleted event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(
        status: UIStatus.loading, message: '', actionDone: false));
    try {
      await calendarRepository.deleteSeries(
        circleId: event.circleId,
        recurrenceId: event.recurrenceId,
      );
      await notifyCircleStudents(
        circleId: event.circleId,
        title: 'إلغاء جلسات',
        body: 'أُلغيت سلسلة من جلسات الحلقة',
        type: NotificationType.circleUpcoming,
      );
      final sessions = await calendarRepository.getSessions(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        sessions: sessions,
        message: 'تم حذف السلسلة',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
