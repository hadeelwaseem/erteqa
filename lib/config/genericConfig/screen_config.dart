import 'component_config.dart';

/// Configuration for a screen with a single tree root.
class ScreenConfig {
  final String id;
  final ComponentConfig root;

  const ScreenConfig({
    required this.id,
    required this.root,
  });
}
