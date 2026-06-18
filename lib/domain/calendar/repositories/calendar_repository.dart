import '../../session/models/session.dart';

/// Sessions-calendar contract (US-30/31).
/// Reuses the `circles/{circleId}/sessions` collection.
abstract class CalendarRepository {
  /// All sessions of a circle (for marking calendar days / listing).
  Future<List<Session>> getSessions(String circleId);

  /// US-30: teacher/supervisor adds a single session appointment.
  Future<Session> addSession({
    required String circleId,
    required String title,
    required DateTime scheduledAt,
    int durationMinutes,
    SessionType type,
    String link,
  });

  /// Add a recurring series — one session per occurrence, shared recurrenceId.
  Future<void> addRecurringSessions({
    required String circleId,
    required String title,
    required SessionType type,
    required int durationMinutes,
    required List<DateTime> occurrences,
    String link,
  });

  /// US-30: edit an existing session appointment.
  Future<Session> updateSession({
    required String circleId,
    required String sessionId,
    required String title,
    required DateTime scheduledAt,
    int durationMinutes,
    SessionType type,
    String link,
  });

  /// US-30: delete a single session appointment.
  Future<void> deleteSession({
    required String circleId,
    required String sessionId,
  });

  /// Delete a whole recurring series.
  Future<void> deleteSeries({
    required String circleId,
    required String recurrenceId,
  });
}
