import 'package:equatable/equatable.dart';

enum FactCheckVerdict {
  true_,
  false_,
  partiallyTrue,
  misleading,
  unverified,
  satire,
}

class FactCheckResult extends Equatable {
  final String id;
  final String inputText;
  final String? sourceUrl;
  final FactCheckVerdict verdict;
  final double confidenceScore;
  final String explanation;
  final List<String> sources;
  final List<String> keyPoints;
  final DateTime analyzedAt;
  final bool isFromCache;
  final String? modelVersion;

  const FactCheckResult({
    required this.id,
    required this.inputText,
    this.sourceUrl,
    required this.verdict,
    required this.confidenceScore,
    required this.explanation,
    required this.sources,
    required this.keyPoints,
    required this.analyzedAt,
    this.isFromCache = false,
    this.modelVersion,
  });

  factory FactCheckResult.fromJson(Map<String, dynamic> json) {
    return FactCheckResult(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      inputText: json['inputText'] ?? '',
      sourceUrl: json['sourceUrl'],
      verdict: _verdictFromString(json['verdict'] ?? 'unverified'),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      explanation: json['explanation'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      analyzedAt: DateTime.tryParse(json['analyzedAt'] ?? '') ?? DateTime.now(),
      isFromCache: json['isFromCache'] ?? false,
      modelVersion: json['modelVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inputText': inputText,
      'sourceUrl': sourceUrl,
      'verdict': verdict.name,
      'confidenceScore': confidenceScore,
      'explanation': explanation,
      'sources': sources,
      'keyPoints': keyPoints,
      'analyzedAt': analyzedAt.toIso8601String(),
      'isFromCache': isFromCache,
      'modelVersion': modelVersion,
    };
  }

  static FactCheckVerdict _verdictFromString(String verdict) {
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

  String get verdictDisplayText {
    switch (verdict) {
      case FactCheckVerdict.true_:
        return 'True';
      case FactCheckVerdict.false_:
        return 'False';
      case FactCheckVerdict.partiallyTrue:
        return 'Partially True';
      case FactCheckVerdict.misleading:
        return 'Misleading';
      case FactCheckVerdict.unverified:
        return 'Unverified';
      case FactCheckVerdict.satire:
        return 'Satire';
    }
  }

  FactCheckResult copyWith({
    String? id,
    String? inputText,
    String? sourceUrl,
    FactCheckVerdict? verdict,
    double? confidenceScore,
    String? explanation,
    List<String>? sources,
    List<String>? keyPoints,
    DateTime? analyzedAt,
    bool? isFromCache,
    String? modelVersion,
  }) {
    return FactCheckResult(
      id: id ?? this.id,
      inputText: inputText ?? this.inputText,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      verdict: verdict ?? this.verdict,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      explanation: explanation ?? this.explanation,
      sources: sources ?? this.sources,
      keyPoints: keyPoints ?? this.keyPoints,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      isFromCache: isFromCache ?? this.isFromCache,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }

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
        isFromCache,
        modelVersion,
      ];
}
