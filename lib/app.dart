import 'package:flutter/material.dart';

import 'features/sudoku/presentation/pages/sudoku_home_page.dart';
import 'route_observer.dart';
import 'theme/app_theme.dart';
import 'theme/theme_settings.dart';

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key, required this.themeSettings});

  final ThemeSettings themeSettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sudoku',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [appRouteObserver],
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeSettings.themeMode,
          builder: (context, child) {
            return InheritedThemeSettings(
              notifier: themeSettings,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SudokuHomePage(),
        );
      },
    );
  }
}
