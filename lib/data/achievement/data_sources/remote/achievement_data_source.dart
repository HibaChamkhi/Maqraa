import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/achievement/models/achievement.dart';
import '../../dtos/achievement_dto.dart';

/// Firestore-backed streak & badge data source (US-24).
/// Streak/badge fields live directly on users/{uid}.
@injectable
class AchievementRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  AchievementRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  String get _uid {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    return user.uid;
  }

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  Future<Achievement> getAchievement() async {
    final doc = await _users.doc(_uid).get();
    return AchievementDto.fromMap(doc.data() ?? const {});
  }

  Future<Achievement> registerCompletion() async {
    final uid = _uid;
    final ref = _users.doc(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _fmt.format(today);

    return firestore.runTransaction<Achievement>((txn) async {
      final snap = await txn.get(ref);
      final current = AchievementDto.fromMap(snap.data() ?? const {});

      // Already completed today — idempotent, no change.
      if (current.lastCompletedDate == todayKey) {
        return current;
      }

      int newStreak;
      if (current.lastCompletedDate.isEmpty) {
        newStreak = 1;
      } else {
        final last = DateTime.tryParse(current.lastCompletedDate);
        if (last == null) {
          newStreak = 1;
        } else {
          final lastDay = DateTime(last.year, last.month, last.day);
          final gap = today.difference(lastDay).inDays;
          // gap == 1 => consecutive day; gap > 1 => streak broken.
          newStreak = gap == 1 ? current.streakCount + 1 : 1;
        }
      }

      final earned = Badge.earnedFor(newStreak);
      final mergedBadges = {...current.badges, ...earned}.toList();

      final updated = Achievement(
        streakCount: newStreak,
        lastCompletedDate: todayKey,
        badges: mergedBadges,
      );
      txn.set(ref, AchievementDto.toMap(updated), SetOptions(merge: true));
      return updated;
    });
  }
}
