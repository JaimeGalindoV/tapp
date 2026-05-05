import 'package:cloud_firestore/cloud_firestore.dart';

class UserReview {
  const UserReview({
    required this.userId,
    required this.userDisplayName,
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String userDisplayName;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserReview.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return UserReview(
      userId: (data['userId'] as String? ?? snapshot.id).trim(),
      userDisplayName: (data['userDisplayName'] as String? ?? 'Usuario').trim(),
      text: (data['text'] as String? ?? '').trim(),
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'userDisplayName': userDisplayName,
      'text': text,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
