import 'package:equatable/equatable.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';

class NetWorthItem extends Equatable {
  const NetWorthItem({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.currencyCode = 'BDT',
  });

  final String id;
  final String name;
  final FinanceAccountType type;
  final double value;
  final String currencyCode;

  bool get isAsset => type.classification == AccountClassification.asset;

  @override
  List<Object?> get props => [id, name, type, value, currencyCode];
}

class NetWorthSnapshot extends Equatable {
  NetWorthSnapshot({
    required List<NetWorthItem> assets,
    required List<NetWorthItem> liabilities,
  }) : assets = List.unmodifiable(assets),
       liabilities = List.unmodifiable(liabilities);

  final List<NetWorthItem> assets;
  final List<NetWorthItem> liabilities;

  double get totalAssets => assets.fold(0, (total, item) => total + item.value);

  double get totalLiabilities =>
      liabilities.fold(0, (total, item) => total + item.value);

  double get netWorth => totalAssets - totalLiabilities;

  @override
  List<Object?> get props => [assets, liabilities];
}
