import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

enum FilterType { all, income, expense }

class FinanceState {
  final List<TransactionModel> transactions;
  final FilterType filter;
  final String searchQuery;
  final bool isLoading;

  const FinanceState({
    this.transactions = const [],
    this.filter = FilterType.all,
    this.searchQuery = '',
    this.isLoading = false,
  });

  FinanceState copyWith({
    List<TransactionModel>? transactions,
    FilterType? filter,
    String? searchQuery,
    bool? isLoading,
  }) {
    return FinanceState(
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
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
  final String userId;

  FinanceNotifier(this._db, this.userId) : super(const FinanceState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    try {
      final snap = await _db
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      final list = snap.docs.map((d) => TransactionModel.fromMap(d.data())).toList();
      state = state.copyWith(transactions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _db.collection('transactions').doc(tx.id).set(tx.toMap());
    final list = [tx, ...state.transactions];
    state = state.copyWith(transactions: list);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _db.collection('transactions').doc(tx.id).update(tx.toMap());
    final list = state.transactions.map((t) => t.id == tx.id ? tx : t).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(transactions: list);
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
    final list = state.transactions.where((t) => t.id != id).toList();
    state = state.copyWith(transactions: list);
  }

  void setFilter(FilterType f) => state = state.copyWith(filter: f);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void clearData() => state = const FinanceState();
}

final financeProvider = StateNotifierProvider.family<FinanceNotifier, FinanceState, String>((ref, userId) {
  return FinanceNotifier(ref.watch(firestoreProvider), userId);
});
