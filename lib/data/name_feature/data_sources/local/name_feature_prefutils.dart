import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/interceptor/AuthInterceptor.dart';

abstract class PrefUtils {
  void setPrefExample(String prefExample);
  String? getPrefExample();
}

@Injectable(as: PrefUtils)
class PrefUtilsImpl implements PrefUtils {
  final SharedPreferences sharedPreferences;
  final AuthenticatedHttpClient httpClientInterceptor;

  PrefUtilsImpl(
      {required this.sharedPreferences, required this.httpClientInterceptor});

  @override
  void setPrefExample(String prefExample) {
    sharedPreferences.setString("prefExample", prefExample);
  }

  @override
  String? getPrefExample() {
    return sharedPreferences.getString("prefExample");
  }
}
