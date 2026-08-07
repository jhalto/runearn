enum TransactionCategory {
  // Income - Work
  salary,
  freelance,
  business,
  commission,
  bonus,
  overtime,
  tips,

  // Income - Investment / Assets
  investment,
  dividend,
  interest,
  rentIncome,
  assetSale,
  cryptoProfit,
  stockProfit,

  // Income - Personal
  gift,
  refund,
  cashback,
  reward,
  prize,
  allowance,
  pension,
  grant,
  scholarship,

  // Income - Loan / Finance
  loanReceived,
  debtCollected,
  insuranceClaim,
  taxRefund,

  // Expense - Food
  food,
  groceries,
  restaurant,
  coffee,

  // Expense - Transport
  transport,
  fuel,
  parking,
  rideSharing,
  vehicleMaintenance,

  // Expense - Home
  rent,
  mortgage,
  utilities,
  electricity,
  water,
  gas,
  internet,
  phone,
  homeMaintenance,

  // Expense - Lifestyle
  shopping,
  clothing,
  personalCare,
  entertainment,
  subscriptions,
  travel,
  hotel,
  vacation,

  // Expense - Health
  healthcare,
  medicine,
  doctor,
  hospital,
  fitness,
  insurance,

  // Expense - Education
  education,
  tuition,
  books,
  course,
  examFee,

  // Expense - Family / Social
  family,
  childCare,
  pets,
  donation,
  charity,
  religious,
  wedding,
  event,

  // Expense - Finance
  savings,
  investmentExpense,
  loanRepayment,
  debtPayment,
  creditCardPayment,
  bankFee,
  tax,
  fine,
  penalty,

  // Expense - Business
  office,
  software,
  hosting,
  domain,
  marketing,
  staffSalary,
  businessTravel,

  // Other
  transfer,
  adjustment,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get value {
    switch (this) {
      case TransactionCategory.rentIncome:
        return 'rent_income';
      case TransactionCategory.assetSale:
        return 'asset_sale';
      case TransactionCategory.cryptoProfit:
        return 'crypto_profit';
      case TransactionCategory.stockProfit:
        return 'stock_profit';
      case TransactionCategory.loanReceived:
        return 'loan_received';
      case TransactionCategory.debtCollected:
        return 'debt_collected';
      case TransactionCategory.insuranceClaim:
        return 'insurance_claim';
      case TransactionCategory.taxRefund:
        return 'tax_refund';

      case TransactionCategory.rideSharing:
        return 'ride_sharing';
      case TransactionCategory.vehicleMaintenance:
        return 'vehicle_maintenance';
      case TransactionCategory.homeMaintenance:
        return 'home_maintenance';
      case TransactionCategory.personalCare:
        return 'personal_care';
      case TransactionCategory.examFee:
        return 'exam_fee';
      case TransactionCategory.childCare:
        return 'child_care';

      case TransactionCategory.investmentExpense:
        return 'investment_expense';
      case TransactionCategory.loanRepayment:
        return 'loan_repayment';
      case TransactionCategory.debtPayment:
        return 'debt_payment';
      case TransactionCategory.creditCardPayment:
        return 'credit_card_payment';
      case TransactionCategory.bankFee:
        return 'bank_fee';

      case TransactionCategory.staffSalary:
        return 'staff_salary';
      case TransactionCategory.businessTravel:
        return 'business_travel';

      default:
        return name;
    }
  }

  String get label {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  static TransactionCategory fromValue(String value) {
    return TransactionCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionCategory.other,
    );
  }
}
