import 'package:flutter/foundation.dart';
import 'package:tapp/models/swipe_content_item.dart';

class LikesProvider extends ChangeNotifier {
  final List<SwipeContentItem> _likedItems = [];

  List<SwipeContentItem> get likedItems => List.unmodifiable(_likedItems);

  List<SwipeContentItem> get likedSeries => _likedItems
      .where((item) => item.type == ContentType.series)
      .toList(growable: false);

  List<SwipeContentItem> get likedMovies => _likedItems
      .where((item) => item.type == ContentType.movie)
      .toList(growable: false);

  void addLike(SwipeContentItem item) {
    final existingIndex = _likedItems.indexWhere(
      (likedItem) => likedItem.id == item.id,
    );

    if (existingIndex != -1) {
      _likedItems.removeAt(existingIndex);
    }

    _likedItems.insert(0, item);
    notifyListeners();
  }
}
