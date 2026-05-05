import 'package:flutter/material.dart';

class PlatformProfileImage extends StatelessWidget {
  const PlatformProfileImage({
    super.key,
    required this.photoUrl,
    required this.fit,
    required this.fallback,
  });

  final String photoUrl;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(photoUrl);
    final hasScheme = uri?.hasScheme == true;
    if (hasScheme) {
      return Image.network(
        photoUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return fallback;
  }
}
