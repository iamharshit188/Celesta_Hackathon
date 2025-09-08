import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/news_models.dart';
import '../../data/providers/news_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    // Load initial news
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsProvider.notifier).loadNews(
        category: _selectedCategory,
        refresh: true,
      );
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadMoreArticles() async {
    final newsNotifier = ref.read(newsProvider.notifier);
    await newsNotifier.loadNews(category: _selectedCategory);
  }

  Future<void> _refreshNews() async {
    final newsNotifier = ref.read(newsProvider.notifier);
    await newsNotifier.loadNews(
      category: _selectedCategory,
      refresh: true,
    );
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    ref.read(newsProvider.notifier).loadNews(
      category: category,
      refresh: true,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore News'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement search functionality
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search news',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.gridSpacing),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.gridSpacing * 2),
              itemCount: AppConstants.filterChips.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppConstants.gridSpacing),
              itemBuilder: (context, index) {
                final category = AppConstants.filterChips[index];
                final isSelected = _selectedCategory == category.toLowerCase();
                
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => _onCategoryChanged(category.toLowerCase()),
                  backgroundColor: context.colorScheme.surfaceContainerHighest,
                  selectedColor: context.colorScheme.primaryContainer,
                  checkmarkColor: context.colorScheme.onPrimaryContainer,
                );
              },
            ),
          ),
          
          // News list
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final newsState = ref.watch(newsProvider);
                
                if (newsState.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: context.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load news',
                          style: context.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          newsState.error!,
                          style: context.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _refreshNews(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (newsState.isLoading && newsState.articles.isEmpty) {
                  return _buildShimmerList();
                }
                
                return _buildNewsList(newsState);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: context.colorScheme.surfaceContainerHighest,
          highlightColor: context.colorScheme.surface,
          child: Card(
            margin: const EdgeInsets.only(bottom: AppConstants.gridSpacing * 2),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  const SizedBox(height: AppConstants.gridSpacing * 2),
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppConstants.gridSpacing),
                  Container(
                    width: context.screenWidth * 0.7,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppConstants.gridSpacing),
                  Container(
                    width: context.screenWidth * 0.5,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsList(NewsState newsState) {
    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
        itemCount: newsState.articles.length + (newsState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == newsState.articles.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.gridSpacing * 2),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final article = newsState.articles[index];
          return _buildArticleCard(article);
        },
      ),
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.gridSpacing * 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to article detail or open URL
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            if (article.urlToImage != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.urlToImage!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      color: context.colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                  ),
                ),
              ),
            
            // Article content
            Padding(
              padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article.title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppConstants.gridSpacing),
                  
                  // Description
                  Text(
                    article.description,
                    style: context.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppConstants.gridSpacing * 2),
                  
                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.source,
                        size: 16,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: AppConstants.gridSpacing / 2),
                      Text(
                        article.sourceName,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.publishedAt.timeAgo,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
