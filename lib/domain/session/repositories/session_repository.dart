import '../models/session.dart';

/// Live-session contract (US-32/33/42).
/// Implemented with Cloud Firestore in the data layer.
abstract class SessionRepository {
  /// The currently active (live) session of a circle, or null if none.
  Future<Session?> getActiveSession(String circleId);

  /// All sessions of a circle (used to find the next scheduled session).
  Future<List<Session>> getSessions(String circleId);

  /// US-32: teacher/supervisor starts a session — sets status 'scheduled' ->
  /// 'live'. Returns the updated session.
  Future<Session> startSession({
    required String circleId,
    required String sessionId,
  });

  /// US-32: teacher/supervisor ends a session — sets status 'live' -> 'ended'.
  Future<Session> endSession({
    required String circleId,
    required String sessionId,
  });

  /// US-33: student joins the live session — writes their attendance doc
  /// (present=true) and returns the session (so the UI can show the link).
  Future<Session> joinSession({
    required String circleId,
    required String sessionId,
  });

  /// US-42: list who is present in a session's attendance subcollection.
  Future<List<Attendance>> getAttendance({
    required String circleId,
    required String sessionId,
  });
}
