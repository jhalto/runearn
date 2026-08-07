enum LoanInterestMethod {
  none('No interest'),
  simple('Simple interest'),
  compoundMonthly('Compound monthly');

  const LoanInterestMethod(this.label);
  final String label;
}
