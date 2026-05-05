import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapp/data/swipe_content_data.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/services/tmdb_service.dart';

class ContentRepository {
  ContentRepository({FirebaseFirestore? firestore, TmdbService? tmdbService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _tmdbService = tmdbService ?? TmdbService();

  final FirebaseFirestore _firestore;
  final TmdbService _tmdbService;

  CollectionReference<Map<String, dynamic>> get _contentCollection =>
      _firestore.collection('content');

  Future<List<SwipeContentItem>> fetchContent() async {
    await _ensureSeeded();
    final snapshot = await _contentCollection.get();
    return _sortItems(
      snapshot.docs.map(SwipeContentItem.fromFirestore).toList(growable: false),
    );
  }

  Future<SwipeContentItem?> getContentById(String contentId) async {
    await _ensureSeeded();
    final snapshot = await _contentCollection.doc(contentId).get();
    if (!snapshot.exists) {
      return null;
    }
    return SwipeContentItem.fromFirestore(snapshot);
  }

  Future<List<SwipeContentItem>> refreshContent() async {
    await _ensureSeeded();
    await syncProvidersFromTmdb();
    return fetchContent();
  }

  Future<void> syncProvidersFromTmdb() async {
    if (!_tmdbService.isConfigured) {
      return;
    }

    final snapshot = await _contentCollection.get();
    for (final document in snapshot.docs) {
      final item = SwipeContentItem.fromFirestore(document);
      final updatedAt = item.providerUpdatedAt;
      final canSkip =
          updatedAt != null &&
          DateTime.now().difference(updatedAt) < const Duration(hours: 12);
      if (canSkip) {
        continue;
      }

      final enriched = await _tmdbService.enrichContent(item);
      if (enriched == null) {
        continue;
      }

      await document.reference.update(<String, dynamic>{
        ...enriched.toFirestore(),
      });
    }
  }

  Future<void> _ensureSeeded() async {
    final existing = await _contentCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final item in swipeContentItems) {
      final reference = _contentCollection.doc(item.id);
      batch.set(reference, <String, dynamic>{
        ...item.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  List<SwipeContentItem> _sortItems(List<SwipeContentItem> items) {
    final sorted = List<SwipeContentItem>.from(items);
    sorted.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return a.title.compareTo(b.title);
    });
    return List<SwipeContentItem>.unmodifiable(sorted);
  }
}
