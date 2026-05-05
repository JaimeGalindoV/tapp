class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.authPhotoUrl,
    this.localPhotoPath,
    this.deviceToken,
    this.likesCount = 0,
    this.reviewsCount = 0,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? authPhotoUrl;
  final String? localPhotoPath;
  final String? deviceToken;
  final int likesCount;
  final int reviewsCount;

  String get handle {
    final cleaned = displayName.trim();
    if (cleaned.isEmpty) {
      return '@usuario';
    }
    return cleaned.startsWith('@') ? cleaned : '@$cleaned';
  }

  String get statsLabel => '$likesCount favoritos | $reviewsCount reseñas';

  String? get photoUrl => localPhotoPath ?? authPhotoUrl;

  AppUserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? authPhotoUrl,
    String? localPhotoPath,
    String? deviceToken,
    int? likesCount,
    int? reviewsCount,
  }) {
    return AppUserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      authPhotoUrl: authPhotoUrl ?? this.authPhotoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      deviceToken: deviceToken ?? this.deviceToken,
      likesCount: likesCount ?? this.likesCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }
}
