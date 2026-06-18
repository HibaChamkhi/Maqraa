import 'package:injectable/injectable.dart';

import '../../../domain/circle/models/circle.dart';
import '../../../domain/circle/repositories/circle_repository.dart';
import '../data_sources/remote/circle_data_source.dart';

@Injectable(as: CircleRepository)
class CircleRepositoryImpl implements CircleRepository {
  final CircleRemoteDataSource remoteDataSource;

  CircleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Circle> createCircle({
    required String name,
    required Privacy privacy,
  }) =>
      remoteDataSource.createCircle(name: name, privacy: privacy);

  @override
  Future<Circle> joinByInviteCode(String inviteCode) =>
      remoteDataSource.joinByInviteCode(inviteCode);

  @override
  Future<void> requestToJoin(String circleId) =>
      remoteDataSource.requestToJoin(circleId);

  @override
  Future<List<Circle>> discoverPublicCircles() =>
      remoteDataSource.discoverPublicCircles();

  @override
  Future<List<CircleMember>> getMembers(String circleId) =>
      remoteDataSource.getMembers(circleId);

  @override
  Stream<List<CircleMember>> membersStream(String circleId) =>
      remoteDataSource.membersStream(circleId);

  @override
  Future<List<CircleMember>> getPendingRequests(String circleId) =>
      remoteDataSource.getPendingRequests(circleId);

  @override
  Future<void> acceptRequest({
    required String circleId,
    required String uid,
  }) =>
      remoteDataSource.acceptRequest(circleId: circleId, uid: uid);

  @override
  Future<void> rejectRequest({
    required String circleId,
    required String uid,
  }) =>
      remoteDataSource.rejectRequest(circleId: circleId, uid: uid);

  @override
  Future<void> promoteToSupervisor({
    required String circleId,
    required String uid,
  }) =>
      remoteDataSource.promoteToSupervisor(circleId: circleId, uid: uid);

  @override
  Future<void> updatePrivacy({
    required String circleId,
    required Privacy privacy,
  }) =>
      remoteDataSource.updatePrivacy(circleId: circleId, privacy: privacy);

  @override
  Future<void> updateDescription({
    required String circleId,
    required String description,
  }) =>
      remoteDataSource.updateDescription(
          circleId: circleId, description: description);

  @override
  Future<void> updateRiwayah({
    required String circleId,
    required String riwayah,
  }) =>
      remoteDataSource.updateRiwayah(circleId: circleId, riwayah: riwayah);

  @override
  Future<void> updateLevel({
    required String circleId,
    required String unit,
    String surah = '',
    int? fromAyah,
    int? toAyah,
  }) =>
      remoteDataSource.updateLevel(
        circleId: circleId,
        unit: unit,
        surah: surah,
        fromAyah: fromAyah,
        toAyah: toAyah,
      );

  @override
  Future<void> updateSchedule({
    required String circleId,
    required Map<String, String> dayTimes,
    required int durationMinutes,
  }) =>
      remoteDataSource.updateSchedule(
        circleId: circleId,
        dayTimes: dayTimes,
        durationMinutes: durationMinutes,
      );

  @override
  Future<Circle> getCircle(String circleId) =>
      remoteDataSource.getCircle(circleId);

  @override
  Future<List<Circle>> getMyCircles() => remoteDataSource.getMyCircles();

  @override
  Future<CircleMember> addStudentManually({
    required String circleId,
    required String name,
    int? juz,
  }) =>
      remoteDataSource.addStudentManually(
          circleId: circleId, name: name, juz: juz);

  @override
  Future<CircleMember> addStudentByContact({
    required String circleId,
    required String contact,
  }) =>
      remoteDataSource.addStudentByContact(
          circleId: circleId, contact: contact);

  @override
  Future<void> updateMember({
    required String circleId,
    required String uid,
    AttendanceState? attendance,
    PerformanceTag? performance,
    int? memorizedPages,
    int? juz,
    bool touchRecitation = false,
  }) =>
      remoteDataSource.updateMember(
        circleId: circleId,
        uid: uid,
        attendance: attendance,
        performance: performance,
        memorizedPages: memorizedPages,
        juz: juz,
        touchRecitation: touchRecitation,
      );

  @override
  Future<void> removeMember({required String circleId, required String uid}) =>
      remoteDataSource.removeMember(circleId: circleId, uid: uid);
}
