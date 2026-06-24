import 'package:injectable/injectable.dart';

import '../../../domain/auth/models/app_user.dart';
import '../../../domain/profile/repositories/profile_repository.dart';
import '../data_sources/remote/profile_data_source.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AppUser> updateProfile({
    required String uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    return remoteDataSource.updateProfile(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
  }
}
