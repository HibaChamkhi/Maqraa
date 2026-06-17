import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/interceptor/AuthInterceptor.dart';

abstract class AuthPrefUtils {
  String? getToken();

  String? getRefreshToken();

  void setToken(String token);

  void setRefreshToken(String refreshToken);

  void clear();
}

@Injectable(as: AuthPrefUtils)
class PrefUtilsImpl implements AuthPrefUtils {
  final SharedPreferences sharedPreferences;
  final AuthenticatedHttpClient httpClientInterceptor;

  PrefUtilsImpl({required this.sharedPreferences, required this.httpClientInterceptor});

  @override
  String? getToken() {
    return sharedPreferences.getString("token");
  }

  @override
  void setToken(String token) async {
    await sharedPreferences.setString("token", token);
  }

  @override
  String? getRefreshToken() {
    return sharedPreferences.getString("refreshToken");
  }

  @override
  void setRefreshToken(String refreshToken) {
    sharedPreferences.setString("refreshToken", refreshToken);
  }

  @override
  void clear() async {
    sharedPreferences.remove("token");
    sharedPreferences.remove("refreshToken");
  }
}
