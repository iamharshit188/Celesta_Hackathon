import 'package:equatable/equatable.dart';

enum FactCheckVerdict {
  true_,
  false_,
  partiallyTrue,
  misleading,
  unverified,
  satire,
}

class FactCheckEntity extends Equatable {
  final String id;
  final String inputText;
  final String? sourceUrl;
  final FactCheckVerdict verdict;
  final double confidenceScore;
  final String explanation;
  final List<String> sources;
  final List<String> keyPoints;
  final DateTime analyzedAt;

  const FactCheckEntity({
    required this.id,
    required this.inputText,
    this.sourceUrl,
    required this.verdict,
    required this.confidenceScore,
    required this.explanation,
    required this.sources,
    required this.keyPoints,
    required this.analyzedAt,
  });

  @override
  List<Object?> get props => [
        id,
        inputText,
        sourceUrl,
        verdict,
        confidenceScore,
        explanation,
        sources,
        keyPoints,
        analyzedAt,
      ];
}
