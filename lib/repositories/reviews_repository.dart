import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapp/models/user_review.dart';

class ReviewsRepository {
  ReviewsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviewsCollection(
    String contentId,
  ) {
    return _firestore
        .collection('content')
        .doc(contentId)
        .collection('reviews');
  }

  Stream<List<UserReview>> watchReviews(String contentId) {
    return _reviewsCollection(contentId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(UserReview.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> upsertReview({
    required String contentId,
    required User user,
    required String text,
  }) {
    final review = UserReview(
      userId: user.uid,
      userDisplayName: _resolveDisplayName(user),
      text: text.trim(),
    );
    return _reviewsCollection(
      contentId,
    ).doc(user.uid).set(review.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteReview({
    required String contentId,
    required String userId,
  }) {
    return _reviewsCollection(contentId).doc(userId).delete();
  }

  Future<int> getUserReviewCount(String userId) async {
    final snapshot = await _firestore
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  Stream<int> watchUserReviewCount(String userId) {
    return _firestore
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<UserReview?> getUserReviewForContent({
    required String contentId,
    required String userId,
  }) async {
    final snapshot = await _reviewsCollection(contentId).doc(userId).get();
    if (!snapshot.exists) {
      return null;
    }
    return UserReview.fromFirestore(snapshot);
  }

  String _resolveDisplayName(User user) {
    final displayName = (user.displayName ?? '').trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = (user.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Usuario';
  }
}
