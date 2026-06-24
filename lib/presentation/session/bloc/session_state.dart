part of 'session_bloc.dart';

class SessionState extends Equatable {
  final UIStatus status;
  final String message;

  /// The currently active (live) session, if any.
  final Session? activeSession;

  /// All sessions of the circle (used to pick the next one to start).
  final List<Session> sessions;

  /// Attendance list of the active session (US-42).
  final List<Attendance> attendance;

  /// Set true once the student has joined the live session (US-33).
  final bool joined;

  const SessionState({
    this.status = UIStatus.success,
    this.message = '',
    this.activeSession,
    this.sessions = const [],
    this.attendance = const [],
    this.joined = false,
  });

  SessionState copyWith({
    UIStatus? status,
    String? message,
    Session? activeSession,
    bool clearActive = false,
    List<Session>? sessions,
    List<Attendance>? attendance,
    bool? joined,
  }) {
    return SessionState(
      status: status ?? this.status,
      message: message ?? this.message,
      activeSession:
          clearActive ? null : (activeSession ?? this.activeSession),
      sessions: sessions ?? this.sessions,
      attendance: attendance ?? this.attendance,
      joined: joined ?? this.joined,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, activeSession, sessions, attendance, joined];
}
