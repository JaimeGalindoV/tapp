import 'dart:io';

import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'profile_photo_store_base.dart';

class IoProfilePhotoStore implements ProfilePhotoStore {
  @override
  bool get supportsLocalFileImages => true;

  @override
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

  @override
  Future<String?> saveProfilePhoto({
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

  @override
  Future<String?> loadProfilePhotoPath(String uid) async {
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

  String _extractExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }
}

ProfilePhotoStore createProfilePhotoStoreImpl() => IoProfilePhotoStore();
