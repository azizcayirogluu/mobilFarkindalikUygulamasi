import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

String normalizeProfileAvatar(String image) {
  var normalized = image;
  if (normalized.startsWith('assets/') &&
      !normalized.startsWith('assets/image/')) {
    normalized = normalized.replaceFirst('assets/', 'assets/image/');
  }

  const removedAvatarAssets = {
    'assets/image/girls-boy.png',
    'assets/image/superhero-man.png',
    'assets/image/superhero-girls.png',
  };
  return removedAvatarAssets.contains(normalized)
      ? 'assets/image/boy.png'
      : normalized;
}

class ProfileAvatar extends StatelessWidget {
  final String image;
  final double radius;
  final Color backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.image,
    required this.radius,
    this.backgroundColor = const Color(0xFFF0F9FF),
  });

  @override
  Widget build(BuildContext context) {
    if (!image.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: AssetImage(image),
      );
    }

    return CachedNetworkImage(
      imageUrl: image,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: SizedBox(
          width: radius * 0.55,
          height: radius * 0.55,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: const AssetImage('assets/image/boy.png'),
      ),
    );
  }
}
