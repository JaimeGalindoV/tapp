import 'package:image_picker/image_picker.dart';

abstract class ProfilePhotoStore {
  bool get supportsLocalFileImages;

  Future<String?> saveCapturedPhotoToSystemGallery(XFile pickedFile);

  Future<String?> saveProfilePhoto({
    required String uid,
    required XFile pickedFile,
  });

  Future<String?> loadProfilePhotoPath(String uid);
}
