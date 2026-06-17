import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/call/models/weekly_call.dart';
import '../../../domain/call/repositories/call_repository.dart';

part 'call_event.dart';
part 'call_state.dart';

@injectable
class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository callRepository;

  CallBloc(this.callRepository) : super(const CallState()) {
    on<CallsRequested>(_onCalls);
    on<CallScheduled>(_onSchedule);
    on<CallAttendanceConfirmed>(_onConfirm);
    on<CallAttendanceRequested>(_onAttendance);
  }

  Future<void> _onCalls(CallsRequested event, Emitter<CallState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final calls = await callRepository.getCalls(event.circleId);
      // Tag the user's attendance for the latest call (for the student view).
      bool myPresence = false;
      if (calls.isNotEmpty) {
        myPresence = await callRepository.myAttendance(
          circleId: event.circleId,
          callId: calls.first.id,
        );
      }
      emit(state.copyWith(
        status: UIStatus.success,
        calls: calls,
        myAttendance: myPresence,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onSchedule(CallScheduled event, Emitter<CallState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await callRepository.scheduleCall(
        circleId: event.circleId,
        title: event.title,
        time: event.time,
        link: event.link,
      );
      final calls = await callRepository.getCalls(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        calls: calls,
        actionDone: true,
        message: 'تم جدولة المكالمة',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onConfirm(
      CallAttendanceConfirmed event, Emitter<CallState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await callRepository.confirmAttendance(
        circleId: event.circleId,
        callId: event.callId,
        present: event.present,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        myAttendance: event.present,
        message: event.present
            ? 'تم تأكيد حضورك'
            : 'تم تسجيل اعتذارك عن الحضور',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAttendance(
      CallAttendanceRequested event, Emitter<CallState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final attendance = await callRepository.getAttendance(
        circleId: event.circleId,
        callId: event.callId,
      );
      emit(state.copyWith(status: UIStatus.success, attendance: attendance));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
