import 'package:flutter_test/flutter_test.dart';
import 'package:runearn/feature/loans/data/models/loan_model.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';

void main() {
  group('LoanModel', () {
    final issuedAt = DateTime.utc(2026, 7, 27);
    final dueAt = DateTime.utc(2026, 8, 27);
    final loan = Loan(
      id: 'loan-1',
      personName: 'Samira',
      amount: 2500,
      direction: LoanDirection.lent,
      note: 'Emergency',
      issuedAt: issuedAt,
      dueAt: dueAt,
    );

    test('round-trips an entity through local storage data', () {
      final model = LoanModel.fromEntity(loan, userId: 'user-1');
      final restored = LoanModel.fromMap(model.toMap()).toEntity();

      expect(restored, loan);
    });

    test('uses a boolean settlement value for Firestore', () {
      final model = LoanModel.fromEntity(
        loan.copyWith(isSettled: true),
        userId: 'user-1',
      );

      expect(model.toRemoteMap()['isSettled'], isTrue);
    });
  });
}
