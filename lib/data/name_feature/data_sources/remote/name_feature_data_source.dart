import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/error_utils.dart';
import '../../../../core/interceptor/HttpInterceptor.dart';
import '../../../../core/network/network_info.dart';
import '../local/name_feature_prefutils.dart';

@injectable
class NameFeatureRemoteDataSource {
  final HttpInterceptor httpClient;
  final PrefUtils prefUtils;
  final NetworkInfo networkInfo;

  NameFeatureRemoteDataSource({
    required this.httpClient,
    required this.prefUtils,
    required this.networkInfo,
  });

  Future<Either<Exception, Unit>> create(Map<String, dynamic> data) async {
    return await performNetworkRequest<Unit>(
      operation: () async => httpClient.httpInterceptor().post(
        Uri.parse("NameFeature/create"),
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"},
      ),
      handleResponse: (_) {
        return unit;
      },
      networkInfo: networkInfo,
    );
  }

  Future<Either<Exception, Map<String, dynamic>>> read(String id) async {
    return await performNetworkRequest<Map<String, dynamic>>(
      operation: () async => httpClient.httpInterceptor().get(
        Uri.parse("NameFeature/read/$id"),
      ),
      handleResponse: (response) {
        // final json = jsonDecode(response.body);
        return json as Map<String, dynamic>;
      },
      networkInfo: networkInfo,
    );
  }

  Future<Either<Exception, Unit>> update(String id, Map<String, dynamic> data) async {
    return await performNetworkRequest<Unit>(
      operation: () async => httpClient.httpInterceptor().put(
        Uri.parse("NameFeature/update/$id"),
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"},
      ),
      handleResponse: (_) {
        return unit;
      },
      networkInfo: networkInfo,
    );
  }

  Future<Either<Exception, Unit>> delete(String id) async {
    return await performNetworkRequest<Unit>(
      operation: () async => httpClient.httpInterceptor().delete(
        Uri.parse("NameFeature/delete/$id"),
      ),
      handleResponse: (_) {
        return unit;
      },
      networkInfo: networkInfo,
    );
  }
}
