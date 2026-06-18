import 'package:flutter/material.dart';

import '../../../domain/notification/models/app_notification.dart';
import '../../profile/pages/profile_theme.dart';

/// Icon + colour for each notification type (matches the mockups).
class NotifVisual {
  final IconData icon;
  final Color color;
  const NotifVisual(this.icon, this.color);

  static const _green = ProfileTheme.green;
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFE2574C);
  static const _gold = Color(0xFFE0A82E);
  static const _blue = Color(0xFF3B82A0);

  static NotifVisual of(NotificationType type) {
    switch (type) {
      case NotificationType.studentJoined:
        return const NotifVisual(Icons.person_add_alt_1_outlined, _green);
      case NotificationType.homework:
        return const NotifVisual(Icons.assignment_turned_in_outlined, _amber);
      case NotificationType.circleUpcoming:
        return const NotifVisual(Icons.schedule_outlined, _green);
      case NotificationType.report:
        return const NotifVisual(Icons.notifications_active_outlined, _amber);
      case NotificationType.adminMessage:
        return const NotifVisual(Icons.description_outlined, _red);
      case NotificationType.prayer:
        return const NotifVisual(Icons.mosque_outlined, _green);
      case NotificationType.exam:
        return const NotifVisual(Icons.event_note_outlined, _blue);
      case NotificationType.achievement:
        return const NotifVisual(Icons.workspace_premium_outlined, _gold);
      case NotificationType.teacherMessage:
        return const NotifVisual(Icons.mail_outline, _green);
      case NotificationType.attendance:
        return const NotifVisual(Icons.bolt_outlined, _green);
      case NotificationType.general:
        return const NotifVisual(Icons.notifications_outlined, _green);
    }
  }
}

/// "منذ ١٠ دقائق" style relative time in Arabic.
String arabicTimeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return 'منذ ${(diff.inDays / 30).floor()} شهر';
}
