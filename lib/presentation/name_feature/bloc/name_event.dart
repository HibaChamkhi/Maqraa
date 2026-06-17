part of 'name_bloc.dart';

abstract class NameEvent extends Equatable {
  const NameEvent();

  @override
  List<Object?> get props => [];
}

class CreateNameEvent extends NameEvent {
  final Map<String, dynamic> data;

  const CreateNameEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class ReadNameEvent extends NameEvent {
  final String id;

  const ReadNameEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateNameEvent extends NameEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateNameEvent(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteNameEvent extends NameEvent {
  final String id;

  const DeleteNameEvent(this.id);

  @override
  List<Object?> get props => [id];
}
