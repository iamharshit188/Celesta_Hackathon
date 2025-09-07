import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/navigation/app_router.dart';
import 'package:wpfactcheck/core/utils/extensions.dart';
import 'package:wpfactcheck/core/utils/validators.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to WP FactCheck',
      description: 'Your AI-powered companion for verifying news and claims with confidence.',
      icon: Icons.fact_check,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Analyze Any Content',
      description: 'Paste text, URLs, or use voice input to fact-check information instantly.',
      icon: Icons.search,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Stay Informed',
      description: 'Explore curated news from trusted sources and bookmark important articles.',
      icon: Icons.newspaper,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Get Started',
      description: 'Tell us your name to personalize your experience.',
      icon: Icons.person,
      color: Colors.purple,
      isNameInput: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      context.showErrorSnackBar('Please enter your name');
      return;
    }

    if (!Validators.isValidName(name)) {
      context.showErrorSnackBar('Please enter a valid name (2-50 characters, letters only)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Save user profile to secure storage
      await Future.delayed(const Duration(seconds: 1)); // Simulate saving
      
      if (mounted) {
        context.go(AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to complete setup: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
              child: Row(
                children: List.generate(
                  _pages.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < _pages.length - 1 ? AppConstants.gridSpacing : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? context.colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _isLoading ? null : _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  const Spacer(),
                  
                  FilledButton(
                    onPressed: _isLoading ? null : _nextPage,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.gridSpacing * 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          
          const SizedBox(height: AppConstants.gridSpacing * 4),
          
          // Title
          Text(
            page.title,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.gridSpacing * 2),
          
          // Description
          Text(
            page.description,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Name input for last page
          if (page.isNameInput) ...[
            const SizedBox(height: AppConstants.gridSpacing * 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _completeOnboarding(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isNameInput;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isNameInput = false,
  });
}
