import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/repositories/likes_repository.dart';

class LikesProvider extends ChangeNotifier {
  LikesProvider({required LikesRepository repository})
    : _repository = repository;

  final LikesRepository _repository;

  StreamSubscription<List<String>>? _subscription;
  List<String> _likedContentIds = const <String>[];
  String? _uid;

  List<String> get likedContentIds =>
      List<String>.unmodifiable(_likedContentIds);

  bool isLiked(String contentId) => _likedContentIds.contains(contentId);

  Future<void> bindUser(String uid) async {
    if (_uid == uid && _subscription != null) {
      return;
    }

    await _subscription?.cancel();
    _uid = uid;
    _subscription = _repository.watchLikedContentIds(uid).listen((likedIds) {
      _likedContentIds = likedIds;
      notifyListeners();
    });
  }

  Future<void> addLike(SwipeContentItem item) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    _likedContentIds = <String>[
      item.id,
      ..._likedContentIds.where((likedId) => likedId != item.id),
    ];
    notifyListeners();
    await _repository.upsertLike(uid, item.id);
  }

  Future<void> removeLike(String contentId) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    _likedContentIds = _likedContentIds
        .where((likedId) => likedId != contentId)
        .toList(growable: false);
    notifyListeners();
    await _repository.deleteLike(uid, contentId);
  }

  List<SwipeContentItem> resolveLikedItems(List<SwipeContentItem> catalog) {
    final byId = <String, SwipeContentItem>{
      for (final item in catalog) item.id: item,
    };
    return _likedContentIds
        .map((contentId) => byId[contentId])
        .whereType<SwipeContentItem>()
        .toList(growable: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
