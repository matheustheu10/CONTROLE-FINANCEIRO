import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction_model.dart';
import '../core/dependencies.dart';
import '../database/local_database.dart';

enum FilterType { all, income, expense }

class FinanceState {
  final List<TransactionModel> transactions;
  final FilterType filter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const FinanceState({
    this.transactions = const [],
    this.filter = FilterType.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  FinanceState copyWith({
    List<TransactionModel>? transactions,
    FilterType? filter,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FinanceState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<TransactionModel> get filtered {
    var list = transactions;
    if (filter == FilterType.income) list = list.where((t) => t.isIncome).toList();
    if (filter == FilterType.expense) list = list.where((t) => !t.isIncome).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.category.label.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  double get totalIncome => transactions.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  double get totalExpense => transactions.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
  double get balance => totalIncome - totalExpense;

  Map<TransactionCategory, double> get expenseByCategory {
    final map = <TransactionCategory, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FirebaseFirestore _db;
  final LocalDatabase _local;
  final Connectivity _connectivity;
  final String userId;

  FinanceNotifier(this._db, this._local, this._connectivity, this.userId)
      : super(const FinanceState()) {
    loadTransactions();
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);

    // Carrega local primeiro (SQLite)
    try {
      final local = await _local.getTransactions(userId);
      if (local.isNotEmpty) {
        state = state.copyWith(transactions: local, isLoading: false);
      }
    } catch (_) {}

    final online = await _isOnline();
    if (!online) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '📶 Modo offline — dados locais',
      );
      return;
    }

    try {
      final snap = await _db
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          
          .get();
      final list = snap.docs.map((d) => TransactionModel.fromMap(d.data())).toList();
      await _local.saveTransactions(list); // Salva no SQLite
      state = state.copyWith(transactions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao sincronizar. Exibindo dados locais.',
      );
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    try {
      await _db.collection('transactions').doc(tx.id).set(tx.toMap());
      await _local.insertTransaction(tx); // Salva no SQLite
      final list = [tx, ...state.transactions];
      state = state.copyWith(transactions: list);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao salvar. Verifique sua conexão.');
    }
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    try {
      await _db.collection('transactions').doc(tx.id).update(tx.toMap());
      await _local.updateTransaction(tx); // Atualiza no SQLite
      final list = state.transactions.map((t) => t.id == tx.id ? tx : t).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(transactions: list);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao atualizar. Verifique sua conexão.');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _db.collection('transactions').doc(id).delete();
      await _local.deleteTransaction(id); // Remove do SQLite
      final list = state.transactions.where((t) => t.id != id).toList();
      state = state.copyWith(transactions: list);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao excluir. Verifique sua conexão.');
    }
  }

  void setFilter(FilterType f) => state = state.copyWith(filter: f);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void clearData() => state = const FinanceState();
}

final financeProvider = StateNotifierProvider.family<FinanceNotifier, FinanceState, String>((ref, userId) {
  return FinanceNotifier(
    ref.watch(firestoreProvider),
    ref.watch(localDatabaseProvider),
    ref.watch(connectivityProvider),
    userId,
  );
});
