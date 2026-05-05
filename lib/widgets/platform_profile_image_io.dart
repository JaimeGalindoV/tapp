import 'dart:io';

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
    if (hasScheme && uri?.scheme != 'file') {
      return Image.network(
        photoUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    final file = uri?.scheme == 'file' ? File.fromUri(uri!) : File(photoUrl);
    if (!file.existsSync()) {
      return fallback;
    }

    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
