import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wpfactcheck/presentation/main/main_screen.dart';
import 'package:wpfactcheck/presentation/explore/explore_screen.dart';
import 'package:wpfactcheck/presentation/profile/profile_screen.dart';
import 'package:wpfactcheck/presentation/profile/onboarding_screen.dart';
import 'package:wpfactcheck/presentation/shared_widgets/bottom_nav_scaffold.dart';

class AppRouter {
  static const String home = '/home';
  static const String explore = '/explore';
  static const String profile = '/profile';
  static const String onboarding = '/onboarding';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      // Onboarding route
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Main shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            builder: (context, state) => const MainScreen(),
          ),
          GoRoute(
            path: explore,
            name: 'explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
