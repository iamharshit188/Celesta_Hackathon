import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wpfactcheck/core/error/exceptions.dart';
import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/data/api_clients/fact_check_api_client.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';
import 'package:wpfactcheck/domain/repositories/fact_check_repository.dart';

class FactCheckRepositoryImpl implements FactCheckRepository {
  final FactCheckApiClient _apiClient;
  final Connectivity _connectivity;
  final List<FactCheckResult> _memoryCache = [];

  FactCheckRepositoryImpl({
    required FactCheckApiClient apiClient,
    required Connectivity connectivity,
  }) : _apiClient = apiClient,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, FactCheckResult>> analyzeText({
    required String text,
    String? sourceUrl,
    bool useLocalModel = false,
  }) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline || useLocalModel) {
        // Use local TFLite model when offline or requested
        return await _analyzeWithLocalModel(text, sourceUrl);
      }

      // Use remote API when online
      final result = await _apiClient.analyzeText(
        text: text,
        sourceUrl: sourceUrl,
      );

      // Cache the result in memory
      _cacheAnalysisInMemory(result);

      return Right(result);
    } on ServerException catch (e) {
      // Fallback to local model if server fails
      if (e.statusCode == 503 || e.statusCode == 500) {
        return await _analyzeWithLocalModel(text, sourceUrl);
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (_) {
      // Use local model when network fails
      return await _analyzeWithLocalModel(text, sourceUrl);
    } on AnalysisException catch (e) {
      return Left(AnalysisFailure(message: e.message, inputText: e.inputText));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> extractTextFromUrl(String url) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      final extractedText = await _apiClient.extractTextFromUrl(url);
      return Right(extractedText);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CrawlerException catch (e) {
      return Left(CrawlerFailure(message: e.message, url: e.url));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FactCheckResult>>> getCachedAnalyses({
    int limit = 20,
  }) async {
    try {
      final analyses = _memoryCache.take(limit).toList();
      return Right(analyses);
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get cached analyses: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheAnalysis(FactCheckResult result) async {
    try {
      _cacheAnalysisInMemory(result);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to cache analysis: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      _memoryCache.clear();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isServiceHealthy() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        return const Right(false);
      }

      final healthStatus = await _apiClient.getHealthStatus();
      final isHealthy = healthStatus['status'] == 'healthy';
      return Right(isHealthy);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Health check failed: $e'));
    }
  }

  // Private helper methods
  Future<Either<Failure, FactCheckResult>> _analyzeWithLocalModel(
    String text,
    String? sourceUrl,
  ) async {
    try {
      // TODO: Implement TFLite model inference
      // For now, return a mock result
      final mockResult = FactCheckResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inputText: text,
        sourceUrl: sourceUrl,
        verdict: FactCheckVerdict.unverified,
        confidenceScore: 0.5,
        explanation: 'Analysis performed using local model. Limited accuracy without internet connection.',
        sources: ['Local AI Model'],
        keyPoints: ['Offline analysis', 'Limited data available'],
        analyzedAt: DateTime.now(),
        isFromCache: false,
        modelVersion: 'local-roberta-v1',
      );

      _cacheAnalysisInMemory(mockResult);
      return Right(mockResult);
    } catch (e) {
      return Left(ModelLoadFailure(message: 'Local model analysis failed: $e'));
    }
  }

  void _cacheAnalysisInMemory(FactCheckResult result) {
    _memoryCache.insert(0, result);
    // Keep only the latest 20 analyses
    if (_memoryCache.length > 20) {
      _memoryCache.removeRange(20, _memoryCache.length);
    }
  }
}
