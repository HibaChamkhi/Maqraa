import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../domain/auth/models/app_user.dart';
import '../../../auth/dtos/app_user_dto.dart';

@injectable
class ProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  ProfileRemoteDataSource({required this.firestore});

  Future<AppUser> updateProfile({
    required String uid,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? photoUrl,
  }) async {
    final doc = firestore.collection('users').doc(uid);
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (city != null) 'city': city,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
    if (updates.isNotEmpty) await doc.update(updates);
    final snapshot = await doc.get();
    return AppUserDto.fromMap(uid, snapshot.data() ?? {});
  }
}
