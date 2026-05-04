abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection.',
    super.code,
  });
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException({required super.message, this.statusCode, super.code});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  });
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Resource not found.', super.code});
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Failed to load cached data.',
    super.code,
  });
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
}
