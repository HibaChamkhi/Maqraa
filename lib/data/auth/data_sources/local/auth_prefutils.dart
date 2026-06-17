import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache of identity info. With Firebase the session token is handled by
/// the SDK, so here we only cache lightweight profile facts (uid, role, gender)
/// for fast startup routing.
abstract class AuthPrefUtils {
  String? getUid();
  String? getRole();
  String? getGender();
  String? getActiveCircleId();
  void setUid(String? uid);
  void setRole(String? role);
  void setGender(String? gender);
  void setActiveCircleId(String? circleId);
  void clear();
}

@Injectable(as: AuthPrefUtils)
class AuthPrefUtilsImpl implements AuthPrefUtils {
  final SharedPreferences sharedPreferences;

  AuthPrefUtilsImpl({required this.sharedPreferences});

  static const _uid = 'uid';
  static const _role = 'role';
  static const _gender = 'gender';
  static const _circle = 'activeCircleId';

  @override
  String? getUid() => sharedPreferences.getString(_uid);

  @override
  String? getRole() => sharedPreferences.getString(_role);

  @override
  String? getGender() => sharedPreferences.getString(_gender);

  @override
  String? getActiveCircleId() => sharedPreferences.getString(_circle);

  @override
  void setActiveCircleId(String? circleId) {
    if (circleId == null) {
      sharedPreferences.remove(_circle);
    } else {
      sharedPreferences.setString(_circle, circleId);
    }
  }

  @override
  void setUid(String? uid) {
    if (uid == null) {
      sharedPreferences.remove(_uid);
    } else {
      sharedPreferences.setString(_uid, uid);
    }
  }

  @override
  void setRole(String? role) {
    if (role == null) {
      sharedPreferences.remove(_role);
    } else {
      sharedPreferences.setString(_role, role);
    }
  }

  @override
  void setGender(String? gender) {
    if (gender == null) {
      sharedPreferences.remove(_gender);
    } else {
      sharedPreferences.setString(_gender, gender);
    }
  }

  @override
  void clear() {
    sharedPreferences
      ..remove(_uid)
      ..remove(_role)
      ..remove(_gender)
      ..remove(_circle);
  }
}
