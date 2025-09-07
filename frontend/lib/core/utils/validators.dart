class Validators {
  // URL validation
  static bool isValidUrl(String input) {
    if (input.isEmpty) return false;
    
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      caseSensitive: false,
    );
    
    return urlPattern.hasMatch(input);
  }

  // Text validation for fact-checking
  static bool isValidFactCheckText(String input) {
    if (input.trim().isEmpty) return false;
    if (input.trim().length < 10) return false;
    if (input.trim().length > 5000) return false;
    return true;
  }

  // Email validation
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailPattern.hasMatch(email);
  }

  // Name validation
  static bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    if (name.trim().length > 50) return false;
    
    final namePattern = RegExp(r'^[a-zA-Z\s]+$');
    return namePattern.hasMatch(name.trim());
  }

  // Check if input contains potentially harmful content
  static bool containsHarmfulContent(String input) {
    final harmfulPatterns = [
      RegExp(r'<script.*?>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
    ];
    
    return harmfulPatterns.any((pattern) => pattern.hasMatch(input));
  }

  // Sanitize input text
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s\.,!?;:\-\(\)@#\$%&\*\+=/]'), '') // Keep only safe characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  // Check if text is likely spam
  static bool isLikelySpam(String text) {
    final spamIndicators = [
      RegExp(r'(buy now|click here|free money|guaranteed)', caseSensitive: false),
      RegExp(r'[A-Z]{10,}'), // Too many consecutive capitals
      RegExp(r'(.)\1{5,}'), // Repeated characters
      RegExp(r'[!]{3,}'), // Multiple exclamation marks
    ];
    
    return spamIndicators.any((pattern) => pattern.hasMatch(text));
  }

  // Validate API key format
  static bool isValidApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;
    if (apiKey.length < 16) return false;
    
    // Basic format check for common API key patterns
    final apiKeyPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    return apiKeyPattern.hasMatch(apiKey);
  }
}
