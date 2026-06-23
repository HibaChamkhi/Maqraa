import '../../domain/auth/models/app_user.dart';
import '../../domain/circle/models/circle.dart';
import '../../domain/circle/repositories/circle_repository.dart';
import '../../domain/notification/models/app_notification.dart';
import '../../domain/notification/repositories/notification_repository.dart';
import '../di/injection.dart';

/// Sends a notification to every active student of [circleId].
///
/// Best-effort: failures per student are swallowed so one bad write doesn't
/// abort the rest. Used when a session/schedule changes (cancel / move).
Future<void> notifyCircleStudents({
  required String circleId,
  required String title,
  required String body,
  NotificationType type = NotificationType.circleUpcoming,
}) async {
  try {
    final members = await getIt<CircleRepository>().getMembers(circleId);
    final repo = getIt<NotificationRepository>();
    for (final m in members) {
      if (m.role != UserRole.student || m.status != MemberStatus.active) {
        continue;
      }
      try {
        await repo.createNotification(
          title: title,
          body: body,
          type: type,
          recipientId: m.uid,
        );
      } catch (_) {/* skip this student, keep going */}
    }
  } catch (_) {/* couldn't load members — give up quietly */}
}
