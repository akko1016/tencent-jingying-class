import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedPhotoImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isSmall;

  const CachedPhotoImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: isSmall ? 100 : 800,
      memCacheHeight: isSmall ? 100 : 1200,
      maxWidthDiskCache: isSmall ? 100 : 800,
      maxHeightDiskCache: isSmall ? 100 : 1200,
      cacheKey: imageUrl,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          strokeWidth: isSmall ? 2 : 3,
        ),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error),
      ),
      cacheManager: DefaultCacheManager(),
    );
  }
} 