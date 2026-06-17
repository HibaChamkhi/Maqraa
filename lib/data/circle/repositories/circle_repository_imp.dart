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
  Future<Circle> getCircle(String circleId) =>
      remoteDataSource.getCircle(circleId);

  @override
  Future<List<Circle>> getMyCircles() => remoteDataSource.getMyCircles();
}
