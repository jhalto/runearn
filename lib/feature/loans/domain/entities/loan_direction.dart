enum LoanDirection {
  lent,
  borrowed;

  String get title => switch (this) {
    LoanDirection.lent => 'Loans Given',
    LoanDirection.borrowed => 'Loans Taken',
  };

  String get emptyMessage => switch (this) {
    LoanDirection.lent => 'No loans given yet',
    LoanDirection.borrowed => 'No loans taken yet',
  };
}
