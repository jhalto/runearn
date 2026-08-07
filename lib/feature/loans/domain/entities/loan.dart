import 'package:equatable/equatable.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';

class Loan extends Equatable {
  final String id;
  final String personName;
  final double amount;
  final LoanDirection direction;
  final String note;
  final DateTime issuedAt;
  final DateTime? dueAt;
  final bool isSettled;
  final double annualInterestRate;
  final LoanInterestMethod interestMethod;
  final bool reminderEnabled;
  final int reminderDaysBefore;

  const Loan({
    required this.id,
    required this.personName,
    required this.amount,
    required this.direction,
    required this.issuedAt,
    this.note = '',
    this.dueAt,
    this.isSettled = false,
    this.annualInterestRate = 0,
    this.interestMethod = LoanInterestMethod.none,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 1,
  });

  Loan copyWith({
    String? id,
    String? personName,
    double? amount,
    LoanDirection? direction,
    String? note,
    DateTime? issuedAt,
    DateTime? dueAt,
    bool clearDueAt = false,
    bool? isSettled,
    double? annualInterestRate,
    LoanInterestMethod? interestMethod,
    bool? reminderEnabled,
    int? reminderDaysBefore,
  }) {
    return Loan(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      note: note ?? this.note,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      isSettled: isSettled ?? this.isSettled,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      interestMethod: interestMethod ?? this.interestMethod,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }

  @override
  List<Object?> get props => [
    id,
    personName,
    amount,
    direction,
    note,
    issuedAt,
    dueAt,
    isSettled,
    annualInterestRate,
    interestMethod,
    reminderEnabled,
    reminderDaysBefore,
  ];

  FinanceAccountType get accountType => direction == LoanDirection.lent
      ? FinanceAccountType.loanGiven
      : FinanceAccountType.loanTaken;
}
