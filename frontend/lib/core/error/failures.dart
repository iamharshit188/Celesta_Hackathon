import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

// General failures
class ServerFailure extends Failure {
  final String message;
  final int? statusCode;

  const ServerFailure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class CacheFailure extends Failure {
  final String message;

  const CacheFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthenticationFailure extends Failure {
  final String message;

  const AuthenticationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class PermissionFailure extends Failure {
  final String message;

  const PermissionFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class UnknownFailure extends Failure {
  final String message;

  const UnknownFailure({required this.message});

  @override
  List<Object> get props => [message];
}

// Specific failures for fact-checking
class AnalysisFailure extends Failure {
  final String message;
  final String? inputText;

  const AnalysisFailure({
    required this.message,
    this.inputText,
  });

  @override
  List<Object> get props => [message, inputText ?? ''];
}

class CrawlerFailure extends Failure {
  final String message;
  final String? url;

  const CrawlerFailure({
    required this.message,
    this.url,
  });

  @override
  List<Object> get props => [message, url ?? ''];
}

class ModelLoadFailure extends Failure {
  final String message;

  const ModelLoadFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class SpeechRecognitionFailure extends Failure {
  final String message;

  const SpeechRecognitionFailure({required this.message});

  @override
  List<Object> get props => [message];
}
