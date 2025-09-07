import 'package:equatable/equatable.dart';

class NewsArticleEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String content;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String sourceName;
  final String? author;
  final String category;
  final bool isBookmarked;

  const NewsArticleEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.sourceName,
    this.author,
    required this.category,
    this.isBookmarked = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        content,
        url,
        imageUrl,
        publishedAt,
        sourceName,
        author,
        category,
        isBookmarked,
      ];
}
