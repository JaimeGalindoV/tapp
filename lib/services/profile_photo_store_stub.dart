import 'package:image_picker/image_picker.dart';

import 'profile_photo_store_base.dart';

class StubProfilePhotoStore implements ProfilePhotoStore {
  @override
  bool get supportsLocalFileImages => false;

  @override
  Future<String?> loadProfilePhotoPath(String uid) async => null;

  @override
  Future<String?> saveCapturedPhotoToSystemGallery(XFile pickedFile) async {
    final path = pickedFile.path.trim();
    return path.isEmpty ? null : path;
  }

  @override
  Future<String?> saveProfilePhoto({
    required String uid,
    required XFile pickedFile,
  }) async {
    final path = pickedFile.path.trim();
    return path.isEmpty ? null : path;
  }
}

ProfilePhotoStore createProfilePhotoStoreImpl() => StubProfilePhotoStore();
