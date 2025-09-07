import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/core/utils/validators.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';
import 'package:wpfactcheck/domain/repositories/fact_check_repository.dart';

class AnalyzeTextUseCase {
  final FactCheckRepository _repository;

  AnalyzeTextUseCase(this._repository);

  Future<Either<Failure, FactCheckResult>> call({
    required String text,
    String? sourceUrl,
    bool useLocalModel = false,
  }) async {
    // Validate input
    if (!Validators.isValidFactCheckText(text)) {
      return const Left(ValidationFailure(
        message: 'Text must be between 10 and 5000 characters',
      ));
    }

    if (Validators.containsHarmfulContent(text)) {
      return const Left(ValidationFailure(
        message: 'Input contains potentially harmful content',
      ));
    }

    if (Validators.isLikelySpam(text)) {
      return const Left(ValidationFailure(
        message: 'Input appears to be spam',
      ));
    }

    // Sanitize input
    final sanitizedText = Validators.sanitizeInput(text);

    return await _repository.analyzeText(
      text: sanitizedText,
      sourceUrl: sourceUrl,
      useLocalModel: useLocalModel,
    );
  }
}

class ExtractTextFromUrlUseCase {
  final FactCheckRepository _repository;

  ExtractTextFromUrlUseCase(this._repository);

  Future<Either<Failure, String>> call(String url) async {
    if (!Validators.isValidUrl(url)) {
      return const Left(ValidationFailure(message: 'Invalid URL format'));
    }

    return await _repository.extractTextFromUrl(url);
  }
}

class GetCachedAnalysesUseCase {
  final FactCheckRepository _repository;

  GetCachedAnalysesUseCase(this._repository);

  Future<Either<Failure, List<FactCheckResult>>> call({int limit = 20}) async {
    return await _repository.getCachedAnalyses(limit: limit);
  }
}

class CheckServiceHealthUseCase {
  final FactCheckRepository _repository;

  CheckServiceHealthUseCase(this._repository);

  Future<Either<Failure, bool>> call() async {
    return await _repository.isServiceHealthy();
  }
}
