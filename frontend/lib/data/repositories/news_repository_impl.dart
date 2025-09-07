import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wpfactcheck/core/error/exceptions.dart';
import 'package:wpfactcheck/core/error/failures.dart';
import 'package:wpfactcheck/core/utils/either.dart';
import 'package:wpfactcheck/data/api_clients/news_api_client.dart';
import 'package:wpfactcheck/data/models/news_article.dart';
import 'package:wpfactcheck/domain/repositories/news_repository.dart';
import 'package:sqflite/sqflite.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiClient _apiClient;
  final Database _database;
  final Connectivity _connectivity;

  NewsRepositoryImpl({
    required NewsApiClient apiClient,
    required Database database,
    required Connectivity connectivity,
  }) : _apiClient = apiClient,
       _database = database,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, List<NewsArticle>>> getTopHeadlines({
    String? category,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline && !forceRefresh) {
        // Return cached articles when offline
        final cachedArticles = await _getCachedArticles(category: category);
        return Right(cachedArticles);
      }

      if (isOnline) {
        final response = await _apiClient.getTopHeadlines(
          category: category,
          page: page,
        );

        if (response.isSuccess) {
          // Cache the articles
          await _cacheArticles(response.articles, category: category);
          return Right(response.articles);
        } else {
          return Left(ServerFailure(message: response.message ?? 'Failed to fetch news'));
        }
      } else {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticle>>> searchNews({
    required String query,
    String? sortBy,
    int page = 1,
  }) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (!isOnline) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      final response = await _apiClient.searchNews(
        query: query,
        sortBy: sortBy,
        page: page,
      );

      if (response.isSuccess) {
        return Right(response.articles);
      } else {
        return Left(ServerFailure(message: response.message ?? 'Search failed'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticle>>> getCachedArticles({
    String? category,
    int limit = 50,
  }) async {
    try {
      final articles = await _getCachedArticles(category: category, limit: limit);
      return Right(articles);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get cached articles: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> bookmarkArticle(NewsArticle article) async {
    try {
      final bookmarkedArticle = article.copyWith(isBookmarked: true);
      await _updateArticleInCache(bookmarkedArticle);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to bookmark article: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeBookmark(NewsArticle article) async {
    try {
      final unbookmarkedArticle = article.copyWith(isBookmarked: false);
      await _updateArticleInCache(unbookmarkedArticle);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to remove bookmark: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticle>>> getBookmarkedArticles() async {
    try {
      final articles = await _getBookmarkedArticles();
      return Right(articles);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get bookmarked articles: $e'));
    }
  }

  // Private helper methods
  Future<List<NewsArticle>> _getCachedArticles({
    String? category,
    int limit = 50,
  }) async {
    try {
      String? whereClause = 'cachedAt IS NOT NULL';
      List<dynamic> whereArgs = [];
      
      if (category != null) {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }

      final List<Map<String, dynamic>> maps = await _database.query(
        'articles',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'publishedAt DESC',
        limit: limit,
      );

      return maps.map((map) => NewsArticle.fromJson(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached articles: $e');
    }
  }

  Future<void> _cacheArticles(List<NewsArticle> articles, {String? category}) async {
    try {
      final batch = _database.batch();
      
      for (final article in articles) {
        final cachedArticle = article.copyWith(
          cachedAt: DateTime.now(),
          category: category ?? article.category,
        );
        
        batch.insert(
          'articles',
          cachedArticle.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
      
      // Clean up old articles to maintain cache limit
      await _cleanupOldArticles();
    } catch (e) {
      throw CacheException(message: 'Failed to cache articles: $e');
    }
  }

  Future<void> _updateArticleInCache(NewsArticle article) async {
    try {
      await _database.update(
        'articles',
        article.toJson(),
        where: 'id = ?',
        whereArgs: [article.id],
      );
    } catch (e) {
      throw CacheException(message: 'Failed to update article: $e');
    }
  }

  Future<List<NewsArticle>> _getBookmarkedArticles() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'articles',
        where: 'isBookmarked = ?',
        whereArgs: [1],
        orderBy: 'publishedAt DESC',
      );

      return maps.map((map) => NewsArticle.fromJson(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get bookmarked articles: $e');
    }
  }

  Future<void> _cleanupOldArticles() async {
    try {
      // Keep only the latest 50 articles
      await _database.execute('''
        DELETE FROM articles 
        WHERE id NOT IN (
          SELECT id FROM articles 
          ORDER BY publishedAt DESC 
          LIMIT 50
        )
      ''');
    } catch (e) {
      throw CacheException(message: 'Failed to cleanup old articles: $e');
    }
  }
}
