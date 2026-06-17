import 'package:injectable/injectable.dart';

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
  }) =>
      remoteDataSource.startSession(circleId: circleId, sessionId: sessionId);

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
