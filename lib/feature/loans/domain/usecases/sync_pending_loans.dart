import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';

class SyncPendingLoans {
  final LoanRepository repository;

  const SyncPendingLoans(this.repository);

  Future<void> call() => repository.syncPendingLoans();
}
