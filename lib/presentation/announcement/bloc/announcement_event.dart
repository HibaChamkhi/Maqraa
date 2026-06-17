part of 'announcement_bloc.dart';

abstract class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();

  @override
  List<Object?> get props => [];
}

class AnnouncementsRequested extends AnnouncementEvent {
  final String circleId;

  const AnnouncementsRequested(this.circleId);

  @override
  List<Object?> get props => [circleId];
}

class AnnouncementPosted extends AnnouncementEvent {
  final String circleId;
  final String text;

  const AnnouncementPosted({required this.circleId, required this.text});

  @override
  List<Object?> get props => [circleId, text];
}
