import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wpfactcheck/core/di/providers.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';
import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/domain/use_cases/fact_check_use_case.dart';

// State classes
class FactCheckState {
  final bool isLoading;
  final FactCheckResult? result;
  final Failure? failure;

  const FactCheckState({
    this.isLoading = false,
    this.result,
    this.failure,
  });

  FactCheckState copyWith({
    bool? isLoading,
    FactCheckResult? result,
    Failure? failure,
  }) {
    return FactCheckState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      failure: failure ?? this.failure,
    );
  }
}

// Notifier for fact-checking
class FactCheckNotifier extends StateNotifier<FactCheckState> {
  final AnalyzeTextUseCase _analyzeTextUseCase;
  final ExtractTextFromUrlUseCase _extractTextFromUrlUseCase;

  FactCheckNotifier(this._analyzeTextUseCase, this._extractTextFromUrlUseCase)
      : super(const FactCheckState());

  Future<void> analyzeText({
    required String text,
    String? sourceUrl,
    bool useLocalModel = false,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _analyzeTextUseCase(
      text: text,
      sourceUrl: sourceUrl,
      useLocalModel: useLocalModel,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (factCheckResult) => state = state.copyWith(
        isLoading: false,
        result: factCheckResult,
        failure: null,
      ),
    );
  }

  Future<void> analyzeUrl(String url) async {
    state = state.copyWith(isLoading: true, failure: null);

    // First extract text from URL
    final extractResult = await _extractTextFromUrlUseCase(url);

    await extractResult.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, failure: failure);
      },
      (extractedText) async {
        // Then analyze the extracted text
        await analyzeText(text: extractedText, sourceUrl: url);
      },
    );
  }

  void clearResult() {
    state = const FactCheckState();
  }
}

// Provider for the fact-check notifier
final factCheckProvider = StateNotifierProvider<FactCheckNotifier, FactCheckState>((ref) {
  return FactCheckNotifier(
    ref.watch(analyzeTextUseCaseProvider),
    ref.watch(extractTextFromUrlUseCaseProvider),
  );
});
