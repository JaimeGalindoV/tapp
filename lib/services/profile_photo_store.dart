import 'profile_photo_store_stub.dart'
    if (dart.library.io) 'profile_photo_store_io.dart';
import 'profile_photo_store_base.dart';

export 'profile_photo_store_base.dart';

ProfilePhotoStore createProfilePhotoStore() => createProfilePhotoStoreImpl();
