enum TransactionCategory {
  trabalho,
  alimentacao,
  moradia,
  transporte,
  saude,
  lazer,
  educacao,
  outros,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.trabalho:
        return 'Trabalho';
      case TransactionCategory.alimentacao:
        return 'Alimentação';
      case TransactionCategory.moradia:
        return 'Moradia';
      case TransactionCategory.transporte:
        return 'Transporte';
      case TransactionCategory.saude:
        return 'Saúde';
      case TransactionCategory.lazer:
        return 'Lazer';
      case TransactionCategory.educacao:
        return 'Educação';
      case TransactionCategory.outros:
        return 'Outros';
    }
  }

  String get emoji {
    switch (this) {
      case TransactionCategory.trabalho:
        return '💼';
      case TransactionCategory.alimentacao:
        return '🍽️';
      case TransactionCategory.moradia:
        return '🏠';
      case TransactionCategory.transporte:
        return '🚌';
      case TransactionCategory.saude:
        return '❤️';
      case TransactionCategory.lazer:
        return '🎮';
      case TransactionCategory.educacao:
        return '📚';
      case TransactionCategory.outros:
        return '📦';
    }
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final TransactionCategory category;
  final String? note;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
    this.note,
  });

  TransactionModel copyWith({
    String? title,
    double? amount,
    bool? isIncome,
    DateTime? date,
    TransactionCategory? category,
    String? note,
  }) =>
      TransactionModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        isIncome: isIncome ?? this.isIncome,
        date: date ?? this.date,
        category: category ?? this.category,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'amount': amount,
        'is_income': isIncome ? 1 : 0,
        'date': date.toIso8601String(),
        'category': category.name,
        'note': note,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        isIncome: (m['is_income'] as int) == 1,
        date: DateTime.parse(m['date'] as String),
        category: TransactionCategory.values.firstWhere(
          (c) => c.name == m['category'],
          orElse: () => TransactionCategory.outros,
        ),
        note: m['note'] as String?,
      );
}
