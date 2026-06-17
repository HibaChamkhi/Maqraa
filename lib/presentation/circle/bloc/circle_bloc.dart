import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';

part 'circle_event.dart';
part 'circle_state.dart';

@injectable
class CircleBloc extends Bloc<CircleEvent, CircleState> {
  final CircleRepository circleRepository;

  CircleBloc(this.circleRepository) : super(const CircleState()) {
    on<CircleCreateRequested>(_onCreate);
    on<CircleJoinByCodeRequested>(_onJoinByCode);
    on<CircleJoinRequestSent>(_onRequestToJoin);
    on<CircleDiscoverRequested>(_onDiscover);
    on<CircleMembersRequested>(_onMembers);
    on<CirclePendingRequestsRequested>(_onPending);
    on<CircleRequestAccepted>(_onAccept);
    on<CircleRequestRejected>(_onReject);
    on<CircleMemberPromoted>(_onPromote);
    on<CirclePrivacyChanged>(_onPrivacy);
    on<CircleLoadRequested>(_onLoad);
    on<CircleMyCirclesRequested>(_onMyCircles);
  }

  Future<void> _onCreate(
      CircleCreateRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      final circle = await circleRepository.createCircle(
        name: event.name,
        privacy: event.privacy,
      );
      emit(state.copyWith(
          status: UIStatus.success, circle: circle, actionDone: true));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onJoinByCode(
      CircleJoinByCodeRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      final circle = await circleRepository.joinByInviteCode(event.inviteCode);
      emit(state.copyWith(
          status: UIStatus.success, circle: circle, actionDone: true));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onRequestToJoin(
      CircleJoinRequestSent event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await circleRepository.requestToJoin(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        message: 'تم إرسال طلب الانضمام',
        actionDone: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onDiscover(
      CircleDiscoverRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final circles = await circleRepository.discoverPublicCircles();
      emit(state.copyWith(status: UIStatus.success, discoverCircles: circles));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMembers(
      CircleMembersRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(status: UIStatus.success, members: members));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onPending(
      CirclePendingRequestsRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final pending = await circleRepository.getPendingRequests(event.circleId);
      emit(state.copyWith(status: UIStatus.success, pendingRequests: pending));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onAccept(
      CircleRequestAccepted event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await circleRepository.acceptRequest(
          circleId: event.circleId, uid: event.uid);
      final pending =
          await circleRepository.getPendingRequests(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        pendingRequests: pending,
        message: 'تم قبول الطلب',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onReject(
      CircleRequestRejected event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await circleRepository.rejectRequest(
          circleId: event.circleId, uid: event.uid);
      final pending =
          await circleRepository.getPendingRequests(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        pendingRequests: pending,
        message: 'تم رفض الطلب',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onPromote(
      CircleMemberPromoted event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await circleRepository.promoteToSupervisor(
          circleId: event.circleId, uid: event.uid);
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        members: members,
        message: 'تمت الترقية إلى مشرفة',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onPrivacy(
      CirclePrivacyChanged event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await circleRepository.updatePrivacy(
          circleId: event.circleId, privacy: event.privacy);
      final circle = await circleRepository.getCircle(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        circle: circle,
        message: 'تم تحديث الخصوصية',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onLoad(
      CircleLoadRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final circle = await circleRepository.getCircle(event.circleId);
      emit(state.copyWith(status: UIStatus.success, circle: circle));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMyCircles(
      CircleMyCirclesRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final circles = await circleRepository.getMyCircles();
      emit(state.copyWith(status: UIStatus.success, myCircles: circles));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
