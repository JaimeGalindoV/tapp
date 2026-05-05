import 'package:flutter/foundation.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/repositories/content_repository.dart';

class ContentProvider extends ChangeNotifier {
  ContentProvider({required ContentRepository repository})
    : _repository = repository;

  final ContentRepository _repository;

  List<SwipeContentItem> _items = const <SwipeContentItem>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<SwipeContentItem> get items =>
      List<SwipeContentItem>.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SwipeContentItem? getById(String contentId) {
    for (final item in _items) {
      if (item.id == contentId) {
        return item;
      }
    }
    return null;
  }

  Future<void> loadContent() async {
    if (_isLoading && _items.isNotEmpty) {
      return;
    }

    _setLoading(true);
    try {
      _items = await _repository.fetchContent();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshContent() async {
    _setLoading(true);
    try {
      _items = await _repository.refreshContent();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> ensureContentAvailable(String contentId) async {
    final existing = getById(contentId);
    if (existing != null) {
      return;
    }

    _setLoading(true);
    try {
      final item = await _repository.getContentById(contentId);
      if (item != null) {
        _items = <SwipeContentItem>[..._items, item];
      }
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }
}
