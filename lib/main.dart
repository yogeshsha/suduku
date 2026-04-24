import 'package:flutter/material.dart';

import 'app.dart';
import 'theme/theme_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeSettings = ThemeSettings();
  await themeSettings.load();
  runApp(SudokuApp(themeSettings: themeSettings));
}
