import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';

class LoanModel {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final String direction;
  final String note;
  final String issuedAt;
  final String? dueAt;
  final bool isSettled;
  final double annualInterestRate;
  final String interestMethod;
  final bool reminderEnabled;
  final int reminderDaysBefore;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.direction,
    required this.note,
    required this.issuedAt,
    required this.dueAt,
    required this.isSettled,
    required this.annualInterestRate,
    required this.interestMethod,
    required this.reminderEnabled,
    required this.reminderDaysBefore,
  });

  factory LoanModel.fromEntity(Loan loan, {required String userId}) {
    return LoanModel(
      id: loan.id,
      userId: userId,
      personName: loan.personName,
      amount: loan.amount,
      direction: loan.direction.name,
      note: loan.note,
      issuedAt: loan.issuedAt.toIso8601String(),
      dueAt: loan.dueAt?.toIso8601String(),
      isSettled: loan.isSettled,
      annualInterestRate: loan.annualInterestRate,
      interestMethod: loan.interestMethod.name,
      reminderEnabled: loan.reminderEnabled,
      reminderDaysBefore: loan.reminderDaysBefore,
    );
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      direction: map['direction'] as String,
      note: map['note'] as String? ?? '',
      issuedAt: map['issuedAt'] as String,
      dueAt: map['dueAt'] as String?,
      isSettled:
          (map['isSettled'] as int? ?? 0) == 1 || map['isSettled'] == true,
      annualInterestRate: (map['annualInterestRate'] as num?)?.toDouble() ?? 0,
      interestMethod: map['interestMethod'] as String? ?? 'none',
      reminderEnabled:
          map['reminderEnabled'] == null ||
          map['reminderEnabled'] == true ||
          map['reminderEnabled'] == 1,
      reminderDaysBefore: (map['reminderDaysBefore'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'personName': personName,
    'amount': amount,
    'direction': direction,
    'note': note,
    'issuedAt': issuedAt,
    'dueAt': dueAt,
    'isSettled': isSettled ? 1 : 0,
    'annualInterestRate': annualInterestRate,
    'interestMethod': interestMethod,
    'reminderEnabled': reminderEnabled ? 1 : 0,
    'reminderDaysBefore': reminderDaysBefore,
  };

  Map<String, dynamic> toRemoteMap() => {
    ...toMap(),
    'isSettled': isSettled,
    'reminderEnabled': reminderEnabled,
  };

  Loan toEntity() => Loan(
    id: id,
    personName: personName,
    amount: amount,
    direction: LoanDirection.values.byName(direction),
    note: note,
    issuedAt: DateTime.parse(issuedAt),
    dueAt: dueAt == null ? null : DateTime.parse(dueAt!),
    isSettled: isSettled,
    annualInterestRate: annualInterestRate,
    interestMethod: LoanInterestMethod.values.firstWhere(
      (value) => value.name == interestMethod,
      orElse: () => LoanInterestMethod.none,
    ),
    reminderEnabled: reminderEnabled,
    reminderDaysBefore: reminderDaysBefore.clamp(0, 30),
  );
}
