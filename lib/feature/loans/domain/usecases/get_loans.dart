import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class GetLoans {
  final LoanRepository repository;

  const GetLoans(this.repository);

  Future<List<Loan>> call() => repository.getLoans();
}
