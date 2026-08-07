import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/currency/domain/entities/currency_definition.dart';

void main() {
  test(
    'catalog contains the world currency dataset without duplicate codes',
    () {
      final currencies = CurrencyCatalog.supported;
      expect(currencies.length, greaterThan(140));
      expect(
        currencies.map((currency) => currency.code).toSet(),
        hasLength(currencies.length),
      );
    },
  );

  test('currency search matches code, currency name, and country', () {
    final bdt = CurrencyCatalog.find('BDT');
    expect(bdt.matches('BDT'), isTrue);
    expect(bdt.matches('taka'), isTrue);
    expect(bdt.matches('Bangladesh'), isTrue);
  });
}
