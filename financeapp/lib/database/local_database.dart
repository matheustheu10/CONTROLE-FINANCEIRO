import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'financeapp_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            is_income INTEGER NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveTransactions(List<TransactionModel> list) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('transactions');
    for (final tx in list) {
      batch.insert('transactions', {
        'id': tx.id,
        'user_id': tx.userId,
        'title': tx.title,
        'amount': tx.amount,
        'is_income': tx.isIncome ? 1 : 0,
        'date': tx.date.toIso8601String(),
        'category': tx.category.name,
        'note': tx.note,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((m) => TransactionModel.fromMap({
      'id': m['id'],
      'user_id': m['user_id'],
      'title': m['title'],
      'amount': m['amount'],
      'is_income': m['is_income'],
      'date': m['date'],
      'category': m['category'],
      'note': m['note'],
    })).toList();
  }

  Future<void> insertTransaction(TransactionModel tx) async {
    final db = await database;
    await db.insert('transactions', {
      'id': tx.id,
      'user_id': tx.userId,
      'title': tx.title,
      'amount': tx.amount,
      'is_income': tx.isIncome ? 1 : 0,
      'date': tx.date.toIso8601String(),
      'category': tx.category.name,
      'note': tx.note,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final db = await database;
    await db.update('transactions', {
      'id': tx.id,
      'user_id': tx.userId,
      'title': tx.title,
      'amount': tx.amount,
      'is_income': tx.isIncome ? 1 : 0,
      'date': tx.date.toIso8601String(),
      'category': tx.category.name,
      'note': tx.note,
    }, where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
