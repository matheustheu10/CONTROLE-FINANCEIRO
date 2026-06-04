import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

enum FilterType { all, income, expense }

class FinanceViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  FilterType _activeFilter = FilterType.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get allTransactions => _transactions;
  FilterType get activeFilter => _activeFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TransactionModel> get filteredTransactions {
    var list = _transactions;

    if (_activeFilter == FilterType.income) {
      list = list.where((t) => t.isIncome).toList();
    } else if (_activeFilter == FilterType.expense) {
      list = list.where((t) => !t.isIncome).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.category.label.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  double get incomeRatio =>
      (totalIncome + totalExpense) == 0 ? 0 : totalIncome / (totalIncome + totalExpense);

  Map<TransactionCategory, double> get expenseByCategory {
    final Map<TransactionCategory, double> map = {};
    for (final t in _transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<TransactionModel> get recentTransactions =>
      _transactions.take(5).toList();

  // ─── LOAD ─────────────────────────────────────────────────

  Future<void> loadTransactions(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _db.getTransactions(userId);
    } catch (e) {
      _errorMessage = 'Erro ao carregar transações.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── ADD ──────────────────────────────────────────────────

  Future<void> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required bool isIncome,
    required DateTime date,
    required TransactionCategory category,
    String? note,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      userId: userId,
      title: title.trim(),
      amount: amount,
      isIncome: isIncome,
      date: date,
      category: category,
      note: note?.trim(),
    );

    await _db.insertTransaction(tx);
    _transactions.insert(0, tx);
    notifyListeners();
  }

  // ─── UPDATE ───────────────────────────────────────────────

  Future<void> updateTransaction({
    required String id,
    required String title,
    required double amount,
    required bool isIncome,
    required DateTime date,
    required TransactionCategory category,
    String? note,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updated = _transactions[index].copyWith(
      title: title.trim(),
      amount: amount,
      isIncome: isIncome,
      date: date,
      category: category,
      note: note?.trim(),
    );

    await _db.updateTransaction(updated);
    _transactions[index] = updated;
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // ─── DELETE ───────────────────────────────────────────────

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ─── FILTER / SEARCH ──────────────────────────────────────

  void setFilter(FilterType filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearData() {
    _transactions = [];
    _activeFilter = FilterType.all;
    _searchQuery = '';
    notifyListeners();
  }
}
