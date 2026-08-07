import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/currency/data/currency_preferences.dart';
import 'package:runearn/feature/currency/domain/entities/exchange_rate.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';

class CurrencyState extends Equatable {
  CurrencyState({
    required this.baseCurrency,
    required Iterable<ExchangeRate> rates,
    this.loading = false,
    this.error,
  }) : rates = Map.unmodifiable({
         for (final rate in rates) rate.currencyCode: rate,
       });

  factory CurrencyState.initial() => CurrencyState(
    baseCurrency: 'BDT',
    rates: [
      ExchangeRate(
        currencyCode: 'BDT',
        rateToBase: 1,
        updatedAt: DateTime.now().toUtc(),
      ),
    ],
    loading: true,
  );

  final String baseCurrency;
  final Map<String, ExchangeRate> rates;
  final bool loading;
  final String? error;

  bool supports(String currencyCode) =>
      currencyCode == baseCurrency || rates.containsKey(currencyCode);

  double toBase(double amount, String currencyCode) {
    if (currencyCode == baseCurrency) return amount;
    final rate = rates[currencyCode]?.rateToBase;
    if (rate == null || rate <= 0) {
      throw StateError('Set an exchange rate for $currencyCode first.');
    }
    return amount * rate;
  }

  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    final baseAmount = toBase(amount, from);
    if (to == baseCurrency) return baseAmount;
    final targetRate = rates[to]?.rateToBase;
    if (targetRate == null || targetRate <= 0) {
      throw StateError('Set an exchange rate for $to first.');
    }
    return baseAmount / targetRate;
  }

  @override
  List<Object?> get props => [
    baseCurrency,
    rates.values.toList(growable: false),
    loading,
    error,
  ];
}

class CurrencyCubit extends Cubit<CurrencyState> {
  CurrencyCubit(this.preferences) : super(CurrencyState.initial());

  final CurrencyPreferences preferences;

  Future<void> load() async {
    try {
      final base = await preferences.loadBaseCurrency();
      final rates = await preferences.loadRates();
      final normalized = <String, ExchangeRate>{
        for (final rate in rates) rate.currencyCode: rate,
        base: ExchangeRate(
          currencyCode: base,
          rateToBase: 1,
          updatedAt: DateTime.now().toUtc(),
        ),
      };
      MoneyFormatter.baseCurrency = base;
      emit(CurrencyState(baseCurrency: base, rates: normalized.values));
    } catch (error) {
      emit(
        CurrencyState(
          baseCurrency: state.baseCurrency,
          rates: state.rates.values,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> setRate(String currencyCode, double rateToBase) async {
    if (!rateToBase.isFinite || rateToBase <= 0) {
      throw ArgumentError('Exchange rate must be greater than zero.');
    }
    final code = currencyCode.toUpperCase();
    final updated = Map<String, ExchangeRate>.from(state.rates)
      ..[code] = ExchangeRate(
        currencyCode: code,
        rateToBase: code == state.baseCurrency ? 1 : rateToBase,
        updatedAt: DateTime.now().toUtc(),
      );
    await _save(state.baseCurrency, updated);
  }

  Future<void> setBaseCurrency(String currencyCode) async {
    final code = currencyCode.toUpperCase();
    if (code == state.baseCurrency) return;
    final newBaseRate = state.rates[code]?.rateToBase;
    if (newBaseRate == null || newBaseRate <= 0) {
      throw StateError(
        'Add an exchange rate for $code before making it the base currency.',
      );
    }
    final converted = <String, ExchangeRate>{};
    final now = DateTime.now().toUtc();
    for (final entry in state.rates.entries) {
      converted[entry.key] = ExchangeRate(
        currencyCode: entry.key,
        rateToBase: entry.value.rateToBase / newBaseRate,
        updatedAt: now,
      );
    }
    converted[code] = ExchangeRate(
      currencyCode: code,
      rateToBase: 1,
      updatedAt: now,
    );
    await _save(code, converted);
  }

  Future<void> _save(
    String baseCurrency,
    Map<String, ExchangeRate> rates,
  ) async {
    await preferences.save(baseCurrency: baseCurrency, rates: rates.values);
    MoneyFormatter.baseCurrency = baseCurrency;
    emit(CurrencyState(baseCurrency: baseCurrency, rates: rates.values));
  }
}
