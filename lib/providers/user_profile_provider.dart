import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapp/models/app_user_profile.dart';
import 'package:tapp/repositories/likes_repository.dart';
import 'package:tapp/repositories/reviews_repository.dart';
import 'package:tapp/repositories/user_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({
    required UserRepository userRepository,
    required LikesRepository likesRepository,
    required ReviewsRepository reviewsRepository,
  }) : _userRepository = userRepository,
       _likesRepository = likesRepository,
       _reviewsRepository = reviewsRepository;

  final UserRepository _userRepository;
  final LikesRepository _likesRepository;
  final ReviewsRepository _reviewsRepository;

  AppUserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _boundUserId;
  StreamSubscription<List<String>>? _likesCountSubscription;
  StreamSubscription<int>? _reviewsCountSubscription;

  AppUserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> bindUser(User user) async {
    final isSameUser = _boundUserId == user.uid;
    if (!isSameUser) {
      await _stopStatsListeners();
      _boundUserId = user.uid;
      _profile = await _buildFallbackProfile(user);
      _startStatsListeners(user.uid);
    } else {
      _profile ??= await _buildFallbackProfile(
        user,
        existingProfile: _profile,
      );
      if (_likesCountSubscription == null || _reviewsCountSubscription == null) {
        _startStatsListeners(user.uid);
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final likesCount = await _likesRepository.countLikes(user.uid);
      final reviewsCount = await _resolveReviewCount(
        user.uid,
        fallback: _profile?.reviewsCount ?? 0,
      );
      _patchProfileCounts(likesCount: likesCount, reviewsCount: reviewsCount);
    } catch (error) {
      _errorMessage = error.toString();
    }

    try {
      final deviceToken = await _userRepository.getDeviceToken();
      await _userRepository.upsertCurrentUser(user, deviceToken: deviceToken);
      final currentProfile = _profile;
      final likesCount = currentProfile?.likesCount ?? 0;
      final reviewsCount = currentProfile?.reviewsCount ?? 0;
      final syncedProfile = await _userRepository.loadUserProfile(
        user,
        likesCount: likesCount,
        reviewsCount: reviewsCount,
      );
      if (_boundUserId == user.uid) {
        _profile = syncedProfile;
      }
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStats(User user) async {
    try {
      final likesCount = await _likesRepository.countLikes(user.uid);
      final reviewsCount = await _resolveReviewCount(
        user.uid,
        fallback: _profile?.reviewsCount ?? 0,
      );
      final localPhotoPath =
          _profile?.localPhotoPath ??
          await _userRepository.loadLocalProfilePhoto(user.uid);
      final displayName = _profile?.displayName.isNotEmpty == true
          ? _profile!.displayName
          : (user.displayName ?? '').trim();
      _profile =
          (_profile ??
                  AppUserProfile(
                    uid: user.uid,
                    email: (user.email ?? '').trim(),
                    displayName: displayName.isEmpty ? 'usuario' : displayName,
                  ))
              .copyWith(
                likesCount: likesCount,
                reviewsCount: reviewsCount,
                localPhotoPath: localPhotoPath,
              );
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _startStatsListeners(String uid) {
    _likesCountSubscription = _likesRepository.watchLikedContentIds(uid).listen((
      likedIds,
    ) {
      _patchProfileCounts(likesCount: likedIds.length);
    }, onError: (Object error) {
      _errorMessage = error.toString();
      notifyListeners();
    });

    _reviewsCountSubscription = _reviewsRepository.watchUserReviewCount(uid).listen((
      reviewCount,
    ) {
      _patchProfileCounts(reviewsCount: reviewCount);
    }, onError: (Object error) {
      if (_isMissingReviewIndexError(error)) {
        return;
      }
      _errorMessage = error.toString();
      notifyListeners();
    });
  }

  Future<void> _stopStatsListeners() async {
    await _likesCountSubscription?.cancel();
    await _reviewsCountSubscription?.cancel();
    _likesCountSubscription = null;
    _reviewsCountSubscription = null;
  }

  void _patchProfileCounts({int? likesCount, int? reviewsCount}) {
    final existingProfile = _profile;
    final uid = _boundUserId;
    if (existingProfile == null || uid == null) {
      return;
    }

    _profile = existingProfile.copyWith(
      likesCount: likesCount ?? existingProfile.likesCount,
      reviewsCount: reviewsCount ?? existingProfile.reviewsCount,
    );
    _errorMessage = null;
    notifyListeners();
  }

  Future<AppUserProfile> _buildFallbackProfile(
    User user, {
    AppUserProfile? existingProfile,
  }) async {
    final localPhotoPath = await _userRepository.loadLocalProfilePhoto(user.uid);
    final displayName = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();

    return AppUserProfile(
      uid: user.uid,
      email: email,
      displayName: displayName.isEmpty
          ? (email.contains('@') ? email.split('@').first : 'usuario')
          : displayName,
      authPhotoUrl: (user.photoURL ?? '').trim().isEmpty
          ? null
          : (user.photoURL ?? '').trim(),
      localPhotoPath: localPhotoPath,
      likesCount: existingProfile?.likesCount ?? 0,
      reviewsCount: existingProfile?.reviewsCount ?? 0,
    );
  }

  Future<void> saveProfile({
    required User user,
    required String displayName,
    XFile? localPhoto,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await user.updateDisplayName(displayName.trim());
      final likesCount = await _likesRepository.countLikes(user.uid);
      final reviewsCount = await _resolveReviewCount(
        user.uid,
        fallback: _profile?.reviewsCount ?? 0,
      );
      final savedProfile = await _userRepository.saveProfile(
        user: user,
        displayName: displayName,
        likesCount: likesCount,
        reviewsCount: reviewsCount,
        localPhoto: localPhoto,
      );
      _profile = savedProfile;
      final reloadedPhotoPath = await _userRepository.loadLocalProfilePhoto(
        user.uid,
      );
      if (reloadedPhotoPath != null || _userRepository.supportsLocalFileImages) {
        _profile = savedProfile.copyWith(localPhotoPath: reloadedPhotoPath);
      }
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopStatsListeners();
    super.dispose();
  }

  Future<int> _resolveReviewCount(String userId, {required int fallback}) async {
    try {
      return await _reviewsRepository.getUserReviewCount(userId);
    } catch (error) {
      if (_isMissingReviewIndexError(error)) {
        return fallback;
      }
      rethrow;
    }
  }

  bool _isMissingReviewIndexError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('failed-precondition') &&
        message.contains('index');
  }
}
