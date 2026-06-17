import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for local reminders
/// (US-13 daily task reminder, US-15 exam reminder).
///
/// NATIVE SETUP (pending — document only, no native files touched here):
///  - Android: add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
///    and `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` to AndroidManifest.xml; ensure
///    `flutterLocalNotificationsPlugin` icon `@mipmap/ic_launcher` exists.
///  - iOS: enable Push/Local notification capability; the plugin requests
///    permission at [init] via `requestPermissions`.
///  - The `timezone` package is pulled in transitively by
///    `flutter_local_notifications`; [init] initialises its database.
@lazySingleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  static const String _dailyChannelId = 'wesal_daily';
  static const String _dailyChannelName = 'التذكير اليومي';
  static const String _examChannelId = 'wesal_exam';
  static const String _examChannelName = 'تذكير الاختبار';

  /// Stable notification ids so reminders can be re-scheduled / cancelled.
  static const int dailyReminderId = 1001;
  static const int examReminderBaseId = 2000;

  /// Initialise the plugin + timezone database. Safe to call multiple times.
  Future<void> init() async {
    if (_initialised) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    _initialised = true;
  }

  /// Schedule a repeating DAILY reminder (US-13) at [hour]:[minute].
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    String title = 'وردك اليومي',
    String body = 'حان وقت إنجاز مهمتك اليومية في الحلقة',
    int id = dailyReminderId,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  /// Schedule a ONE-OFF reminder at the given [when] (US-15 exam reminder).
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _examChannelId,
          _examChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel a single scheduled notification by [id].
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Next [tz.TZDateTime] for the given local time (today if still ahead,
  /// otherwise tomorrow).
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
