import 'dart:convert';

import 'package:runearn/feature/currency/domain/entities/exchange_rate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyPreferences {
  const CurrencyPreferences();

  static const _baseKey = 'finance_base_currency_v1';
  static const _ratesKey = 'finance_exchange_rates_v1';

  Future<String> loadBaseCurrency() async =>
      (await SharedPreferences.getInstance()).getString(_baseKey) ?? 'BDT';

  Future<List<ExchangeRate>> loadRates() async {
    final source = (await SharedPreferences.getInstance()).getString(_ratesKey);
    if (source == null) {
      return [
        ExchangeRate(
          currencyCode: 'BDT',
          rateToBase: 1,
          updatedAt: DateTime.now().toUtc(),
        ),
      ];
    }
    try {
      final values = jsonDecode(source) as List<dynamic>;
      return values
          .map((value) {
            final map = value as Map<String, dynamic>;
            return ExchangeRate(
              currencyCode: map['currencyCode'] as String,
              rateToBase: (map['rateToBase'] as num).toDouble(),
              updatedAt: DateTime.parse(map['updatedAt'] as String),
            );
          })
          .toList(growable: false);
    } catch (_) {
      throw const FormatException('Saved exchange rates are damaged.');
    }
  }

  Future<void> save({
    required String baseCurrency,
    required Iterable<ExchangeRate> rates,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseKey, baseCurrency);
    await preferences.setString(
      _ratesKey,
      jsonEncode([
        for (final rate in rates)
          {
            'currencyCode': rate.currencyCode,
            'rateToBase': rate.rateToBase,
            'updatedAt': rate.updatedAt.toUtc().toIso8601String(),
          },
      ]),
    );
  }
}
