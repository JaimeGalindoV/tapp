import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapp/models/app_user_profile.dart';
import 'package:tapp/services/profile_photo_store.dart';

class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    ProfilePhotoStore? photoStore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _photoStore = photoStore ?? createProfilePhotoStore();

  final FirebaseFirestore _firestore;
  final ProfilePhotoStore _photoStore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  bool get supportsLocalFileImages => _photoStore.supportsLocalFileImages;

  Future<String?> saveCapturedPhotoToSystemGallery(XFile pickedFile) async {
    return _photoStore.saveCapturedPhotoToSystemGallery(pickedFile);
  }

  Future<String?> getDeviceToken() async {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
      default:
        return null;
    }

    try {
      await FirebaseMessaging.instance.requestPermission();
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertCurrentUser(User user, {String? deviceToken}) {
    final email = (user.email ?? '').trim().toLowerCase();
    final displayName = _resolveDisplayName(user);
    final reference = _usersCollection.doc(user.uid);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final payload = <String, dynamic>{
        'uid': user.uid,
        'email': email,
        'displayName': displayName,
        'authPhotoUrl': (user.photoURL ?? '').trim(),
        'providerIds': user.providerData
            .map((provider) => provider.providerId.trim())
            .where((providerId) => providerId.isNotEmpty)
            .toList(growable: false),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final normalizedToken = (deviceToken ?? '').trim();
      if (normalizedToken.isNotEmpty) {
        payload['deviceToken'] = normalizedToken;
      }
      if (!snapshot.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      transaction.set(reference, payload, SetOptions(merge: true));
    });
  }

  Future<AppUserProfile> loadUserProfile(
    User user, {
    required int likesCount,
    required int reviewsCount,
  }) async {
    final snapshot = await _usersCollection.doc(user.uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    return AppUserProfile(
      uid: user.uid,
      email: (data['email'] as String? ?? user.email ?? '').trim(),
      displayName: (data['displayName'] as String? ?? _resolveDisplayName(user))
          .trim(),
      authPhotoUrl: _nullableString(
        (data['authPhotoUrl'] as String? ?? user.photoURL ?? '').trim(),
      ),
      localPhotoPath: await loadLocalProfilePhoto(user.uid),
      deviceToken: _nullableString(
        (data['deviceToken'] as String? ?? '').trim(),
      ),
      likesCount: likesCount,
      reviewsCount: reviewsCount,
    );
  }

  Future<AppUserProfile> saveProfile({
    required User user,
    required String displayName,
    required int likesCount,
    required int reviewsCount,
    XFile? localPhoto,
  }) async {
    final normalizedName = displayName.trim();
    String? localPhotoPath;
    if (localPhoto != null) {
      localPhotoPath = await saveProfilePhotoLocally(
        uid: user.uid,
        pickedFile: localPhoto,
      );
      if (localPhotoPath == null) {
        throw Exception('No se pudo persistir la foto de perfil localmente.');
      }
    } else {
      localPhotoPath = await loadLocalProfilePhoto(user.uid);
    }

    await _usersCollection.doc(user.uid).set(<String, dynamic>{
      'uid': user.uid,
      'email': (user.email ?? '').trim().toLowerCase(),
      'displayName': normalizedName,
      'authPhotoUrl': (user.photoURL ?? '').trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return AppUserProfile(
      uid: user.uid,
      email: (user.email ?? '').trim().toLowerCase(),
      displayName: normalizedName,
      authPhotoUrl: _nullableString((user.photoURL ?? '').trim()),
      localPhotoPath: localPhotoPath,
      likesCount: likesCount,
      reviewsCount: reviewsCount,
    );
  }

  Future<String?> saveProfilePhotoLocally({
    required String uid,
    required XFile pickedFile,
  }) async {
    return _photoStore.saveProfilePhoto(uid: uid, pickedFile: pickedFile);
  }

  Future<String?> loadLocalProfilePhoto(String uid) async {
    return _photoStore.loadProfilePhotoPath(uid);
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
    return 'usuario';
  }

  String? _nullableString(String value) {
    return value.isEmpty ? null : value;
  }
}
