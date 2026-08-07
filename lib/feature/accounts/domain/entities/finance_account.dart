import 'package:equatable/equatable.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';

class FinanceAccount extends Equatable {
  const FinanceAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
    this.currencyCode = 'BDT',
    this.note = '',
    this.creditLimit,
    this.statementDay,
    this.paymentDueDay,
    this.minimumPaymentPercent = 5,
    this.minimumPaymentAmount = 0,
    this.paymentReminderEnabled = true,
    this.paymentReminderDaysBefore = 3,
  });

  final String id;
  final String name;
  final FinanceAccountType type;
  final double balance;
  final String note;
  final DateTime createdAt;
  final String currencyCode;
  final double? creditLimit;
  final int? statementDay;
  final int? paymentDueDay;
  final double minimumPaymentPercent;
  final double minimumPaymentAmount;
  final bool paymentReminderEnabled;
  final int paymentReminderDaysBefore;

  FinanceAccount copyWith({
    String? name,
    FinanceAccountType? type,
    double? balance,
    String? note,
    String? currencyCode,
    double? creditLimit,
    int? statementDay,
    int? paymentDueDay,
    double? minimumPaymentPercent,
    double? minimumPaymentAmount,
    bool? paymentReminderEnabled,
    int? paymentReminderDaysBefore,
  }) => FinanceAccount(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    note: note ?? this.note,
    createdAt: createdAt,
    currencyCode: currencyCode ?? this.currencyCode,
    creditLimit: creditLimit ?? this.creditLimit,
    statementDay: statementDay ?? this.statementDay,
    paymentDueDay: paymentDueDay ?? this.paymentDueDay,
    minimumPaymentPercent: minimumPaymentPercent ?? this.minimumPaymentPercent,
    minimumPaymentAmount: minimumPaymentAmount ?? this.minimumPaymentAmount,
    paymentReminderEnabled:
        paymentReminderEnabled ?? this.paymentReminderEnabled,
    paymentReminderDaysBefore:
        paymentReminderDaysBefore ?? this.paymentReminderDaysBefore,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    note,
    createdAt,
    currencyCode,
    creditLimit,
    statementDay,
    paymentDueDay,
    minimumPaymentPercent,
    minimumPaymentAmount,
    paymentReminderEnabled,
    paymentReminderDaysBefore,
  ];
}
