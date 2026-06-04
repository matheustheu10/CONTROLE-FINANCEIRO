qimport 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ─── KEYS ────────────────────────────────────────────────
  static const _usersKey = 'db_users';
  static const _transactionsKey = 'db_transactions';

  // ─── HELPERS ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  // ─── USERS ───────────────────────────────────────────────

  Future<UserModel?> getUserByEmail(String email) async {
    final users = await _readList(_usersKey);
    final match = users.where((u) => u['email'] == email).toList();
    if (match.isEmpty) return null;
    return UserModel.fromMap(match.first);
  }

  Future<bool> insertUser(UserModel user) async {
    try {
      final users = await _readList(_usersKey);
      // Check for duplicate email
      if (users.any((u) => u['email'] == user.email)) return false;
      users.add(user.toMap());
      await _writeList(_usersKey, users);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final all = await _readList(_transactionsKey);
    final filtered = all.where((t) => t['user_id'] == userId).toList();
    filtered.sort((a, b) => b['date'].compareTo(a['date']));
    return filtered.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<void> insertTransaction(TransactionModel tx) async {
    final all = await _readList(_transactionsKey);
    all.removeWhere((t) => t['id'] == tx.id); // replace if exists
    all.add(tx.toMap());
    await _writeList(_transactionsKey, all);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final all = await _readList(_transactionsKey);
    final index = all.indexWhere((t) => t['id'] == tx.id);
    if (index == -1) return;
    all[index] = tx.toMap();
    await _writeList(_transactionsKey, all);
  }

  Future<void> deleteTransaction(String id) async {
    final all = await _readList(_transactionsKey);
    all.removeWhere((t) => t['id'] == id);
    await _writeList(_transactionsKey, all);
  }
}
