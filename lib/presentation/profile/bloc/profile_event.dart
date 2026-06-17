part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String uid;
  final String? name;
  final String? photoUrl;

  const ProfileUpdateRequested({required this.uid, this.name, this.photoUrl});

  @override
  List<Object?> get props => [uid, name, photoUrl];
}
