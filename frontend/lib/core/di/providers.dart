import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/data/api_clients/fact_check_api_client.dart';
import 'package:wpfactcheck/data/api_clients/chat_api_client.dart';
import 'package:wpfactcheck/data/repositories/fact_check_repository_impl.dart';
import 'package:wpfactcheck/domain/repositories/fact_check_repository.dart';
import 'package:wpfactcheck/domain/use_cases/fact_check_use_case.dart';

// Core providers
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl = AppConstants.factCheckBaseUrl;
  dio.options.connectTimeout = AppConstants.networkTimeout;
  dio.options.receiveTimeout = AppConstants.networkTimeout;
  return dio;
});

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

// Database provider - using a temporary workaround for mock database
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Database not needed for current implementation');
});

// API client providers
final factCheckApiClientProvider = Provider<FactCheckApiClient>((ref) {
  return FactCheckApiClient(
    dio: ref.watch(dioProvider),
    baseUrl: AppConstants.factCheckBaseUrl,
  );
});

final chatApiClientProvider = Provider<ChatApiClient>((ref) {
  return ChatApiClient(
    dio: ref.watch(dioProvider),
    baseUrl: AppConstants.chatBaseUrl,
  );
});

// Repository providers
final factCheckRepositoryProvider = Provider<FactCheckRepository>((ref) {
  return FactCheckRepositoryImpl(
    apiClient: ref.watch(factCheckApiClientProvider),
    connectivity: ref.watch(connectivityProvider),
  );
});

// Use case providers
final analyzeTextUseCaseProvider = Provider<AnalyzeTextUseCase>((ref) {
  return AnalyzeTextUseCase(ref.watch(factCheckRepositoryProvider));
});

final extractTextFromUrlUseCaseProvider = Provider<ExtractTextFromUrlUseCase>((ref) {
  return ExtractTextFromUrlUseCase(ref.watch(factCheckRepositoryProvider));
});

final checkServiceHealthUseCaseProvider = Provider<CheckServiceHealthUseCase>((ref) {
  return CheckServiceHealthUseCase(ref.watch(factCheckRepositoryProvider));
});
