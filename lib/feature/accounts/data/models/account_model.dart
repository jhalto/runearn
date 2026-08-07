import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';

class AccountModel {
  const AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.note,
    required this.createdAt,
    required this.currencyCode,
    this.creditLimit,
    this.statementDay,
    this.paymentDueDay,
    required this.minimumPaymentPercent,
    required this.minimumPaymentAmount,
    required this.paymentReminderEnabled,
    required this.paymentReminderDaysBefore,
  });

  final String id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final String note;
  final String createdAt;
  final String currencyCode;
  final double? creditLimit;
  final int? statementDay;
  final int? paymentDueDay;
  final double minimumPaymentPercent;
  final double minimumPaymentAmount;
  final bool paymentReminderEnabled;
  final int paymentReminderDaysBefore;

  factory AccountModel.fromEntity(
    FinanceAccount account, {
    required String userId,
  }) => AccountModel(
    id: account.id,
    userId: userId,
    name: account.name,
    type: account.type.name,
    balance: account.balance,
    note: account.note,
    createdAt: account.createdAt.toIso8601String(),
    currencyCode: account.currencyCode,
    creditLimit: account.creditLimit,
    statementDay: account.statementDay,
    paymentDueDay: account.paymentDueDay,
    minimumPaymentPercent: account.minimumPaymentPercent,
    minimumPaymentAmount: account.minimumPaymentAmount,
    paymentReminderEnabled: account.paymentReminderEnabled,
    paymentReminderDaysBefore: account.paymentReminderDaysBefore,
  );

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    name: map['name'] as String,
    type: map['type'] as String,
    balance: (map['balance'] as num).toDouble(),
    note: map['note'] as String? ?? '',
    createdAt: map['createdAt'] as String,
    currencyCode: map['currencyCode'] as String? ?? 'BDT',
    creditLimit: (map['creditLimit'] as num?)?.toDouble(),
    statementDay: (map['statementDay'] as num?)?.toInt(),
    paymentDueDay: (map['paymentDueDay'] as num?)?.toInt(),
    minimumPaymentPercent:
        (map['minimumPaymentPercent'] as num?)?.toDouble() ?? 5,
    minimumPaymentAmount:
        (map['minimumPaymentAmount'] as num?)?.toDouble() ?? 0,
    paymentReminderEnabled:
        (map['paymentReminderEnabled'] as num?)?.toInt() != 0,
    paymentReminderDaysBefore:
        (map['paymentReminderDaysBefore'] as num?)?.toInt() ?? 3,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type,
    'balance': balance,
    'note': note,
    'createdAt': createdAt,
    'currencyCode': currencyCode,
    'creditLimit': creditLimit,
    'statementDay': statementDay,
    'paymentDueDay': paymentDueDay,
    'minimumPaymentPercent': minimumPaymentPercent,
    'minimumPaymentAmount': minimumPaymentAmount,
    'paymentReminderEnabled': paymentReminderEnabled ? 1 : 0,
    'paymentReminderDaysBefore': paymentReminderDaysBefore,
  };

  FinanceAccount toEntity() => FinanceAccount(
    id: id,
    name: name,
    type: FinanceAccountType.values.firstWhere(
      (value) => value.name == type,
      orElse: () => FinanceAccountType.cash,
    ),
    balance: balance,
    note: note,
    createdAt: DateTime.parse(createdAt),
    currencyCode: currencyCode,
    creditLimit: creditLimit,
    statementDay: statementDay,
    paymentDueDay: paymentDueDay,
    minimumPaymentPercent: minimumPaymentPercent,
    minimumPaymentAmount: minimumPaymentAmount,
    paymentReminderEnabled: paymentReminderEnabled,
    paymentReminderDaysBefore: paymentReminderDaysBefore,
  );
}
