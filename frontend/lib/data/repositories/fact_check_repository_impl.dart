import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wpfactcheck/core/error/exceptions.dart';
import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/data/api_clients/fact_check_api_client.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';
import 'package:wpfactcheck/domain/repositories/fact_check_repository.dart';
import 'package:sqflite/sqflite.dart';

class FactCheckRepositoryImpl implements FactCheckRepository {
  final FactCheckApiClient _apiClient;
  final Database _database;
  final Connectivity _connectivity;

  FactCheckRepositoryImpl({
    required FactCheckApiClient apiClient,
    required Database database,
    required Connectivity connectivity,
  }) : _apiClient = apiClient,
       _database = database,
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

      // Cache the result
      await _cacheAnalysis(result);

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
      final analyses = await _getCachedAnalyses(limit: limit);
      return Right(analyses);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get cached analyses: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheAnalysis(FactCheckResult result) async {
    try {
      await _cacheAnalysis(result);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to cache analysis: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _database.delete('fact_check_results');
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
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

      await _cacheAnalysis(mockResult);
      return Right(mockResult);
    } catch (e) {
      return Left(ModelLoadFailure(message: 'Local model analysis failed: $e'));
    }
  }

  Future<List<FactCheckResult>> _getCachedAnalyses({int limit = 20}) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'fact_check_results',
        orderBy: 'analyzedAt DESC',
        limit: limit,
      );

      return maps.map((map) => _mapToFactCheckResult(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached analyses: $e');
    }
  }

  Future<void> _cacheAnalysis(FactCheckResult result) async {
    try {
      final map = _mapFromFactCheckResult(result);
      await _database.insert(
        'fact_check_results',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Clean up old analyses to maintain cache limit
      await _cleanupOldAnalyses();
    } catch (e) {
      throw CacheException(message: 'Failed to cache analysis: $e');
    }
  }

  Future<void> _cleanupOldAnalyses() async {
    try {
      // Keep only the latest 20 analyses
      await _database.execute('''
        DELETE FROM fact_check_results 
        WHERE id NOT IN (
          SELECT id FROM fact_check_results 
          ORDER BY analyzedAt DESC 
          LIMIT 20
        )
      ''');
    } catch (e) {
      throw CacheException(message: 'Failed to cleanup old analyses: $e');
    }
  }

  FactCheckResult _mapToFactCheckResult(Map<String, dynamic> map) {
    return FactCheckResult(
      id: map['id'],
      inputText: map['inputText'],
      sourceUrl: map['sourceUrl'],
      verdict: _verdictFromString(map['verdict']),
      confidenceScore: map['confidenceScore'],
      explanation: map['explanation'],
      sources: (map['sources'] as String).split(','),
      keyPoints: (map['keyPoints'] as String).split(','),
      analyzedAt: DateTime.parse(map['analyzedAt']),
      isFromCache: map['isFromCache'] == 1,
      modelVersion: map['modelVersion'],
    );
  }

  Map<String, dynamic> _mapFromFactCheckResult(FactCheckResult result) {
    return {
      'id': result.id,
      'inputText': result.inputText,
      'sourceUrl': result.sourceUrl,
      'verdict': result.verdict.name,
      'confidenceScore': result.confidenceScore,
      'explanation': result.explanation,
      'sources': result.sources.join(','),
      'keyPoints': result.keyPoints.join(','),
      'analyzedAt': result.analyzedAt.toIso8601String(),
      'isFromCache': result.isFromCache ? 1 : 0,
      'modelVersion': result.modelVersion,
    };
  }

  FactCheckVerdict _verdictFromString(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'true':
      case 'true_':
        return FactCheckVerdict.true_;
      case 'false':
      case 'false_':
        return FactCheckVerdict.false_;
      case 'partially_true':
      case 'partiallytrue':
        return FactCheckVerdict.partiallyTrue;
      case 'misleading':
        return FactCheckVerdict.misleading;
      case 'satire':
        return FactCheckVerdict.satire;
      default:
        return FactCheckVerdict.unverified;
    }
  }
}
