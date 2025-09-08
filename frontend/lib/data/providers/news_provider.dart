import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_models.dart';
import '../api/news_api_client.dart';

// News API client provider
final newsApiClientProvider = Provider<NewsApiClient>((ref) {
  return NewsApiClient();
});

// News state class
class NewsState {
  final List<NewsArticle> articles;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final String? selectedCategory;

  const NewsState({
    this.articles = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.selectedCategory,
  });

  NewsState copyWith({
    List<NewsArticle>? articles,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    String? selectedCategory,
  }) {
    return NewsState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// News provider
class NewsNotifier extends StateNotifier<NewsState> {
  final NewsApiClient _apiClient;

  NewsNotifier(this._apiClient) : super(const NewsState());

  Future<void> loadNews({
    String? category,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = state.copyWith(
        articles: [],
        currentPage: 1,
        hasMore: true,
        selectedCategory: category,
      );
    }

    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.getTopHeadlines(
        category: category,
        page: state.currentPage,
        pageSize: 20,
      );

      final newArticles = refresh 
          ? response.articles 
          : [...state.articles, ...response.articles];

      state = state.copyWith(
        articles: newArticles,
        isLoading: false,
        hasMore: response.articles.length == 20,
        currentPage: state.currentPage + 1,
        selectedCategory: category,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> searchNews(String query, {bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        articles: [],
        currentPage: 1,
        hasMore: true,
      );
    }

    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.searchNews(
        query: query,
        page: state.currentPage,
        pageSize: 20,
      );

      final newArticles = refresh 
          ? response.articles 
          : [...state.articles, ...response.articles];

      state = state.copyWith(
        articles: newArticles,
        isLoading: false,
        hasMore: response.articles.length == 20,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// News provider instance
final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  final apiClient = ref.watch(newsApiClientProvider);
  return NewsNotifier(apiClient);
});
