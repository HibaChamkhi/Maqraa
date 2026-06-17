part of 'calendar_bloc.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// US-30/31: load all sessions of a circle for the calendar.
class CalendarSessionsRequested extends CalendarEvent {
  final String circleId;

  const CalendarSessionsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

/// US-30: add a session appointment.
class CalendarSessionAdded extends CalendarEvent {
  final String circleId;
  final String title;
  final DateTime scheduledAt;
  final String link;

  const CalendarSessionAdded({
    required this.circleId,
    required this.title,
    required this.scheduledAt,
    this.link = '',
  });

  @override
  List<Object?> get props => [circleId, title, scheduledAt, link];
}

/// US-30: edit a session appointment.
class CalendarSessionUpdated extends CalendarEvent {
  final String circleId;
  final String sessionId;
  final String title;
  final DateTime scheduledAt;
  final String link;

  const CalendarSessionUpdated({
    required this.circleId,
    required this.sessionId,
    required this.title,
    required this.scheduledAt,
    this.link = '',
  });

  @override
  List<Object?> get props => [circleId, sessionId, title, scheduledAt, link];
}

/// US-30: delete a session appointment.
class CalendarSessionDeleted extends CalendarEvent {
  final String circleId;
  final String sessionId;

  const CalendarSessionDeleted({
    required this.circleId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [circleId, sessionId];
}
