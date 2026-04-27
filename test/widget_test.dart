import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:suduko/app.dart';
import 'package:suduko/theme/theme_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen shows start, theme, and difficulty', (tester) async {
    final themeSettings = ThemeSettings();
    await themeSettings.load();
    await tester.pumpWidget(SudokuApp(themeSettings: themeSettings));
    await tester.pumpAndSettle();

    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Start game'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Expert'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
