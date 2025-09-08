import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  /// Get the current theme's TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get the current theme's ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the current MediaQuery data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get the screen size
  Size get screenSize => mediaQuery.size;

  /// Get the screen width
  double get screenWidth => screenSize.width;

  /// Get the screen height
  double get screenHeight => screenSize.height;

  /// Check if the device is in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get the current theme
  ThemeData get theme => Theme.of(this);

  /// Show a snackbar with the given message
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show an error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  }

  /// Show a success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
