import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const _transactionsKey = 'transactions';

  Future<List<Map<String, dynamic>>> readAll() async {
    return await _readList(_transactionsKey);
  }

  Future<void> writeAll(List<Map<String, dynamic>> list) async {
    await _writeList(_transactionsKey, list);
  }

  Future<void> deleteById(String id) async {
    final all = await _readList(_transactionsKey);
    all.removeWhere((t) => t['id'] == id);
    await _writeList(_transactionsKey, all);
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }
}
