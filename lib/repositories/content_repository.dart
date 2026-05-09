import 'dart:math' as math;

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
  final math.Random _random = math.Random();
  bool _isBackfillingMetadata = false;

  static const int _minimumCatalogSize = 24;
  static const int _defaultRandomBatchSize = 12;
  static const int _enrichmentConcurrency = 4;

  CollectionReference<Map<String, dynamic>> get _contentCollection =>
      _firestore.collection('content');

  Future<List<SwipeContentItem>> fetchContent() async {
    await _ensureSeededOrBootstrapped();
    final snapshot = await _contentCollection.get();
    return _mixItems(
      snapshot.docs.map(SwipeContentItem.fromFirestore).toList(growable: false),
    );
  }

  Future<SwipeContentItem?> getContentById(String contentId) async {
    await _ensureSeededOrBootstrapped();
    final snapshot = await _contentCollection.doc(contentId).get();
    if (!snapshot.exists) {
      return null;
    }
    return SwipeContentItem.fromFirestore(snapshot);
  }

  Future<List<SwipeContentItem>> refreshContent() async {
    await _ensureSeededOrBootstrapped();
    await fetchAndPersistRandomBatch();
    await syncProvidersFromTmdb();
    return fetchContent();
  }

  Future<List<SwipeContentItem>> searchByTitle(String query) async {
    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery.isEmpty) {
      return const <SwipeContentItem>[];
    }

    await _ensureSeededOrBootstrapped();
    final snapshot = await _contentCollection.get();
    final localItems = snapshot.docs
        .map(SwipeContentItem.fromFirestore)
        .where(
          (item) => _normalizeQuery(item.title).contains(normalizedQuery),
        )
        .toList(growable: true);

    final mergedItems = <SwipeContentItem>[
      ...localItems,
    ];
    final seenIds = localItems.map((item) => item.id).toSet();
    final seenKeys = localItems.map(_tmdbUniquenessKey).whereType<String>().toSet();

    try {
      final remoteItems = await _tmdbService.searchByTitle(query);
      if (remoteItems.isNotEmpty) {
        await _persistSearchResults(remoteItems, snapshot);
        for (final item in remoteItems) {
          if (seenIds.contains(item.id)) {
            continue;
          }

          final uniquenessKey = _tmdbUniquenessKey(item);
          if (uniquenessKey != null && seenKeys.contains(uniquenessKey)) {
            continue;
          }

          mergedItems.add(item);
          seenIds.add(item.id);
          if (uniquenessKey != null) {
            seenKeys.add(uniquenessKey);
          }
        }
      }
    } catch (_) {
      // Fall back to local matches when TMDB is unavailable.
    }

    mergedItems.sort((a, b) {
      final aNormalized = _normalizeQuery(a.title);
      final bNormalized = _normalizeQuery(b.title);
      final aStarts = aNormalized.startsWith(normalizedQuery);
      final bStarts = bNormalized.startsWith(normalizedQuery);
      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }

      final titleCompare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (titleCompare != 0) {
        return titleCompare;
      }
      return b.year.compareTo(a.year);
    });

    return List<SwipeContentItem>.unmodifiable(mergedItems);
  }

  Future<List<SwipeContentItem>> getUnseenCandidates({
    required Set<String> excludedIds,
    required int desiredCount,
  }) async {
    if (desiredCount <= 0) {
      return const <SwipeContentItem>[];
    }

    await _ensureSeededOrBootstrapped();

    var attempts = 0;
    while (attempts < 4) {
      attempts++;
      final candidates = await _readUnseenCandidates(
        excludedIds: excludedIds,
        desiredCount: desiredCount,
      );
      if (candidates.length >= desiredCount) {
        return candidates;
      }

      final missingCount = desiredCount - candidates.length;
      final inserted = await fetchAndPersistRandomBatch(
        targetCount: math.max(_defaultRandomBatchSize, missingCount + 4),
      );
      if (inserted <= 0) {
        return candidates;
      }
    }

    return _readUnseenCandidates(
      excludedIds: excludedIds,
      desiredCount: desiredCount,
    );
  }

  Future<int> ensureMinimumContentPool({int minimumCount = _minimumCatalogSize}) async {
    await _ensureSeeded();
    final existingSnapshot = await _contentCollection.get();
    final currentCount = existingSnapshot.docs.length;
    if (currentCount >= minimumCount) {
      return 0;
    }

    final missingCount = minimumCount - currentCount;
    return fetchAndPersistRandomBatch(targetCount: missingCount);
  }

  Future<int> fetchAndPersistRandomBatch({
    int targetCount = _defaultRandomBatchSize,
  }) async {
    if (!_tmdbService.isConfigured || targetCount <= 0) {
      return 0;
    }

    final existingSnapshot = await _contentCollection.get();
    final existingIds = existingSnapshot.docs.map((doc) => doc.id).toSet();
    final existingKeys = existingSnapshot.docs
        .map(SwipeContentItem.fromFirestore)
        .map(_tmdbUniquenessKey)
        .whereType<String>()
        .toSet();

    var inserted = 0;
    var attempts = 0;
    while (inserted < targetCount && attempts < 4) {
      attempts++;
      final batch = await _tmdbService.fetchRandomDiscoverBatch();
      if (batch.isEmpty) {
        break;
      }

      final itemsToInsert = <SwipeContentItem>[];
      for (final item in batch) {
        if (existingIds.contains(item.id)) {
          continue;
        }

        final uniquenessKey = _tmdbUniquenessKey(item);
        if (uniquenessKey != null && existingKeys.contains(uniquenessKey)) {
          continue;
        }

        itemsToInsert.add(item);
        existingIds.add(item.id);
        if (uniquenessKey != null) {
          existingKeys.add(uniquenessKey);
        }
        if (itemsToInsert.length >= targetCount - inserted) {
          break;
        }
      }

      if (itemsToInsert.isEmpty) {
        continue;
      }

      final enrichedItems = await _enrichItemsConcurrently(itemsToInsert);
      final writeBatch = _firestore.batch();
      var pendingWrites = 0;
      for (var index = 0; index < itemsToInsert.length; index++) {
        final item = itemsToInsert[index];
        final enriched = enrichedItems[index];
        final reference = _contentCollection.doc(item.id);
        writeBatch.set(reference, <String, dynamic>{
          ...enriched.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        pendingWrites++;
        inserted++;
        if (inserted >= targetCount) {
          break;
        }
      }

      if (pendingWrites > 0) {
        await writeBatch.commit();
      }
    }

    return inserted;
  }

  Future<List<SwipeContentItem>> _enrichItemsConcurrently(
    List<SwipeContentItem> items,
  ) async {
    final enrichedItems = <SwipeContentItem>[];

    for (var start = 0; start < items.length; start += _enrichmentConcurrency) {
      final end = math.min(start + _enrichmentConcurrency, items.length);
      final chunk = items.sublist(start, end);
      final enrichedChunk = await Future.wait(
        chunk.map(
          (item) async => await _tmdbService.enrichContent(item) ?? item,
        ),
      );
      enrichedItems.addAll(enrichedChunk);
    }

    return enrichedItems;
  }

  Future<void> syncProvidersFromTmdb() async {
    if (!_tmdbService.isConfigured) {
      return;
    }

    final snapshot = await _contentCollection.get();
    for (final document in snapshot.docs) {
      final item = SwipeContentItem.fromFirestore(document);
      final updatedAt = item.providerUpdatedAt;
      final isMissingMetadata = _isMissingMetadata(item);
      final canSkip =
          updatedAt != null &&
          DateTime.now().difference(updatedAt) < const Duration(hours: 12) &&
          !isMissingMetadata;
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

  Future<void> _ensureSeededOrBootstrapped() async {
    await _ensureSeeded();
    await ensureMinimumContentPool();
    await _backfillMissingMetadata();
  }

  Future<void> _backfillMissingMetadata() async {
    if (!_tmdbService.isConfigured || _isBackfillingMetadata) {
      return;
    }

    _isBackfillingMetadata = true;
    try {
      final snapshot = await _contentCollection.get();
      final itemsNeedingMetadata = snapshot.docs
          .map(SwipeContentItem.fromFirestore)
          .where(_isMissingMetadata)
          .toList(growable: false);
      if (itemsNeedingMetadata.isEmpty) {
        return;
      }

      final writeBatch = _firestore.batch();
      var pendingWrites = 0;

      for (var start = 0;
          start < itemsNeedingMetadata.length;
          start += _enrichmentConcurrency) {
        final end = math.min(
          start + _enrichmentConcurrency,
          itemsNeedingMetadata.length,
        );
        final chunk = itemsNeedingMetadata.sublist(start, end);
        final enrichedChunk = await Future.wait(
          chunk.map((item) async => await _tmdbService.enrichContent(item)),
        );

        for (var index = 0; index < chunk.length; index++) {
          final item = chunk[index];
          final enriched = enrichedChunk[index];
          if (enriched == null || !_hasMoreMetadata(item, enriched)) {
            continue;
          }

          writeBatch.update(
            _contentCollection.doc(item.id),
            enriched.toFirestore(),
          );
          pendingWrites++;
        }
      }

      if (pendingWrites > 0) {
        await writeBatch.commit();
      }
    } finally {
      _isBackfillingMetadata = false;
    }
  }

  Future<void> _persistSearchResults(
    List<SwipeContentItem> items,
    QuerySnapshot<Map<String, dynamic>> existingSnapshot,
  ) async {
    if (items.isEmpty) {
      return;
    }

    final existingIds = existingSnapshot.docs.map((doc) => doc.id).toSet();
    final existingKeys = existingSnapshot.docs
        .map(SwipeContentItem.fromFirestore)
        .map(_tmdbUniquenessKey)
        .whereType<String>()
        .toSet();

    final batch = _firestore.batch();
    var pendingWrites = 0;

    for (final item in items) {
      if (existingIds.contains(item.id)) {
        continue;
      }

      final uniquenessKey = _tmdbUniquenessKey(item);
      if (uniquenessKey != null && existingKeys.contains(uniquenessKey)) {
        continue;
      }

      final enriched = await _tmdbService.enrichContent(item) ?? item;
      final reference = _contentCollection.doc(item.id);
      batch.set(reference, <String, dynamic>{
        ...enriched.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      existingIds.add(item.id);
      if (uniquenessKey != null) {
        existingKeys.add(uniquenessKey);
      }
      pendingWrites++;
    }

    if (pendingWrites > 0) {
      await batch.commit();
    }
  }

  Future<List<SwipeContentItem>> _readUnseenCandidates({
    required Set<String> excludedIds,
    required int desiredCount,
  }) async {
    final snapshot = await _contentCollection.get();
    final items = _mixItems(
      snapshot.docs.map(SwipeContentItem.fromFirestore).toList(growable: false),
    );

    return items
        .where((item) => !excludedIds.contains(item.id))
        .take(desiredCount)
        .toList(growable: false);
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

  List<SwipeContentItem> _mixItems(List<SwipeContentItem> items) {
    final shuffled = List<SwipeContentItem>.from(items);
    shuffled.shuffle(_random);
    return List<SwipeContentItem>.unmodifiable(shuffled);
  }

  static String? _tmdbUniquenessKey(SwipeContentItem item) {
    final tmdbId = item.tmdbId;
    if (tmdbId == null) {
      return null;
    }
    return '${item.type.name}:$tmdbId';
  }

  static String _normalizeQuery(String value) {
    return value.trim().toLowerCase();
  }

  static bool _isMissingMetadata(SwipeContentItem item) {
    if (item.tmdbId == null) {
      return false;
    }
    return item.isMovie
        ? item.durationMinutes == null
        : item.seasonCount == null;
  }

  static bool _hasMoreMetadata(
    SwipeContentItem original,
    SwipeContentItem enriched,
  ) {
    if (original.isMovie) {
      return original.durationMinutes == null &&
          enriched.durationMinutes != null;
    }
    return original.seasonCount == null && enriched.seasonCount != null;
  }
}
