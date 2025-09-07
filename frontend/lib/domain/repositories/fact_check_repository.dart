import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';

abstract class FactCheckRepository {
  Future<Either<Failure, FactCheckResult>> analyzeText({
    required String text,
    String? sourceUrl,
    bool useLocalModel = false,
  });

  Future<Either<Failure, String>> extractTextFromUrl(String url);

  Future<Either<Failure, List<FactCheckResult>>> getCachedAnalyses({
    int limit = 20,
  });

  Future<Either<Failure, void>> cacheAnalysis(FactCheckResult result);

  Future<Either<Failure, void>> clearCache();

  Future<Either<Failure, bool>> isServiceHealthy();
}
