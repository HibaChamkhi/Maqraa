import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/notification/models/app_notification.dart';
import '../../dtos/notification_dto.dart';

/// Firestore-backed notifications: users/{uid}/notifications/{id} and the
/// users/{uid}.notificationSettings map.
class NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  NotificationRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _notifs(String uid) =>
      firestore.collection('users').doc(uid).collection('notifications');

  Future<List<AppNotification>> getNotifications() async {
    final snap =
        await _notifs(_uid).orderBy('createdAt', descending: true).limit(100).get();
    return snap.docs
        .map((d) => NotificationDto.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  Future<void> markRead(String id) async {
    await _notifs(_uid).doc(id).update({'read': true});
  }

  Future<void> markAllRead() async {
    final unread = await _notifs(_uid).where('read', isEqualTo: false).get();
    final batch = firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Create a notification for [recipientId] (defaults to the current user).
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? recipientId,
  }) async {
    final uid = recipientId ?? _uid;
    final ref = _notifs(uid).doc();
    await ref.set(NotificationDto.toMap(AppNotification(
      id: ref.id,
      title: title,
      body: body,
      type: type,
    )));
  }

  Future<NotificationSettings> getSettings() async {
    final doc = await firestore.collection('users').doc(_uid).get();
    return NotificationSettingsDto.fromMap(
        doc.data()?['notificationSettings'] as Map<String, dynamic>?);
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    await firestore.collection('users').doc(_uid).set(
      {'notificationSettings': NotificationSettingsDto.toMap(settings)},
      SetOptions(merge: true),
    );
  }
}
