enum TransactionCategory {
  // 💰 Income
  salary,
  freelance,
  business,
  bonus,
  investment,
  gift,
  refund,
  cashback,

  // 💸 Expenses
  food,
  transport,
  rent,
  utilities, // electricity, water, gas, internet
  shopping,
  healthcare,
  education,
  entertainment,
  travel,
  subscriptions,
  insurance,

  // 💰 Financial movements
  savings,
  loanReceived,
  loanRepayment,
  debtPayment,

  // 🧠 Other
  tax,
  fine,
  donation,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get value {
    switch (this) {
      case TransactionCategory.loanReceived:
        return "loan_received";
      case TransactionCategory.loanRepayment:
        return "loan_repayment";
      case TransactionCategory.debtPayment:
        return "debt_payment";
      default:
        return name;
    }
  }

  static TransactionCategory fromValue(String value) {
    return TransactionCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionCategory.other,
    );
  }
}