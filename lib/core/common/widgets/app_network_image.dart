import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'custom_shimmer.dart';

/// Network image tuned for Cloudinary.
///
/// Original uploads are often full-resolution (several MB). For Cloudinary
/// URLs this asks the CDN for a resized, compressed WebP that matches the
/// on-screen size instead, which is usually 10-50x smaller. It also decodes
/// at display size, so large images don't stall the UI thread or bloat
/// memory. Non-Cloudinary URLs are loaded unchanged.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pixelWidth = bucketWidth(logicalWidth * dpr);

        return CachedNetworkImage(
          imageUrl: optimizeCloudinaryUrl(url, width: pixelWidth),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: pixelWidth,
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: Duration.zero,
          placeholder: (context, _) => placeholder ?? const CustomShimmer(),
          errorWidget: (context, _, __) =>
              errorWidget ??
              Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.image, color: Colors.grey.shade400),
              ),
        );
      },
    );
  }

  /// Rounds up to a few fixed sizes so the same image rendered at slightly
  /// different widths reuses one CDN variant and one disk-cache entry.
  static int bucketWidth(double px) {
    const buckets = [160, 320, 480, 640, 800, 1080, 1440];
    for (final b in buckets) {
      if (px <= b) return b;
    }
    return buckets.last;
  }

  /// Inserts `w_<width>,c_limit,q_auto,f_webp` after `/image/upload/` in a
  /// Cloudinary delivery URL. Other URLs are returned unchanged.
  ///
  /// `f_webp` rather than `f_auto`: f_auto picks the format from the Accept
  /// header, which Flutter's HTTP client doesn't send, so it would fall back
  /// to JPEG/PNG. WebP is decoded natively by Flutter on all platforms.
  static String optimizeCloudinaryUrl(String url, {required int width}) {
    const marker = '/image/upload/';
    if (!url.contains('res.cloudinary.com')) return url;
    final i = url.indexOf(marker);
    if (i < 0) return url;
    final rest = url.substring(i + marker.length);
    // Already optimized by us - don't stack transformations.
    if (rest.startsWith('w_')) return url;
    return '${url.substring(0, i + marker.length)}'
        'w_$width,c_limit,q_auto,f_webp/$rest';
  }
}
