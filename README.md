# suduko

Flutter Sudoku game with difficulty selection, win history (persisted with `shared_preferences`), and light/dark theming. Puzzle generation and solving use the [`fludoku`](https://pub.dev/packages/fludoku) package.

## Project structure

```
suduku/
├── android/                          # Android Gradle project, manifests, launcher assets
├── ios/                              # Xcode workspace, Runner, icons, launch screen
├── assets/
│   └── branding/
│       └── app_icon.png              # Source branding asset (see tool/)
├── lib/
│   ├── main.dart                     # App entrypoint
│   ├── app.dart                      # Root widget / MaterialApp wiring
│   ├── route_observer.dart           # Route observation helper
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── theme_settings.dart
│   │   └── theme_mode_picker_button.dart
│   └── features/
│       └── sudoku/
│           ├── application/
│           │   └── sudoku_game_controller.dart   # Game state & logic orchestration
│           ├── data/
│           │   └── win_history_repository.dart   # Persisted win history
│           ├── domain/
│           │   ├── game_difficulty.dart
│           │   └── sudoku_win_record.dart
│           └── presentation/
│               ├── navigation/
│               │   └── page_transitions.dart
│               ├── pages/
│               │   ├── sudoku_home_page.dart
│               │   ├── sudoku_game_page.dart
│               │   └── sudoku_history_page.dart
│               └── widgets/
│                   ├── animated_success_dialog.dart
│                   ├── fade_slide_in.dart
│                   ├── how_to_play.dart
│                   ├── number_pad.dart
│                   └── sudoku_grid.dart
├── test/
│   └── widget_test.dart
├── tool/
│   └── generate_app_icon.dart        # Icon generation script
├── analysis_options.yaml
└── pubspec.yaml
```

## Run locally

```bash
flutter pub get
flutter run
```

For Flutter setup and docs, see [https://docs.flutter.dev/](https://docs.flutter.dev/).
