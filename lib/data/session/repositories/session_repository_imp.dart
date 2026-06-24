import 'package:injectable/injectable.dart';

import '../../../core/util/notify.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../../domain/session/models/session.dart';
import '../../../domain/session/repositories/session_repository.dart';
import '../data_sources/remote/session_data_source.dart';

@Injectable(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource remoteDataSource;

  SessionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Session?> getActiveSession(String circleId) =>
      remoteDataSource.getActiveSession(circleId);

  @override
  Future<List<Session>> getSessions(String circleId) =>
      remoteDataSource.getSessions(circleId);

  @override
  Future<Session> startSession({
    required String circleId,
    required String sessionId,
  }) async {
    final session = await remoteDataSource.startSession(
        circleId: circleId, sessionId: sessionId);
    // Best-effort: tell the circle's students the session is live.
    await notifyCircleStudents(
      circleId: circleId,
      title: 'جلسة بدأت الآن',
      body: session.title.trim().isNotEmpty
          ? 'بدأت جلسة «${session.title.trim()}» — انضمّي الآن'
          : 'بدأت جلسة في حلقتك — انضمّي الآن',
      type: NotificationType.circleUpcoming,
    );
    return session;
  }

  @override
  Future<Session> endSession({
    required String circleId,
    required String sessionId,
  }) =>
      remoteDataSource.endSession(circleId: circleId, sessionId: sessionId);

  @override
  Future<Session> joinSession({
    required String circleId,
    required String sessionId,
  }) =>
      remoteDataSource.joinSession(circleId: circleId, sessionId: sessionId);

  @override
  Future<List<Attendance>> getAttendance({
    required String circleId,
    required String sessionId,
  }) =>
      remoteDataSource.getAttendance(circleId: circleId, sessionId: sessionId);
}
