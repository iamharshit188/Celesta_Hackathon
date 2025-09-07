import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/data/models/news_article.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<NewsArticle>>> getTopHeadlines({
    String? category,
    int page = 1,
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<NewsArticle>>> searchNews({
    required String query,
    String? sortBy,
    int page = 1,
  });

  Future<Either<Failure, List<NewsArticle>>> getCachedArticles({
    String? category,
    int limit = 50,
  });

  Future<Either<Failure, void>> bookmarkArticle(NewsArticle article);

  Future<Either<Failure, void>> removeBookmark(NewsArticle article);

  Future<Either<Failure, List<NewsArticle>>> getBookmarkedArticles();
}
