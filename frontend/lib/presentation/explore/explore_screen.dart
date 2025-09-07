import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/utils/extensions.dart';
import 'package:wpfactcheck/data/models/news_article.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'general';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<NewsArticle> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadArticles() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _articles.clear();
    });

    try {
      // TODO: Implement actual news loading with providers
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data for now
      final mockArticles = _generateMockArticles();
      
      if (mounted) {
        setState(() {
          _articles = mockArticles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load news: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || _isLoading) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final moreArticles = _generateMockArticles(startIndex: _articles.length);
      
      if (mounted) {
        setState(() {
          _articles.addAll(moreArticles);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  List<NewsArticle> _generateMockArticles({int startIndex = 0}) {
    final titles = [
      'Breaking: Major Policy Changes Announced',
      'Tech Innovation Drives Economic Growth',
      'Sports Championship Finals This Weekend',
      'Entertainment Industry Sees Record Profits',
      'Business Leaders Discuss Future Trends',
      'Political Debate Sparks National Discussion',
      'New Research Reveals Surprising Findings',
      'Local Community Celebrates Achievement',
    ];

    return List.generate(8, (index) {
      final actualIndex = startIndex + index;
      return NewsArticle(
        id: 'article_$actualIndex',
        title: titles[index % titles.length],
        description: 'This is a sample description for article ${actualIndex + 1}. It provides a brief overview of the content.',
        content: 'Full article content would go here...',
        url: 'https://example.com/article/$actualIndex',
        urlToImage: 'https://picsum.photos/400/200?random=$actualIndex',
        publishedAt: DateTime.now().subtract(Duration(hours: actualIndex)),
        sourceName: ['Reuters', 'BBC', 'CNN', 'Associated Press'][index % 4],
        category: _selectedCategory,
        author: 'Reporter ${index + 1}',
      );
    });
  }

  void _onCategorySelected(String category) {
    if (category != _selectedCategory) {
      setState(() {
        _selectedCategory = category;
      });
      _loadArticles();
    }
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
                  onSelected: (_) => _onCategorySelected(category.toLowerCase()),
                  backgroundColor: context.colorScheme.surfaceContainerHighest,
                  selectedColor: context.colorScheme.primaryContainer,
                  checkmarkColor: context.colorScheme.onPrimaryContainer,
                );
              },
            ),
          ),
          
          // News list
          Expanded(
            child: _isLoading 
                ? _buildShimmerList()
                : _buildNewsList(),
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

  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
        itemCount: _articles.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _articles.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.gridSpacing * 2),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final article = _articles[index];
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
