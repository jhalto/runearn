import 'dart:convert';

import 'package:runearn/core/security/backup_cipher.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/repositories/account_repository.dart';
import 'package:runearn/feature/backup/domain/entities/backup_result.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';
import 'package:runearn/feature/budgets/domain/repositories/budget_repository.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';
import 'package:runearn/feature/goals/domain/repositories/goal_repository.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';
import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:runearn/feature/recurring/domain/repositories/recurring_repository.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_split.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';
import 'package:runearn/feature/tours/domain/repositories/tour_repository.dart';
import 'package:runearn/feature/currency/data/currency_preferences.dart';
import 'package:runearn/feature/currency/domain/entities/exchange_rate.dart';

class FinanceBackupService {
  FinanceBackupService({
    required this.accounts,
    required this.transactions,
    required this.loans,
    required this.budgets,
    required this.goals,
    required this.recurring,
    required this.tours,
    required this.currencyPreferences,
    BackupCipher? backupCipher,
  }) : _backupCipher = backupCipher ?? BackupCipher();

  static const version = 9;
  final AccountRepository accounts;
  final TransactionRepository transactions;
  final LoanRepository loans;
  final BudgetRepository budgets;
  final GoalRepository goals;
  final RecurringRepository recurring;
  final TourRepository tours;
  final CurrencyPreferences currencyPreferences;
  final BackupCipher _backupCipher;

  Future<String> createBackup(String password) async {
    final clearText = await _createClearTextBackup();
    return _backupCipher.encrypt(clearText, password);
  }

