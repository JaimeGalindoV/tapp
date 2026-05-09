import 'package:cloud_firestore/cloud_firestore.dart';

class UserReview {
  const UserReview({
    required this.userId,
    required this.userDisplayName,
    required this.text,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String userDisplayName;
  final String text;
  final double? rating;
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
      rating: _ratingFromValue(data['rating']),
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'userDisplayName': userDisplayName,
      'text': text,
      'rating': rating,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static double? _ratingFromValue(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0, 5);
    }
    return null;
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
