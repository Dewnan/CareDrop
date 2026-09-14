import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Reusable modular avatar widget displaying user profile picture with fallback to local asset placeholder.
class UserAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final File? localImageFile;
  final Uint8List? localImageBytes;
  final double size;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final String placeholderAsset;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    this.localImageFile,
    this.localImageBytes,
    this.size = 80,
    this.showEditBadge = false,
    this.onTap,
    this.placeholderAsset = 'assets/images/profile_picture_placeholder.jpg',
  });

  /// Builds image provider or widget based on local file, memory bytes, network URL, or placeholder asset
  Widget _buildAvatarImage() {
    if (localImageBytes != null && localImageBytes!.isNotEmpty) {
      return Image.memory(
        localImageBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (localImageFile != null) {
      return Image.file(
        localImageFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          placeholderAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          placeholderAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      placeholderAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: CareDropTheme.cardBorderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildAvatarImage(),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          avatarContent,
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: CareDropTheme.royalBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
