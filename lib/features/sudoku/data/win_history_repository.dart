import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sudoku_win_record.dart';

/// Persists successful solves locally (newest first, capped).
class WinHistoryRepository {
  WinHistoryRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const _storageKey = 'sudoku_win_history_v1';
  static const _maxRecords = 60;

  static WinHistoryRepository? _instance;

  static Future<WinHistoryRepository> instance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = WinHistoryRepository._(prefs);
    return _instance!;
  }

  List<SudokuWinRecord> readAllSync() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SudokuWinRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SudokuWinRecord>> readAll() async => readAllSync();

  Future<void> addWin(SudokuWinRecord record) async {
    final current = readAllSync();
    final next = [record, ...current];
    final capped =
        next.length > _maxRecords ? next.sublist(0, _maxRecords) : next;
    await _prefs.setString(
      _storageKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }
}
