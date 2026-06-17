import '../../auth/models/app_user.dart';
import '../models/circle.dart';

/// Circle management contract (US-03/04/05/29/38/39/40/41).
/// Implemented with Cloud Firestore in the data layer.
abstract class CircleRepository {
  /// US-03: create a circle. Generates a unique 6-char invite code, sets the
  /// circle gender to the teacher's gender, and adds the teacher as an active
  /// member. Returns the created [Circle].
  Future<Circle> createCircle({
    required String name,
    required Privacy privacy,
  });

  /// US-04 / US-29: join a circle directly via its invite code. Adds the
  /// current user as an active student member. Returns the joined [Circle].
  Future<Circle> joinByInviteCode(String inviteCode);

  /// US-39: send a join request to a (public) circle — creates a member doc
  /// with status 'pending'.
  Future<void> requestToJoin(String circleId);

  /// US-39: discover public circles matching the current user's gender.
  Future<List<Circle>> discoverPublicCircles();

  /// US-05: list all members of a circle (active + pending).
  Future<List<CircleMember>> getMembers(String circleId);

  /// US-41: list pending join requests for a circle.
  Future<List<CircleMember>> getPendingRequests(String circleId);

  /// US-41: accept a pending member — sets status to 'active'.
  Future<void> acceptRequest({required String circleId, required String uid});

  /// US-41: reject a pending member — deletes the member doc.
  Future<void> rejectRequest({required String circleId, required String uid});

  /// US-40: promote a member to supervisor — adds uid to supervisorIds and
  /// sets the member role to 'supervisor'.
  Future<void> promoteToSupervisor({
    required String circleId,
    required String uid,
  });

  /// US-38: update the circle privacy setting.
  Future<void> updatePrivacy({
    required String circleId,
    required Privacy privacy,
  });

  /// Fetch a single circle by id.
  Future<Circle> getCircle(String circleId);

  /// Circles the current user is a member of (used by the home screen).
  Future<List<Circle>> getMyCircles();
}
