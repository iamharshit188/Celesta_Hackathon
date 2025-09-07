import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/data/models/news_article.dart';
import 'package:wpfactcheck/domain/repositories/news_repository.dart';

class GetNewsUseCase {
  final NewsRepository _repository;

  GetNewsUseCase(this._repository);

  Future<Either<Failure, List<NewsArticle>>> call({
    String? category,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    return await _repository.getTopHeadlines(
      category: category,
      page: page,
      forceRefresh: forceRefresh,
    );
  }
}

class SearchNewsUseCase {
  final NewsRepository _repository;

  SearchNewsUseCase(this._repository);

  Future<Either<Failure, List<NewsArticle>>> call({
    required String query,
    String? sortBy,
    int page = 1,
  }) async {
    if (query.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Search query cannot be empty'));
    }

    return await _repository.searchNews(
      query: query,
      sortBy: sortBy,
      page: page,
    );
  }
}

class BookmarkArticleUseCase {
  final NewsRepository _repository;

  BookmarkArticleUseCase(this._repository);

  Future<Either<Failure, void>> call(NewsArticle article) async {
    return await _repository.bookmarkArticle(article);
  }
}

class RemoveBookmarkUseCase {
  final NewsRepository _repository;

  RemoveBookmarkUseCase(this._repository);

  Future<Either<Failure, void>> call(NewsArticle article) async {
    return await _repository.removeBookmark(article);
  }
}

class GetBookmarkedArticlesUseCase {
  final NewsRepository _repository;

  GetBookmarkedArticlesUseCase(this._repository);

  Future<Either<Failure, List<NewsArticle>>> call() async {
    return await _repository.getBookmarkedArticles();
  }
}
