import 'package:equatable/equatable.dart';
import 'transaction_filter.dart';

class SavedTransactionFilter extends Equatable {
  const SavedTransactionFilter({
    required this.id,
    required this.name,
    required this.filter,
    required this.createdAt,
  });

  final String id;
  final String name;
  final TransactionFilter filter;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'filter': filter.toMap(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedTransactionFilter.fromMap(Map<String, dynamic> map) =>
      SavedTransactionFilter(
        id: map['id'] as String,
        name: map['name'] as String,
        filter: TransactionFilter.fromMap(
          Map<String, dynamic>.from(map['filter'] as Map),
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id, name, filter, createdAt];
}