  Future<String> _createClearTextBackup() async {
    final accountItems = await accounts.getAccounts();
    final transferItems = await accounts.getTransfers();
    final transactionItems = await transactions.getTransactions();
    final loanItems = await loans.getLoans();
    final loanPaymentItems = await loans.getPayments();
    final budgetItems = await budgets.getBudgets();
    final goalItems = await goals.getGoals();
    final contributionItems = await goals.getContributions();
    final recurringItems = await recurring.getRecurringTransactions();
    final tourItems = await tours.getTours();
    final tourCollectionItems = await tours.getCollections();
    final tourExpenseItems = await tours.getExpenses();
    final baseCurrency = await currencyPreferences.loadBaseCurrency();
    final exchangeRates = await currencyPreferences.loadRates();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'RunEarn',
      'version': version,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'accounts': accountItems.map(_accountToMap).toList(),
        'transfers': transferItems.map(_transferToMap).toList(),
        'transactions': transactionItems.map(_transactionToMap).toList(),
        'loans': loanItems.map(_loanToMap).toList(),
        'loanPayments': loanPaymentItems.map(_loanPaymentToMap).toList(),
        'budgets': budgetItems.map(_budgetToMap).toList(),
        'goals': goalItems.map(_goalToMap).toList(),
        'goalContributions': contributionItems.map(_contributionToMap).toList(),
        'recurring': recurringItems.map(_recurringToMap).toList(),
        'tours': tourItems.map(_tourToMap).toList(),
        'tourCollections': tourCollectionItems
            .map(_tourCollectionToMap)
            .toList(),
        'tourExpenses': tourExpenseItems.map(_tourExpenseToMap).toList(),
        'currency': {
          'baseCurrency': baseCurrency,
          'rates': [
            for (final rate in exchangeRates)
              {
                'currencyCode': rate.currencyCode,
                'rateToBase': rate.rateToBase,
                'updatedAt': rate.updatedAt.toIso8601String(),
              },
          ],
        },
      },
    });
  }

  Future<BackupResult> restore(String source, String password) async {
    final clearText = await _backupCipher.decrypt(source, password);
    final root = _map(jsonDecode(clearText), 'backup');
    if (root['app'] != 'RunEarn') {
      throw const FormatException('This is not a RunEarn backup.');
    }
    if (root['version'] != 1 &&
        root['version'] != 2 &&
        root['version'] != 3 &&
        root['version'] != 4 &&
        root['version'] != 5 &&
        root['version'] != 6 &&
        root['version'] != 7 &&
        root['version'] != 8 &&
        root['version'] != version) {
      throw FormatException('Unsupported backup version: ${root['version']}.');
    }
    final data = _map(root['data'], 'data');
    final accountItems = _list(data, 'accounts').map(_accountFromMap).toList();
    final transferItems = _list(
      data,
      'transfers',
    ).map(_transferFromMap).toList();
    final transactionItems = _list(
      data,
      'transactions',
    ).map(_transactionFromMap).toList();
    final loanItems = _list(data, 'loans').map(_loanFromMap).toList();
    final paymentItems = _list(
      data,
      'loanPayments',
    ).map(_loanPaymentFromMap).toList();
    final budgetItems = _list(data, 'budgets').map(_budgetFromMap).toList();
    final goalItems = _list(data, 'goals').map(_goalFromMap).toList();
    final contributionItems = _list(
      data,
      'goalContributions',
    ).map(_contributionFromMap).toList();
    final recurringItems = _list(
      data,
      'recurring',
    ).map(_recurringFromMap).toList();
    final tourItems = _optionalList(data, 'tours').map(_tourFromMap).toList();
    final tourCollectionItems = _optionalList(
      data,
      'tourCollections',
    ).map(_tourCollectionFromMap).toList();
    final tourExpenseItems = _optionalList(
      data,
      'tourExpenses',
    ).map(_tourExpenseFromMap).toList();
    final currencyData = data['currency'] is Map
        ? _map(data['currency'], 'currency')
        : null;
    if (currencyData != null) {
      final baseCurrency = _string(currencyData, 'baseCurrency');
      final rates = _list(currencyData, 'rates')
          .map(
            (map) => ExchangeRate(
              currencyCode: _string(map, 'currencyCode'),
              rateToBase: _number(map, 'rateToBase'),
              updatedAt: _date(map, 'updatedAt'),
            ),
          )
          .toList(growable: false);
      await currencyPreferences.save(baseCurrency: baseCurrency, rates: rates);
    }

    for (final item in accountItems) {
      await accounts.saveAccount(item);
    }
    for (final item in transferItems) {
      await accounts.saveTransfer(item);
    }
    for (final item in transactionItems) {
      await transactions.addTransaction(item);
    }
    for (final item in loanItems) {
      await loans.updateLoan(item);
    }
    for (final item in paymentItems) {
      await loans.savePayment(item);
    }
    for (final item in budgetItems) {
      await budgets.saveBudget(item);
    }
    for (final item in goalItems) {
      await goals.saveGoal(item);
    }
    for (final item in contributionItems) {
      await goals.saveContribution(item);
    }
    for (final item in recurringItems) {
      await recurring.save(item);
    }
    for (final item in tourItems) {
      await tours.saveTour(item);
    }
    for (final item in tourCollectionItems) {
      await tours.saveCollection(item);
    }
    for (final item in tourExpenseItems) {
      await tours.saveExpense(item);
    }
    return BackupResult(
      accounts: accountItems.length,
      transfers: transferItems.length,
      transactions: transactionItems.length,
      loans: loanItems.length,
      loanPayments: paymentItems.length,
      budgets: budgetItems.length,
      goals: goalItems.length,
      goalContributions: contributionItems.length,
      recurring: recurringItems.length,
      tours: tourItems.length,
      tourCollections: tourCollectionItems.length,
      tourExpenses: tourExpenseItems.length,
    );
  }

  Future<String> createTransactionsCsv() async {
    final items = await transactions.getTransactions();
    final rows = <List<String>>[
      ['id', 'date', 'type', 'amount', 'category', 'description', 'accountId'],
      for (final item in items)
        [
          item.id,
          item.date.toIso8601String(),
          item.type.name,
          item.amount.toStringAsFixed(2),
          item.categoryName,
          item.description,
          item.accountId ?? '',
        ],
    ];
    return rows.map((row) => row.map(_csv).join(',')).join('\r\n');
  }
}

