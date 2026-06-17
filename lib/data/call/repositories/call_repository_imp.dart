import 'package:injectable/injectable.dart';

import '../../../domain/call/models/weekly_call.dart';
import '../../../domain/call/repositories/call_repository.dart';
import '../data_sources/remote/call_data_source.dart';

@Injectable(as: CallRepository)
class CallRepositoryImpl implements CallRepository {
  final CallRemoteDataSource remoteDataSource;

  CallRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WeeklyCall> scheduleCall({
    required String circleId,
    required String title,
    required DateTime time,
    required String link,
  }) =>
      remoteDataSource.scheduleCall(
        circleId: circleId,
        title: title,
        time: time,
        link: link,
      );

  @override
  Future<List<WeeklyCall>> getCalls(String circleId) =>
      remoteDataSource.getCalls(circleId);

  @override
  Future<void> confirmAttendance({
    required String circleId,
    required String callId,
    required bool present,
  }) =>
      remoteDataSource.confirmAttendance(
        circleId: circleId,
        callId: callId,
        present: present,
      );

  @override
  Future<bool> myAttendance({
    required String circleId,
    required String callId,
  }) =>
      remoteDataSource.myAttendance(circleId: circleId, callId: callId);

  @override
  Future<List<CallAttendance>> getAttendance({
    required String circleId,
    required String callId,
  }) =>
      remoteDataSource.getAttendance(circleId: circleId, callId: callId);
}
