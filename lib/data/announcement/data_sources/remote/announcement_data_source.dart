import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/announcement/models/announcement.dart';
import '../../dtos/announcement_dto.dart';

/// Firestore-backed announcement data source (US-14).
@injectable
class AnnouncementRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  AnnouncementRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _circles =>
      firestore.collection('circles');

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _announcements(String circleId) =>
      _circles.doc(circleId).collection('announcements');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  Future<Announcement> postAnnouncement({
    required String circleId,
    required String text,
  }) async {
    final uid = _uid;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw BadRequestException(message: 'نص الإعلان مطلوب');
    }
    final ref = _announcements(circleId).doc();
    final announcement = Announcement(
      id: ref.id,
      text: trimmed,
      authorId: uid,
      authorName: await _currentUserName(),
    );
    await ref.set(AnnouncementDto.toMap(announcement));
    await _notifyMembers(circleId: circleId, authorUid: uid, text: trimmed);
    return announcement;
  }

  /// Fan-out a notification to every active circle member (except the author)
  /// so the announcement shows up in their notifications feed.
  Future<void> _notifyMembers({
    required String circleId,
    required String authorUid,
    required String text,
  }) async {
    try {
      final circleDoc = await _circles.doc(circleId).get();
      final circleName = (circleDoc.data()?['name'] ?? '') as String;
      final members = await _circles.doc(circleId).collection('members').get();
      final batch = firestore.batch();
      for (final m in members.docs) {
        if (m.id == authorUid) continue;
        final nref =
            _users.doc(m.id).collection('notifications').doc();
        batch.set(nref, {
          'title': circleName.isEmpty ? 'إعلان جديد' : 'إعلان في $circleName',
          'body': text,
          'type': 'adminMessage',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {
      // Never fail the announcement because the fan-out had an issue.
    }
  }

  Future<List<Announcement>> getAnnouncements(String circleId) async {
    final snap = await _announcements(circleId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => AnnouncementDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  Future<String> _currentUserName() async {
    final doc = await _users.doc(_uid).get();
    return (doc.data()?['name'] ?? '') as String;
  }
}
