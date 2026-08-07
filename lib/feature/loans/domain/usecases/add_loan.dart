import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class AddLoan {
  final LoanRepository repository;

  const AddLoan(this.repository);

  Future<void> call(Loan loan) => repository.addLoan(loan);
}
