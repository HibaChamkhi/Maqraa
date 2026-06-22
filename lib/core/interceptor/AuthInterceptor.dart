import 'package:http_interceptor/http_interceptor.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';


@Singleton()
class AuthenticatedHttpClient extends InterceptorContract {
  SharedPreferences sharedPref;

  AuthenticatedHttpClient({required this.sharedPref});

  String get userAccessToken {
    return sharedPref.getString("token") ?? "";
  }

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    // intercept each call and add the Authorization header if token is available
    request.headers['Content-Type'] = 'application/json; charset=utf-8';
    request.headers['Accept'] = 'application/json';

    if (userAccessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $userAccessToken';
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async {
    return response;
  }
}
