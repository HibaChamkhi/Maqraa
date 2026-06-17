import 'package:injectable/injectable.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../domain/reminder/models/reminder_settings.dart';
import '../../../domain/reminder/repositories/reminder_repository.dart';
import '../data_sources/local/reminder_prefutils.dart';

@Injectable(as: ReminderRepository)
class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderPrefUtils prefUtils;
  final NotificationService notificationService;

  ReminderRepositoryImpl({
    required this.prefUtils,
    required this.notificationService,
  });

  @override
  Future<ReminderSettings> getSettings() async => prefUtils.getSettings();

  @override
  Future<void> saveDailyReminder(ReminderSettings settings) async {
    prefUtils.saveSettings(settings);
    if (settings.enabled) {
      await notificationService.scheduleDaily(
        hour: settings.hour,
        minute: settings.minute,
      );
    } else {
      await notificationService.cancel(NotificationService.dailyReminderId);
    }
  }

  @override
  Future<void> scheduleExamReminder({
    required String examId,
    required String examTitle,
    required DateTime examTime,
    Duration before = const Duration(hours: 1),
  }) async {
    final when = examTime.subtract(before);
    if (when.isBefore(DateTime.now())) return; // too late to remind
    await notificationService.scheduleAt(
      id: _examNotificationId(examId),
      when: when,
      title: 'تذكير بالاختبار',
      body: 'اقترب موعد اختبار «$examTitle»',
    );
  }

  @override
  Future<void> cancelExamReminder(String examId) async {
    await notificationService.cancel(_examNotificationId(examId));
  }

  /// Derive a stable notification id for an exam from its id.
  int _examNotificationId(String examId) {
    return NotificationService.examReminderBaseId +
        (examId.hashCode & 0x7fff);
  }
}
