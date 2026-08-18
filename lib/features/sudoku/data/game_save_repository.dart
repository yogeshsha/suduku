import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sudoku_saved_game.dart';

/// Persists a single in-progress game locally so it can be resumed after the
/// app is closed, backgrounded, or crashes. Only one game is kept at a time;
/// starting a new game or finishing the current one replaces/clears it.
class GameSaveRepository {
  GameSaveRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const _storageKey = 'sudoku_saved_game_v1';

  static GameSaveRepository? _instance;

  static Future<GameSaveRepository> instance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = GameSaveRepository._(prefs);
    return _instance!;
  }

  SudokuSavedGame? readSync() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SudokuSavedGame.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<SudokuSavedGame?> read() async => readSync();

  Future<void> save(SudokuSavedGame game) async {
    await _prefs.setString(_storageKey, jsonEncode(game.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }
}
