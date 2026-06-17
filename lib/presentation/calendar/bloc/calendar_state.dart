part of 'calendar_bloc.dart';

class CalendarState extends Equatable {
  final UIStatus status;
  final String message;

  /// All sessions of the circle, sorted by scheduledAt.
  final List<Session> sessions;

  /// True after an add/edit/delete succeeds (for feedback).
  final bool actionDone;

  const CalendarState({
    this.status = UIStatus.loading,
    this.message = '',
    this.sessions = const [],
    this.actionDone = false,
  });

  CalendarState copyWith({
    UIStatus? status,
    String? message,
    List<Session>? sessions,
    bool? actionDone,
  }) {
    return CalendarState(
      status: status ?? this.status,
      message: message ?? this.message,
      sessions: sessions ?? this.sessions,
      actionDone: actionDone ?? this.actionDone,
    );
  }

  @override
  List<Object?> get props => [status, message, sessions, actionDone];
}
