import 'package:injectable/injectable.dart';

import '../../../domain/calendar/repositories/calendar_repository.dart';
import '../../../domain/session/models/session.dart';
import '../data_sources/remote/calendar_data_source.dart';

@Injectable(as: CalendarRepository)
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remoteDataSource;

  CalendarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Session>> getSessions(String circleId) =>
      remoteDataSource.getSessions(circleId);

  @override
  Future<Session> addSession({
    required String circleId,
    required String title,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    SessionType type = SessionType.tasmi3,
    String link = '',
  }) =>
      remoteDataSource.addSession(
        circleId: circleId,
        title: title,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        type: type,
        link: link,
      );

  @override
  Future<void> addRecurringSessions({
    required String circleId,
    required String title,
    required SessionType type,
    required int durationMinutes,
    required List<DateTime> occurrences,
    String link = '',
  }) =>
      remoteDataSource.addRecurringSessions(
        circleId: circleId,
        title: title,
        type: type,
        durationMinutes: durationMinutes,
        occurrences: occurrences,
        link: link,
      );

  @override
  Future<Session> updateSession({
    required String circleId,
    required String sessionId,
    required String title,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    SessionType type = SessionType.tasmi3,
    String link = '',
  }) =>
      remoteDataSource.updateSession(
        circleId: circleId,
        sessionId: sessionId,
        title: title,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        type: type,
        link: link,
      );

  @override
  Future<void> deleteSession({
    required String circleId,
    required String sessionId,
  }) =>
      remoteDataSource.deleteSession(circleId: circleId, sessionId: sessionId);

  @override
  Future<void> deleteSeries({
    required String circleId,
    required String recurrenceId,
  }) =>
      remoteDataSource.deleteSeries(
          circleId: circleId, recurrenceId: recurrenceId);
}
