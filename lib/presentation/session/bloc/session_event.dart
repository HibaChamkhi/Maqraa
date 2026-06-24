part of 'session_bloc.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Load the active (live) session + all sessions of a circle.
class SessionActiveRequested extends SessionEvent {
  final String circleId;

  const SessionActiveRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// US-32: start a scheduled session.
class SessionStartRequested extends SessionEvent {
  final String circleId;
  final String sessionId;

  const SessionStartRequested({
    required this.circleId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [circleId, sessionId];
}

/// US-32: end the live session.
class SessionEndRequested extends SessionEvent {
  final String circleId;
  final String sessionId;

  const SessionEndRequested({
    required this.circleId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [circleId, sessionId];
}

/// US-33: student joins the live session (records attendance).
class SessionJoinRequested extends SessionEvent {
  final String circleId;
  final String sessionId;

  const SessionJoinRequested({
    required this.circleId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [circleId, sessionId];
}

/// US-42: load attendance list for a session.
class SessionAttendanceRequested extends SessionEvent {
  final String circleId;
  final String sessionId;

  const SessionAttendanceRequested({
    required this.circleId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [circleId, sessionId];
}
