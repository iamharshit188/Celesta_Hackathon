class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;

  const ValidationException({required this.message});

  @override
  String toString() => 'ValidationException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException({required this.message});

  @override
  String toString() => 'AuthenticationException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}

class AnalysisException implements Exception {
  final String message;
  final String? inputText;

  const AnalysisException({
    required this.message,
    this.inputText,
  });

  @override
  String toString() => 'AnalysisException: $message';
}

class CrawlerException implements Exception {
  final String message;
  final String? url;

  const CrawlerException({
    required this.message,
    this.url,
  });

  @override
  String toString() => 'CrawlerException: $message (URL: $url)';
}

class ModelLoadException implements Exception {
  final String message;

  const ModelLoadException({required this.message});

  @override
  String toString() => 'ModelLoadException: $message';
}

class SpeechRecognitionException implements Exception {
  final String message;

  const SpeechRecognitionException({required this.message});

  @override
  String toString() => 'SpeechRecognitionException: $message';
}
