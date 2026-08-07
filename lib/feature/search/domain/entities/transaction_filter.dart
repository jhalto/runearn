import 'package:equatable/equatable.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

enum TransactionSort {
  newest('Newest first'),
  oldest('Oldest first'),
  amountHigh('Highest amount'),
  amountLow('Lowest amount');

  const TransactionSort(this.label);
  final String label;
}

class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.query = '',
    this.type,
    this.categoryNames = const {},
    this.accountIds = const {},
    this.tags = const {},
    this.from,
    this.to,
    this.minimumAmount,
    this.maximumAmount,
    this.sort = TransactionSort.newest,
  });

  final String query;
  final TransactionType? type;
  final Set<String> categoryNames;
  final Set<String> accountIds;
  final Set<String> tags;
  final DateTime? from;
  final DateTime? to;
  final double? minimumAmount;
  final double? maximumAmount;
  final TransactionSort sort;

  bool get isActive =>
      query.trim().isNotEmpty ||
      type != null ||
      categoryNames.isNotEmpty ||
      accountIds.isNotEmpty ||
      tags.isNotEmpty ||
      from != null ||
      to != null ||
      minimumAmount != null ||
      maximumAmount != null ||
      sort != TransactionSort.newest;

  int get activeFilterCount => [
    if (type != null) 1,
    if (categoryNames.isNotEmpty) 1,
    if (accountIds.isNotEmpty) 1,
    if (tags.isNotEmpty) 1,
    if (from != null || to != null) 1,
    if (minimumAmount != null || maximumAmount != null) 1,
    if (sort != TransactionSort.newest) 1,
  ].length;

  List<Transaction> apply(Iterable<Transaction> source) {
    final needle = query.trim().toLowerCase();
    final result = source.where((item) {
      if (type != null && item.type != type) return false;
      if (categoryNames.isNotEmpty &&
          !item.categoryAllocations.any(
            (allocation) =>
                categoryNames.contains(allocation.categoryName.toLowerCase()),
          )) {
        return false;
      }
      if (accountIds.isNotEmpty && !accountIds.contains(item.accountId)) {
        return false;
      }
      if (tags.isNotEmpty && !tags.every(item.tags.contains)) return false;
      if (from != null && item.date.isBefore(_startOfDay(from!))) return false;
      if (to != null && item.date.isAfter(_endOfDay(to!))) return false;
      if (minimumAmount != null && item.amount < minimumAmount!) return false;
      if (maximumAmount != null && item.amount > maximumAmount!) return false;
      if (needle.isNotEmpty) {
        final haystack = [
          item.description,
          item.categoryName,
          ...item.categoryAllocations.map(
            (allocation) => allocation.categoryName,
          ),
          item.type.name,
          ...item.tags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(needle)) return false;
      }
      return true;
    }).toList();

    result.sort(switch (sort) {
      TransactionSort.newest => (a, b) => b.date.compareTo(a.date),
      TransactionSort.oldest => (a, b) => a.date.compareTo(b.date),
      TransactionSort.amountHigh => (a, b) => b.amount.compareTo(a.amount),
      TransactionSort.amountLow => (a, b) => a.amount.compareTo(b.amount),
    });
    return List.unmodifiable(result);
  }

  TransactionFilter copyWith({
    String? query,
    TransactionType? type,
    bool clearType = false,
    Set<String>? categoryNames,
    Set<String>? accountIds,
    Set<String>? tags,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    double? minimumAmount,
    bool clearMinimumAmount = false,
    double? maximumAmount,
    bool clearMaximumAmount = false,
    TransactionSort? sort,
  }) => TransactionFilter(
    query: query ?? this.query,
    type: clearType ? null : type ?? this.type,
    categoryNames: categoryNames ?? this.categoryNames,
    accountIds: accountIds ?? this.accountIds,
    tags: tags ?? this.tags,
    from: clearFrom ? null : from ?? this.from,
    to: clearTo ? null : to ?? this.to,
    minimumAmount: clearMinimumAmount
        ? null
        : minimumAmount ?? this.minimumAmount,
    maximumAmount: clearMaximumAmount
        ? null
        : maximumAmount ?? this.maximumAmount,
    sort: sort ?? this.sort,
  );

  Map<String, dynamic> toMap() => {
    'query': query,
    'type': type?.name,
    'categories': categoryNames.toList(),
    'accounts': accountIds.toList(),
    'tags': tags.toList(),
    'from': from?.toIso8601String(),
    'to': to?.toIso8601String(),
    'minimumAmount': minimumAmount,
    'maximumAmount': maximumAmount,
    'sort': sort.name,
  };

  factory TransactionFilter.fromMap(Map<String, dynamic> map) =>
      TransactionFilter(
        query: map['query'] as String? ?? '',
        type: TransactionType.values
            .where((value) => value.name == map['type'])
            .firstOrNull,
        categoryNames: _strings(map['categories']),
        accountIds: _strings(map['accounts']),
        tags: _strings(map['tags']),
        from: DateTime.tryParse(map['from'] as String? ?? ''),
        to: DateTime.tryParse(map['to'] as String? ?? ''),
        minimumAmount: (map['minimumAmount'] as num?)?.toDouble(),
        maximumAmount: (map['maximumAmount'] as num?)?.toDouble(),
        sort:
            TransactionSort.values
                .where((value) => value.name == map['sort'])
                .firstOrNull ??
            TransactionSort.newest,
      );

  @override
  List<Object?> get props => [
    query,
    type,
    categoryNames,
    accountIds,
    tags,
    from,
    to,
    minimumAmount,
    maximumAmount,
    sort,
  ];
}

Set<String> _strings(Object? value) => value is List
    ? value.map((item) => item.toString()).toSet()
    : const <String>{};

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
