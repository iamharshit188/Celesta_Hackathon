import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:wpfactcheck/core/theming/app_theme.dart';
import 'package:wpfactcheck/core/navigation/app_router.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';

class WPFactCheckApp extends ConsumerWidget {
  const WPFactCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveTheme(
      light: AppTheme.lightTheme,
      dark: AppTheme.darkTheme,
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        routerConfig: AppRouter.router,
        
        // Device preview configuration
          locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        
        // Accessibility
        showSemanticsDebugger: false,
      ),
    );
  }
}
