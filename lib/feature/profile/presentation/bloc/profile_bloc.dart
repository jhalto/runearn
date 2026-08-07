import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:runearn/feature/profile/domain/usecases/create_or_update_user_profile_use_case.dart';
import 'package:runearn/feature/profile/domain/usecases/get_current_user_use_case.dart';
import 'package:runearn/feature/profile/domain/usecases/update_user_profile_use_case.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentUserProfileUseCase getCurrentUserProfileUseCase;
  final CreateOrUpdateUserProfileUseCase createOrUpdateUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;

  ProfileBloc({
    required this.getCurrentUserProfileUseCase,
    required this.createOrUpdateUserProfileUseCase,
    required this.updateUserProfileUseCase,
  }) : super(ProfileInitial()) {
    on<ResetProfileEvent>((event, emit) => emit(ProfileInitial()));
    on<LoadCurrentUserProfileEvent>(_loadCurrentUserProfile);
    on<CreateOrUpdateUserProfileEvent>(_createOrUpdateUserProfile);
    on<UpdateUserProfileEvent>(_updateUserProfile);
  }

  Future<void> _loadCurrentUserProfile(
    LoadCurrentUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final user = await getCurrentUserProfileUseCase();

      if (user == null) {
        emit(ProfileEmpty());
        return;
      }

      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _createOrUpdateUserProfile(
    CreateOrUpdateUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final user = await createOrUpdateUserProfileUseCase(event.user);
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _updateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;

    try {
      await updateUserProfileUseCase(event.user);

      emit(ProfileLoaded(event.user));
    } catch (e) {
      if (currentState is ProfileLoaded) {
        emit(currentState);
      } else {
        emit(ProfileFailure(e.toString()));
      }
    }
  }
}
