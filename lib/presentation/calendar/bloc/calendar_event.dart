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

/// US-30: add a single session appointment.
class CalendarSessionAdded extends CalendarEvent {
  final String circleId;
  final String title;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionType type;
  final String link;

  const CalendarSessionAdded({
    required this.circleId,
    required this.title,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.type = SessionType.tasmi3,
    this.link = '',
  });

  @override
  List<Object?> get props =>
      [circleId, title, scheduledAt, durationMinutes, type, link];
}

/// Add a recurring weekly series (one session per occurrence).
class CalendarRecurringSessionsAdded extends CalendarEvent {
  final String circleId;
  final String title;
  final SessionType type;
  final int durationMinutes;
  final List<DateTime> occurrences;
  final String link;

  const CalendarRecurringSessionsAdded({
    required this.circleId,
    required this.title,
    required this.type,
    required this.durationMinutes,
    required this.occurrences,
    this.link = '',
  });

  @override
  List<Object?> get props =>
      [circleId, title, type, durationMinutes, occurrences, link];
}

/// US-30: edit a session appointment.
class CalendarSessionUpdated extends CalendarEvent {
  final String circleId;
  final String sessionId;
  final String title;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionType type;
  final String link;

  const CalendarSessionUpdated({
    required this.circleId,
    required this.sessionId,
    required this.title,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.type = SessionType.tasmi3,
    this.link = '',
  });

  @override
  List<Object?> get props =>
      [circleId, sessionId, title, scheduledAt, durationMinutes, type, link];
}

/// US-30: delete a single session appointment.
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

/// Delete a whole recurring series.
class CalendarSeriesDeleted extends CalendarEvent {
  final String circleId;
  final String recurrenceId;

  const CalendarSeriesDeleted({
    required this.circleId,
    required this.recurrenceId,
  });

  @override
  List<Object?> get props => [circleId, recurrenceId];
}
