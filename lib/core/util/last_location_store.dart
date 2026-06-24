import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last-opened circle + tab so a web refresh restores it
/// instead of dropping back to the home page.
class LastLocationStore {
  static const _key = 'last_circle_location';

  static Future<void> saveCircle(String circleId, int tab) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, '$circleId|$tab');
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  /// Returns (circleId, tabIndex). circleId is null when nothing is saved.
  static Future<({String? circleId, int tab})> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    if (v == null || v.isEmpty) return (circleId: null, tab: 0);
    final parts = v.split('|');
    return (
      circleId: parts.first,
      tab: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }
}
