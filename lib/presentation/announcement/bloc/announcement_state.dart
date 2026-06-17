part of 'announcement_bloc.dart';

class AnnouncementState extends Equatable {
  final UIStatus status;
  final String message;

  /// Feed of announcements, newest first (US-14).
  final List<Announcement> announcements;

  /// Set true after posting (navigation/feedback hook).
  final bool actionDone;

  const AnnouncementState({
    this.status = UIStatus.success,
    this.message = '',
    this.announcements = const [],
    this.actionDone = false,
  });

  AnnouncementState copyWith({
    UIStatus? status,
    String? message,
    List<Announcement>? announcements,
    bool? actionDone,
  }) {
    return AnnouncementState(
      status: status ?? this.status,
      message: message ?? this.message,
      announcements: announcements ?? this.announcements,
      actionDone: actionDone ?? this.actionDone,
    );
  }

  @override
  List<Object?> get props => [status, message, announcements, actionDone];
}
