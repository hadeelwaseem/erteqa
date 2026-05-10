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
  late final VideoPlayerController _controller;
  Future<void>? _init;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _init = _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      if (widget.autoplay) {
        await _controller.play();
      }
      setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FutureBuilder<void>(
          future: _init,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                !_controller.value.isInitialized) {
              return const ColoredBox(
                color: Color(0xFF0F172A),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              );
            }

            final size = _controller.value.size;
            final video = FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(_controller),
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
                  if (!_controller.value.isPlaying)
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
