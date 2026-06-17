import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';

part 'session_event.dart';
part 'session_state.dart';

@injectable
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository sessionRepository;

  SessionBloc(this.sessionRepository) : super(const SessionState()) {
    on<SessionActiveRequested>(_onActive);
    on<SessionStartRequested>(_onStart);
    on<SessionEndRequested>(_onEnd);
    on<SessionJoinRequested>(_onJoin);
    on<SessionAttendanceRequested>(_onAttendance);
  }

  Future<void> _onActive(
      SessionActiveRequested event, Emitter<SessionState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final active = await sessionRepository.getActiveSession(event.circleId);
      final all = await sessionRepository.getSessions(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        activeSession: active,
        clearActive: active == null,
        sessions: all,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onStart(
      SessionStartRequested event, Emitter<SessionState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final session = await sessionRepository.startSession(
        circleId: event.circleId,
        sessionId: event.sessionId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        activeSession: session,
        message: 'بدأت الجلسة',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onEnd(
      SessionEndRequested event, Emitter<SessionState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await sessionRepository.endSession(
        circleId: event.circleId,
        sessionId: event.sessionId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        clearActive: true,
        message: 'انتهت الجلسة',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onJoin(
      SessionJoinRequested event, Emitter<SessionState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final session = await sessionRepository.joinSession(
        circleId: event.circleId,
        sessionId: event.sessionId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        activeSession: session,
        joined: true,
        message: 'تم تسجيل حضورك',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAttendance(
      SessionAttendanceRequested event, Emitter<SessionState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final attendance = await sessionRepository.getAttendance(
        circleId: event.circleId,
        sessionId: event.sessionId,
      );
      emit(state.copyWith(status: UIStatus.success, attendance: attendance));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
