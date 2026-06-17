import 'package:injectable/injectable.dart';

import '../../../domain/circle/models/circle.dart';
import '../../../domain/partner/models/partner.dart';
import '../../../domain/partner/repositories/partner_repository.dart';
import '../data_sources/remote/partner_data_source.dart';

@Injectable(as: PartnerRepository)
class PartnerRepositoryImpl implements PartnerRepository {
  final PartnerRemoteDataSource remoteDataSource;

  PartnerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Pair> pairMembers({
    required String circleId,
    required CircleMember a,
    required CircleMember b,
  }) =>
      remoteDataSource.pairMembers(circleId: circleId, a: a, b: b);

  @override
  Future<List<Pair>> autoPairActiveStudents(String circleId) =>
      remoteDataSource.autoPairActiveStudents(circleId);

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
