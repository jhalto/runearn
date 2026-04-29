import 'transaction_type.dart';
import 'transaction_category.dart';

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });
}