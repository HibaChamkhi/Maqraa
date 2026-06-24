import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/auth/models/app_user.dart';
import '../../../domain/profile/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc(this.profileRepository) : super(const ProfileState()) {
    on<ProfileUpdateRequested>(_onUpdate);
  }

  Future<void> _onUpdate(
      ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      final user = await profileRepository.updateProfile(
        uid: event.uid,
        name: event.name,
        email: event.email,
        phone: event.phone,
        city: event.city,
        photoUrl: event.photoUrl,
      );
      emit(state.copyWith(status: UIStatus.success, user: user));
    } on Exception catch (e) {
      emit(state.copyWith(status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
