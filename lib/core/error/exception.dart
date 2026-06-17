class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException({required this.message});
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException({required this.message});
}

class ServerErrorException implements Exception {
  final String message;
  ServerErrorException({required this.message});
}

class UnknownNetworkException implements Exception {
  final String message;
  UnknownNetworkException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
}

class ServerException implements Exception {
  final String message;
  ServerException({required this.message});
}
