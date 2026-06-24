import 'package:injectable/injectable.dart';

import '../../../core/di/injection.dart';
import '../../../domain/circle/models/circle.dart';
import '../../../domain/notification/models/app_notification.dart';
import '../../../domain/notification/repositories/notification_repository.dart';
import '../../../domain/partner/models/partner.dart';
import '../../../domain/partner/repositories/partner_repository.dart';
import '../data_sources/remote/partner_data_source.dart';

@Injectable(as: PartnerRepository)
class PartnerRepositoryImpl implements PartnerRepository {
  final PartnerRemoteDataSource remoteDataSource;

  PartnerRepositoryImpl({required this.remoteDataSource});

  /// Tell both members of a new pair who their رفيقة is. Best-effort.
  Future<void> _notifyPair(Pair p) async {
    try {
      final repo = getIt<NotificationRepository>();
      await repo.createNotification(
        title: 'تم تحديد رفيقتك',
        body: 'رفيقتك في التسميع: ${p.bName}',
        type: NotificationType.circleUpcoming,
        recipientId: p.aId,
      );
      await repo.createNotification(
        title: 'تم تحديد رفيقتك',
        body: 'رفيقتك في التسميع: ${p.aName}',
        type: NotificationType.circleUpcoming,
        recipientId: p.bId,
      );
    } catch (_) {/* best-effort */}
  }

  @override
  Future<Pair> pairMembers({
    required String circleId,
    required CircleMember a,
    required CircleMember b,
  }) async {
    final p = await remoteDataSource.pairMembers(circleId: circleId, a: a, b: b);
    await _notifyPair(p);
    return p;
  }

  @override
  Future<List<Pair>> autoPairActiveStudents(String circleId) async {
    final pairs = await remoteDataSource.autoPairActiveStudents(circleId);
    for (final p in pairs) {
      await _notifyPair(p);
    }
    return pairs;
  }

  @override
  Future<List<Pair>> getPairs(String circleId) =>
      remoteDataSource.getPairs(circleId);

  @override
  Future<Pair?> getMyPair(String circleId) =>
      remoteDataSource.getMyPair(circleId);

  @override
  Future<bool> isDailyCallDone(String circleId) =>
      remoteDataSource.isDailyCallDone(circleId);

  @override
  Future<bool> setDailyCallDone({
    required String circleId,
    required bool done,
  }) =>
      remoteDataSource.setDailyCallDone(circleId: circleId, done: done);

  @override
  Future<Appointment> bookAppointment({
    required String circleId,
    required String toId,
    required String toName,
    required DateTime time,
  }) =>
      remoteDataSource.bookAppointment(
        circleId: circleId,
        toId: toId,
        toName: toName,
        time: time,
      );

  @override
  Future<void> confirmAppointment({
    required String circleId,
    required String appointmentId,
  }) =>
      remoteDataSource.confirmAppointment(
        circleId: circleId,
        appointmentId: appointmentId,
      );

  @override
  Future<List<Appointment>> getMyAppointments(String circleId) =>
      remoteDataSource.getMyAppointments(circleId);
}
