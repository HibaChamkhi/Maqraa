part of 'circle_bloc.dart';

abstract class CircleEvent extends Equatable {
  const CircleEvent();

  @override
  List<Object?> get props => [];
}

/// US-03
class CircleCreateRequested extends CircleEvent {
  final String name;
  final Privacy privacy;

  const CircleCreateRequested({required this.name, required this.privacy});

  @override
  List<Object?> get props => [name, privacy];
}

/// US-04 / US-29
class CircleJoinByCodeRequested extends CircleEvent {
  final String inviteCode;

  const CircleJoinByCodeRequested(this.inviteCode);

  @override
  List<Object?> get props => [inviteCode];
}

/// US-39
class CircleJoinRequestSent extends CircleEvent {
  final String circleId;

  const CircleJoinRequestSent(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// US-39
class CircleDiscoverRequested extends CircleEvent {
  const CircleDiscoverRequested();
}

/// US-05
class CircleMembersRequested extends CircleEvent {
  final String circleId;

  const CircleMembersRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// US-41
class CirclePendingRequestsRequested extends CircleEvent {
  final String circleId;

  const CirclePendingRequestsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// US-41
class CircleRequestAccepted extends CircleEvent {
  final String circleId;
  final String uid;

  const CircleRequestAccepted({required this.circleId, required this.uid});

  @override
  List<Object?> get props => [circleId, uid];
}

/// US-41
class CircleRequestRejected extends CircleEvent {
  final String circleId;
  final String uid;

  const CircleRequestRejected({required this.circleId, required this.uid});

  @override
  List<Object?> get props => [circleId, uid];
}

/// US-40
class CircleMemberPromoted extends CircleEvent {
  final String circleId;
  final String uid;

  const CircleMemberPromoted({required this.circleId, required this.uid});

  @override
  List<Object?> get props => [circleId, uid];
}

/// US-38
class CirclePrivacyChanged extends CircleEvent {
  final String circleId;
  final Privacy privacy;

  const CirclePrivacyChanged({required this.circleId, required this.privacy});

  @override
  List<Object?> get props => [circleId, privacy];
}

/// Load a single circle (info screen).
class CircleLoadRequested extends CircleEvent {
  final String circleId;

  const CircleLoadRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// Circles the current user belongs to (home screen).
class CircleMyCirclesRequested extends CircleEvent {
  const CircleMyCirclesRequested();
}

/// Manually add a student to a حلقة.
class CircleStudentAdded extends CircleEvent {
  final String circleId;
  final String name;
  final int? juz;

  const CircleStudentAdded({required this.circleId, required this.name, this.juz});

  @override
  List<Object?> get props => [circleId, name, juz];
}

/// Add an existing account holder to a حلقة by email/phone.
class CircleStudentLinkedByContact extends CircleEvent {
  final String circleId;
  final String contact;

  const CircleStudentLinkedByContact(
      {required this.circleId, required this.contact});

  @override
  List<Object?> get props => [circleId, contact];
}

/// Update a student's per-enrollment data (progress / attendance / rating).
class CircleMemberUpdated extends CircleEvent {
  final String circleId;
  final String uid;
  final AttendanceState? attendance;
  final PerformanceTag? performance;
  final int? memorizedPages;
  final int? juz;
  final bool touchRecitation;

  const CircleMemberUpdated({
    required this.circleId,
    required this.uid,
    this.attendance,
    this.performance,
    this.memorizedPages,
    this.juz,
    this.touchRecitation = false,
  });

  @override
  List<Object?> get props =>
      [circleId, uid, attendance, performance, memorizedPages, juz, touchRecitation];
}

/// Remove a student from a حلقة.
class CircleMemberRemoved extends CircleEvent {
  final String circleId;
  final String uid;

  const CircleMemberRemoved({required this.circleId, required this.uid});

  @override
  List<Object?> get props => [circleId, uid];
}
