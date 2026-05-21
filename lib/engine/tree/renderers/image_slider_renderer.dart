import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/network_config.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/service_locator.dart';
import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

/// Full-screen image carousel or static hero image from JSON URLs only.
class ImageSliderRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final images = _parseImages(config.properties['images']);
    final fitString = PropertyParsers.parseImageFitString(
      config.properties['fit'] as String?,
    );
    final fit = _stringToBoxFit(fitString);
    final multi = images.length > 1;
    final autoPlay = config.properties.containsKey('autoPlay')
        ? config.properties['autoPlay'] == true
        : multi;
    final intervalMs =
        PropertyParsers.parseInt(config.properties['intervalMs']) ?? 1000;
    final showIndicators = config.properties.containsKey('showIndicators')
        ? config.properties['showIndicators'] == true
        : multi;
    final indicatorPosition =
        (config.properties['indicatorPosition'] as String? ?? 'bottom')
            .toLowerCase();
    final theme = EngineTheme.fromDataContext(dataContext);
    final indicatorColor = PropertyParsers.parseColor(
      config.properties['indicatorColor'] as String?,
    );
    final indicatorInactiveColor = PropertyParsers.parseColor(
      config.properties['indicatorInactiveColor'] as String?,
    );
    final animationDurationMs =
        PropertyParsers.parseInt(config.properties['animationDurationMs']) ??
        300;
    final indicatorStyle =
        (config.properties['indicatorStyle'] as String? ?? 'dot').toLowerCase();
    final indicatorBottomPadding =
        PropertyParsers.parseDouble(config.properties['indicatorBottomPadding']) ??
        24.0;

    if (images.isEmpty) {
      return const SizedBox.expand(child: ColoredBox(color: Color(0xFF0F172A)));
    }

    return _EngineImageSlider(
      images: images,
      fit: fit,
      autoPlay: autoPlay && multi,
      intervalMs: intervalMs.clamp(100, 60000),
      showIndicators: showIndicators && multi,
      indicatorOnTop: indicatorPosition == 'top',
      activeDotColor: indicatorColor ?? theme?.primaryColor ?? Colors.white,
      inactiveDotColor:
          indicatorInactiveColor ?? (theme?.mutedColor ?? Colors.white54),
      animationDurationMs: animationDurationMs.clamp(50, 5000),
      indicatorStyle: indicatorStyle,
      indicatorBottomPadding: indicatorBottomPadding.clamp(0.0, 400.0),
      theme: theme,
    );
  }

  static List<_SliderImage> _parseImages(dynamic raw) {
    if (raw is! List) return const [];
    final out = <_SliderImage>[];
    for (final entry in raw) {
      if (entry is String && entry.trim().isNotEmpty) {
        out.add(_SliderImage(url: entry.trim()));
      } else if (entry is Map) {
        final url = entry['url']?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        final alt = entry['alt']?.toString();
        out.add(_SliderImage(url: url, alt: alt));
      }
    }
    return out;
  }

  static BoxFit _stringToBoxFit(String fit) {
    switch (fit) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
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
}

class _SliderImage {
  const _SliderImage({required this.url, this.alt});

  final String url;
  final String? alt;
}

class _EngineImageSlider extends StatefulWidget {
  const _EngineImageSlider({
    required this.images,
    required this.fit,
    required this.autoPlay,
    required this.intervalMs,
    required this.showIndicators,
    required this.indicatorOnTop,
    required this.activeDotColor,
    required this.inactiveDotColor,
    required this.animationDurationMs,
    required this.indicatorStyle,
    required this.indicatorBottomPadding,
    this.theme,
  });

  final List<_SliderImage> images;
  final BoxFit fit;
  final bool autoPlay;
  final int intervalMs;
  final bool showIndicators;
  final bool indicatorOnTop;
  final Color activeDotColor;
  final Color inactiveDotColor;
  final int animationDurationMs;
  final String indicatorStyle;
  final double indicatorBottomPadding;
  final EngineTheme? theme;

  @override
  State<_EngineImageSlider> createState() => _EngineImageSliderState();
}

class _EngineImageSliderState extends State<_EngineImageSlider> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleAutoPlay();
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!widget.autoPlay || widget.images.length < 2) return;
    _autoPlayTimer = Timer(Duration(milliseconds: widget.intervalMs), () {
      if (!mounted) return;
      _advancePage();
      _scheduleAutoPlay();
    });
  }

  void _advancePage() {
    if (!mounted || widget.images.length < 2) return;
    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _advancePage();
      });
      return;
    }
    final next = (_currentIndex + 1) % widget.images.length;
    _pageController.animateToPage(
      next,
      duration: Duration(milliseconds: widget.animationDurationMs),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.length == 1) {
      return SizedBox.expand(child: _buildImage(widget.images.first));
    }

    final pageView = PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        _scheduleAutoPlay();
      },
      itemBuilder: (_, index) => _buildImage(widget.images[index]),
    );

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [pageView, if (widget.showIndicators) _buildIndicators()],
      ),
    );
  }

  Widget _buildImage(_SliderImage image) {
    final url = _resolveNetworkUrl(image.url);
    final resolvedUrl = url.trim();
    if (resolvedUrl.startsWith('assets/') ||
        (!resolvedUrl.startsWith('http://') &&
            !resolvedUrl.startsWith('https://'))) {
      return Image.asset(
        resolvedUrl,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return Image.network(
      resolvedUrl,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(progress: progress);
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder({ImageChunkEvent? progress}) {
    return ColoredBox(
      color: widget.theme?.surfaceColor ?? const Color(0xFF0F172A),
      child: Center(
        child: progress != null
            ? CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: widget.theme?.primaryColor ?? Colors.white,
              )
            : Icon(
                Icons.image_outlined,
                color: widget.theme?.mutedColor ?? Colors.white54,
              ),
      ),
    );
  }

  Widget _buildIndicators() {
    final usePill = widget.indicatorStyle == 'pill';
    final dots = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.images.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: usePill
                ? (i == _currentIndex ? 24.0 : 8.0)
                : (i == _currentIndex ? 10.0 : 8.0),
            height: usePill
                ? (i == _currentIndex ? 8.0 : 8.0)
                : (i == _currentIndex ? 10.0 : 8.0),
            decoration: BoxDecoration(
              borderRadius: usePill
                  ? BorderRadius.circular(4)
                  : null,
              shape: usePill ? BoxShape.rectangle : BoxShape.circle,
              color: i == _currentIndex
                  ? widget.activeDotColor
                  : widget.inactiveDotColor,
            ),
          ),
        ],
      ],
    );

    return Align(
      alignment: widget.indicatorOnTop
          ? Alignment.topCenter
          : Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.indicatorOnTop ? 24 : 0,
          bottom: widget.indicatorOnTop ? 0 : widget.indicatorBottomPadding,
        ),
        child: dots,
      ),
    );
  }

  String _resolveNetworkUrl(String url) {
    final value = url.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      final assetBase = getIt.isRegistered<NetworkConfig>()
          ? getIt<NetworkConfig>().assetBaseUrl
          : kBaseUrlAsset;
      return '$assetBase$value';
    }
    return value;
  }
}
