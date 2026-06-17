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
