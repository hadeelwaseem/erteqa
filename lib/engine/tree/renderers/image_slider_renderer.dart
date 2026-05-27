import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../../core/network/remote_image_url.dart';
import '../../../core/widgets/engine_network_image.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

/// Full-screen image carousel or static hero image from JSON URLs only.
class ImageSliderRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final images = _resolveImages(config.properties, dataContext);
    final fitString = PropertyParsers.parseImageFitString(
      config.properties['fit'] as String?,
    );
    final fit = _stringToBoxFit(fitString);
    final aspectRatio = PropertyParsers.parseDouble(config.properties['aspectRatio']);
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
        PropertyParsers.parseDouble(
          config.properties['indicatorBottomPadding'],
        ) ??
        24.0;
    final borderRadius = PropertyParsers.parseBorderRadius(
      config.properties['borderRadius'],
    );
    final enableFullscreenPreview = config.properties['enableFullscreenPreview'] == true;
    final showThumbnails = config.properties['showThumbnails'] == true;
    final showIndicatorsWhenSingle =
        config.properties['showIndicatorsWhenSingle'] == true;
    final showThumbnailsWhenSingle =
        config.properties['showThumbnailsWhenSingle'] == true;
    final thumbnailSize =
        PropertyParsers.parseDouble(config.properties['thumbnailSize']) ?? 64.0;
    final thumbnailGap =
        PropertyParsers.parseDouble(config.properties['thumbnailGap']) ?? 8.0;
    final thumbnailBorderRadius = PropertyParsers.parseDouble(
          config.properties['thumbnailBorderRadius'],
        ) ??
        10.0;
    final thumbnailBorderWidth = PropertyParsers.parseDouble(
          config.properties['thumbnailBorderWidth'],
        ) ??
        2.0;
    final thumbnailActiveBorderColor = PropertyParsers.parseColor(
      config.properties['thumbnailActiveBorderColor'] as String?,
    );
    final thumbnailInactiveBorderColor = PropertyParsers.parseColor(
      config.properties['thumbnailInactiveBorderColor'] as String?,
    );

    if (images.isEmpty) {
      return _buildEmptyState(
        aspectRatio: aspectRatio,
        borderRadius: borderRadius,
        theme: theme,
      );
    }

    return _EngineImageSlider(
      images: images,
      fit: fit,
      aspectRatio: aspectRatio,
      autoPlay: autoPlay && multi,
      intervalMs: intervalMs.clamp(100, 60000),
      showIndicators: showIndicators,
      showIndicatorsWhenSingle: showIndicatorsWhenSingle,
      indicatorOnTop: indicatorPosition == 'top',
      activeDotColor: indicatorColor ?? theme?.primaryColor ?? Colors.white,
      inactiveDotColor:
          indicatorInactiveColor ?? (theme?.mutedColor ?? Colors.white54),
      animationDurationMs: animationDurationMs.clamp(50, 5000),
      indicatorStyle: indicatorStyle,
      indicatorBottomPadding: indicatorBottomPadding.clamp(0.0, 400.0),
      borderRadius: borderRadius,
      enableFullscreenPreview: enableFullscreenPreview,
      showThumbnails: showThumbnails,
      showThumbnailsWhenSingle: showThumbnailsWhenSingle,
      thumbnailSize: thumbnailSize.clamp(24.0, 200.0),
      thumbnailGap: thumbnailGap.clamp(0.0, 48.0),
      thumbnailBorderRadius: thumbnailBorderRadius.clamp(0.0, 80.0),
      thumbnailBorderWidth: thumbnailBorderWidth.clamp(0.0, 8.0),
      thumbnailActiveBorderColor:
          thumbnailActiveBorderColor ?? theme?.primaryColor ?? Colors.orange,
      thumbnailInactiveBorderColor:
          thumbnailInactiveBorderColor ?? Colors.transparent,
      theme: theme,
    );
  }

  static List<_SliderImage> _resolveImages(
    Map<String, dynamic> properties,
    Map<String, dynamic>? dataContext,
  ) {
    final imagesPath = properties['imagesPath'] as String?;
    final itemUrlPath = (properties['itemUrlPath'] as String?)?.trim();
    final itemAltPath = (properties['itemAltPath'] as String?)?.trim();
    if (imagesPath != null && imagesPath.trim().isNotEmpty) {
      final bound = resolveDataContextPath(dataContext, imagesPath);
      final fromPath = _parseImages(
        bound,
        itemUrlPath: itemUrlPath,
        itemAltPath: itemAltPath,
      );
      if (fromPath.isNotEmpty) {
        return fromPath;
      }
    }
    return _parseImages(
      properties['images'],
      itemUrlPath: itemUrlPath,
      itemAltPath: itemAltPath,
    );
  }

  static List<_SliderImage> _parseImages(
    dynamic raw, {
    String? itemUrlPath,
    String? itemAltPath,
  }) {
    if (raw is! List) return const [];
    final out = <_SliderImage>[];
    for (final entry in raw) {
      if (entry is String && entry.trim().isNotEmpty) {
        out.add(_SliderImage(url: entry.trim()));
      } else if (entry is Map) {
        final url = _resolveMapPath(entry, itemUrlPath ?? 'url');
        if (url.isEmpty) continue;
        final alt = _resolveMapPath(
          entry,
          itemAltPath ?? 'alt',
          fallback: entry['alt']?.toString(),
        );
        out.add(_SliderImage(url: url, alt: alt));
      }
    }
    return out;
  }

  static String _resolveMapPath(
    Map<dynamic, dynamic> map,
    String path, {
    String? fallback,
  }) {
    if (path.trim().isEmpty) return fallback?.trim() ?? '';
    dynamic current = map;
    for (final segment in path.split('.')) {
      if (segment.isEmpty) continue;
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return fallback?.trim() ?? '';
      }
    }
    return current?.toString().trim() ?? (fallback?.trim() ?? '');
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

  static Widget _buildEmptyState({
    required double? aspectRatio,
    required BorderRadius? borderRadius,
    required EngineTheme? theme,
  }) {
    Widget empty = ColoredBox(
      color: theme?.surfaceColor ?? const Color(0xFF0F172A),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: theme?.mutedColor ?? Colors.white54,
        ),
      ),
    );
    if (borderRadius != null) {
      empty = ClipRRect(borderRadius: borderRadius, child: empty);
    }
    if (aspectRatio != null && aspectRatio > 0) {
      return AspectRatio(aspectRatio: aspectRatio, child: empty);
    }
    return SizedBox(height: 220, width: double.infinity, child: empty);
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
    required this.aspectRatio,
    required this.autoPlay,
    required this.intervalMs,
    required this.showIndicators,
    required this.showIndicatorsWhenSingle,
    required this.indicatorOnTop,
    required this.activeDotColor,
    required this.inactiveDotColor,
    required this.animationDurationMs,
    required this.indicatorStyle,
    required this.indicatorBottomPadding,
    required this.borderRadius,
    required this.enableFullscreenPreview,
    required this.showThumbnails,
    required this.showThumbnailsWhenSingle,
    required this.thumbnailSize,
    required this.thumbnailGap,
    required this.thumbnailBorderRadius,
    required this.thumbnailBorderWidth,
    required this.thumbnailActiveBorderColor,
    required this.thumbnailInactiveBorderColor,
    this.theme,
  });

  final List<_SliderImage> images;
  final BoxFit fit;
  final double? aspectRatio;
  final bool autoPlay;
  final int intervalMs;
  final bool showIndicators;
  final bool showIndicatorsWhenSingle;
  final bool indicatorOnTop;
  final Color activeDotColor;
  final Color inactiveDotColor;
  final int animationDurationMs;
  final String indicatorStyle;
  final double indicatorBottomPadding;
  final BorderRadius? borderRadius;
  final bool enableFullscreenPreview;
  final bool showThumbnails;
  final bool showThumbnailsWhenSingle;
  final double thumbnailSize;
  final double thumbnailGap;
  final double thumbnailBorderRadius;
  final double thumbnailBorderWidth;
  final Color thumbnailActiveBorderColor;
  final Color thumbnailInactiveBorderColor;
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

  Future<void> _openFullscreenPreview() async {
    if (!widget.enableFullscreenPreview || widget.images.isEmpty) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenSliderDialog(
        images: widget.images,
        initialIndex: _currentIndex,
        fit: widget.fit,
        indicatorColor: widget.activeDotColor,
        indicatorInactiveColor: widget.inactiveDotColor,
      ),
    );
  }

  void _goToPage(int index) {
    if (!mounted || index < 0 || index >= widget.images.length) return;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: widget.animationDurationMs),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _currentIndex = index);
    }
    _scheduleAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final mainMedia = _buildMainMedia();
    final canShowThumbnails =
        widget.showThumbnails &&
        (widget.images.length > 1 || widget.showThumbnailsWhenSingle);
    if (!canShowThumbnails) {
      return mainMedia;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mainMedia,
        SizedBox(height: widget.thumbnailGap),
        SizedBox(
          height: widget.thumbnailSize + (widget.thumbnailBorderWidth * 2),
          child: _buildThumbnailStrip(),
        ),
      ],
    );
  }

  Widget _buildMainMedia() {
    final sliderContent = widget.images.length == 1
        ? _buildImage(widget.images.first)
        : PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _scheduleAutoPlay();
            },
            itemBuilder: (_, index) => _buildImage(widget.images[index]),
          );
    final canShowIndicators =
        widget.showIndicators &&
        (widget.images.length > 1 || widget.showIndicatorsWhenSingle);
    final slider = Stack(
      fit: StackFit.expand,
      children: [
        sliderContent,
        if (canShowIndicators) _buildIndicators(),
      ],
    );

    Widget clipped = slider;
    if (widget.borderRadius != null) {
      clipped = ClipRRect(borderRadius: widget.borderRadius!, child: clipped);
    }
    if (!widget.enableFullscreenPreview) {
      return _applyAspectRatio(clipped);
    }
    return _applyAspectRatio(GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openFullscreenPreview,
      child: clipped,
    ));
  }

  Widget _applyAspectRatio(Widget child) {
    final ratio = widget.aspectRatio;
    if (ratio != null && ratio > 0) {
      return AspectRatio(aspectRatio: ratio, child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) {
          return SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: child,
          );
        }
        return SizedBox(height: 220, width: double.infinity, child: child);
      },
    );
  }

  Widget _buildThumbnailStrip() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: widget.images.length,
      separatorBuilder: (_, __) => SizedBox(width: widget.thumbnailGap),
      itemBuilder: (_, index) {
        final isActive = index == _currentIndex;
        return GestureDetector(
          key: Key('engine-image-slider-thumb-$index'),
          onTap: () => _goToPage(index),
          child: Container(
            width: widget.thumbnailSize,
            height: widget.thumbnailSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.thumbnailBorderRadius),
              border: Border.all(
                color: isActive
                    ? widget.thumbnailActiveBorderColor
                    : widget.thumbnailInactiveBorderColor,
                width: widget.thumbnailBorderWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.thumbnailBorderRadius),
              child: _buildImage(widget.images[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(_SliderImage image) {
    final resolvedUrl = resolveRemoteImageUrl(image.url).trim();
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

    return EngineNetworkImage(
      url: resolvedUrl,
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
              borderRadius: usePill ? BorderRadius.circular(4) : null,
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

}

class _FullscreenSliderDialog extends StatefulWidget {
  const _FullscreenSliderDialog({
    required this.images,
    required this.initialIndex,
    required this.fit,
    required this.indicatorColor,
    required this.indicatorInactiveColor,
  });

  final List<_SliderImage> images;
  final int initialIndex;
  final BoxFit fit;
  final Color indicatorColor;
  final Color indicatorInactiveColor;

  @override
  State<_FullscreenSliderDialog> createState() => _FullscreenSliderDialogState();
}

class _FullscreenSliderDialogState extends State<_FullscreenSliderDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, index) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: _buildImage(widget.images[index]),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              key: const Key('engine-image-slider-fullscreen-close'),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Container(
                      width: i == _index ? 10 : 8,
                      height: i == _index ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? widget.indicatorColor
                            : widget.indicatorInactiveColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(_SliderImage image) {
    final resolvedUrl = resolveRemoteImageUrl(image.url).trim();
    if (resolvedUrl.startsWith('assets/') ||
        (!resolvedUrl.startsWith('http://') &&
            !resolvedUrl.startsWith('https://'))) {
      return Image.asset(
        resolvedUrl,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return EngineNetworkImage(
      url: resolvedUrl,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54),
      ),
    );
  }
}
