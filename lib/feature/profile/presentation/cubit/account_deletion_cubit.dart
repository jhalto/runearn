import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:runearn/feature/profile/domain/repositories/account_deletion_repository.dart';

sealed class AccountDeletionState extends Equatable {
  const AccountDeletionState();
  @override
  List<Object?> get props => const [];
}

final class AccountDeletionIdle extends AccountDeletionState {
  const AccountDeletionIdle();
}

final class AccountDeletionInProgress extends AccountDeletionState {
  const AccountDeletionInProgress();
}

final class AccountDeletionSucceeded extends AccountDeletionState {
  const AccountDeletionSucceeded();
}

final class AccountDeletionFailed extends AccountDeletionState {
  const AccountDeletionFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit(this.service) : super(const AccountDeletionIdle());

  final AccountDeletionRepository service;

  Future<void> delete({String? password}) async {
    if (state is AccountDeletionInProgress) return;
    emit(const AccountDeletionInProgress());
    try {
      await service.deleteCurrentAccount(password: password);
      emit(const AccountDeletionSucceeded());
    } on FirebaseAuthException catch (error) {
      emit(AccountDeletionFailed(_firebaseMessage(error)));
    } on GoogleSignInException catch (error) {
      emit(
        AccountDeletionFailed(
          error.code == GoogleSignInExceptionCode.canceled
              ? 'Google verification was cancelled.'
              : error.description ?? 'Google verification failed.',
        ),
      );
    } catch (error) {
      emit(
        AccountDeletionFailed(error.toString().replaceFirst('Bad state: ', '')),
      );
    }
  }

  String _firebaseMessage(FirebaseAuthException error) => switch (error.code) {
    'wrong-password' || 'invalid-credential' => 'The password is incorrect.',
    'requires-recent-login' =>
      'Your login is too old. Sign out, sign in again, and retry.',
    'network-request-failed' =>
      'A network connection is required to delete your account.',
    _ => error.message ?? 'Account deletion failed.',
  };
}
