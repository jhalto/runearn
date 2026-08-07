import 'dart:convert';

import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_split.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String category;
  final String? customCategory;
  final String? accountId;
  final String description;
  final String date;
  final String? localReceiptPath;
  final List<String> tags;
  final List<TransactionSplit> splits;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    this.customCategory,
    this.accountId,
    required this.description,
    required this.date,
    this.localReceiptPath,
    this.tags = const [],
    this.splits = const [],
  });

  // Entity → Model
  factory TransactionModel.fromEntity(Transaction t, {required String userId}) {
    return TransactionModel(
      id: t.id,
      userId: userId,
      amount: t.amount,
      type: t.type.name,
      category: t.category.name,
      customCategory: t.customCategory,
      accountId: t.accountId,
      description: t.description,
      date: t.date.toIso8601String(),
      localReceiptPath: t.localReceiptPath,
      tags: t.tags,
      splits: t.splits,
    );
  }

  // DB / Firestore → Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      customCategory: map['customCategory'] as String?,
      accountId: map['accountId'] as String?,
      description: map['description'] as String? ?? '',
      date: map['date'] as String,
      localReceiptPath: map['localReceiptPath'] as String?,
      tags: _readTags(map['tags']),
      splits: _readSplits(map['splits']),
    );
  }

  // Model → DB / Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'customCategory': customCategory,
      'accountId': accountId,
      'description': description,
      'date': date,
      'localReceiptPath': localReceiptPath,
      'tags': tags,
      'splits': splits.map((item) => item.toMap()).toList(),
    };
  }

  // Model → Entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      amount: amount,
      type: TransactionType.values.byName(type),
      category: TransactionCategory.values.firstWhere(
        (value) => value.name == category,
        orElse: () => TransactionCategory.other,
      ),
      customCategory: customCategory,
      accountId: accountId,
      description: description,
      date: DateTime.parse(date),
      localReceiptPath: localReceiptPath,
      tags: tags,
      splits: splits,
    );
  }
}

List<TransactionSplit> _readSplits(Object? value) {
  Object? decoded = value;
  if (value is String && value.trim().isNotEmpty) {
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return const [];
    }
  }
  if (decoded is! List) return const [];
  return List.unmodifiable(
    decoded
        .whereType<Map>()
        .map(
          (item) => TransactionSplit.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.amount > 0),
  );
}

List<String> _readTags(Object? value) {
  Object? decoded = value;
  if (value is String && value.trim().isNotEmpty) {
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      decoded = [value];
    }
  }
  if (decoded is! List) return const [];
  final normalized =
      decoded
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return List.unmodifiable(normalized);
}
