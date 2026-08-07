import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class ClearLoans {
  final LoanRepository repository;

  const ClearLoans(this.repository);

  Future<void> call() => repository.clearLoans();
}
