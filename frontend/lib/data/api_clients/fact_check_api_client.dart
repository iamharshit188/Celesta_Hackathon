import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/fact_check_result.dart';

class FactCheckApiClient {
  final Dio _dio;
  final String _baseUrl;

  FactCheckApiClient({
    required Dio dio,
    required String baseUrl,
  }) : _dio = dio, _baseUrl = baseUrl {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) {
          final exception = _handleDioError(error);
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: exception,
          ));
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[FactCheckAPI] $obj'),
    ));
  }

  Future<FactCheckResult> analyzeText({
    required String text,
    String? sourceUrl,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/analyze',
        data: {
          'text': text,
          'source_url': sourceUrl,
          'model_version': 'roberta-v1',
        },
        options: Options(
          sendTimeout: AppConstants.networkTimeout,
          receiveTimeout: AppConstants.networkTimeout,
        ),
      );

      if (response.statusCode == 200) {
        return FactCheckResult.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Analysis failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw AnalysisException(
        message: 'Unexpected error during analysis: $e',
        inputText: text,
      );
    }
  }

  Future<String> extractTextFromUrl(String url) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/extract',
        data: {'url': url},
        options: Options(
          sendTimeout: AppConstants.networkTimeout,
          receiveTimeout: AppConstants.networkTimeout,
        ),
      );

      if (response.statusCode == 200) {
        return response.data['extracted_text'] ?? '';
      } else {
        throw ServerException(
          message: 'Failed to extract text from URL',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw CrawlerException(
        message: 'Failed to extract text: $e',
        url: url,
      );
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/healthz',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException(
          message: 'Health check failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Health check error: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Request timeout');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        
        if (statusCode == 401) {
          return const AuthenticationException(message: 'Unauthorized access');
        } else if (statusCode == 429) {
          return const ServerException(message: 'Rate limit exceeded');
        } else if (statusCode == 503) {
          return const ServerException(message: 'Service temporarily unavailable');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: 'Server error: $message',
            statusCode: statusCode,
          );
        } else {
          return ServerException(
            message: message,
            statusCode: statusCode,
          );
        }
      
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request cancelled');
      
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection');
      
      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'Certificate error');
      
      case DioExceptionType.unknown:
        return NetworkException(message: 'Network error: ${error.message}');
    }
  }
}
