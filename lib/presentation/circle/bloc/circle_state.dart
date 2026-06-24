part of 'circle_bloc.dart';

class CircleState extends Equatable {
  final UIStatus status;
  final String message;

  /// The circle most recently created / loaded / joined.
  final Circle? circle;

  /// Members of the current circle (US-05).
  final List<CircleMember> members;

  /// Pending join requests (US-41).
  final List<CircleMember> pendingRequests;

  /// Discoverable public circles (US-39).
  final List<Circle> discoverCircles;

  /// Circles the current user belongs to (home screen).
  final List<Circle> myCircles;

  /// Set true after an action that should trigger navigation/feedback
  /// (create / join / request sent).
  final bool actionDone;

  const CircleState({
    this.status = UIStatus.success,
    this.message = '',
    this.circle,
    this.members = const [],
    this.pendingRequests = const [],
    this.discoverCircles = const [],
    this.myCircles = const [],
    this.actionDone = false,
  });

  CircleState copyWith({
    UIStatus? status,
    String? message,
    Circle? circle,
    List<CircleMember>? members,
    List<CircleMember>? pendingRequests,
    List<Circle>? discoverCircles,
    List<Circle>? myCircles,
    bool? actionDone,
  }) {
    return CircleState(
      status: status ?? this.status,
      message: message ?? this.message,
      circle: circle ?? this.circle,
      members: members ?? this.members,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      discoverCircles: discoverCircles ?? this.discoverCircles,
      myCircles: myCircles ?? this.myCircles,
      actionDone: actionDone ?? this.actionDone,
    );
  }

  @override
  List<Object?> get props => [
        status,
        message,
        circle,
        members,
        pendingRequests,
        discoverCircles,
        myCircles,
        actionDone,
      ];
}
