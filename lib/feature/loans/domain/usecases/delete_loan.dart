import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class DeleteLoan {
  final LoanRepository repository;

  const DeleteLoan(this.repository);

  Future<void> call(String id) => repository.deleteLoan(id);
}
