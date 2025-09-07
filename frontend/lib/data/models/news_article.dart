import 'package:equatable/equatable.dart';

class NewsArticle extends Equatable {
  final String id;
  final String title;
  final String description;
  final String content;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String sourceName;
  final String? sourceId;
  final String? author;
  final String category;
  final bool isBookmarked;
  final DateTime? cachedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    required this.sourceName,
    this.sourceId,
    this.author,
    required this.category,
    this.isBookmarked = false,
    this.cachedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      sourceName: json['source']?['name'] ?? 'Unknown Source',
      sourceId: json['source']?['id'],
      author: json['author'],
      category: json['category'] ?? 'general',
      isBookmarked: json['isBookmarked'] ?? false,
      cachedAt: json['cachedAt'] != null 
          ? DateTime.tryParse(json['cachedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt.toIso8601String(),
      'source': {
        'name': sourceName,
        'id': sourceId,
      },
      'author': author,
      'category': category,
      'isBookmarked': isBookmarked,
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  NewsArticle copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? url,
    String? urlToImage,
    DateTime? publishedAt,
    String? sourceName,
    String? sourceId,
    String? author,
    String? category,
    bool? isBookmarked,
    DateTime? cachedAt,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      url: url ?? this.url,
      urlToImage: urlToImage ?? this.urlToImage,
      publishedAt: publishedAt ?? this.publishedAt,
      sourceName: sourceName ?? this.sourceName,
      sourceId: sourceId ?? this.sourceId,
      author: author ?? this.author,
      category: category ?? this.category,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        content,
        url,
        urlToImage,
        publishedAt,
        sourceName,
        sourceId,
        author,
        category,
        isBookmarked,
        cachedAt,
      ];
}
