import 'package:flutter/material.dart';

import '../../../core/utils/constants.dart';
import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders an Image component.
///
/// Currently supports network images. Asset and file support can be added later.
///
/// JSON Properties:
/// - `source` (string, optional): 'network', 'asset', or 'file'. Default: 'network'
/// - `url` (string, required): URL or path to the image
/// - `width` (number, optional): Width constraint in logical pixels
/// - `height` (number, optional): Height constraint in logical pixels
/// - `fit` (string, optional): How to fit the image. Values: 'fill', 'contain', 'cover', 'fitWidth', 'fitHeight', 'scaleDown'. Default: 'cover'
///
/// Example JSON:
/// ```json
/// {
///   "type": "image",
///   "source": "network",
///   "url": "https://example.com/image.jpg",
///   "width": 200,
///   "height": 150,
///   "fit": "cover"
/// }
/// ```
class ImageRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final source = PropertyParsers.parseImageSource(
      config.properties['source'] as String?,
    );
    final urlPath = config.properties['urlPath'] as String?;
    final boundUrl = _resolvePath(dataContext, urlPath);
    final url = (boundUrl?.toString().trim().isNotEmpty ?? false)
        ? boundUrl.toString()
        : (config.properties['url'] as String? ?? '');
    final resolvedUrl = _resolveNetworkUrl(url);
    final width = PropertyParsers.parseDouble(config.properties['width']);
    final height = PropertyParsers.parseDouble(config.properties['height']);
    final fitString = PropertyParsers.parseImageFitString(
      config.properties['fit'] as String?,
    );
    final fit = _stringToBoxFit(fitString);
    final aspectRatio = PropertyParsers.parseDouble(
      config.properties['aspectRatio'],
    );

    // For network images, use Image.network
    Widget image;
    if (source == 'network') {
      image = _buildNetworkImage(resolvedUrl, width, height, fit);
    } else if (source == 'asset') {
      image = _buildAssetImage(url, width, height, fit);
    } else if (source == 'file') {
      image = _buildFileImage(url, width, height, fit);
    } else {
      image = Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(child: Text('Unsupported image source')),
      );
    }

    if (aspectRatio != null && aspectRatio > 0) {
      return AspectRatio(aspectRatio: aspectRatio, child: image);
    }
    return image;
  }

  String _resolveNetworkUrl(String url) {
    final value = url.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$kBaseUrlAsset$value';
    }
    return value;
  }

  dynamic _resolvePath(Map<String, dynamic>? root, String? path) {
    if (root == null || path == null || path.isEmpty) return null;

    dynamic current = root;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Converts a fit string to BoxFit enum.
  static BoxFit _stringToBoxFit(String fit) {
    switch (fit) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }

  /// Builds a network image widget.
  Widget _buildNetworkImage(
    String url,
    double? width,
    double? height,
    BoxFit fit,
  ) {
    final image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image)),
        );
      },
    );

    // Wrap in SizedBox if dimensions are specified
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: image);
    }

    return image;
  }

  /// Builds an asset image widget.
  Widget _buildAssetImage(
    String path,
    double? width,
    double? height,
    BoxFit fit,
  ) {
    final image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image)),
        );
      },
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: image);
    }

    return image;
  }

  /// Placeholder for file-based images (not implemented yet).
  Widget _buildFileImage(
    String path,
    double? width,
    double? height,
    BoxFit fit,
  ) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(child: Text('File images not yet supported')),
    );
  }
}