Map<String, dynamic> _accountToMap(FinanceAccount value) => {
  'id': value.id,
  'name': value.name,
  'type': value.type.name,
  'balance': value.balance,
  'note': value.note,
  'createdAt': value.createdAt.toIso8601String(),
  'currencyCode': value.currencyCode,
  'creditLimit': value.creditLimit,
  'statementDay': value.statementDay,
  'paymentDueDay': value.paymentDueDay,
  'minimumPaymentPercent': value.minimumPaymentPercent,
  'minimumPaymentAmount': value.minimumPaymentAmount,
  'paymentReminderEnabled': value.paymentReminderEnabled,
  'paymentReminderDaysBefore': value.paymentReminderDaysBefore,
};
FinanceAccount _accountFromMap(Map<String, dynamic> map) => FinanceAccount(
  id: _string(map, 'id'),
  name: _string(map, 'name'),
  type: _enum(FinanceAccountType.values, _string(map, 'type'), 'account type'),
  balance: _number(map, 'balance'),
  note: _optionalString(map, 'note') ?? '',
  createdAt: _date(map, 'createdAt'),
  currencyCode: _optionalString(map, 'currencyCode') ?? 'BDT',
  creditLimit: (map['creditLimit'] as num?)?.toDouble(),
  statementDay: (map['statementDay'] as num?)?.toInt(),
  paymentDueDay: (map['paymentDueDay'] as num?)?.toInt(),
  minimumPaymentPercent:
      (map['minimumPaymentPercent'] as num?)?.toDouble() ?? 5,
  minimumPaymentAmount: (map['minimumPaymentAmount'] as num?)?.toDouble() ?? 0,
  paymentReminderEnabled: map['paymentReminderEnabled'] as bool? ?? true,
  paymentReminderDaysBefore:
      (map['paymentReminderDaysBefore'] as num?)?.toInt() ?? 3,
);

Map<String, dynamic> _transferToMap(AccountTransfer value) => {
  'id': value.id,
  'fromAccountId': value.fromAccountId,
  'toAccountId': value.toAccountId,
  'amount': value.amount,
  'receivedAmount': value.receivedAmount,
  'date': value.date.toIso8601String(),
  'note': value.note,
};
AccountTransfer _transferFromMap(Map<String, dynamic> map) => AccountTransfer(
  id: _string(map, 'id'),
  fromAccountId: _string(map, 'fromAccountId'),
  toAccountId: _string(map, 'toAccountId'),
  amount: _number(map, 'amount'),
  receivedAmount: map['receivedAmount'] == null
      ? _number(map, 'amount')
      : _number(map, 'receivedAmount'),
  date: _date(map, 'date'),
  note: _optionalString(map, 'note') ?? '',
);

Map<String, dynamic> _transactionToMap(Transaction value) => {
  'id': value.id,
  'amount': value.amount,
  'type': value.type.name,
  'category': value.category.value,
  'customCategory': value.customCategory,
  'accountId': value.accountId,
  'description': value.description,
  'date': value.date.toIso8601String(),
  'tags': value.tags,
  'splits': value.splits.map((item) => item.toMap()).toList(),
};
Transaction _transactionFromMap(Map<String, dynamic> map) => Transaction(
  id: _string(map, 'id'),
  amount: _number(map, 'amount'),
  type: _enum(TransactionType.values, _string(map, 'type'), 'transaction type'),
  category: TransactionCategoryX.fromValue(_string(map, 'category')),
  customCategory: _optionalString(map, 'customCategory'),
  accountId: _optionalString(map, 'accountId'),
  description: _optionalString(map, 'description') ?? '',
  date: _date(map, 'date'),
  tags: _optionalStringList(map, 'tags'),
  splits: _optionalList(
    map,
    'splits',
  ).map(TransactionSplit.fromMap).toList(growable: false),
);

Map<String, dynamic> _loanToMap(Loan value) => {
  'id': value.id,
  'personName': value.personName,
  'amount': value.amount,
  'direction': value.direction.name,
  'note': value.note,
  'issuedAt': value.issuedAt.toIso8601String(),
  'dueAt': value.dueAt?.toIso8601String(),
  'isSettled': value.isSettled,
  'annualInterestRate': value.annualInterestRate,
  'interestMethod': value.interestMethod.name,
  'reminderEnabled': value.reminderEnabled,
  'reminderDaysBefore': value.reminderDaysBefore,
};
Loan _loanFromMap(Map<String, dynamic> map) => Loan(
  id: _string(map, 'id'),
  personName: _string(map, 'personName'),
  amount: _number(map, 'amount'),
  direction: _enum(
    LoanDirection.values,
    _string(map, 'direction'),
    'loan direction',
  ),
  note: _optionalString(map, 'note') ?? '',
  issuedAt: _date(map, 'issuedAt'),
  dueAt: _optionalDate(map, 'dueAt'),
  isSettled: _boolean(map, 'isSettled'),
  annualInterestRate: map['annualInterestRate'] == null
      ? 0
      : _number(map, 'annualInterestRate'),
  interestMethod: map['interestMethod'] == null
      ? LoanInterestMethod.none
      : _enum(
          LoanInterestMethod.values,
          _string(map, 'interestMethod'),
          'loan interest method',
        ),
  reminderEnabled:
      map['reminderEnabled'] == null || _boolean(map, 'reminderEnabled'),
  reminderDaysBefore: map['reminderDaysBefore'] is num
      ? (map['reminderDaysBefore'] as num).toInt().clamp(0, 30)
      : 1,
);

