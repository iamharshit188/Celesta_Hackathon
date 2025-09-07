import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../data/dto/news_response_dto.dart';

class NewsApiClient {
  final Dio _dio;
  final String _apiKey;

  NewsApiClient({
    required Dio dio,
    required String apiKey,
  }) : _dio = dio, _apiKey = apiKey {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.queryParameters['apiKey'] = _apiKey;
          options.queryParameters['country'] = AppConstants.newsApiCountry;
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
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrint('[NewsAPI] $obj'),
    ));
  }

  Future<NewsResponseDto> getTopHeadlines({
    String? category,
    int page = 1,
    int pageSize = AppConstants.newsApiPageSize,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.newsApiBaseUrl}/top-headlines',
        queryParameters: {
          'category': category,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return NewsResponseDto.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch news',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<NewsResponseDto> searchNews({
    required String query,
    String? sortBy,
    int page = 1,
    int pageSize = AppConstants.newsApiPageSize,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.newsApiBaseUrl}/everything',
        queryParameters: {
          'q': query,
          'sortBy': sortBy ?? 'publishedAt',
          'page': page,
          'pageSize': pageSize,
          'language': 'en',
        },
      );

      if (response.statusCode == 200) {
        return NewsResponseDto.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to search news',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<NewsResponseDto> getNewsBySource({
    required String sourceId,
    int page = 1,
    int pageSize = AppConstants.newsApiPageSize,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.newsApiBaseUrl}/everything',
        queryParameters: {
          'sources': sourceId,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return NewsResponseDto.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to fetch news from source',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.error is Exception) {
        throw e.error as Exception;
      }
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timeout');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        
        if (statusCode == 401) {
          return const AuthenticationException(message: 'Invalid API key');
        } else if (statusCode == 429) {
          return const ServerException(message: 'Rate limit exceeded');
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
