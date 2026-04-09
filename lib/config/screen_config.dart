import 'component_config.dart';

/// Configuration for a dynamic screen (page).
///
/// This is the minimal envelope for dynamic screens, containing:
/// - [pageId]: Unique identifier for the page (used for navigation)
/// - [pageName]: Human-readable display name (used for debugging and UI labels)
/// - [root]: The component tree representing the page content (content envelope)
class ScreenConfig {
  /// Unique identifier for this page. Used for route resolution and lookups.
  final String pageId;

  /// Human-readable display name for this page (for debugging and UI labels).
  final String pageName;

  /// The root component tree (content envelope) that defines the page layout and structure.
  final ComponentConfig root;

  const ScreenConfig({
    required this.pageId,
    required this.pageName,
    required this.root,
  });
}
