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
    on<CircleMemberDemoted>(_onDemote);
    on<CircleOwnershipTransferred>(_onTransferOwnership);
    on<CirclePrivacyChanged>(_onPrivacy);
    on<CircleLoadRequested>(_onLoad);
    on<CircleMyCirclesRequested>(_onMyCircles);
    on<CircleStudentAdded>(_onStudentAdded);
    on<CircleStudentLinkedByContact>(_onStudentLinked);
    on<CircleMemberUpdated>(_onMemberUpdated);
    on<CircleMemberRemoved>(_onMemberRemoved);
  }

  Future<void> _onStudentAdded(
      CircleStudentAdded event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      await circleRepository.addStudentManually(
          circleId: event.circleId, name: event.name, juz: event.juz);
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(
          status: UIStatus.success, members: members, message: 'تمت إضافة الطالبة'));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onStudentLinked(
      CircleStudentLinkedByContact event, Emitter<CircleState> emit) async {
    emit(state.copyWith(
        status: UIStatus.loading, message: '', actionDone: false));
    try {
      await circleRepository.addStudentByContact(
          circleId: event.circleId, contact: event.contact);
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(
          status: UIStatus.success,
          members: members,
          message: 'تمت إضافة الطالبة'));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMemberUpdated(
      CircleMemberUpdated event, Emitter<CircleState> emit) async {
    try {
      await circleRepository.updateMember(
        circleId: event.circleId,
        uid: event.uid,
        attendance: event.attendance,
        performance: event.performance,
        memorizedPages: event.memorizedPages,
        juz: event.juz,
        contact: event.contact,
        notes: event.notes,
        touchRecitation: event.touchRecitation,
      );
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(status: UIStatus.success, members: members));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onMemberRemoved(
      CircleMemberRemoved event, Emitter<CircleState> emit) async {
    try {
      await circleRepository.removeMember(
          circleId: event.circleId, uid: event.uid);
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(
          status: UIStatus.success, members: members, message: 'تم حذف الطالبة'));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onCreate(
      CircleCreateRequested event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: '', actionDone: false));
    try {
      final circle = await circleRepository
          .createCircle(name: event.name, privacy: event.privacy)
          .timeout(const Duration(seconds: 20));
      emit(state.copyWith(
          status: UIStatus.success, circle: circle, actionDone: true));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    } catch (e) {
      emit(state.copyWith(
          status: UIStatus.error,
          message: 'تعذّر إنشاء الحلقة (تحقّقي من قواعد Firestore): $e'));
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
    // Subscribe to live roster changes so newly-joined students appear at once.
    await emit.forEach<List<CircleMember>>(
      circleRepository.membersStream(event.circleId),
      onData: (members) =>
          state.copyWith(status: UIStatus.success, members: members),
      onError: (e, _) => state.copyWith(
          status: UIStatus.error,
          message: e is Exception ? mapExceptionToMessage(e) : '$e'),
    );
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

  Future<void> _onDemote(
      CircleMemberDemoted event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await circleRepository.demoteToStudent(
          circleId: event.circleId, uid: event.uid);
      final members = await circleRepository.getMembers(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        members: members,
        message: 'تم إرجاعها إلى طالبة',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onTransferOwnership(
      CircleOwnershipTransferred event, Emitter<CircleState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await circleRepository.transferOwnership(
          circleId: event.circleId, newTeacherId: event.newTeacherId);
      final members = await circleRepository.getMembers(event.circleId);
      final circle = await circleRepository.getCircle(event.circleId);
      emit(state.copyWith(
        status: UIStatus.success,
        members: members,
        circle: circle,
        message: 'تم نقل ملكية الحلقة',
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
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
