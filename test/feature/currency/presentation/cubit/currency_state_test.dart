import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/currency/domain/entities/exchange_rate.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

void main() {
  final state = CurrencyState(
    baseCurrency: 'BDT',
    rates: [
      ExchangeRate(
        currencyCode: 'BDT',
        rateToBase: 1,
        updatedAt: DateTime.utc(2026),
      ),
      ExchangeRate(
        currencyCode: 'USD',
        rateToBase: 122,
        updatedAt: DateTime.utc(2026),
      ),
      ExchangeRate(
        currencyCode: 'EUR',
        rateToBase: 140,
        updatedAt: DateTime.utc(2026),
      ),
    ],
  );

  test('converts native account amount into base currency', () {
    expect(state.toBase(10, 'USD'), 1220);
  });

  test('converts between two non-base currencies through base', () {
    expect(state.convert(140, 'EUR', 'USD'), closeTo(160.6557, .0001));
  });

  test('rejects a conversion without a configured rate', () {
    expect(() => state.toBase(10, 'GBP'), throwsStateError);
  });
}
