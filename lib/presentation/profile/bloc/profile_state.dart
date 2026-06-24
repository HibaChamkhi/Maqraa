part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  final UIStatus status;
  final String message;
  final AppUser? user;

  const ProfileState({
    this.status = UIStatus.success,
    this.message = '',
    this.user,
  });

  ProfileState copyWith({UIStatus? status, String? message, AppUser? user}) {
    return ProfileState(
      status: status ?? this.status,
      message: message ?? this.message,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, message, user];
}
