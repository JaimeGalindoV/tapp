import 'package:cloud_firestore/cloud_firestore.dart';

class LikesRepository {
  LikesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _likesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('likes');
  }

  Stream<List<String>> watchLikedContentIds(String uid) {
    return _likesCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<void> upsertLike(String uid, String contentId) {
    return _likesCollection(uid).doc(contentId).set(<String, dynamic>{
      'contentId': contentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLike(String uid, String contentId) {
    return _likesCollection(uid).doc(contentId).delete();
  }

  Future<int> countLikes(String uid) async {
    final snapshot = await _likesCollection(uid).count().get();
    return snapshot.count ?? 0;
  }
}
