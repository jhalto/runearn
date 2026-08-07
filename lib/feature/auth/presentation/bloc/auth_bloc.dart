import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:runearn/feature/auth/domain/usecases/google_login_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/guest_login_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/login_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/logout_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/register_use_case.dart';
import 'package:runearn/feature/profile/domain/usecases/create_or_update_user_profile_use_case.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final GuestLoginUseCase guestLoginUseCase;
  final LogoutUseCase logoutUseCase;
  final CreateOrUpdateUserProfileUseCase createOrUpdateUserProfileUseCase;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.googleLoginUseCase,
    required this.guestLoginUseCase,
    required this.logoutUseCase,
    required this.createOrUpdateUserProfileUseCase,
  }) : super(
         FirebaseAuth.instance.currentUser != null
             ? AuthAuthenticated(user: FirebaseAuth.instance.currentUser!)
             : AuthInitial(),
       ) {
    on<CheckAuthStatusEvent>(_checkAuthStatus);
    on<RegisterWithEmailPasswordEvent>(_registerWithEmailPassword);
    on<LoginWithEmailPasswordEvent>(_loginWithEmailPassword);
    on<LoginWithGoogleEvent>(_loginWithGoogle);
    on<LoginAsGuestEvent>(_loginAsGuest);
    on<LogoutEvent>(_logout);
    on<AccountDeletedEvent>((_, emit) => emit(AuthUnauthenticated()));
  }

  Future<void> _checkAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) {
      emit(AuthLoading());
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }

      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser ?? user;

      await createOrUpdateUserProfileUseCase(updatedUser);

      emit(AuthAuthenticated(user: updatedUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? 'Auth check failed'));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _registerWithEmailPassword(
    RegisterWithEmailPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final userCredential = await registerUseCase(event.credential);
      final user = userCredential.user;

      if (user == null) {
        emit(AuthFailure(message: 'Registration failed. User not found.'));
        return;
      }

      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser ?? user;

      await createOrUpdateUserProfileUseCase(updatedUser);

      emit(AuthAuthenticated(user: updatedUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? 'Registration failed'));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _loginWithEmailPassword(
    LoginWithEmailPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final userCredential = await loginUseCase(event.credential);
      final user = userCredential.user;

      if (user == null) {
        emit(AuthFailure(message: 'Login failed. User not found.'));
        return;
      }

      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser ?? user;

      await createOrUpdateUserProfileUseCase(updatedUser);

      emit(AuthAuthenticated(user: updatedUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? 'Login failed'));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _loginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final userCredential = await googleLoginUseCase();
      final user = userCredential.user;

      if (user == null) {
        emit(AuthFailure(message: 'Google login failed. User not found.'));
        return;
      }

      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser ?? user;

      await createOrUpdateUserProfileUseCase(updatedUser);

      emit(AuthAuthenticated(user: updatedUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? 'Google login failed'));
    } catch (e) {
      emit(AuthFailure(message: 'Google login failed. Please try again.'));
    }
  }

  Future<void> _loginAsGuest(
    LoginAsGuestEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final userCredential = await guestLoginUseCase();
      final user = userCredential.user;

      if (user == null) {
        emit(AuthFailure(message: 'Guest login failed. User not found.'));
        return;
      }

      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser ?? user;

      await createOrUpdateUserProfileUseCase(updatedUser);

      emit(AuthAuthenticated(user: updatedUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: e.message ?? 'Guest login failed'));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _logout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await logoutUseCase();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }
}
