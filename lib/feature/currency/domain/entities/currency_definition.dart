import 'package:countries_utils/countries_data.dart';
import 'package:equatable/equatable.dart';

class CurrencyDefinition extends Equatable {
  const CurrencyDefinition({
    required this.code,
    required this.name,
    required this.symbol,
    this.countries = const [],
    this.decimalDigits = 2,
  });

  final String code;
  final String name;
  final String symbol;
  final List<String> countries;
  final int decimalDigits;

  String get countryLabel => countries.join(', ');

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return code.toLowerCase().contains(normalized) ||
        name.toLowerCase().contains(normalized) ||
        countries.any((country) => country.toLowerCase().contains(normalized));
  }

  @override
  List<Object?> get props => [code, name, symbol, countries, decimalDigits];
}

class CurrencyCatalog {
  const CurrencyCatalog._();

  /// Offline catalog built from 250 countries and their active currencies.
  static final List<CurrencyDefinition> supported = _buildCatalog();

  static CurrencyDefinition find(String code) => supported.firstWhere(
    (currency) => currency.code == code.toUpperCase(),
    orElse: () => CurrencyDefinition(
      code: code.toUpperCase(),
      name: code.toUpperCase(),
      symbol: code.toUpperCase(),
    ),
  );

  static List<CurrencyDefinition> _buildCatalog() {
    final records = <String, _CurrencyRecord>{};
    for (final country in countriesData) {
      final countryName = country['name'] as String? ?? '';
      final currencies = country['currencies'];
      if (currencies is! List) continue;
      for (final value in currencies) {
        if (value is! Map) continue;
        final code = value['code']?.toString().toUpperCase() ?? '';
        if (code.length != 3) continue;
        final record = records.putIfAbsent(
          code,
          () => _CurrencyRecord(
            name: value['name']?.toString() ?? code,
            symbol: value['symbol']?.toString() ?? code,
          ),
        );
        if (countryName.isNotEmpty) record.countries.add(countryName);
      }
    }
    final result =
        records.entries
            .map((entry) {
              final countries = entry.value.countries.toList(growable: false)
                ..sort();
              return CurrencyDefinition(
                code: entry.key,
                name: entry.value.name,
                symbol: entry.value.symbol.isEmpty
                    ? entry.key
                    : entry.value.symbol,
                countries: countries,
                decimalDigits: _decimalDigits(entry.key),
              );
            })
            .toList(growable: false)
          ..sort((left, right) => left.code.compareTo(right.code));
    return List.unmodifiable(result);
  }

  static int _decimalDigits(String code) {
    if (const {
      'BIF',
      'CLP',
      'DJF',
      'GNF',
      'ISK',
      'JPY',
      'KMF',
      'KRW',
      'PYG',
      'RWF',
      'UGX',
      'UYI',
      'VND',
      'VUV',
      'XAF',
      'XOF',
      'XPF',
    }.contains(code)) {
      return 0;
    }
    if (const {
      'BHD',
      'IQD',
      'JOD',
      'KWD',
      'LYD',
      'OMR',
      'TND',
    }.contains(code)) {
      return 3;
    }
    if (code == 'CLF') return 4;
    return 2;
  }
}

class _CurrencyRecord {
  _CurrencyRecord({required this.name, required this.symbol});

  final String name;
  final String symbol;
  final Set<String> countries = {};
}
