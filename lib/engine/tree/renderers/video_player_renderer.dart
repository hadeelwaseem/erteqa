import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders network video via [video_player].
///
/// JSON `props`:
/// - `url` (string, required): HTTPS video URL
/// - `autoplay` (bool, optional): default false
/// - `showControls` (bool, optional): tap to play/pause overlay; default true
/// - `height` (number, optional): viewport height; default 200
/// - `borderRadius` (number, optional): corner radius
class VideoPlayerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final url = config.properties['url'] as String? ?? '';
    final autoplay = config.properties['autoplay'] == true;
    final showControls = config.properties['showControls'] != false;
    final height = PropertyParsers.parseDouble(config.properties['height']) ?? 200;
    final borderRadius = PropertyParsers.parseBorderRadius(
      config.properties['borderRadius'],
    );

    if (url.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Missing video url')),
      );
    }

    return _EngineNetworkVideo(
      url: url,
      autoplay: autoplay,
      showControls: showControls,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class _EngineNetworkVideo extends StatefulWidget {
  const _EngineNetworkVideo({
    required this.url,
    required this.autoplay,
    required this.showControls,
    required this.height,
    this.borderRadius,
  });

  final String url;
  final bool autoplay;
  final bool showControls;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<_EngineNetworkVideo> createState() => _EngineNetworkVideoState();
}

class _EngineNetworkVideoState extends State<_EngineNetworkVideo> {
  VideoPlayerController? _controller;
  Future<void>? _init;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    _startInit();
  }

  void _startInit() {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    _initFailed = false;
    _init = _initVideo(controller);
  }

  Future<void> _initVideo(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!mounted) return;
      if (widget.autoplay) {
        await controller.play();
      }
      setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _initFailed = true);
      }
    }
  }

  void _retry() {
    _controller?.dispose();
    setState(() => _startInit());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  Widget _buildErrorState() {
    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not play video',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.zero;
    final controller = _controller;
    final init = _init;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: init == null || controller == null
            ? _buildErrorState()
            : FutureBuilder<void>(
                future: init,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const ColoredBox(
                      color: Color(0xFF0F172A),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                        ),
                      ),
                    );
                  }

                  if (_initFailed || !controller.value.isInitialized) {
                    return _buildErrorState();
                  }

                  final size = controller.value.size;
                  final video = FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: VideoPlayer(controller),
                    ),
                  );

                  if (!widget.showControls) {
                    return ColoredBox(color: Colors.black, child: video);
                  }

                  return GestureDetector(
                    onTap: _togglePlay,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Colors.black, child: video),
                        if (!controller.value.isPlaying)
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 56,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
