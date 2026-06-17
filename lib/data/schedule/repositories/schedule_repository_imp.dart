import 'package:injectable/injectable.dart';

import '../../../domain/schedule/models/weekly_schedule.dart';
import '../../../domain/schedule/repositories/schedule_repository.dart';
import '../data_sources/remote/schedule_data_source.dart';

@Injectable(as: ScheduleRepository)
class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;

  ScheduleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> publishSchedule({
    required String circleId,
    required WeeklySchedule schedule,
  }) {
    return remoteDataSource.publishSchedule(
      circleId: circleId,
      schedule: schedule,
    );
  }

  @override
  Future<WeeklySchedule?> getSchedule({
    required String circleId,
    required String weekId,
  }) {
    return remoteDataSource.getSchedule(circleId: circleId, weekId: weekId);
  }
}
