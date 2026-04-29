import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type;
  final String category;
  final String description;
  final String date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });

  // Entity → Model
  factory TransactionModel.fromEntity(Transaction t) {
    return TransactionModel(
      id: t.id,
      amount: t.amount,
      type: t.type.name,
      category: t.category.name,
      description: t.description,
      date: t.date.toIso8601String(),
    );
  }

  // DB → Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      description: map['description'],
      date: map['date'],
    );
  }

  // Model → DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'date': date,
    };
  }

  // Model → Entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      amount: amount,
      type: TransactionType.values.byName(type),
      category: TransactionCategory.values.byName(category),
      description: description,
      date: DateTime.parse(date),
    );
  }
}