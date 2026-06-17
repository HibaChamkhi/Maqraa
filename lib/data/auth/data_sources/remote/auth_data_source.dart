import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/error_utils.dart';
import '../../../../core/interceptor/HttpInterceptor.dart';
import '../../../../core/network/network_info.dart';
import '../local/auth_prefutils.dart';

@injectable
class AuthRemoteDataSource {
  final HttpInterceptor httpClient;
  final AuthPrefUtils prefUtils;
  final NetworkInfo networkInfo;

  AuthRemoteDataSource({
    required this.httpClient,
    required this.prefUtils,
    required this.networkInfo,
  });

  Future<Either<Exception, Unit>> register(
      Map<String, dynamic> userInfo) async {
    final body = json.encode(userInfo);
    const String baseUrl = "BASE_URL"; // Replace with your actual base URL

    return await performNetworkRequest<Unit>(
      operation: () async => httpClient.httpInterceptor().post(
            Uri.parse(baseUrl),
            headers: {"Content-Type": "application/json"},
            body: body,
          ),
      handleResponse: (_) => unit,
      networkInfo: networkInfo,
    );
  }

  Future<Either<Exception, Unit>> login(String email, String password) async {
    final body = json.encode({"email": email, "password": password});
    const String baseUrl = "BASE_URL"; // Replace with your actual base URL

    return await performNetworkRequest<Unit>(
      operation: () async => httpClient.httpInterceptor().post(
            Uri.parse(baseUrl),
            headers: {"Content-Type": "application/json"},
            body: body,
          ),
      handleResponse: (responseJson) {
        final data = responseJson['data']?['tokens'];
        if (data != null) {
          prefUtils
            ..clear()
            ..setToken(data['accessToken'])
            ..setRefreshToken(data['refreshToken']);
          return unit;
        } else {
          throw Exception("Login failed: no tokens found");
        }
      },
      networkInfo: networkInfo,
    );
  }

  Future<Either<Exception, Unit>> logout() async {
    return await performNetworkRequest<Unit>(
      operation: () async => httpClient.httpInterceptor().delete(
            Uri.parse("auth/logout"),
          ),
      handleResponse: (_) {
        prefUtils.clear();
        return unit;
      },
      networkInfo: networkInfo,
    );
  }
}
