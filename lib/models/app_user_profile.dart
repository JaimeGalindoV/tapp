class AppUserProfile {
  const AppUserProfile({
    required this.email,
    required this.handle,
    this.photoUrl,
    required this.followersLabel,
  });

  final String email;
  final String handle;
  final String? photoUrl;
  final String followersLabel;
}
