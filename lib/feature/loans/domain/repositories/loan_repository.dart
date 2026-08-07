import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';

abstract interface class LoanRepository {
  Future<List<Loan>> getLoans();

  Future<void> addLoan(Loan loan);

  Future<void> updateLoan(Loan loan);

  Future<void> deleteLoan(String id);

  Future<void> syncPendingLoans();

  Future<void> clearLoans();
  Future<List<LoanPayment>> getPayments();
  Future<void> savePayment(LoanPayment payment);
  Future<void> deletePayment(String id);
}
