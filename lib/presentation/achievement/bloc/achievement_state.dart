part of 'achievement_bloc.dart';

class AchievementState extends Equatable {
  final UIStatus status;
  final String message;

  /// Current streak/badge state (US-24).
  final Achievement achievement;

  const AchievementState({
    this.status = UIStatus.success,
    this.message = '',
    this.achievement = const Achievement(),
  });

  AchievementState copyWith({
    UIStatus? status,
    String? message,
    Achievement? achievement,
  }) {
    return AchievementState(
      status: status ?? this.status,
      message: message ?? this.message,
      achievement: achievement ?? this.achievement,
    );
  }

  @override
  List<Object?> get props => [status, message, achievement];
}
