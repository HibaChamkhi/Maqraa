import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/partner/models/partner.dart';

/// Maps circles/{circleId}/pairs/{pairId} <-> [Pair].
class PairDto {
  static Pair fromMap(String id, Map<String, dynamic> map) {
    return Pair(
      id: id,
      aId: (map['aId'] ?? '') as String,
      aName: (map['aName'] ?? '') as String,
      bId: (map['bId'] ?? '') as String,
      bName: (map['bName'] ?? '') as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(Pair pair) {
    return {
      'aId': pair.aId,
      'aName': pair.aName,
      'bId': pair.bId,
      'bName': pair.bName,
      'createdAt': pair.createdAt != null
          ? Timestamp.fromDate(pair.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Maps circles/{circleId}/appointments/{id} <-> [Appointment].
class AppointmentDto {
  static Appointment fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      fromId: (map['fromId'] ?? '') as String,
      fromName: (map['fromName'] ?? '') as String,
      toId: (map['toId'] ?? '') as String,
      toName: (map['toName'] ?? '') as String,
      time: (map['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmed: (map['confirmed'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toMap(Appointment a) {
    return {
      'fromId': a.fromId,
      'fromName': a.fromName,
      'toId': a.toId,
      'toName': a.toName,
      'time': Timestamp.fromDate(a.time),
      'confirmed': a.confirmed,
    };
  }
}
