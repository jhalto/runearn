enum AccountClassification { asset, liability, income, expense, equity }

enum FinanceAccountType {
  cash(AccountClassification.asset, 'Cash'),
  bank(AccountClassification.asset, 'Bank Account'),
  mobileWallet(AccountClassification.asset, 'Mobile Wallet'),
  savings(AccountClassification.asset, 'Savings Account'),
  investment(AccountClassification.asset, 'Investment'),
  otherAsset(AccountClassification.asset, 'Other Asset'),
  loanGiven(AccountClassification.asset, 'Loan Given'),
  loanTaken(AccountClassification.liability, 'Loan Taken'),
  creditCard(AccountClassification.liability, 'Credit Card'),
  lineOfCredit(AccountClassification.liability, 'Line of Credit'),
  mortgage(AccountClassification.liability, 'Mortgage'),
  otherLiability(AccountClassification.liability, 'Other Liability'),
  income(AccountClassification.income, 'Income'),
  expense(AccountClassification.expense, 'Expense'),
  equity(AccountClassification.equity, 'Equity');

  const FinanceAccountType(this.classification, this.label);

  final AccountClassification classification;
  final String label;

  bool get isUserCreatable => switch (this) {
    cash ||
    bank ||
    mobileWallet ||
    savings ||
    investment ||
    otherAsset ||
    creditCard ||
    lineOfCredit ||
    otherLiability => true,
    loanGiven || loanTaken || mortgage || income || expense || equity => false,
  };
}

extension AccountClassificationX on AccountClassification {
  String get label => switch (this) {
    AccountClassification.asset => 'Asset',
    AccountClassification.liability => 'Liability',
    AccountClassification.income => 'Income',
    AccountClassification.expense => 'Expense',
    AccountClassification.equity => 'Equity',
  };
}
