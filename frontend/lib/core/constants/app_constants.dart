class AppConstants {
  // App Info
  static const String appName = 'WP FactCheck';
  static const String appVersion = '1.0.0';
  static const String teamName = 'Team WaterPlane';

  // API Configuration
  static const String backendBaseUrl = 'http://localhost:8000/api/v1';
  static const String factCheckBaseUrl = '$backendBaseUrl/fact-check';
  static const String newsBaseUrl = '$backendBaseUrl/news';
  static const String chatBaseUrl = '$backendBaseUrl/chat';
  static const String usersBaseUrl = '$backendBaseUrl/users';
  
  // External APIs
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';
  static const String newsApiCountry = 'in';
  static const int newsApiPageSize = 20;
  static const int maxCachedArticles = 50;
  static const int maxCachedAnalyses = 20;

  // Storage Keys
  static const String userNameKey = 'user_name';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_completed';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // UI Constants
  static const double gridSpacing = 8.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 40.0;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // News Categories
  static const List<String> newsCategories = [
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  // Filter Chips
  static const List<String> filterChips = [
    'Politics',
    'Tech',
    'Business',
    'Sports',
    'Entertainment',
  ];

  // ML Model
  static const String mlModelPath = 'assets/models/roberta_factcheck.tflite';
  static const String modelHashKey = 'model_hash';
}