Map<String, dynamic> _loanPaymentToMap(LoanPayment value) => {
  'id': value.id,
  'loanId': value.loanId,
  'amount': value.amount,
  'date': value.date.toIso8601String(),
  'note': value.note,
};
LoanPayment _loanPaymentFromMap(Map<String, dynamic> map) => LoanPayment(
  id: _string(map, 'id'),
  loanId: _string(map, 'loanId'),
  amount: _number(map, 'amount'),
  date: _date(map, 'date'),
  note: _optionalString(map, 'note') ?? '',
);

Map<String, dynamic> _budgetToMap(Budget value) => {
  'id': value.id,
  'categoryName': value.categoryName,
  'limit': value.limit,
  'month': value.month.toIso8601String(),
  'rolloverEnabled': value.rolloverEnabled,
  'isTemplate': value.isTemplate,
  'templateName': value.templateName,
};
Budget _budgetFromMap(Map<String, dynamic> map) => Budget(
  id: _string(map, 'id'),
  categoryName: _string(map, 'categoryName'),
  limit: _number(map, 'limit'),
  month: _date(map, 'month'),
  rolloverEnabled: map['rolloverEnabled'] as bool? ?? false,
  isTemplate: map['isTemplate'] as bool? ?? false,
  templateName: _optionalString(map, 'templateName') ?? '',
);

Map<String, dynamic> _goalToMap(FinancialGoal value) => {
  'id': value.id,
  'name': value.name,
  'targetAmount': value.targetAmount,
  'createdAt': value.createdAt.toIso8601String(),
  'deadline': value.deadline?.toIso8601String(),
  'note': value.note,
};
FinancialGoal _goalFromMap(Map<String, dynamic> map) => FinancialGoal(
  id: _string(map, 'id'),
  name: _string(map, 'name'),
  targetAmount: _number(map, 'targetAmount'),
  createdAt: _date(map, 'createdAt'),
  deadline: _optionalDate(map, 'deadline'),
  note: _optionalString(map, 'note') ?? '',
);

Map<String, dynamic> _contributionToMap(GoalContribution value) => {
  'id': value.id,
  'goalId': value.goalId,
  'amount': value.amount,
  'date': value.date.toIso8601String(),
  'note': value.note,
  'sourceAccountId': value.sourceAccountId,
  'goalAccountId': value.goalAccountId,
  'transferId': value.transferId,
};
GoalContribution _contributionFromMap(Map<String, dynamic> map) =>
    GoalContribution(
      id: _string(map, 'id'),
      goalId: _string(map, 'goalId'),
      amount: _number(map, 'amount'),
      date: _date(map, 'date'),
      note: _optionalString(map, 'note') ?? '',
      sourceAccountId: _optionalString(map, 'sourceAccountId'),
      goalAccountId: _optionalString(map, 'goalAccountId'),
      transferId: _optionalString(map, 'transferId'),
    );

