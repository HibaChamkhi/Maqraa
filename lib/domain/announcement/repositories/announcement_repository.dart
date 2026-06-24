import '../models/announcement.dart';

/// Announcement contract (US-14).
abstract class AnnouncementRepository {
  /// US-14: teacher/supervisor posts an announcement to the circle.
  Future<Announcement> postAnnouncement({
    required String circleId,
    required String text,
  });

  /// US-14: feed of announcements, newest first.
  Future<List<Announcement>> getAnnouncements(String circleId);
}
