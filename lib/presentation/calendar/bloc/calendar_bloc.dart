import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/session/models/session.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

@injectable
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository calendarRepository;

  CalendarBloc(this.calendarRepository) : super(const CalendarState()) {
    on<CalendarSessionsRequested>(_onLoad);
    on<CalendarSessionAdded>(_onAdd);
    on<CalendarSessionUpdated>(_onUpdate);
    on<CalendarSessionDeleted>(_onDelete);
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
        link: event.link,
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

  Future<void> _onUpdate(
      CalendarSessionUpdated event, Emitter<CalendarState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await calendarRepository.updateSession(
        circleId: event.circleId,
        sessionId: event.sessionId,
        title: event.title,
        scheduledAt: event.scheduledAt,
        link: event.link,
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
}
