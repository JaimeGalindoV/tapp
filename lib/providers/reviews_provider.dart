import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tapp/models/user_review.dart';
import 'package:tapp/repositories/reviews_repository.dart';

class ReviewsProvider extends ChangeNotifier {
  ReviewsProvider({required ReviewsRepository repository})
    : _repository = repository;

  final ReviewsRepository _repository;

  Stream<List<UserReview>> watchReviews(String contentId) {
    return _repository.watchReviews(contentId);
  }

  Future<void> upsertReview({
    required String contentId,
    required User user,
    required String text,
  }) {
    return _repository.upsertReview(
      contentId: contentId,
      user: user,
      text: text,
    );
  }

  Future<void> deleteReview({
    required String contentId,
    required String userId,
  }) {
    return _repository.deleteReview(contentId: contentId, userId: userId);
  }

  Future<UserReview?> getUserReviewForContent({
    required String contentId,
    required String userId,
  }) {
    return _repository.getUserReviewForContent(
      contentId: contentId,
      userId: userId,
    );
  }

  Future<int> getUserReviewCount(String userId) {
    return _repository.getUserReviewCount(userId);
  }
}
