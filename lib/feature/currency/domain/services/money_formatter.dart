import 'package:intl/intl.dart';
import 'package:runearn/feature/currency/domain/entities/currency_definition.dart';

class MoneyFormatter {
  const MoneyFormatter._();

  static String baseCurrency = 'BDT';

  static String formatBase(double value) => format(value, baseCurrency);

  static String format(double value, String currencyCode) {
    final currency = CurrencyCatalog.find(currencyCode);
    final amount = NumberFormat.currency(
      symbol: '',
      decimalDigits: currency.decimalDigits,
    ).format(value).trim();
    return '${currency.symbol} $amount';
  }
}
