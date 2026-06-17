part of 'name_bloc.dart';


class NameState extends UIState<Map<String, dynamic>> {
  const NameState({
     super.status,
    super.message,
    super.data,
  });

  @override
  NameState copyWith({
     UIStatus? status,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return NameState(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}
