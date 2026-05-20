import 'package:flutter/material.dart';

import '../../../core/network/network_config.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/service_locator.dart';
import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

/// Renders an Image component.
///
/// Currently supports network images. Asset and file support can be added later.
class ImageRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final theme = EngineTheme.fromDataContext(dataContext);
    final source = PropertyParsers.parseImageSource(
      config.properties['source'] as String?,
    );
    final urlPath = config.properties['urlPath'] as String?;
    final boundUrl = resolveDataContextPath(dataContext, urlPath);
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

    Widget image;
    if (source == 'network') {
      image = _buildNetworkImage(
        resolvedUrl,
        width,
        height,
        fit,
        theme: theme,
      );
    } else if (source == 'asset') {
      image = _buildAssetImage(url, width, height, fit, theme: theme);
    } else if (source == 'file') {
      image = _buildFileImage(url, width, height, fit, theme: theme);
    } else {
      image = _placeholderBox(width, height, theme: theme);
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
      // Follow-up: inject assetBaseUrl via dataContext instead of getIt.
      final assetBase = getIt.isRegistered<NetworkConfig>()
          ? getIt<NetworkConfig>().assetBaseUrl
          : kBaseUrlAsset;
      return '$assetBase$value';
    }
    return value;
  }

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

  Widget _buildNetworkImage(
    String url,
    double? width,
    double? height,
    BoxFit fit, {
    EngineTheme? theme,
  }) {
    if (url.trim().isEmpty) {
      return _placeholderBox(width, height, theme: theme);
    }

    final image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingBox(
          width,
          height,
          theme: theme,
          progress: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _errorBox(width, height, theme: theme);
      },
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: image);
    }

    return image;
  }

  Widget _buildAssetImage(
    String path,
    double? width,
    double? height,
    BoxFit fit, {
    EngineTheme? theme,
  }) {
    final image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _errorBox(width, height, theme: theme);
      },
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: image);
    }

    return image;
  }

  Widget _buildFileImage(
    String path,
    double? width,
    double? height,
    BoxFit fit, {
    EngineTheme? theme,
  }) {
    return _placeholderBox(
      width,
      height,
      theme: theme,
      child: const Center(child: Text('File images not yet supported')),
    );
  }

  Widget _placeholderBox(
    double? width,
    double? height, {
    EngineTheme? theme,
    Widget? child,
  }) {
    return Container(
      width: width,
      height: height,
      color: theme?.surfaceColor ?? const Color(0xFFF8FAFC),
      child: child ??
          Center(
            child: Icon(
              Icons.image_outlined,
              color: theme?.mutedColor ?? const Color(0xFF475569),
            ),
          ),
    );
  }

  Widget _loadingBox(
    double? width,
    double? height, {
    EngineTheme? theme,
    double? progress,
  }) {
    return Container(
      width: width,
      height: height,
      color: theme?.surfaceColor ?? const Color(0xFFF8FAFC),
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          color: theme?.primaryColor ?? const Color(0xFF1D4ED8),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _errorBox(
    double? width,
    double? height, {
    EngineTheme? theme,
  }) {
    return Container(
      width: width,
      height: height,
      color: theme?.surfaceColor ?? const Color(0xFFF8FAFC),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: theme?.mutedColor ?? const Color(0xFF475569),
        ),
      ),
    );
  }
}
