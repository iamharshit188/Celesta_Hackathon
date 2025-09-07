import 'package:flutter/material.dart';

extension StringExtensions on String {
  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Title case
  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  // Check if string is URL
  bool get isUrl {
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(this);
  }

  // Extract domain from URL
  String? get domain {
    if (!isUrl) return null;
    final uri = Uri.tryParse(this);
    return uri?.host;
  }

  // Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  // Remove HTML tags
  String get removeHtmlTags {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // Word count
  int get wordCount {
    return trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }
}

extension DateTimeExtensions on DateTime {
  // Time ago format
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Format for display
  String get displayFormat {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
}

extension BuildContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // MediaQuery shortcuts
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  // Responsive helpers
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  // Navigation shortcuts
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => navigator.pop(result);
  Future<T?> push<T>(Route<T> route) => navigator.push(route);
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      navigator.pushNamed(routeName, arguments: arguments);

  // Snackbar helper
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.error);
  }

  // Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }
}

extension ListExtensions<T> on List<T> {
  // Safe get element at index
  T? safeGet(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  // Add if not null
  void addIfNotNull(T? item) {
    if (item != null) add(item);
  }

  // Remove duplicates while preserving order
  List<T> get unique {
    final seen = <T>{};
    return where((item) => seen.add(item)).toList();
  }
}
