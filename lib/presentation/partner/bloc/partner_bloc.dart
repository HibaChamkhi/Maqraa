import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/partner/models/partner.dart';
import '../../../domain/partner/repositories/partner_repository.dart';

part 'partner_event.dart';
part 'partner_state.dart';

@injectable
class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final PartnerRepository partnerRepository;

  PartnerBloc(this.partnerRepository) : super(const PartnerState()) {
    on<PartnerPairsRequested>(_onPairs);
    on<PartnerManualPairRequested>(_onManualPair);
    on<PartnerAutoPairRequested>(_onAutoPair);
    on<PartnerMyPairRequested>(_onMyPair);
    on<PartnerDailyCallToggled>(_onToggleDailyCall);
    on<PartnerAppointmentsRequested>(_onAppointments);
    on<PartnerAppointmentBooked>(_onBook);
    on<PartnerAppointmentConfirmed>(_onConfirm);
  }

  Future<void> _onPairs(
      PartnerPairsRequested event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final pairs = await partnerRepository.getPairs(event.circleId);
      emit(state.copyWith(status: UIStatus.success, pairs: pairs));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onManualPair(
      PartnerManualPairRequested event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await partnerRepository.pairMembers(
        circleId: event.circleId,
        a: event.a,
        b: event.b,
      );
      final pairs = await partnerRepository.getPairs(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        pairs: pairs,
        actionDone: true,
        message: 'تم الإقران بنجاح',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAutoPair(
      PartnerAutoPairRequested event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      final pairs = await partnerRepository.autoPairActiveStudents(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        pairs: pairs,
        actionDone: true,
        message: 'تم الإقران التلقائي (${pairs.length} ثنائيات)',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMyPair(
      PartnerMyPairRequested event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final pair = await partnerRepository.getMyPair(event.circleId);
      final dailyDone = pair == null
          ? false
          : await partnerRepository.isDailyCallDone(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        myPair: pair,
        clearMyPair: pair == null,
        dailyCallDone: dailyDone,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onToggleDailyCall(
      PartnerDailyCallToggled event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final done = await partnerRepository.setDailyCallDone(
        circleId: event.circleId,
        done: event.done,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        dailyCallDone: done,
        message: done ? 'تم تسجيل المكالمة اليومية' : 'تم إلغاء التسجيل',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAppointments(
      PartnerAppointmentsRequested event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final appointments =
          await partnerRepository.getMyAppointments(event.circleId);
      emit(state.copyWith(status: UIStatus.success, appointments: appointments));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onBook(
      PartnerAppointmentBooked event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await partnerRepository.bookAppointment(
        circleId: event.circleId,
        toId: event.toId,
        toName: event.toName,
        time: event.time,
      );
      final appointments =
          await partnerRepository.getMyAppointments(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        appointments: appointments,
        actionDone: true,
        message: 'تم حجز الموعد، بانتظار التأكيد',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onConfirm(
      PartnerAppointmentConfirmed event, Emitter<PartnerState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await partnerRepository.confirmAppointment(
        circleId: event.circleId,
        appointmentId: event.appointmentId,
      );
      final appointments =
          await partnerRepository.getMyAppointments(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        appointments: appointments,
        message: 'تم تأكيد الموعد',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
