import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/schedule/models/weekly_schedule.dart';
import '../../dtos/weekly_schedule_dto.dart';

/// Firestore-backed weekly schedule data source.
/// Documents live at `circles/{circleId}/schedules/{weekId}`.
@injectable
class ScheduleRemoteDataSource {
  final FirebaseFirestore firestore;

  ScheduleRemoteDataSource({required this.firestore});

  CollectionReference<Map<String, dynamic>> _schedules(String circleId) =>
      firestore.collection('circles').doc(circleId).collection('schedules');

  Future<void> publishSchedule({
    required String circleId,
    required WeeklySchedule schedule,
  }) async {
    try {
      await _schedules(circleId)
          .doc(schedule.weekId)
          .set(WeeklyScheduleDto.toMap(schedule), SetOptions(merge: true));
    } catch (e) {
      throw BadRequestException(message: 'تعذّر نشر الجدول، حاولي مرة أخرى');
    }
  }

  Future<WeeklySchedule?> getSchedule({
    required String circleId,
    required String weekId,
  }) async {
    try {
      final doc = await _schedules(circleId).doc(weekId).get();
      if (!doc.exists) return null;
      return WeeklyScheduleDto.fromMap(weekId, doc.data()!);
    } catch (e) {
      throw BadRequestException(message: 'تعذّر تحميل الجدول');
    }
  }
}
