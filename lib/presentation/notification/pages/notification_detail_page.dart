import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/notification/models/app_notification.dart';
import '../../profile/pages/profile_theme.dart';
import 'notification_ui.dart';

/// تفاصيل الإشعار — single notification view.
class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final v = NotifVisual.of(notification.type);
    final date = notification.createdAt;
    final timeStr = date != null ? DateFormat('h:mm a', 'ar').format(date) : '—';
    final dateStr =
        date != null ? DateFormat('d MMMM yyyy - h:mm a', 'ar').format(date) : '—';

    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text('تفاصيل الإشعار',
                        textAlign: TextAlign.center,
                        style: ProfileTheme.appBarTitle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: ProfileTheme.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: v.color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(v.icon, color: v.color, size: 44),
                    ),
                    const SizedBox(height: 18),
                    Text(notification.title,
                        textAlign: TextAlign.center,
                        style: ProfileTheme.name.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(notification.body,
                        textAlign: TextAlign.center, style: ProfileTheme.hint),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: ProfileTheme.cardShadow,
                      child: Column(
                        children: [
                          _Line(label: 'الوقت', value: timeStr),
                          const Divider(height: 22, color: ProfileTheme.border),
                          _Line(label: 'التاريخ', value: dateStr),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ProfileTheme.primaryButton,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('حسناً'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ProfileTheme.hint),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: ProfileTheme.ink, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
