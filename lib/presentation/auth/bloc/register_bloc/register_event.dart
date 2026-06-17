part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
}
class RegisterUserEvent extends RegisterEvent {
  final Map<String, dynamic> userInfo;

  const RegisterUserEvent({
    required this.userInfo,
  });

  @override
  List<Object> get props => [
    userInfo
  ];
}