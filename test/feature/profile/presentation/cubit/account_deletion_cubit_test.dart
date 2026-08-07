import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:runearn/feature/profile/domain/repositories/account_deletion_repository.dart';
import 'package:runearn/feature/profile/presentation/cubit/account_deletion_cubit.dart';

class _MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

void main() {
  late _MockAccountDeletionRepository repository;

  setUp(() {
    repository = _MockAccountDeletionRepository();
  });

  test('emits progress then success after confirmed deletion', () async {
    when(
      () => repository.deleteCurrentAccount(password: 'secret'),
    ).thenAnswer((_) async {});
    final cubit = AccountDeletionCubit(repository);

    expectLater(
      cubit.stream,
      emitsInOrder([
        const AccountDeletionInProgress(),
        const AccountDeletionSucceeded(),
      ]),
    );

    await cubit.delete(password: 'secret');
    verify(() => repository.deleteCurrentAccount(password: 'secret')).called(1);
    await cubit.close();
  });

  test('keeps the flow recoverable when deletion fails', () async {
    when(
      () => repository.deleteCurrentAccount(password: any(named: 'password')),
    ).thenThrow(StateError('Unable to delete'));
    final cubit = AccountDeletionCubit(repository);

    await cubit.delete(password: 'wrong');

    expect(cubit.state, const AccountDeletionFailed('Unable to delete'));
    await cubit.close();
  });
}
