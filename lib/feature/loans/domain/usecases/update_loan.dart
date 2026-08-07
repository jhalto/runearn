import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class UpdateLoan {
  final LoanRepository repository;

  const UpdateLoan(this.repository);

  Future<void> call(Loan loan) => repository.updateLoan(loan);
}
