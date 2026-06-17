import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../domain/reminder/models/reminder_settings.dart';

/// Local persistence of daily-reminder settings (US-13).
abstract class ReminderPrefUtils {
  ReminderSettings getSettings();
  void saveSettings(ReminderSettings settings);
}

@Injectable(as: ReminderPrefUtils)
class ReminderPrefUtilsImpl implements ReminderPrefUtils {
  final SharedPreferences sharedPreferences;

  ReminderPrefUtilsImpl({required this.sharedPreferences});

  static const _enabled = 'reminder_enabled';
  static const _hour = 'reminder_hour';
  static const _minute = 'reminder_minute';

  @override
  ReminderSettings getSettings() {
    return ReminderSettings(
      enabled: sharedPreferences.getBool(_enabled) ?? false,
      hour: sharedPreferences.getInt(_hour) ?? 20,
      minute: sharedPreferences.getInt(_minute) ?? 0,
    );
  }

  @override
  void saveSettings(ReminderSettings settings) {
    sharedPreferences
      ..setBool(_enabled, settings.enabled)
      ..setInt(_hour, settings.hour)
      ..setInt(_minute, settings.minute);
  }
}
