import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../network/engine_image_cache_manager.dart';
import '../network/remote_image_url.dart';

/// Network catalog image with shared URL resolution and merchant-aware headers.
class EngineNetworkImage extends StatefulWidget {
  EngineNetworkImage({
    super.key,
    required String url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
  }) : url = resolveRemoteImageUrl(url);

  /// Initial resolved URL passed to the image provider.
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<EngineNetworkImage> createState() => _EngineNetworkImageState();
}

class _EngineNetworkImageState extends State<EngineNetworkImage> {
  late String _activeUrl;
  bool _retriedFullSize = false;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.url;
  }

  @override
  void didUpdateWidget(EngineNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _activeUrl = widget.url;
      _retriedFullSize = false;
    }
  }

  static void _logFailure(
    String imageUrl,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    debugPrint('[EngineNetworkImage] FAILED $imageUrl');
    debugPrint('[EngineNetworkImage]   error: $error');
    if (stackTrace != null) {
      debugPrint('[EngineNetworkImage]   stack: $stackTrace');
    }
  }

  void _maybeRetryWithFullSize(String failedUrl) {
    if (_retriedFullSize) {
      return;
    }
    final fallback = fullSizeFallbackForGeneratedThumbnail(failedUrl);
    if (fallback == null || fallback == failedUrl) {
      return;
    }
    _retriedFullSize = true;
    setState(() => _activeUrl = fallback);
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _activeUrl.trim();
    if (trimmed.isEmpty) {
      const error = 'empty image url';
      _logFailure(trimmed, error);
      return widget.errorBuilder?.call(context, Exception(error), null) ??
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
      key: ValueKey(trimmed),
      imageUrl: trimmed,
      cacheManager: EngineImageCacheManager.instance,
      httpHeaders: headers,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorListener: (error) {
        _logFailure(trimmed, error);
        _maybeRetryWithFullSize(trimmed);
      },
      progressIndicatorBuilder: widget.loadingBuilder == null
          ? null
          : (context, imageUrl, downloadProgress) {
              final total = downloadProgress.totalSize;
              final loaded = downloadProgress.downloaded;
              final fraction = downloadProgress.progress;
              if (fraction == null || fraction < 1) {
                return widget.loadingBuilder!(
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
      errorWidget: widget.errorBuilder == null
          ? null
          : (context, imageUrl, error) {
              if (!_retriedFullSize) {
                final fallback = fullSizeFallbackForGeneratedThumbnail(imageUrl);
                if (fallback != null && fallback != imageUrl) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _maybeRetryWithFullSize(imageUrl);
                    }
                  });
                  if (widget.loadingBuilder != null) {
                    return widget.loadingBuilder!(
                      context,
                      const SizedBox.shrink(),
                      null,
                    );
                  }
                  return SizedBox(
                    width: widget.width,
                    height: widget.height,
                  );
                }
              }
              _logFailure(imageUrl, error, StackTrace.current);
              return widget.errorBuilder!(
                context,
                error,
                StackTrace.current,
              );
            },
    );
  }
}
