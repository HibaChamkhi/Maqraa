import 'package:injectable/injectable.dart';

import '../../../domain/announcement/models/announcement.dart';
import '../../../domain/announcement/repositories/announcement_repository.dart';
import '../data_sources/remote/announcement_data_source.dart';

@Injectable(as: AnnouncementRepository)
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementRemoteDataSource remoteDataSource;

  AnnouncementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Announcement> postAnnouncement({
    required String circleId,
    required String text,
  }) =>
      remoteDataSource.postAnnouncement(circleId: circleId, text: text);

  @override
  Future<List<Announcement>> getAnnouncements(String circleId) =>
      remoteDataSource.getAnnouncements(circleId);
}
