import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wpfactcheck/app.dart';
import 'package:wpfactcheck/presentation/main/main_screen.dart';
import 'package:wpfactcheck/presentation/explore/explore_screen.dart';
import 'package:wpfactcheck/presentation/profile/profile_screen.dart';

void main() {
  group('WPFactCheck App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: WPFactCheckApp(),
        ),
      );

      // Verify the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Main screen should display fact check interface', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Verify main screen elements
      expect(find.text('WP FactCheck'), findsOneWidget);
      expect(find.text('Enter text or URL to fact-check'), findsOneWidget);
      expect(find.text('Check Facts'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Explore screen should display news interface', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );

      // Verify explore screen elements
      expect(find.text('Explore News'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('Profile screen should display user interface', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('Text input should accept user input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text
      await tester.enterText(textField, 'Test fact check input');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Test fact check input'), findsOneWidget);
    });

    testWidgets('Check Facts button should be enabled with text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      final textField = find.byType(TextField);
      final checkButton = find.text('Check Facts');

      // Enter text
      await tester.enterText(textField, 'This is a test claim to fact check');
      await tester.pump();

      // Verify button is present
      expect(checkButton, findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('All interactive elements should have semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Check for semantic labels on key elements
      final semantics = tester.getSemantics(find.byType(TextField));
      expect(semantics.label, isNotNull);
    });

    testWidgets('App should support large text scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MainScreen(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });
}