Map<String, dynamic> _recurringToMap(RecurringTransaction value) => {
  'id': value.id,
  'title': value.title,
  'amount': value.amount,
  'type': value.type.name,
  'category': value.category.value,
  'customCategory': value.customCategory,
  'accountId': value.accountId,
  'frequency': value.frequency.name,
  'nextDue': value.nextDue.toIso8601String(),
  'note': value.note,
  'isActive': value.isActive,
};
RecurringTransaction _recurringFromMap(Map<String, dynamic> map) =>
    RecurringTransaction(
      id: _string(map, 'id'),
      title: _string(map, 'title'),
      amount: _number(map, 'amount'),
      type: _enum(
        TransactionType.values,
        _string(map, 'type'),
        'transaction type',
      ),
      category: TransactionCategoryX.fromValue(_string(map, 'category')),
      customCategory: _optionalString(map, 'customCategory'),
      accountId: _optionalString(map, 'accountId'),
      frequency: _enum(
        RecurrenceFrequency.values,
        _string(map, 'frequency'),
        'frequency',
      ),
      nextDue: _date(map, 'nextDue'),
      note: _optionalString(map, 'note') ?? '',
      isActive: _boolean(map, 'isActive'),
    );

Map<String, dynamic> _tourToMap(Tour value) => {
  'id': value.id,
  'name': value.name,
  'destination': value.destination,
  'startDate': value.startDate.toIso8601String(),
  'endDate': value.endDate.toIso8601String(),
  'budget': value.budget,
  'status': value.status.name,
  'note': value.note,
};
Tour _tourFromMap(Map<String, dynamic> map) => Tour(
  id: _string(map, 'id'),
  name: _string(map, 'name'),
  destination: _string(map, 'destination'),
  startDate: _date(map, 'startDate'),
  endDate: _date(map, 'endDate'),
  budget: _number(map, 'budget'),
  status: _enum(TourStatus.values, _string(map, 'status'), 'tour status'),
  note: _optionalString(map, 'note') ?? '',
);

Map<String, dynamic> _tourCollectionToMap(TourCollection value) => {
  'id': value.id,
  'tourId': value.tourId,
  'memberName': value.memberName,
  'amount': value.amount,
  'date': value.date.toIso8601String(),
  'note': value.note,
};
TourCollection _tourCollectionFromMap(Map<String, dynamic> map) =>
    TourCollection(
      id: _string(map, 'id'),
      tourId: _string(map, 'tourId'),
      memberName: _string(map, 'memberName'),
      amount: _number(map, 'amount'),
      date: _date(map, 'date'),
      note: _optionalString(map, 'note') ?? '',
    );

Map<String, dynamic> _tourExpenseToMap(TourExpense value) => {
  'id': value.id,
  'tourId': value.tourId,
  'title': value.title,
  'category': value.category,
  'amount': value.amount,
  'date': value.date.toIso8601String(),
  'note': value.note,
};
TourExpense _tourExpenseFromMap(Map<String, dynamic> map) => TourExpense(
  id: _string(map, 'id'),
  tourId: _string(map, 'tourId'),
  title: _string(map, 'title'),
  category: _string(map, 'category'),
  amount: _number(map, 'amount'),
  date: _date(map, 'date'),
  note: _optionalString(map, 'note') ?? '',
);

Map<String, dynamic> _map(Object? value, String field) {
  if (value is! Map) throw FormatException('$field must be an object.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, dynamic>> _list(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! List) throw FormatException('$field must be a list.');
  return value.map((item) => _map(item, field)).toList(growable: false);
}

List<Map<String, dynamic>> _optionalList(
  Map<String, dynamic> map,
  String field,
) {
  if (!map.containsKey(field)) return const [];
  return _list(map, field);
}

List<String> _optionalStringList(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value == null) return const [];
  if (value is! List) throw FormatException('$field must be a list.');
  return value
      .map((item) {
        if (item is! String) {
          throw FormatException('$field must contain only strings.');
        }
        return item.trim().toLowerCase();
      })
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

String _string(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value == null) return null;
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

double _number(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! num || !value.isFinite) {
    throw FormatException('$field must be a valid number.');
  }
  return value.toDouble();
}

bool _boolean(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! bool) throw FormatException('$field must be true or false.');
  return value;
}

DateTime _date(Map<String, dynamic> map, String field) {
  final value = _string(map, field);
  final date = DateTime.tryParse(value);
  if (date == null) throw FormatException('$field must be a valid date.');
  return date;
}

DateTime? _optionalDate(Map<String, dynamic> map, String field) {
  final value = _optionalString(map, field);
  if (value == null) return null;
  final date = DateTime.tryParse(value);
  if (date == null) throw FormatException('$field must be a valid date.');
  return date;
}

T _enum<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown $field: $name.');
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';
