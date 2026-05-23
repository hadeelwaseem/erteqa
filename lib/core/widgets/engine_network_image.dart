import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../network/engine_image_cache_manager.dart';
import '../network/remote_image_url.dart';

/// Network catalog image with shared URL resolution and merchant-aware headers.
class EngineNetworkImage extends StatelessWidget {
  EngineNetworkImage({
    super.key,
    required String url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
  }) : url = resolveRemoteImageUrl(url);

  /// Final resolved URL passed to the image provider.
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  static void _logFailure(String imageUrl, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[EngineNetworkImage] FAILED $imageUrl');
    debugPrint('[EngineNetworkImage]   error: $error');
    if (stackTrace != null) {
      debugPrint('[EngineNetworkImage]   stack: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      const error = 'empty image url';
      _logFailure(trimmed, error);
      return errorBuilder?.call(context, Exception(error), null) ??
          const SizedBox.shrink();
    }

    final headers = httpHeadersForImageUrl(trimmed);
    if (kDebugMode) {
      debugPrint('[EngineNetworkImage] load $trimmed');
      debugPrint(
        '[EngineNetworkImage] headers: '
        '${headers != null ? 'merchant' : 'default'}',
      );
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      cacheManager: EngineImageCacheManager.instance,
      httpHeaders: headers,
      width: width,
      height: height,
      fit: fit,
      errorListener: (error) => _logFailure(trimmed, error),
      progressIndicatorBuilder: loadingBuilder == null
          ? null
          : (context, imageUrl, downloadProgress) {
              final total = downloadProgress.totalSize;
              final loaded = downloadProgress.downloaded;
              final fraction = downloadProgress.progress;
              if (fraction == null || fraction < 1) {
                return loadingBuilder!(
                  context,
                  const SizedBox.shrink(),
                  ImageChunkEvent(
                    cumulativeBytesLoaded: loaded,
                    expectedTotalBytes: total,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
      errorWidget: errorBuilder == null
          ? null
          : (context, imageUrl, error) {
              _logFailure(imageUrl, error, StackTrace.current);
              return errorBuilder!(context, error, StackTrace.current);
            },
    );
  }
}
