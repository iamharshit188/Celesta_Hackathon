import 'package:wpfactcheck/data/models/news_article.dart';

class NewsResponseDto {
  final String status;
  final int totalResults;
  final List<NewsArticle> articles;
  final String? message;

  const NewsResponseDto({
    required this.status,
    required this.totalResults,
    required this.articles,
    this.message,
  });

  factory NewsResponseDto.fromJson(Map<String, dynamic> json) {
    final articlesJson = json['articles'] as List<dynamic>? ?? [];
    
    return NewsResponseDto(
      status: json['status'] ?? 'error',
      totalResults: json['totalResults'] ?? 0,
      articles: articlesJson
          .map((articleJson) => NewsArticle.fromJson(articleJson))
          .toList(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'totalResults': totalResults,
      'articles': articles.map((article) => article.toJson()).toList(),
      'message': message,
    };
  }

  bool get isSuccess => status == 'ok';
  bool get hasArticles => articles.isNotEmpty;
}
