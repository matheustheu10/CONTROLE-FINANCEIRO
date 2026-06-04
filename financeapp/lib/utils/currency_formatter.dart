import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _shortDateFormatter = DateFormat('dd MMM', 'pt_BR');

  static String format(double value) => _formatter.format(value);

  static String formatDate(DateTime date) => _dateFormatter.format(date);

  static String formatShortDate(DateTime date) =>
      _shortDateFormatter.format(date);

  /// Parses a Brazilian-formatted number string like "1.234,56" → 1234.56
  static double? parse(String value) {
    final cleaned = value
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}
