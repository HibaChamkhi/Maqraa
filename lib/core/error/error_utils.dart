import 'dart:convert';
import 'package:http/http.dart';
import '../network/network_info.dart';
import 'exception.dart';
import 'package:dartz/dartz.dart';


//data source
// Future<T> handleError<T>(Future<T> Function() operation) async {
//   try {
//     return await operation();
//   } catch (e) {
//     if (e is Exception) {
//       throw ServerException(message: e.toString());
//     }
//     else {
//       throw ServerException(message: e.toString());
//     }
//   }
// }
String mapExceptionToMessage(Exception e) {
  if (e is ServerException) {
    return e.message;
  } else if (e is UnauthorizedException) {
    return e.message;
  } else if (e is BadRequestException) {
    return e.message;
  } else if (e is UnknownNetworkException) {
    return e.message;
  } else if (e is ServerErrorException) {
    return e.message;
  } else if (e is NetworkException) {
    return e.message;
  } else {
    return 'Unknown error occurred';
  }
}

String _getErrorMessage(Response response) {
  try {
    final Map<String, dynamic> decodedJson = json.decode(response.body);
    return decodedJson['message'] ?? 'An unknown error occurred';
  } catch (e) {
    return 'Failed to parse error message';
  }
}

//repo
Future<Either<Exception, T>> performNetworkRequest<T>({
  required Future<Response> Function() operation,
  required T Function(Map<String, dynamic>) handleResponse,
  required NetworkInfo networkInfo,
}) async {
  if (await networkInfo.isConnected) {
    try {
      final response = await operation();

      switch (response.statusCode) {
        case 200:
        case 201:
        case 202:
        case 204:
          final Map<String, dynamic> decodedJson = json.decode(response.body);
          return Right(handleResponse(decodedJson));

        case 401:
          throw UnauthorizedException(message: 'Unauthorized request');

        case 400:
        case 403:
        case 404:
        case 429:
          final errorMessage = _getErrorMessage(response);
          throw BadRequestException(message: errorMessage);

        case 500:
        case 502:
        case 503:
        case 504:
          throw ServerErrorException(message: 'Server error occurred');

        default:
          throw UnknownNetworkException(
            message: 'Unknown error occurred with status code ${response.statusCode}',
          );
      }
    } on FormatException catch (e) {
      return Left(ServerException(message: 'Invalid JSON format: ${e.message}'));
    } on Exception catch (e) {
      return Left(e);
    }
  } else {
    return Left(Exception('Offline Failure'));
  }
}
