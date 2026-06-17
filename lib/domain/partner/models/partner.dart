/// A recitation-partner pairing «الرفيقة» under
/// circles/{circleId}/pairs/{pairId}: { aId, aName, bId, bName, createdAt }.
class Pair {
  final String id;
  final String aId;
  final String aName;
  final String bId;
  final String bName;
  final DateTime? createdAt;

  const Pair({
    required this.id,
    required this.aId,
    required this.aName,
    required this.bId,
    required this.bName,
    this.createdAt,
  });

  /// The other member of the pair, given my uid (null if I'm not in it).
  String? partnerIdFor(String uid) {
    if (uid == aId) return bId;
    if (uid == bId) return aId;
    return null;
  }

  String? partnerNameFor(String uid) {
    if (uid == aId) return bName;
    if (uid == bId) return aName;
    return null;
  }

  Pair copyWith({
    String? aId,
    String? aName,
    String? bId,
    String? bName,
    DateTime? createdAt,
  }) {
    return Pair(
      id: id,
      aId: aId ?? this.aId,
      aName: aName ?? this.aName,
      bId: bId ?? this.bId,
      bName: bName ?? this.bName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A recitation appointment between two partners (US-34) under
/// circles/{circleId}/appointments/{id}:
/// { fromId, fromName, toId, toName, time (Timestamp), confirmed (bool) }.
class Appointment {
  final String id;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final DateTime time;
  final bool confirmed;

  const Appointment({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.time,
    this.confirmed = false,
  });

  Appointment copyWith({
    String? fromId,
    String? fromName,
    String? toId,
    String? toName,
    DateTime? time,
    bool? confirmed,
  }) {
    return Appointment(
      id: id,
      fromId: fromId ?? this.fromId,
      fromName: fromName ?? this.fromName,
      toId: toId ?? this.toId,
      toName: toName ?? this.toName,
      time: time ?? this.time,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}
