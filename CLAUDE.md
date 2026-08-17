# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter Sudoku game (package name `suduko`) with 4 board sizes, difficulty selection, win/loss history persisted via `shared_preferences`, and light/dark theming.

## Commands

```bash
flutter pub get              # install dependencies
flutter run                  # run on a connected device/simulator
flutter analyze              # static analysis (flutter_lints via analysis_options.yaml)
flutter test                 # run tests (no test/ directory currently exists in this repo)
flutter test test/foo_test.dart   # run a single test file
```

Asset regeneration (run from repo root, outputs into `assets/branding/`):
```bash
dart run tool/generate_app_icon.dart
dart run tool/generate_play_store_graphics.dart
```

Release build/publish is driven by `distribution.yaml` (distribute_cli / Fastlane), producing a signed Android AAB and uploading to the Play Console internal track. This requires `android/key.properties` and `distribution/google-key.json`, which are not present in a fresh checkout — do not attempt to run this without confirming credentials are set up.

## Architecture

Feature-first layout under `lib/features/sudoku/`, split into `domain/` (pure types), `data/` (puzzle generation + persistence), `application/` (the one stateful controller), and `presentation/` (pages/widgets).

### Puzzle generation strategy (three engines, dispatched by board size)

`SudokuBoardSize` (`lib/features/sudoku/domain/sudoku_board_size.dart`) is the single source of truth for which engine handles which dimension:
- **4×4 and 9×9** — generated via the [`fludoku`](https://pub.dev/packages/fludoku) package, called through `fludokuGenerateIsolate` (`lib/features/sudoku/data/sudoku_fludoku_isolate.dart`) inside `Isolate.run` so generation/solving doesn't block the UI thread. Solving has its own timeout budget separate from generation's.
- **6×6** — `SudokuSixEngine`/`SudokuSixBundle` (`lib/features/sudoku/data/sudoku_six_engine.dart`), a hand-rolled generator using 2×3 boxes.
- **12×12** — `SudokuTwelveEngine`/`SudokuTwelveBundle` (`lib/features/sudoku/data/sudoku_twelve_engine.dart`), hand-rolled with 3×4 boxes, also generated inside `Isolate.run` since it's the most expensive case.

Because the three engines have incompatible board representations (`fludoku`'s `Board` vs. raw `List<List<int>>` grids for the six/twelve engines), `SudokuGameController` (`lib/features/sudoku/application/sudoku_game_controller.dart`) holds all three as nullable fields (`_board`, `_six`, `_twelve`) and branches on whichever is non-null throughout — see `cellAt`, `inputDigit`, `applyHint`, `isGiven`, etc. When modifying gameplay logic, all three branches typically need the same change in parallel.

### Game controller

`SudokuGameController` is a `ChangeNotifier` and is the single owner of game state: board data, selection, mistakes/hints counters, win/loss outcome, and the solve-timer (`Stopwatch` + periodic `Timer`). It exposes a separate `ValueNotifier<String> elapsedLabelNotifier` for the elapsed-time display specifically so the timer ticking doesn't force a full-board rebuild via `notifyListeners()` — important for the larger 12×12 grid. `pauseSolveTimer`/`resumeSolveTimer` are driven by route/lifecycle observers (see `route_observer.dart`) so the timer stops when the app is backgrounded or the game page isn't active.

Generation calls are guarded by a `_genToken` counter incremented on every `startNewGame()`; async generation results are discarded if the token has since changed (e.g. the user backed out and started a new game before the previous one finished generating).

### Theming

`ThemeSettings` (`lib/theme/theme_settings.dart`) persists the user's theme mode choice and is provided app-wide via `InheritedThemeSettings` in `app.dart`'s `MaterialApp.builder`, not via a state management package.

### Presentation widgets

`lib/features/sudoku/presentation/widgets/` contains small single-purpose animation/feedback primitives composed together on the game page rather than one large custom-painted widget: `PressableScale` (tactile press feedback), `PulseLoop`, `ShakeOnSignal` / `SignalFlash` (one-shot effects keyed off a changing `signal` value), `ConfettiBurst`, `FadeSlideIn`. Follow this pattern (small composable effect widgets driven by a value/signal) rather than adding animation logic directly into pages.
