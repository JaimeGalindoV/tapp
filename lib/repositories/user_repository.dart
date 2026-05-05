import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapp/models/app_user_profile.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<String?> saveCapturedPhotoToSystemGallery(XFile pickedFile) async {
    final sourcePath = pickedFile.path.trim();
    if (sourcePath.isEmpty) {
      return null;
    }

    final saved = await GallerySaver.saveImage(sourcePath);
    if (saved != true) {
      return null;
    }

    return sourcePath;
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
        'deviceToken': (deviceToken ?? '').trim(),
        'providerIds': user.providerData
            .map((provider) => provider.providerId.trim())
            .where((providerId) => providerId.isNotEmpty)
            .toList(growable: false),
        'updatedAt': FieldValue.serverTimestamp(),
      };
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
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    final legacyPrefix = 'profile_$uid.';
    final versionedPrefix = 'profile_${uid}_';
    for (final entity in files) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      if (name.startsWith(legacyPrefix) || name.startsWith(versionedPrefix)) {
        await entity.delete();
      }
    }

    final extension = _extractExtension(pickedFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final target = File(
      '${directory.path}${Platform.pathSeparator}profile_${uid}_$timestamp$extension',
    );
    final bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    final storedFile = await target.writeAsBytes(bytes, flush: true);
    return storedFile.path;
  }

  Future<String?> loadLocalProfilePhoto(String uid) async {
    final directory = await getApplicationDocumentsDirectory();
    final legacyPrefix = 'profile_$uid.';
    final versionedPrefix = 'profile_${uid}_';
    final matchingFiles = directory
        .listSync()
        .whereType<File>()
        .where((file) {
          final name = file.uri.pathSegments.last;
          return name.startsWith(legacyPrefix) || name.startsWith(versionedPrefix);
        })
        .toList(growable: false);

    if (matchingFiles.isEmpty) {
      return null;
    }

    matchingFiles.sort((a, b) {
      final modifiedA = a.lastModifiedSync();
      final modifiedB = b.lastModifiedSync();
      return modifiedB.compareTo(modifiedA);
    });

    return matchingFiles.first.path;
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

  String _extractExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }
}
