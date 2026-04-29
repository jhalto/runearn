import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class CategoryHelper {
  static List<TransactionCategory> getByType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return [
          TransactionCategory.salary,
          TransactionCategory.freelance,
          TransactionCategory.business,
          TransactionCategory.bonus,
          TransactionCategory.investment,
          TransactionCategory.gift,
          TransactionCategory.refund,
          TransactionCategory.cashback,

          // financial inflow
          TransactionCategory.loanReceived,
        ];

      case TransactionType.expense:
        return [
          TransactionCategory.food,
          TransactionCategory.transport,
          TransactionCategory.rent,
          TransactionCategory.utilities,
          TransactionCategory.shopping,
          TransactionCategory.healthcare,
          TransactionCategory.education,
          TransactionCategory.entertainment,
          TransactionCategory.travel,
          TransactionCategory.subscriptions,
          TransactionCategory.insurance,
          TransactionCategory.tax,
          TransactionCategory.fine,
          TransactionCategory.donation,

          // financial outflow
          TransactionCategory.loanRepayment,
          TransactionCategory.debtPayment,
        ];
    }
  }
}